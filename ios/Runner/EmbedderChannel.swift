import Flutter
import Foundation
import MediaPipeTasksText

/// Native side of the `edgetal/embedder` channel on iOS — on-device text embeddings
/// via MediaPipe's Text Embedder (`TextEmbedder`).
class EmbedderChannel {
    private var embedder: TextEmbedder?
    private var dimension: Int = 0
    private let queue = DispatchQueue(label: "com.knovik.edgetal.embedder", qos: .userInitiated)

    func register(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: "edgetal/embedder", binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            switch call.method {
            case "initialize":
                self.queue.async {
                    do {
                        let dim = try self.ensureEmbedder()
                        DispatchQueue.main.async { result(dim) }
                    } catch {
                        DispatchQueue.main.async {
                            result(FlutterError(code: "INIT_FAILED", message: error.localizedDescription, details: nil))
                        }
                    }
                }
            case "embed":
                let args = call.arguments as? [String: Any]
                let text = args?["text"] as? String ?? ""
                self.queue.async {
                    do {
                        _ = try self.ensureEmbedder()
                        guard let embedder = self.embedder else {
                            throw NSError(domain: "EmbedderError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Embedder instance is nil"])
                        }
                        let embeddingResult = try embedder.embed(text: text)
                        guard let firstEmbedding = embeddingResult.embeddingResult.embeddings.first else {
                            throw NSError(domain: "EmbedderError", code: -2, userInfo: [NSLocalizedDescriptionKey: "No embeddings returned"])
                        }

                        let floatVector: [Float]
                        if let floatArray = firstEmbedding.floatEmbedding {
                            floatVector = floatArray.map { $0.floatValue }
                        } else {
                            floatVector = []
                        }
                        let normalized = self.normalize(floatVector).map { Double($0) }
                        DispatchQueue.main.async { result(normalized) }
                    } catch {
                        DispatchQueue.main.async {
                            result(FlutterError(code: "EMBED_FAILED", message: error.localizedDescription, details: nil))
                        }
                    }
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func ensureEmbedder() throws -> Int {
        if embedder != nil {
            return dimension
        }
        guard let modelPath = Bundle.main.path(forResource: "text_embedder", ofType: "tflite") else {
            throw NSError(domain: "EmbedderError", code: 404, userInfo: [NSLocalizedDescriptionKey: "text_embedder.tflite asset not found in main bundle"])
        }
        let options = TextEmbedderOptions()
        options.baseOptions.modelAssetPath = modelPath

        let createdEmbedder = try TextEmbedder(options: options)
        self.embedder = createdEmbedder

        let probeResult = try createdEmbedder.embed(text: "dimension probe")
        if let firstEmbedding = probeResult.embeddingResult.embeddings.first,
           let floatArray = firstEmbedding.floatEmbedding {
            dimension = floatArray.count
        } else {
            dimension = 512
        }
        return dimension
    }

    private func normalize(_ v: [Float]) -> [Float] {
        var mag: Double = 0.0
        for x in v { mag += Double(x * x) }
        mag = sqrt(mag)
        if mag == 0.0 { return v }
        return v.map { Float(Double($0) / mag) }
    }
}
