package com.example.metronome

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Handler
import android.os.Looper
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.concurrent.thread

/**
 * Native Audio Engine using AudioTrack for sample-accurate timing
 */
class MetronomeAudioEngine(private val context: Context) {

    companion object {
        private const val SAMPLE_RATE = 44100
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_OUT_MONO
        private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
    }

    private var audioTrack: AudioTrack? = null
    private var playbackThread: Thread? = null

    private var highTickSamples: ShortArray? = null  // 强拍
    private var midTickSamples: ShortArray? = null   // 中拍
    private var lowTickSamples: ShortArray? = null   // 弱拍

    private var isPlaying = false
    private var bpm = 120
    private var beatsPerBar = 4
    private var playBars = 1
    private var muteBars = 0

    private var currentBeat = 0
    private var currentBar = 0
    private var isMuted = false

    private var beatCallback: ((Int, Boolean) -> Unit)? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    /**
     * 初始化音频引擎，预加载音频 buffer
     */
    fun initialize(): Boolean {
        return try {
            // 直接生成合成音频
            highTickSamples = generateClickSound(frequency = 1000.0, durationMs = 30)
            midTickSamples = generateClickSound(frequency = 800.0, durationMs = 30)
            lowTickSamples = generateClickSound(frequency = 600.0, durationMs = 30)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    /**
     * 生成一个简单的点击音（作为后备方案）
     */
    private fun generateClickSound(frequency: Double = 800.0, durationMs: Int = 30): ShortArray {
        val numSamples = (SAMPLE_RATE * durationMs / 1000.0).toInt()
        val samples = ShortArray(numSamples)

        for (i in 0 until numSamples) {
            val t = i.toDouble() / SAMPLE_RATE
            // 生成带衰减的正弦波
            val envelope = 1.0 - (i.toDouble() / numSamples)
            val sample = (Math.sin(2 * Math.PI * frequency * t) * envelope * Short.MAX_VALUE).toInt()
            samples[i] = sample.coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort()
        }

        return samples
    }

    /**
     * 开始播放
     */
    fun start(bpm: Int, beatsPerBar: Int, playBars: Int, muteBars: Int): Boolean {
        if (isPlaying) stop()

        this.bpm = bpm.coerceIn(30, 250)
        this.beatsPerBar = beatsPerBar.coerceIn(1, 12)
        this.playBars = playBars.coerceIn(1, 16)
        this.muteBars = muteBars.coerceIn(0, 16)
        this.currentBeat = 0
        this.currentBar = 0
        this.isMuted = false

        val minBufferSize = AudioTrack.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)

        audioTrack = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AUDIO_FORMAT)
                    .setSampleRate(SAMPLE_RATE)
                    .setChannelMask(CHANNEL_CONFIG)
                    .build()
            )
            .setBufferSizeInBytes(minBufferSize * 2)  // 减小缓冲区以降低延迟
            .setTransferMode(AudioTrack.MODE_STREAM)
            .setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY)
            .build()

        isPlaying = true
        audioTrack?.play()

        playbackThread = thread(start = true, name = "MetronomeAudioThread") {
            runPlaybackLoop()
        }

        return true
    }

    /**
     * 音频播放循环 - 运行在独立线程
     * AudioTrack.write() 是阻塞的，会自动控制节拍时间
     */
    private fun runPlaybackLoop() {
        while (isPlaying) {
            val currentBpm = bpm
            val currentSamplesPerBeat = (SAMPLE_RATE * 60.0 / currentBpm).toInt()

            // 选择要播放的音频
            val tickSamples = if (isMuted) {
                null
            } else {
                when {
                    currentBeat == 0 -> highTickSamples
                    beatsPerBar > 3 && currentBeat == beatsPerBar / 2 -> midTickSamples
                    else -> lowTickSamples
                }
            }

            // 生成这一拍的音频数据
            val beatBuffer = ShortArray(currentSamplesPerBeat)

            if (tickSamples != null) {
                // 将 tick 音频复制到 buffer 开头
                val copyLength = minOf(tickSamples.size, beatBuffer.size)
                System.arraycopy(tickSamples, 0, beatBuffer, 0, copyLength)
            }

            // 同步触发回调（在写入音频的同时）
            val beat = currentBeat
            val muted = isMuted
            beatCallback?.let { callback ->
                mainHandler.post { callback(beat, muted) }
            }

            // 写入 AudioTrack（阻塞调用，自动控制节拍时间）
            val byteBuffer = ByteBuffer.allocate(beatBuffer.size * 2)
            byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
            byteBuffer.asShortBuffer().put(beatBuffer)

            val written = audioTrack?.write(byteBuffer.array(), 0, byteBuffer.capacity()) ?: 0
            if (written < 0) break  // 写入错误，退出循环

            // 更新节拍计数
            currentBeat = (currentBeat + 1) % beatsPerBar

            // 检查小节循环
            if (currentBeat == 0) {
                currentBar++

                if (muteBars > 0) {
                    if (isMuted) {
                        if (currentBar >= muteBars) {
                            currentBar = 0
                            isMuted = false
                        }
                    } else {
                        if (currentBar >= playBars) {
                            currentBar = 0
                            isMuted = true
                        }
                    }
                }
            }
        }
    }

    /**
     * 停止播放
     */
    fun stop(): Boolean {
        isPlaying = false

        playbackThread?.join(1000)
        playbackThread = null

        audioTrack?.stop()
        audioTrack?.release()
        audioTrack = null

        currentBeat = 0
        currentBar = 0
        isMuted = false

        return true
    }

    /**
     * 设置 BPM
     */
    fun setBpm(bpm: Int) {
        this.bpm = bpm.coerceIn(30, 250)
    }

    /**
     * 设置每小节拍数
     */
    fun setBeatsPerBar(beats: Int) {
        this.beatsPerBar = beats.coerceIn(1, 12)
        this.currentBeat = 0
    }

    /**
     * 设置循环静音
     */
    fun setBarMute(playBars: Int, muteBars: Int) {
        this.playBars = playBars.coerceIn(1, 16)
        this.muteBars = muteBars.coerceIn(0, 16)
        this.currentBar = 0
        this.isMuted = false
    }

    /**
     * 设置节拍回调
     */
    fun setBeatCallback(callback: ((Int, Boolean) -> Unit)?) {
        this.beatCallback = callback
    }

    /**
     * 释放资源
     */
    fun dispose() {
        stop()
        highTickSamples = null
        midTickSamples = null
        lowTickSamples = null
    }
}
