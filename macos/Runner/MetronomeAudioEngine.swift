import Foundation
import AVFoundation

/// Native Audio Engine using AVAudioEngine for sample-accurate timing (macOS)
class MetronomeAudioEngine {

    private let sampleRate: Double = 44100.0
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?

    // Pre-loaded audio buffers
    private var highTickBuffer: AVAudioPCMBuffer?
    private var midTickBuffer: AVAudioPCMBuffer?
    private var lowTickBuffer: AVAudioPCMBuffer?

    private var isPlaying = false
    private var bpm: Int = 120
    private var beatsPerBar: Int = 4
    private var playBars: Int = 1
    private var muteBars: Int = 0

    private var currentBeat: Int = 0
    private var currentBar: Int = 0
    private var isMuted: Bool = false

    private var playbackThread: Thread?
    private var beatCallback: ((Int, Bool) -> Void)?

    /// Initialize the audio engine and preload audio buffers
    func initialize() -> Bool {
        do {
            // Create audio engine
            audioEngine = AVAudioEngine()
            playerNode = AVAudioPlayerNode()

            guard let engine = audioEngine, let player = playerNode else {
                return false
            }

            engine.attach(player)

            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
            engine.connect(player, to: engine.mainMixerNode, format: format)

            // Generate synthesized click sounds
            highTickBuffer = generateClickSound(frequency: 1000, durationMs: 30)
            midTickBuffer = generateClickSound(frequency: 800, durationMs: 30)
            lowTickBuffer = generateClickSound(frequency: 600, durationMs: 30)

            try engine.start()
            return true

        } catch {
            print("MetronomeAudioEngine: Failed to initialize - \(error)")
            return false
        }
    }

    /// Generate a simple click sound
    private func generateClickSound(frequency: Double, durationMs: Int) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * Double(durationMs) / 1000.0)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }

        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData?[0] else {
            return nil
        }

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = 1.0 - (Double(i) / Double(frameCount))
            let sample = Float(sin(2.0 * .pi * frequency * t) * envelope)
            channelData[i] = sample
        }

        return buffer
    }

    /// Start playback
    func start(bpm: Int, beatsPerBar: Int, playBars: Int, muteBars: Int) -> Bool {
        if isPlaying {
            _ = stop()
        }

        self.bpm = max(30, min(250, bpm))
        self.beatsPerBar = max(1, min(12, beatsPerBar))
        self.playBars = max(1, min(16, playBars))
        self.muteBars = max(0, min(16, muteBars))
        self.currentBeat = 0
        self.currentBar = 0
        self.isMuted = false

        guard let player = playerNode else {
            return false
        }

        isPlaying = true
        player.play()

        // Start playback thread
        playbackThread = Thread { [weak self] in
            self?.runPlaybackLoop()
        }
        playbackThread?.name = "MetronomeAudioThread"
        playbackThread?.start()

        return true
    }

    /// Main playback loop - runs on dedicated thread
    private func runPlaybackLoop() {
        var nextBeatTime = Date()

        while isPlaying {
            let currentBpm = self.bpm
            let beatDurationSeconds = 60.0 / Double(currentBpm)

            // Select tick sound
            let tickBuffer: AVAudioPCMBuffer?
            if isMuted {
                tickBuffer = nil
            } else if currentBeat == 0 {
                tickBuffer = highTickBuffer
            } else if beatsPerBar > 3 && currentBeat == beatsPerBar / 2 {
                tickBuffer = midTickBuffer
            } else {
                tickBuffer = lowTickBuffer
            }

            // Notify callback on main thread
            let beat = currentBeat
            let muted = isMuted
            DispatchQueue.main.async { [weak self] in
                self?.beatCallback?(beat, muted)
            }

            // Schedule audio playback
            if let buffer = tickBuffer, let player = playerNode {
                player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            }

            // Update beat counter
            currentBeat = (currentBeat + 1) % beatsPerBar

            // Handle bar mute logic
            if currentBeat == 0 {
                currentBar += 1

                if muteBars > 0 {
                    if isMuted {
                        if currentBar >= muteBars {
                            currentBar = 0
                            isMuted = false
                        }
                    } else {
                        if currentBar >= playBars {
                            currentBar = 0
                            isMuted = true
                        }
                    }
                }
            }

            // Calculate next beat time
            nextBeatTime = nextBeatTime.addingTimeInterval(beatDurationSeconds)
            let sleepInterval = nextBeatTime.timeIntervalSinceNow
            if sleepInterval > 0 {
                Thread.sleep(forTimeInterval: sleepInterval)
            }
        }
    }

    /// Stop playback
    func stop() -> Bool {
        isPlaying = false

        playbackThread?.cancel()
        playbackThread = nil

        playerNode?.stop()

        currentBeat = 0
        currentBar = 0
        isMuted = false

        return true
    }

    /// Update BPM during playback
    func setBpm(_ bpm: Int) {
        self.bpm = max(30, min(250, bpm))
    }

    /// Update beats per bar
    func setBeatsPerBar(_ beats: Int) {
        self.beatsPerBar = max(1, min(12, beats))
        self.currentBeat = 0
    }

    /// Update bar mute settings
    func setBarMute(playBars: Int, muteBars: Int) {
        self.playBars = max(1, min(16, playBars))
        self.muteBars = max(0, min(16, muteBars))
        self.currentBar = 0
        self.isMuted = false
    }

    /// Set beat callback
    func setBeatCallback(_ callback: ((Int, Bool) -> Void)?) {
        self.beatCallback = callback
    }

    /// Clean up resources
    func dispose() {
        _ = stop()

        audioEngine?.stop()

        if let player = playerNode, let engine = audioEngine {
            engine.detach(player)
        }

        playerNode = nil
        audioEngine = nil
        highTickBuffer = nil
        midTickBuffer = nil
        lowTickBuffer = nil
    }
}
