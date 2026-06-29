import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "EdgeTalMl") {
      AppDelegate.registerMlChannels(messenger: registrar.messenger())
    }
  }

  /// On-device ML channels — iOS stub.
  ///
  /// Same contract as the Android implementation (`edgetal/embedder`,
  /// `edgetal/llm`). Returning `notImplemented` / `false` lets the Dart
  /// `NativeEmbeddingProvider` / `NativeLlmProvider` fall back to the offline
  /// providers, so the app runs unchanged on iOS.
  ///
  /// TODO: implement with the MediaPipeTasksText / MediaPipeTasksGenAI iOS pods,
  /// mirroring `EmbedderChannel.kt` / `LlmChannel.kt` on Android.
  static func registerMlChannels(messenger: FlutterBinaryMessenger) {
    let embedder = FlutterMethodChannel(name: "edgetal/embedder", binaryMessenger: messenger)
    embedder.setMethodCallHandler { _, result in result(FlutterMethodNotImplemented) }

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
