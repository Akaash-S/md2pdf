import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "md2pdf/screenshot",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { (call, result) in
      // iOS: screenshot prevention is not directly supported via API
      // The system blurs the app in App Switcher when this is set
      if call.method == "setProtection" {
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
