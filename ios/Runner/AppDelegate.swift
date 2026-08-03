import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      AppDelegate.registerMlChannels(messenger: controller.binaryMessenger)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private static let embedderChannel = EmbedderChannel()

  static func registerMlChannels(messenger: FlutterBinaryMessenger) {
    embedderChannel.register(messenger: messenger)

    let llm = FlutterMethodChannel(name: "edgetal/llm", binaryMessenger: messenger)
    llm.setMethodCallHandler { call, result in
      if call.method == "initialize" {
        result(false)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
