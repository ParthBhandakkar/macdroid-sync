package com.macdroid.macdroid

import android.app.Notification
import android.app.NotificationManager
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.MediaStore
import android.provider.Settings
import android.telephony.TelephonyManager
import android.util.Base64
import android.util.Size
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.macdroid/native"
    private var alarmRingtone: Ringtone? = null
    private var isAlarmPlaying = false

    companion object {
        var instance: MainActivity? = null
        var methodChannel: MethodChannel? = null

        fun notifyFlutter(method: String, arguments: Any?) {
            instance?.runOnUiThread {
                methodChannel?.invokeMethod(method, arguments)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        instance = this
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getTelemetry" -> {
                    try {
                        result.success(fetchTelemetry())
                    } catch (e: Exception) {
                        result.error("TELEMETRY_ERROR", e.message, null)
                    }
                }
                "findMyPhone" -> {
                    startFindMyPhoneAlarm()
                    result.success(true)
                }
                "stopFindMyPhone" -> {
                    stopFindMyPhoneAlarm()
                    result.success(true)
                }
                "isAlarmPlaying" -> {
                    result.success(isAlarmPlaying)
                }
                "setRingerMode" -> {
                    val mode = call.argument<String>("mode") ?: "normal"
                    setDeviceRingerMode(mode)
                    result.success(true)
                }
                "toggleDnd" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    val success = setDndMode(enable)
                    result.success(success)
                }
                "dialCall" -> {
                    val number = call.argument<String>("number") ?: ""
                    if (number.isNotBlank()) {
                        val intent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:$number")).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "sendSms" -> {
                    val number = call.argument<String>("number") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:$number")).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        putExtra("sms_body", message)
                    }
                    startActivity(intent)
                    result.success(true)
                }
                "getRecentPhotos" -> {
                    val limit = call.argument<Int>("limit") ?: 20
                    Thread {
                        val photos = fetchRecentPhotos(limit)
                        runOnUiThread { result.success(photos) }
                    }.start()
                }
                "getPhotoBytes" -> {
                    val photoId = call.argument<String>("photoId") ?: ""
                    Thread {
                        val bytes = fetchPhotoBytes(photoId)
                        runOnUiThread { result.success(bytes) }
                    }.start()
                }
                "openNotificationSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    })
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        stopFindMyPhoneAlarm()
        if (instance == this) {
            instance = null
            methodChannel = null
        }
        super.onDestroy()
    }

    private fun fetchTelemetry(): Map<String, Any?> {
        // Battery info
        val batteryFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatusIntent = registerReceiver(null, batteryFilter)
        val level = batteryStatusIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = batteryStatusIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val batteryPct = if (level != -1 && scale > 0) ((level.toFloat() / scale.toFloat()) * 100).toInt() else 100
        val status = batteryStatusIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL

        // Storage info
        val statFs = StatFs(Environment.getDataDirectory().path)
        val freeBytes = statFs.availableBytes
        val totalBytes = statFs.totalBytes

        // Wi-Fi info
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
        val activeNet = cm?.activeNetwork
        val caps = cm?.getNetworkCapabilities(activeNet)
        val isWifi = caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
        val isCellular = caps?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true

        val wifiName: String = when {
            isWifi -> {
                try {
                    val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                    val ssid = wm?.connectionInfo?.ssid?.replace("\"", "")
                    if (ssid != null && ssid != "<unknown ssid>" && ssid.isNotBlank()) ssid else "Wi-Fi Connected"
                } catch (_: Exception) {
                    "Wi-Fi Connected"
                }
            }
            isCellular -> "Cellular 5G/LTE"
            else -> "Not Connected"
        }

        // Cellular carrier info
        val tm = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        val carrierName = tm?.networkOperatorName?.takeIf { it.isNotBlank() } ?: "Mobile Network"

        // Ringer mode
        val am = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        val ringer = when (am?.ringerMode) {
            AudioManager.RINGER_MODE_SILENT -> "silent"
            AudioManager.RINGER_MODE_VIBRATE -> "vibrate"
            else -> "normal"
        }

        // DND mode
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        val isDnd = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            nm?.currentInterruptionFilter != NotificationManager.INTERRUPTION_FILTER_ALL
        } else {
            false
        }

        return mapOf(
            "batteryLevel" to batteryPct,
            "isCharging" to isCharging,
            "wifiSsid" to wifiName,
            "wifiStrength" to 4,
            "cellularCarrier" to carrierName,
            "cellularBars" to 4,
            "storageFreeBytes" to freeBytes,
            "storageTotalBytes" to totalBytes,
            "ringerMode" to ringer,
            "isDoNotDisturb" to isDnd,
            "isHotspotOn" to false
        )
    }

    private fun startFindMyPhoneAlarm() {
        if (isAlarmPlaying) return
        isAlarmPlaying = true
        try {
            val am = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            // Maximize alarm stream volume
            val maxVol = am?.getStreamMaxVolume(AudioManager.STREAM_ALARM) ?: 10
            am?.setStreamVolume(AudioManager.STREAM_ALARM, maxVol, 0)

            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                ?: Settings.System.DEFAULT_RINGTONE_URI

            alarmRingtone = RingtoneManager.getRingtone(applicationContext, alarmUri)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                alarmRingtone?.audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            }
            alarmRingtone?.play()

            // Vibrate repeating pattern
            triggerVibration(true)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopFindMyPhoneAlarm() {
        isAlarmPlaying = false
        try {
            alarmRingtone?.stop()
            alarmRingtone = null
            triggerVibration(false)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun triggerVibration(enable: Boolean) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            vm?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
        if (enable) {
            val timings = longArrayOf(0, 600, 300, 600, 300, 600)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(timings, 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(timings, 0)
            }
        } else {
            vibrator?.cancel()
        }
    }

    private fun setDeviceRingerMode(mode: String) {
        try {
            val am = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return
            when (mode.lowercase()) {
                "silent" -> {
                    am.ringerMode = AudioManager.RINGER_MODE_SILENT
                }
                "vibrate" -> {
                    am.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                }
                "normal" -> {
                    am.ringerMode = AudioManager.RINGER_MODE_NORMAL
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun setDndMode(enable: Boolean): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return false
            if (!nm.isNotificationPolicyAccessGranted) {
                // Request access via settings
                val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
                return false
            }
            nm.setInterruptionFilter(
                if (enable) NotificationManager.INTERRUPTION_FILTER_PRIORITY
                else NotificationManager.INTERRUPTION_FILTER_ALL
            )
            return true
        }
        return false
    }

    private fun fetchRecentPhotos(limit: Int): List<Map<String, Any>> {
        val photos = mutableListOf<Map<String, Any>>()
        try {
            val projection = arrayOf(
                MediaStore.Images.Media._ID,
                MediaStore.Images.Media.DISPLAY_NAME,
                MediaStore.Images.Media.SIZE,
                MediaStore.Images.Media.DATE_ADDED
            )
            val sortOrder = "${MediaStore.Images.Media.DATE_ADDED} DESC"
            contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                projection,
                null,
                null,
                sortOrder
            )?.use { cursor ->
                val idCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
                val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)
                val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.SIZE)
                val dateCol = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_ADDED)
                var count = 0
                while (cursor.moveToNext() && count < limit) {
                    val id = cursor.getLong(idCol)
                    val name = cursor.getString(nameCol) ?: "photo_$id.jpg"
                    val size = cursor.getLong(sizeCol)
                    val dateAdded = cursor.getLong(dateCol) * 1000L
                    val contentUri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)

                    var thumbBase64 = ""
                    try {
                        val bitmap = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            contentResolver.loadThumbnail(contentUri, Size(200, 200), null)
                        } else {
                            @Suppress("DEPRECATION")
                            MediaStore.Images.Thumbnails.getThumbnail(contentResolver, id, MediaStore.Images.Thumbnails.MINI_KIND, null)
                        }
                        if (bitmap != null) {
                            val stream = ByteArrayOutputStream()
                            bitmap.compress(Bitmap.CompressFormat.JPEG, 70, stream)
                            thumbBase64 = Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
                        }
                    } catch (_: Exception) {}

                    photos.add(mapOf(
                        "id" to id.toString(),
                        "fileName" to name,
                        "fileSizeBytes" to size,
                        "timestamp" to dateAdded,
                        "thumbnailBase64" to thumbBase64
                    ))
                    count++
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return photos
    }

    private fun fetchPhotoBytes(photoId: String): ByteArray? {
        return try {
            val id = photoId.toLongOrNull() ?: return null
            val uri = ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
            contentResolver.openInputStream(uri)?.use { it.readBytes() }
        } catch (e: Exception) {
            null
        }
    }
}
