import UIKit
import Flutter
import Firebase
import FirebaseFirestore
import GoogleMaps
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase before Flutter plugins — required by native Swift
    // plugins that use async/await (firebase_messaging, firebase_crashlytics).
    // Without this, plugin registration hits swift_Concurrency_fatalErrorv.
    FirebaseApp.configure()
    configureFirestoreCache()

    // Initialize Google Maps with API key for iOS
    if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let apiKey = plist["GMSApiKey"] as? String {
      GMSServices.provideAPIKey(apiKey)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AudioSessionManager") {
      AudioSessionManager.register(with: registrar.messenger())
    }
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  private func configureFirestoreCache() {
    let firestore = Firestore.firestore()
    let settings = firestore.settings

    // Configure the persistent cache natively before any Flutter/Dart code can
    // touch Firestore. This avoids the startup race where the iOS client begins
    // opening its persistence/gRPC stack and then gets reconfigured from Dart.
    settings.cacheSettings = PersistentCacheSettings(
      sizeBytes: NSNumber(value: 100 * 1024 * 1024)
    )
    firestore.settings = settings
  }
}
