package com.exerscroll.exerscroll

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import java.util.TreeMap

object OverlayManager {
    fun isBlocked(context: Context, packageName: String): Boolean {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val json = prefs.getString("flutter.blocked_apps", null) ?: return false
        try {
            val list = JSONArray(json)
            for (i in 0 until list.length()) {
                val app = list.getJSONObject(i)
                if (app.getString("packageName") == packageName && app.getBoolean("isBlocked")) {
                    return true
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }

    fun hasTime(context: Context): Boolean {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // Flutter Shared Preferences stores Double as String usually containing "VGhpcyBpcyBhI..." (base64) for some versions or just Double?
        // Actually, newer versions might use "BigDouble" prefix.
        // Let's look at a simpler check: if we can't parse it, assume 0.
        // But safer: Check if key exists.
        if (!prefs.contains("flutter.time_bank")) return false
        
        try {
            // Try reading as Double (some implementations support it)
            // But standard Android SP doesn't.
            // Flutter plugin usually writes as String "VGhp..." for lists, but for Double?
            // "Double values are stored as String in Shared Preferences" -> No, actually they use "putLong" with doubleToRawLongBits sometimes?
            // Wait, looking at shared_preferences_android implementation:
            // It uses `putDouble` equivalent by storing as Float if it fits? No.
            // It uses "Double" prefix string?
            // Let's try reading as String and parsing.
            val str = prefs.getString("flutter.time_bank", null)
            if (str != null) {
                if (str.startsWith("VGhpcyBpcyBhI")) { // Prefix for something?
                   // If it's complicated encoding, we might fail.
                   // But typically it is just a string representation of double if using basic JSON approach or similar?
                   // NO, shared_preferences plugin 2.0+ uses standard types where possible, but Android SP has no Double.
                   // It uses "flutter." prefix.
                   // Docs say: "Double is stored as a string."
                   return (str.toDoubleOrNull() ?: 0.0) > 0.5
                }
                 return (str.toDoubleOrNull() ?: 0.0) > 0.5
            }
            // Maybe it is stored as specific format?
            // Let's assume the user has some time if we can't read it? No, better block if unsure or unblock?
            // Safer: return false (block) if we can't verify time.
            return false
        } catch (e: Exception) {
            return false
        }
    }
}

class OverlayService : Service() {
    private lateinit var windowManager: WindowManager
    private var overlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())
    private val checkRunnable = object : Runnable {
        override fun run() {
            checkForegroundApp()
            handler.postDelayed(this, 1000)
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()
        startForeground(1, createNotification())
        
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        
        handler.post(checkRunnable)
        
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        removeOverlay()
        handler.removeCallbacks(checkRunnable)
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, "overlay_channel")
            .setContentTitle("ExerScroll Blocking Active")
            .setContentText("Monitoring app usage...")
            .setSmallIcon(R.mipmap.ic_launcher)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "overlay_channel",
                "Overlay Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun checkForegroundApp() {
        if (!Settings.canDrawOverlays(this)) return

        val usageStatsManager = getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, time - 1000 * 60, time)
        
        if (stats != null && stats.isNotEmpty()) {
            val sortedMap = TreeMap<Long, android.app.usage.UsageStats>()
            for (usageStats in stats) {
                sortedMap[usageStats.lastTimeUsed] = usageStats
            }
            if (sortedMap.isNotEmpty()) {
                val currentApp = sortedMap[sortedMap.lastKey()]?.packageName
                if (currentApp != null && currentApp != packageName) {
                    if (OverlayManager.isBlocked(this, currentApp)) {
                        if (!OverlayManager.hasTime(this)) {
                            showOverlay()
                            return
                        }
                    }
                }
            }
        }
        removeOverlay()
    }

    private fun showOverlay() {
        if (overlayView != null) return
        
        overlayView = LayoutInflater.from(this).inflate(R.layout.overlay_blocker, null)
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) 
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY 
            else 
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        )
        
        try {
            windowManager.addView(overlayView, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun removeOverlay() {
        if (overlayView != null) {
            try {
                windowManager.removeView(overlayView)
            } catch (e: Exception) {
                e.printStackTrace()
            }
            overlayView = null
        }
    }
}
