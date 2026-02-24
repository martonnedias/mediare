import Flutter
import UIKit
import GoogleMaps
// ... dentro do didFinishLaunchingWithOptions
GMSServices.provideAPIKey("AIzaSyAVwFW4k41AW1MDQKuZEpNfSZmX_LKDLNw")

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
