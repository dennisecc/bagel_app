import SwiftUI
import SwiftData
import PhotosUI
import VisionKit
import BagelCore

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Person.createdAt) private var people: [Person]

    @State private var viewModel = CaptureViewModel()
    @State private var isPresentingScanner = false
    @State private var isPresentingManualEntry = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isLoadingPickedPhoto = false
    @State private var navigationDocument: ExpenseDocument?

    private var defaultPayer: Person? {
        people.first { $0.isDefaultOwner }
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Capture")
                .navigationDestination(item: $navigationDocument) { document in
                    ItemListView(document: document)
                }
        }
        .sheet(isPresented: $isPresentingScanner) {
            DocumentScannerView { result in
                isPresentingScanner = false
                if case .success(let images) = result, !images.isEmpty {
                    Task { await viewModel.process(images: images, categoryNames: categories.map(\.name)) }
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isPresentingManualEntry) {
            ManualEntryView(payer: defaultPayer, rawOCRText: viewModel.rawOCRText) { document in
                navigationDocument = document
                viewModel.reset()
            }
        }
        .onChange(of: photoPickerItem) { _, newValue in
            guard let newValue else { return }
            Task { await loadPickedPhoto(newValue) }
        }
        .onChange(of: viewModel.stage) { _, newStage in
            guard case .reviewReady = newStage, let parsed = viewModel.parsedReceipt else { return }
            let document = ReceiptPersister.persist(
                parsed,
                rawOCRText: viewModel.rawOCRText,
                payer: defaultPayer,
                categories: categories,
                in: modelContext
            )
            navigationDocument = document
            viewModel.reset()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.stage {
        case .idle:
            captureOptions
        case .recognizingText, .parsingWithLLM, .reviewReady:
            ProcessingView(stage: viewModel.stage)
        case .failed(let message, let canRetryLLM):
            failureView(message: message, canRetryLLM: canRetryLLM)
        }
    }

    private var captureOptions: some View {
        ContentUnavailableView {
            Label("Scan a Receipt", systemImage: "doc.text.viewfinder")
        } description: {
            Text("Scan a receipt or statement, or choose an existing photo, to itemize it automatically.")
        } actions: {
            VStack(spacing: 12) {
                if VNDocumentCameraViewController.isSupported {
                    Button {
                        isPresentingScanner = true
                    } label: {
                        Label("Scan Document", systemImage: "camera.viewfinder")
                    }
                    .buttonStyle(.borderedProminent)
                }

                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)
                .disabled(isLoadingPickedPhoto)

                Button("Enter Manually") {
                    isPresentingManualEntry = true
                }
                .buttonStyle(.plain)
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func failureView(message: String, canRetryLLM: Bool) -> some View {
        ContentUnavailableView {
            Label("Couldn't Process Document", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            VStack(spacing: 12) {
                if canRetryLLM {
                    Button("Try Again") { Task { await viewModel.retryLLM() } }
                        .buttonStyle(.borderedProminent)
                }
                Button("Enter Manually") { isPresentingManualEntry = true }
                Button("Rescan", role: .cancel) { viewModel.reset() }
            }
        }
    }

    private func loadPickedPhoto(_ item: PhotosPickerItem) async {
        isLoadingPickedPhoto = true
        defer {
            isLoadingPickedPhoto = false
            photoPickerItem = nil
        }
        guard
            let data = try? await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data)
        else { return }
        await viewModel.process(images: [image], categoryNames: categories.map(\.name))
    }
}

#Preview {
    CaptureView()
        .modelContainer(ModelContainerFactory.makeContainer(inMemory: true))
}
