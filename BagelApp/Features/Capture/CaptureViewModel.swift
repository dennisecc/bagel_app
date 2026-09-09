import Foundation
import UIKit
import BagelCore

/// Drives the capture pipeline (OCR -> LLM) and exposes its state to `CaptureView`.
/// Persistence is deliberately left to the view (via `ReceiptPersister`), matching
/// the rest of the app's convention of mutating SwiftData only from views/`.modelContext`.
@Observable
final class CaptureViewModel {
    enum Stage: Equatable {
        case idle
        case recognizingText
        case parsingWithLLM
        case reviewReady
        case failed(message: String, canRetryLLM: Bool)
    }

    private(set) var stage: Stage = .idle
    private(set) var rawOCRText: String = ""
    private(set) var parsedReceipt: ParsedReceipt?

    private var knownCategoryNames: [String] = []
    private let environment: AppEnvironment

    init(environment: AppEnvironment = .shared) {
        self.environment = environment
    }

    @MainActor
    func process(images: [UIImage], categoryNames: [String]) async {
        guard !images.isEmpty else { return }
        knownCategoryNames = categoryNames
        stage = .recognizingText
        do {
            let text = try await TextRecognitionService.recognizeText(in: images)
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                stage = .failed(message: "Couldn't read any text from this document. Try rescanning with better lighting.", canRetryLLM: false)
                return
            }
            rawOCRText = text
            await parseWithLLM(ocrText: text)
        } catch {
            stage = .failed(message: "Couldn't read this document. Try rescanning with better lighting.", canRetryLLM: false)
        }
    }

    @MainActor
    func retryLLM() async {
        guard !rawOCRText.isEmpty else { return }
        await parseWithLLM(ocrText: rawOCRText)
    }

    @MainActor
    func reset() {
        stage = .idle
        rawOCRText = ""
        parsedReceipt = nil
        knownCategoryNames = []
    }

    @MainActor
    private func parseWithLLM(ocrText: String) async {
        stage = .parsingWithLLM
        do {
            let service = try environment.makeReceiptParsingService()
            let parsed = try await service.parse(ocrText: ocrText, knownCategories: knownCategoryNames)
            parsedReceipt = parsed
            stage = .reviewReady
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "Something went wrong while parsing this document."
            stage = .failed(message: message, canRetryLLM: true)
        }
    }
}
