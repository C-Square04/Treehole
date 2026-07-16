import SwiftUI
import UIKit

/// A SwiftUI wrapper around `UIImagePickerController` configured for camera capture.
/// SwiftUI's `PhotosPicker` cannot access the camera, so this is required for in-app photo capture.
struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImagePicked: @MainActor (Data) -> Void

    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            // Full camera resolution would bypass the 1024px/JPEG cap the
            // PhotosPicker path enforces — downsample off the main thread.
            if let image = info[.originalImage] as? UIImage {
                let onImagePicked = parent.onImagePicked
                Task {
                    guard let data = await PhotoImportPipeline.downsampledJPEG(from: image) else { return }
                    onImagePicked(data)
                }
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
