import SwiftUI
import AVFoundation

struct CameraView: View {
    let onCapture: ([UIImage]) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraModel()
    @State private var checkInStart: Date?
    @State private var now = Date()
    @State private var isRecording = false
    @State private var isProcessing = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var elapsedText: String {
        guard let start = checkInStart else { return "Start now" }
        let elapsed = Int(now.timeIntervalSince(start))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        GeometryReader { geo in
            let previewWidth = geo.size.width * 0.9
            let topInset = max(geo.size.height * 0.08, 72)
            let bottomInset = geo.size.height * 0.08
            let previewHeight = max(0, geo.size.height - topInset - bottomInset)

            ZStack {
                Color.white.ignoresSafeArea()

                // Camera preview
                CameraPreviewView(camera: camera)
                    .frame(width: previewWidth, height: previewHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.top, topInset)
                    .padding(.bottom, bottomInset)

                VStack {
                    // Top bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 44, height: 44)
                        }

                        Spacer()

                        Button(action: { camera.switchCamera() }) {
                            Image(systemName: "camera.rotate")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding()

                    Spacer()
                }

                VStack {
                    Spacer()

                    if checkInStart == nil {
                        Button(action: startCheckIn) {
                            Text("Start now")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 8)
                                .background(Theme.accent)
                                .cornerRadius(Theme.cornerLarge)
                        }
                    } else {
                        Button(action: finishCheckIn) {
                            Text(isProcessing ? "Processing..." : "Done")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 8)
                                .background(isProcessing ? Theme.accent.opacity(0.4) : Theme.accent)
                                .cornerRadius(Theme.cornerLarge)
                        }
                        .disabled(isProcessing)
                    }
                }
                .frame(width: previewWidth, height: previewHeight)
                .padding(.top, topInset)
                .padding(.bottom, bottomInset)
                .allowsHitTesting(true)

                VStack {
                    Spacer()
                    if checkInStart != nil {
                        Text(elapsedText)
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, Theme.pad)
                            .padding(.vertical, 4)
                            .background(Color.white)
                            .cornerRadius(Theme.cornerLarge)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.cornerLarge)
                                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
                            )
                    }
                }
                .frame(width: previewWidth)
                .padding(.bottom, Theme.padLarge)
            }
        }
        .onAppear {
            camera.checkPermission()
        }
        .onReceive(timer) { now = $0 }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func startCheckIn() {
        checkInStart = Date()
        isRecording = true
        camera.startRecording()
    }

    private func finishCheckIn() {
        guard isRecording else { return }
        isProcessing = true
        isRecording = false
        camera.stopRecording { url in
            guard let url else {
                isProcessing = false
                return
            }
            extractSamples(from: url) { images in
                isProcessing = false
                guard images.count == 3 else { return }
                onCapture(images)
                dismiss()
            }
        }
    }

    private func extractSamples(from url: URL, completion: @escaping ([UIImage]) -> Void) {
        Task.detached(priority: .userInitiated) {
            let asset = AVAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true

            let duration: CMTime
            do {
                duration = try await asset.load(.duration)
            } catch {
                await MainActor.run { completion([]) }
                return
            }

            let durationSeconds = CMTimeGetSeconds(duration)
            guard durationSeconds.isFinite, durationSeconds > 0 else {
                await MainActor.run { completion([]) }
                return
            }

            let samplePercents: [Double] = [0.2, 0.5, 0.8]
            let times = samplePercents.map { percent in
                CMTime(seconds: durationSeconds * percent, preferredTimescale: 600)
            }

            let sampledImages = times.compactMap { time -> UIImage? in
                if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                    return UIImage(cgImage: cgImage)
                }
                return nil
            }

            await MainActor.run {
                completion(sampledImages)
            }
        }
    }
}

class CameraModel: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var output = AVCapturePhotoOutput()
    @Published var movieOutput = AVCaptureMovieFileOutput()
    @Published var isTaken = false
    @Published var isAuthorized = false

    private var currentPosition: AVCaptureDevice.Position = .back
    private var photoCompletion: ((UIImage) -> Void)?
    private var videoCompletion: ((URL?) -> Void)?
    private var recordingURL: URL?

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { [weak self] in
                self?.isAuthorized = true
                self?.setUp()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.setUp()
                    }
                }
            }
        default:
            DispatchQueue.main.async { [weak self] in
                self?.isAuthorized = false
            }
        }
    }

    func setUp() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            // Add camera input
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentPosition),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                return
            }

            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }

            // Add photo output
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }

            if self.session.canAddOutput(self.movieOutput) {
                self.session.addOutput(self.movieOutput)
            }

            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    func switchCamera() {
        currentPosition = currentPosition == .back ? .front : .back

        session.beginConfiguration()

        // Remove existing input
        if let input = session.inputs.first as? AVCaptureDeviceInput {
            session.removeInput(input)
        }

        // Add new input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        session.commitConfiguration()
    }

    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        photoCompletion = completion

        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    func startRecording() {
        guard !movieOutput.isRecording else { return }
        let filename = "\(UUID().uuidString).mov"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        recordingURL = url
        movieOutput.startRecording(to: url, recordingDelegate: self)
    }

    func stopRecording(completion: @escaping (URL?) -> Void) {
        videoCompletion = completion
        guard movieOutput.isRecording else {
            completion(nil)
            return
        }
        movieOutput.stopRecording()
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.photoCompletion?(image)
        }
    }
}

extension CameraModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if error != nil {
                self?.videoCompletion?(nil)
            } else {
                self?.videoCompletion?(outputFileURL)
            }
            self?.videoCompletion = nil
            self?.recordingURL = nil
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var camera: CameraModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)

        let previewLayer = AVCaptureVideoPreviewLayer(session: camera.session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}
