import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // On-device ML channels — macOS stub. Same contract as Android
    // (`edgetal/embedder`, `edgetal/llm`); returning notImplemented / false lets
    // the Dart side fall back to the offline providers.
    // TODO: implement with the MediaPipe Tasks macOS/iOS frameworks, mirroring
    // EmbedderChannel.kt / LlmChannel.kt.
    let messenger = flutterViewController.engine.binaryMessenger
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

    super.awakeFromNib()
  }
}
