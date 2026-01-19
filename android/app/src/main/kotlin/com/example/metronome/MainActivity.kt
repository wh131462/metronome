package com.example.metronome

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.metronome/audio"
    private var audioEngine: MetronomeAudioEngine? = null
    private var methodChannel: MethodChannel? = null

    companion object {
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 1001
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 请求通知权限（Android 13+）
        requestNotificationPermission()

        audioEngine = MetronomeAudioEngine(this)

        // 保存 MethodChannel 实例以便复用
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // 设置服务回调
        setupServiceCallbacks()

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val success = audioEngine?.initialize() ?: false
                    result.success(success)
                }
                "start" -> {
                    val bpm = call.argument<Int>("bpm") ?: 120
                    val beatsPerBar = call.argument<Int>("beatsPerBar") ?: 4
                    val playBars = call.argument<Int>("playBars") ?: 1
                    val muteBars = call.argument<Int>("muteBars") ?: 0

                    val success = audioEngine?.start(bpm, beatsPerBar, playBars, muteBars) ?: false
                    if (success) {
                        // 更新服务状态并启动通知
                        MetronomeService.currentBpm = bpm
                        MetronomeService.currentBeats = beatsPerBar
                        MetronomeService.isPlaying = true
                        startMetronomeService()
                    }
                    result.success(success)
                }
                "stop" -> {
                    val success = audioEngine?.stop() ?: false
                    // 停止服务
                    MetronomeService.isPlaying = false
                    stopMetronomeService()
                    result.success(success)
                }
                "setBpm" -> {
                    val bpm = call.argument<Int>("bpm") ?: 120
                    audioEngine?.setBpm(bpm)
                    MetronomeService.currentBpm = bpm
                    updateServiceNotification()
                    result.success(true)
                }
                "setBeatsPerBar" -> {
                    val beats = call.argument<Int>("beats") ?: 4
                    audioEngine?.setBeatsPerBar(beats)
                    MetronomeService.currentBeats = beats
                    updateServiceNotification()
                    result.success(true)
                }
                "setBarMute" -> {
                    val playBars = call.argument<Int>("playBars") ?: 1
                    val muteBars = call.argument<Int>("muteBars") ?: 0
                    audioEngine?.setBarMute(playBars, muteBars)
                    result.success(true)
                }
                "dispose" -> {
                    audioEngine?.dispose()
                    stopMetronomeService()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // 设置节拍回调 - 复用已保存的 MethodChannel 减少延迟
        audioEngine?.setBeatCallback { beat, isMuted ->
            methodChannel?.invokeMethod("onBeat", mapOf("beat" to beat, "isMuted" to isMuted))
        }
    }

    private fun setupServiceCallbacks() {
        // 播放/暂停回调
        MetronomeService.onPlayPause = {
            if (MetronomeService.isPlaying) {
                audioEngine?.stop()
                MetronomeService.isPlaying = false
                methodChannel?.invokeMethod("onPlayStateChanged", mapOf("isPlaying" to false))
            } else {
                audioEngine?.start(
                    MetronomeService.currentBpm,
                    MetronomeService.currentBeats,
                    1, 0
                )
                MetronomeService.isPlaying = true
                methodChannel?.invokeMethod("onPlayStateChanged", mapOf("isPlaying" to true))
            }
            updateServiceNotification()
        }

        // 停止回调
        MetronomeService.onStop = {
            audioEngine?.stop()
            MetronomeService.isPlaying = false
            methodChannel?.invokeMethod("onPlayStateChanged", mapOf("isPlaying" to false))
        }

        // 预设切换回调
        MetronomeService.onPresetChange = { bpm, beats, presetIndex ->
            MetronomeService.currentBpm = bpm
            MetronomeService.currentBeats = beats

            if (MetronomeService.isPlaying) {
                audioEngine?.stop()
                audioEngine?.start(bpm, beats, 1, 0)
            }

            audioEngine?.setBpm(bpm)
            audioEngine?.setBeatsPerBar(beats)

            methodChannel?.invokeMethod("onPresetChanged", mapOf(
                "bpm" to bpm,
                "beatsPerBar" to beats,
                "presetIndex" to presetIndex
            ))

            updateServiceNotification()
        }
    }

    private fun startMetronomeService() {
        val intent = Intent(this, MetronomeService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopMetronomeService() {
        val intent = Intent(this, MetronomeService::class.java)
        stopService(intent)
    }

    private fun updateServiceNotification() {
        if (MetronomeService.isRunning) {
            val intent = Intent(this, MetronomeService::class.java)
            startService(intent)
        }
    }

    override fun onDestroy() {
        audioEngine?.dispose()
        stopMetronomeService()
        super.onDestroy()
    }

    private fun requestNotificationPermission() {
        // Android 13 (API 33) 及以上需要运行时请求通知权限
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIFICATION_PERMISSION_REQUEST_CODE
                )
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            NOTIFICATION_PERMISSION_REQUEST_CODE -> {
                // 权限请求结果，无需特殊处理
                // 如果用户拒绝，通知栏控制将不可用，但不影响 App 核心功能
            }
        }
    }
}
