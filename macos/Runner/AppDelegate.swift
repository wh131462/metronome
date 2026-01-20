import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    private let channelName = "com.eternalheart.metronome/audio"
    private var audioEngine: MetronomeAudioEngine?
    private var channel: FlutterMethodChannel?

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
            return
        }

        audioEngine = MetronomeAudioEngine()

        channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.engine.binaryMessenger)

        channel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate not available", details: nil))
                return
            }

            switch call.method {
            case "initialize":
                let success = self.audioEngine?.initialize() ?? false
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

                let success = self.audioEngine?.start(bpm: bpm, beatsPerBar: beatsPerBar, playBars: playBars, muteBars: muteBars) ?? false
                result(success)

            case "stop":
                let success = self.audioEngine?.stop() ?? false
                result(success)

            case "setBpm":
                guard let args = call.arguments as? [String: Any],
                      let bpm = args["bpm"] as? Int else {
                    result(false)
                    return
                }
                self.audioEngine?.setBpm(bpm)
                result(true)

            case "setBeatsPerBar":
                guard let args = call.arguments as? [String: Any],
                      let beats = args["beats"] as? Int else {
                    result(false)
                    return
                }
                self.audioEngine?.setBeatsPerBar(beats)
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
                result(true)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Set beat callback
        audioEngine?.setBeatCallback { [weak self] beat, isMuted in
            self?.channel?.invokeMethod("onBeat", arguments: ["beat": beat, "isMuted": isMuted])
        }
    }

    override func applicationWillTerminate(_ notification: Notification) {
        audioEngine?.dispose()
    }
}
