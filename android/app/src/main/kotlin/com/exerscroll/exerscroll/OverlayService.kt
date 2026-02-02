package com.exerscroll.exerscroll

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.LayoutInflater
import android.view.WindowManager
import android.view.View
import android.widget.Button
import androidx.core.app.NotificationCompat

class OverlayService : Service() {
  companion object {
    const val NOTIFICATION_ID = 1
    const val CHANNEL_ID = "overlay_channel"
  }
  
  private var windowManager: WindowManager? = null
  private var overlayView: View? = null
  
  override fun onBind(intent: Intent?): IBinder? {
    return null
  }
  
  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    createNotificationChannel()
    startForeground(NOTIFICATION_ID, createNotification())
    
    // Check if already shown to avoid duplicates
    if (overlayView == null) {
        createBlockingOverlay()
    }
    
    return START_STICKY
  }
  
  override fun onDestroy() {
    super.onDestroy()
    if (overlayView != null && windowManager != null) {
        windowManager?.removeView(overlayView)
        overlayView = null
    }
  }
  
  private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val serviceChannel = NotificationChannel(
        CHANNEL_ID,
        "Overlay Service Channel",
        NotificationManager.IMPORTANCE_DEFAULT
      )
      val manager = getSystemService(NotificationManager::class.java)
      manager.createNotificationChannel(serviceChannel)
    }
  }
  
  private fun createNotification(): Notification {
    return NotificationCompat.Builder(this, CHANNEL_ID)
      .setContentTitle("ExerScroll Active")
      .setContentText("Blocking apps until exercise")
      .setSmallIcon(R.mipmap.ic_launcher)
      .build()
  }
  
  private fun createBlockingOverlay() {
    val inflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
    overlayView = inflater.inflate(R.layout.overlay_blocker, null)
    
    val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
    } else {
        WindowManager.LayoutParams.TYPE_PHONE
    }

    val params = WindowManager.LayoutParams(
      WindowManager.LayoutParams.MATCH_PARENT,
      WindowManager.LayoutParams.MATCH_PARENT,
      layoutFlag,
      WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
      WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
      WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
      WindowManager.LayoutParams.FLAG_FULLSCREEN,
      PixelFormat.TRANSLUCENT
    )
    
    windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    windowManager?.addView(overlayView, params)
    
    // Setup button listener
    val btn = overlayView?.findViewById<Button>(R.id.exercise_now)
    btn?.setOnClickListener {
        // Stop the service (removes overlay) and launch main app
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        if (launchIntent != null) {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(launchIntent)
        }
        stopSelf()
    }
  }
}
