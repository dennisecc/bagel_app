import Vision
import UIKit

/// On-device text extraction shared by both the camera-scan and photo-upload paths,
/// so capture source never matters past this point in the pipeline.
enum TextRecognitionService {
    static func recognizeText(in images: [UIImage]) async throws -> String {
        var pages: [String] = []
        for image in images {
            let text = try await recognizeText(in: image)
            if !text.isEmpty { pages.append(text) }
        }
        return pages.joined(separator: "\n\n")
    }

    private static func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { return "" }
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
