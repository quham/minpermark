import SwiftUI

struct SubmitAnswerView: View {
    @Environment(SessionStore.self) private var session
    @State private var capturedImage: Data?
    @State private var showingCamera = false
    var onSubmit: (Data) -> Void

    var body: some View {
        VStack(spacing: Theme.padLarge) {
            if let img = capturedImage, let ui = UIImage(data: img) {
                GlassCard {
                    Image(uiImage: ui)
                        .resizable().scaledToFit()
                        .frame(maxHeight: 300)
                }
                Button("Submit for marking") { onSubmit(img) }
                    .buttonStyle(.borderedProminent)
                Button("Retake") { showingCamera = true }.buttonStyle(.plain)
            } else {
                Button { showingCamera = true } label: {
                    GlassCard { Label("Take photo of working", systemImage: "camera.fill").frame(maxWidth: .infinity, minHeight: 80) }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .sheet(isPresented: $showingCamera) {
            CameraSheet { data in
                capturedImage = data
                showingCamera = false
            }
        }
    }
}
