package com.example.metronome

import android.app.*
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.BitmapFactory
import android.os.Build
import android.os.IBinder
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle

/**
 * 节拍器前台服务 - 在通知栏显示播放控制
 */
class MetronomeService : Service() {

    companion object {
        const val CHANNEL_ID = "metronome_playback_channel"
        const val NOTIFICATION_ID = 1001

        const val ACTION_PLAY = "com.example.metronome.PLAY"
        const val ACTION_PAUSE = "com.example.metronome.PAUSE"
        const val ACTION_STOP = "com.example.metronome.STOP"
        const val ACTION_PRESET_1 = "com.example.metronome.PRESET_1"  // 流行 4/4
        const val ACTION_PRESET_2 = "com.example.metronome.PRESET_2"  // 华尔兹 3/4
        const val ACTION_PRESET_3 = "com.example.metronome.PRESET_3"  // 进行曲 2/4

        var isRunning = false
        var currentBpm = 120
        var currentBeats = 4
        var isPlaying = false

        var onPlayPause: (() -> Unit)? = null
        var onStop: (() -> Unit)? = null
        var onPresetChange: ((Int, Int, Int) -> Unit)? = null  // bpm, beats, preset index
    }

    private var mediaSession: MediaSessionCompat? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        setupMediaSession()
        isRunning = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PLAY, ACTION_PAUSE -> {
                onPlayPause?.invoke()
            }
            ACTION_STOP -> {
                onStop?.invoke()
                stopSelf()
            }
            ACTION_PRESET_1 -> {
                onPresetChange?.invoke(120, 4, 0)  // 流行/摇滚
            }
            ACTION_PRESET_2 -> {
                onPresetChange?.invoke(90, 3, 1)   // 华尔兹
            }
            ACTION_PRESET_3 -> {
                onPresetChange?.invoke(110, 2, 2)  // 进行曲
            }
        }

        updateNotification()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        mediaSession?.release()
        isRunning = false
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "节拍器播放",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "节拍器播放控制"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun setupMediaSession() {
        mediaSession = MediaSessionCompat(this, "MetronomeSession").apply {
            setFlags(
                MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS or
                MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS
            )

            setCallback(object : MediaSessionCompat.Callback() {
                override fun onPlay() {
                    if (!isPlaying) Companion.onPlayPause?.invoke()
                }

                override fun onPause() {
                    if (isPlaying) Companion.onPlayPause?.invoke()
                }

                override fun onStop() {
                    Companion.onStop?.invoke()
                    stopSelf()
                }
            })

            isActive = true
        }

        updateMediaSessionState()
    }

    private fun updateMediaSessionState() {
        val state = if (isPlaying) {
            PlaybackStateCompat.STATE_PLAYING
        } else {
            PlaybackStateCompat.STATE_PAUSED
        }

        mediaSession?.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setActions(
                    PlaybackStateCompat.ACTION_PLAY or
                    PlaybackStateCompat.ACTION_PAUSE or
                    PlaybackStateCompat.ACTION_STOP or
                    PlaybackStateCompat.ACTION_PLAY_PAUSE
                )
                .setState(state, 0, 1f)
                .build()
        )

        mediaSession?.setMetadata(
            MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, "$currentBpm BPM")
                .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, "${currentBeats}/4 拍")
                .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, "节拍器")
                .build()
        )
    }

    fun updateNotification() {
        updateMediaSessionState()

        val notification = buildNotification()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun buildNotification(): Notification {
        // 点击通知打开 App
        val contentIntent = PendingIntent.getActivity(
            this,
            0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 播放/暂停按钮
        val playPauseIntent = PendingIntent.getService(
            this, 1,
            Intent(this, MetronomeService::class.java).apply {
                action = if (isPlaying) ACTION_PAUSE else ACTION_PLAY
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 停止按钮
        val stopIntent = PendingIntent.getService(
            this, 2,
            Intent(this, MetronomeService::class.java).apply { action = ACTION_STOP },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 预设按钮
        val preset1Intent = PendingIntent.getService(
            this, 3,
            Intent(this, MetronomeService::class.java).apply { action = ACTION_PRESET_1 },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val preset2Intent = PendingIntent.getService(
            this, 4,
            Intent(this, MetronomeService::class.java).apply { action = ACTION_PRESET_2 },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val playPauseIcon = if (isPlaying) {
            android.R.drawable.ic_media_pause
        } else {
            android.R.drawable.ic_media_play
        }

        val playPauseTitle = if (isPlaying) "暂停" else "播放"

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("$currentBpm BPM · ${currentBeats}/4 拍")
            .setContentText(if (isPlaying) "正在播放" else "已暂停")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(contentIntent)
            .setOngoing(isPlaying)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(android.R.drawable.ic_menu_recent_history, "4/4", preset1Intent)
            .addAction(android.R.drawable.ic_menu_recent_history, "3/4", preset2Intent)
            .addAction(playPauseIcon, playPauseTitle, playPauseIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "停止", stopIntent)
            .setStyle(
                MediaStyle()
                    .setMediaSession(mediaSession?.sessionToken)
                    .setShowActionsInCompactView(2, 3)  // 显示播放和停止按钮
            )
            .build()
    }
}
