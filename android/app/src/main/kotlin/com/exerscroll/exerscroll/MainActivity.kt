package com.exerscroll.exerscroll

import android.app.Activity
import android.app.Application
import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Bundle
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import org.json.JSONArray
import java.util.Calendar

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.exerscroll.exerscroll/overlay"
    private val executor = Executors.newSingleThreadExecutor()
    private val monitorExecutor: ScheduledExecutorService = Executors.newSingleThreadScheduledExecutor()
    
    // Track last check time to calculate deduction
    private var lastCheckTime = 0L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsageStatsPermission" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(null)
                }
                "getInstalledApps" -> {
                    executor.execute {
                        val apps = getInstalledApps()
                        runOnUiThread {
                            result.success(apps)
                        }
                    }
                }
                "startNativeOverlay" -> {
                    startNativeOverlay()
                    result.success(null)
                }
                "stopNativeOverlay" -> {
                    stopNativeOverlay()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startNativeOverlay() {
        val intent = Intent(this, OverlayService::class.java)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopNativeOverlay() {
        val intent = Intent(this, OverlayService::class.java)
        stopService(intent)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Register lifecycle callbacks
        application.registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
            override fun onActivityResumed(activity: Activity) {
                val pkg = activity.packageName
                if (isAppBlocked(pkg) && !hasEnoughTime()) {
                    startNativeOverlay()
                }
            }
            override fun onActivityPaused(activity: Activity) {}
            override fun onActivityStarted(activity: Activity) {}
            override fun onActivityDestroyed(activity: Activity) {}
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
            override fun onActivityStopped(activity: Activity) {}
            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
        })

        // Start background monitoring
        startBackgroundMonitor()
    }

    private fun startBackgroundMonitor() {
        monitorExecutor.scheduleAtFixedRate(Runnable {
            if (hasUsageStatsPermission()) {
                val currentTime = System.currentTimeMillis()
                val foregroundPackage = getForegroundPackage()
                
                if (foregroundPackage != null && isAppBlocked(foregroundPackage)) {
                    if (!hasEnoughTime()) {
                        // User is out of time -> Block immediately
                        startNativeOverlay()
                    } else {
                        // User has time -> Deduct time if we haven't checked recently
                        if (lastCheckTime > 0) {
                            val diff = currentTime - lastCheckTime
                            // Deduct if diff is reasonable (e.g. < 5 seconds, to avoid huge jumps after sleep)
                            if (diff < 5000) {
                                deductTime(diff)
                            }
                        }
                    }
                }
                lastCheckTime = currentTime
            }
        }, 1, 1, TimeUnit.SECONDS)
    }

    private fun getForegroundPackage(): String? {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val time = System.currentTimeMillis()
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, time - 1000 * 10, time)
        
        if (stats != null && stats.isNotEmpty()) {
            val sortedStats = stats.sortedByDescending { it.lastTimeUsed }
            return sortedStats.first().packageName
        }
        return null
    }

    private fun isAppBlocked(packageName: String): Boolean {
        // Read from Flutter SharedPreferences
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val jsonString = prefs.getString("flutter.blocked_apps", null) ?: return false
        
        try {
            val jsonArray = JSONArray(jsonString)
            for (i in 0 until jsonArray.length()) {
                val appObj = jsonArray.getJSONObject(i)
                if (appObj.getString("packageName") == packageName) {
                    return true
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }

    private fun hasEnoughTime(): Boolean {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // Flutter shared_preferences stores doubles as Long bits
        val banked = java.lang.Double.longBitsToDouble(
            prefs.getLong("flutter.time_bank", java.lang.Double.doubleToRawLongBits(0.0))
        )
        return banked > 0
    }
    
    private fun deductTime(amountMs: Long) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val currentBank = java.lang.Double.longBitsToDouble(
            prefs.getLong("flutter.time_bank", java.lang.Double.doubleToRawLongBits(0.0))
        )
        
        val minutesToDeduct = amountMs / 1000.0 / 60.0
        
        if (minutesToDeduct > 0) {
            val newBank = (currentBank - minutesToDeduct).coerceAtLeast(0.0)
            prefs.edit()
                .putLong("flutter.time_bank", java.lang.Double.doubleToRawLongBits(newBank))
                .apply()
        }
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val apps = mutableListOf<Map<String, Any>>()
        val pm = packageManager
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)

        for (appInfo in packages) {
            // Filter system apps and apps without launch intent
            if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0) {
                if (pm.getLaunchIntentForPackage(appInfo.packageName) != null) {
                    val appMap = mutableMapOf<String, Any>()
                    appMap["name"] = pm.getApplicationLabel(appInfo).toString()
                    appMap["packageName"] = appInfo.packageName
                    
                    try {
                        val icon = pm.getApplicationIcon(appInfo)
                        val bitmap = drawableToBitmap(icon)
                        val stream = ByteArrayOutputStream()
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                        appMap["icon"] = stream.toByteArray()
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                    
                    apps.add(appMap)
                }
            }
        }
        return apps
    }
    
    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable) {
            return drawable.bitmap
        }
        val bitmap = Bitmap.createBitmap(
            if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 1,
            if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 1,
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    override fun onDestroy() {
        monitorExecutor.shutdown()
        super.onDestroy()
    }
}
