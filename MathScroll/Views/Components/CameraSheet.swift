import SwiftUI

/// Adapts the existing `CameraView(onCapture: ([UIImage]) -> Void)` API —
/// which records video and yields 3 sampled frames — into the simpler
/// `(Data) -> Void` callback used by SubmitAnswerView and DiagnosticView.
/// Strategy: take the middle frame (index 1 out of 3; fallback to first),
/// encode as JPEG at 0.85 quality, and forward the Data.
struct CameraSheet: View {
    var onImageData: (Data) -> Void

    var body: some View {
        CameraView { images in
            let chosen = images.count > 1 ? images[1] : images.first
            guard let image = chosen,
                  let data = image.jpegData(compressionQuality: 0.85) else { return }
            onImageData(data)
        }
    }
}
