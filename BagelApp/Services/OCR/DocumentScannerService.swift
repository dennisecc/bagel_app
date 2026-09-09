import SwiftUI
import VisionKit
import UIKit

/// Wraps `VNDocumentCameraViewController` so both the camera-scan and photo-upload
/// flows in `CaptureView` funnel into the same `[UIImage]` -> OCR pipeline.
/// `VNDocumentCameraViewController.isSupported` is false on the Simulator (no camera
/// hardware) — callers should hide the scan option and fall back to the photo picker there.
struct DocumentScannerView: UIViewControllerRepresentable {
    var onComplete: (Result<[UIImage], Error>) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onComplete: (Result<[UIImage], Error>) -> Void

        init(onComplete: @escaping (Result<[UIImage], Error>) -> Void) {
            self.onComplete = onComplete
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for pageIndex in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: pageIndex))
            }
            onComplete(.success(images))
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onComplete(.success([]))
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onComplete(.failure(error))
        }
    }
}
