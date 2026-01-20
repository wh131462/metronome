import Flutter
import UIKit
import MediaPlayer
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let channelName = "com.eternalheart.metronome/audio"
    private var audioEngine: MetronomeAudioEngine?
    private var channel: FlutterMethodChannel?

    private var currentBpm: Int = 120
    private var currentBeats: Int = 4
    private var isPlaying: Bool = false

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // 启用远程控制事件
        UIApplication.shared.beginReceivingRemoteControlEvents()

        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        audioEngine = MetronomeAudioEngine()

        channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)

        channel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate not available", details: nil))
                return
            }

            switch call.method {
            case "initialize":
                let success = self.audioEngine?.initialize() ?? false
                if success {
                    self.setupRemoteCommandCenter()
                }
                result(success)

            case "start":
                guard let args = call.arguments as? [String: Any] else {
                    result(false)
                    return
                }
                let bpm = args["bpm"] as? Int ?? 120
                let beatsPerBar = args["beatsPerBar"] as? Int ?? 4
                let playBars = args["playBars"] as? Int ?? 1
                let muteBars = args["muteBars"] as? Int ?? 0

                self.currentBpm = bpm
                self.currentBeats = beatsPerBar

                let success = self.audioEngine?.start(bpm: bpm, beatsPerBar: beatsPerBar, playBars: playBars, muteBars: muteBars) ?? false
                if success {
                    self.isPlaying = true
                    self.updateNowPlayingInfo()
                }
                result(success)

            case "stop":
                let success = self.audioEngine?.stop() ?? false
                self.isPlaying = false
                self.clearNowPlayingInfo()
                result(success)

            case "setBpm":
                guard let args = call.arguments as? [String: Any],
                      let bpm = args["bpm"] as? Int else {
                    result(false)
                    return
                }
                self.currentBpm = bpm
                self.audioEngine?.setBpm(bpm)
                self.updateNowPlayingInfo()
                result(true)

            case "setBeatsPerBar":
                guard let args = call.arguments as? [String: Any],
                      let beats = args["beats"] as? Int else {
                    result(false)
                    return
                }
                self.currentBeats = beats
                self.audioEngine?.setBeatsPerBar(beats)
                self.updateNowPlayingInfo()
                result(true)

            case "setBarMute":
                guard let args = call.arguments as? [String: Any] else {
                    result(false)
                    return
                }
                let playBars = args["playBars"] as? Int ?? 1
                let muteBars = args["muteBars"] as? Int ?? 0
                self.audioEngine?.setBarMute(playBars: playBars, muteBars: muteBars)
                result(true)

            case "dispose":
                self.audioEngine?.dispose()
                self.clearNowPlayingInfo()
                result(true)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Set beat callback
        audioEngine?.setBeatCallback { [weak self] beat, isMuted in
            self?.channel?.invokeMethod("onBeat", arguments: ["beat": beat, "isMuted": isMuted])
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Remote Command Center

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // 播放命令
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self, !self.isPlaying else { return .success }

            _ = self.audioEngine?.start(
                bpm: self.currentBpm,
                beatsPerBar: self.currentBeats,
                playBars: 1,
                muteBars: 0
            )
            self.isPlaying = true
            self.updateNowPlayingInfo()
            self.channel?.invokeMethod("onPlayStateChanged", arguments: ["isPlaying": true])
            return .success
        }

        // 暂停命令
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self, self.isPlaying else { return .success }

            _ = self.audioEngine?.stop()
            self.isPlaying = false
            self.updateNowPlayingInfo()
            self.channel?.invokeMethod("onPlayStateChanged", arguments: ["isPlaying": false])
            return .success
        }

        // 播放/暂停切换命令
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }

            if self.isPlaying {
                _ = self.audioEngine?.stop()
                self.isPlaying = false
            } else {
                _ = self.audioEngine?.start(
                    bpm: self.currentBpm,
                    beatsPerBar: self.currentBeats,
                    playBars: 1,
                    muteBars: 0
                )
                self.isPlaying = true
            }
            self.updateNowPlayingInfo()
            self.channel?.invokeMethod("onPlayStateChanged", arguments: ["isPlaying": self.isPlaying])
            return .success
        }

        // 停止命令
        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }

            _ = self.audioEngine?.stop()
            self.isPlaying = false
            self.clearNowPlayingInfo()
            self.channel?.invokeMethod("onPlayStateChanged", arguments: ["isPlaying": false])
            return .success
        }
    }

    // MARK: - Now Playing Info

    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()

        nowPlayingInfo[MPMediaItemPropertyTitle] = "\(currentBpm) BPM"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "\(currentBeats)/4 拍"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "节拍器"
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused

        print("iOS Now Playing: \(currentBpm) BPM, isPlaying: \(isPlaying)")
    }

    private func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPNowPlayingInfoCenter.default().playbackState = .stopped
    }

    override func applicationWillTerminate(_ application: UIApplication) {
        audioEngine?.dispose()
        clearNowPlayingInfo()
    }
}
