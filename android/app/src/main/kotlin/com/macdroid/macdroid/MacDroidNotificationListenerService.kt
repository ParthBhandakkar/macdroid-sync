package com.macdroid.macdroid

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class MacDroidNotificationListenerService : NotificationListenerService() {
    companion object {
        var isRunning = false
        var activeService: MacDroidNotificationListenerService? = null
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isRunning = true
        activeService = this
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        isRunning = false
        activeService = null
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val packageName = sbn.packageName ?: return
        if (packageName == applicationContext.packageName) return // Ignore own notifications

        val extras = sbn.notification?.extras ?: return
        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val body = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        if (title.isBlank() && body.isBlank()) return

        val pm = applicationContext.packageManager
        val appName = try {
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (_: Exception) {
            packageName
        }

        // Check if quick reply action exists
        var hasQuickReply = false
        sbn.notification.actions?.forEach { action ->
            if (action?.remoteInputs != null && action.remoteInputs.isNotEmpty()) {
                hasQuickReply = true
            }
        }

        val map = mapOf(
            "id" to sbn.key,
            "packageName" to packageName,
            "appName" to appName,
            "title" to title,
            "body" to body,
            "timestamp" to sbn.postTime,
            "hasQuickReply" to hasQuickReply
        )

        MainActivity.notifyFlutter("onNotificationPosted", map)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        if (sbn == null) return
        MainActivity.notifyFlutter("onNotificationDismissed", mapOf("id" to sbn.key))
    }
}
