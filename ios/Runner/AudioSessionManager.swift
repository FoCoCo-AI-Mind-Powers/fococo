import AVFoundation
import Flutter

/// Manages the iOS audio session for FoCoCo voice.
///
/// - `activate`        — voice conversation: `.playAndRecord` so the mic and
///                       speaker are both available (used while recording).
/// - `activatePlayback`— TTS-only playback: `.playback` so Cartesia speech can
///                       continue when the app is backgrounded / screen locked
///                       (paired with the `audio` UIBackgroundMode).
/// - `deactivate`      — release the session.
///
/// Interruptions (calls, Siri) and route changes (headphone unplug) are
/// forwarded to Dart over the same channel so the voice layer can pause and
/// resume cleanly instead of ending up in a glitchy state.
class AudioSessionManager: NSObject {
    private let channel: FlutterMethodChannel
    private var observersRegistered = false

    private init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: "com.fococo.audio/session",
            binaryMessenger: messenger
        )
        let manager = AudioSessionManager(channel: channel)
        channel.setMethodCallHandler { call, result in
            manager.handle(call, result: result)
        }
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let session = AVAudioSession.sharedInstance()
        do {
            switch call.method {
            case "activate":
                try session.setCategory(
                    .playAndRecord,
                    mode: .voiceChat,
                    options: [.defaultToSpeaker, .allowBluetooth]
                )
                try session.setActive(true)
                registerObservers()
                result(nil)
            case "activatePlayback":
                // Background-friendly category for Cartesia TTS playback.
                try session.setCategory(
                    .playback,
                    mode: .spokenAudio,
                    options: [.allowBluetooth, .allowAirPlay]
                )
                try session.setActive(true)
                registerObservers()
                result(nil)
            case "deactivate":
                try session.setActive(false, options: .notifyOthersOnDeactivation)
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        } catch {
            result(FlutterError(
                code: "AUDIO_SESSION_ERROR",
                message: error.localizedDescription,
                details: nil
            ))
        }
    }

    private func registerObservers() {
        guard !observersRegistered else { return }
        observersRegistered = true
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: raw)
        else { return }

        switch type {
        case .began:
            channel.invokeMethod("interruption", arguments: ["type": "began"])
        case .ended:
            var shouldResume = false
            if let optionsRaw = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsRaw)
                shouldResume = options.contains(.shouldResume)
            }
            channel.invokeMethod(
                "interruption",
                arguments: ["type": "ended", "shouldResume": shouldResume]
            )
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let raw = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: raw)
        else { return }

        if reason == .oldDeviceUnavailable {
            // Headphones / Bluetooth removed — pause so audio does not blast
            // out of the speaker unexpectedly.
            channel.invokeMethod("routeChange", arguments: ["reason": "deviceUnavailable"])
        }
    }
}
