import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps iOS SDK must be initialized before any map usage, otherwise the app
    // will crash with: GMSServicesException ("must be initialized via provideAPIKey prior to use")
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      GMSServices.provideAPIKey(apiKey)
    } else {
      // Don't crash in production; just log a clear message.
      NSLog("⚠️ Missing GMSApiKey in Info.plist. Google Maps will not work until it's provided.")
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
 