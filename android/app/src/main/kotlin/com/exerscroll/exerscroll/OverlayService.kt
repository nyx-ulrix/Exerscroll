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
                // Check both 'isBlocked' (for backward compatibility) and 'enabled' (current field name)
                val isEnabled = if (app.has("enabled")) app.getBoolean("enabled") else app.optBoolean("isBlocked", false)
                if (app.getString("packageName") == packageName && isEnabled) {
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
        // Read the banked minutes (time_bank) and used minutes to calculate remaining
        if (!prefs.contains("flutter.time_bank")) return true // If not set, allow access (safer default)
        
        try {
            // Flask SharedPreferences stores Doubles
            val bankedStr = prefs.getString("flutter.time_bank", "0")
            val usedStr = prefs.getString("flutter.used_today_${getTodayKey()}", "0")
            
            val banked = bankedStr?.toDoubleOrNull() ?: 0.0
            val used = usedStr?.toDoubleOrNull() ?: 0.0
            val remaining = (banked - used).coerceAtLeast(0.0)
            
            return remaining > 0
        } catch (e: Exception) {
            e.printStackTrace()
            return true // If error reading, allow access (safer default)
        }
    }
    
    private fun getTodayKey(): String {
        val now = System.currentTimeMillis()
        val calendar = java.util.Calendar.getInstance()
        calendar.timeInMillis = now
        val year = calendar.get(java.util.Calendar.YEAR)
        val month = (calendar.get(java.util.Calendar.MONTH) + 1).toString().padStart(2, '0')
        val day = calendar.get(java.util.Calendar.DAY_OF_MONTH).toString().padStart(2, '0')
        return "$year-$month-$day"
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
        // Ensure it covers status bar and nav bar
        params.flags = params.flags or 
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or 
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        
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
