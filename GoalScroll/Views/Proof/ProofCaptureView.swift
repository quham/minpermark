import SwiftUI
import CryptoKit
import Photos
import PhotosUI
import SwiftData

struct ProofCaptureView: View {
    let goal: Goal
    let onComplete: ([ProofItem]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedProofMethod: ProofMethod?
    @State private var capturedProofs: [ProofItem] = []
    @State private var reflectionText = ""
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var showingProofAlert = false
    @State private var proofAlertMessage = ""
    @State private var showingFriendVouchSheet = false

    private var availableMethods: [ProofMethod] {
        goal.proofMethods.isEmpty ? [.reflection] : goal.proofMethods
    }

    private var canSubmit: Bool {
        !capturedProofs.isEmpty || !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackgroundView()
                proofContent
                bottomActionArea
            }
            .navigationTitle("Proof")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $showingCamera) {
                CameraView { images in
                    handleCapturedImages(images, type: .camera)
                }
            }
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .onChange(of: selectedPhotoItem) { _ in
                guard let item = selectedPhotoItem else { return }
                Task {
                    let creationDate = loadAssetCreationDate(for: item)
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            handleCapturedImage(
                                image,
                                data: data,
                                type: .screenshot,
                                capturedAt: creationDate,
                                assetLocalIdentifier: item.itemIdentifier
                            )
                        }
                    }
                }
            }
            .alert("Proof issue", isPresented: $showingProofAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(proofAlertMessage)
            }
            .sheet(isPresented: $showingFriendVouchSheet) {
                FriendVouchComingSoonSheet()
                    .presentationDetents([.medium])
            }
        }
    }

    private var proofContent: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                goalInfoSection
                proofMethodsSection
                proofTipSection
                capturedPreviewSection
                reflectionSection
                Spacer()
                    .frame(height: AppSpacing.xxl)
            }
        }
    }

    private var goalInfoSection: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("Track your progress")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)

            Text(goal.microHabit)
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppSpacing.lg)
    }

    private var proofMethodsSection: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(availableMethods) { method in
                ProofMethodButton(
                    method: method,
                    hasProof: hasProofFor(method),
                    onTap: { handleMethodTap(method) }
                )
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    @ViewBuilder
    private var proofTipSection: some View {
        if availableMethods.contains(.screenshot) {
            Text("Tip: If your photo includes a timestamp, it's easier to verify.")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, AppSpacing.lg)
        }
    }

    @ViewBuilder
    private var capturedPreviewSection: some View {
        if let image = capturedImage {
            CapturedImagePreview(image: image) {
                capturedImage = nil
                capturedProofs.removeAll { $0.type == .camera || $0.type == .screenshot }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    @ViewBuilder
    private var reflectionSection: some View {
        if availableMethods.contains(.reflection) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Quick reflection")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)

                TextAreaField(
                    placeholder: "How did it go? What did you notice?",
                    text: $reflectionText,
                    minHeight: 100
                )
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }

    private var bottomActionArea: some View {
        VStack {
            Spacer()

            VStack(spacing: AppSpacing.sm) {
                PrimaryButton(title: "Submit Proof", isEnabled: canSubmit) {
                    submitProof()
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
            )
        }
    }

    private func hasProofFor(_ method: ProofMethod) -> Bool {
        switch method {
        case .camera, .screenshot:
            return capturedProofs.contains { $0.type == method }
        case .reflection:
            return !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .friendVouch:
            return false
        }
    }

    private func handleMethodTap(_ method: ProofMethod) {
        selectedProofMethod = method

        switch method {
        case .camera:
            showingCamera = true
        case .screenshot:
            showingPhotoPicker = true
        case .reflection:
            // Focus is handled by TextAreaField
            break
        case .friendVouch:
            showingFriendVouchSheet = true
        }
    }

    private func handleCapturedImage(
        _ image: UIImage,
        data: Data,
        type: ProofMethod,
        capturedAt: Date?,
        assetLocalIdentifier: String?
    ) {
        replaceCapturedProofs(
            [image],
            dataList: [data],
            type: type,
            capturedAtList: [capturedAt],
            assetLocalIdentifierList: [assetLocalIdentifier]
        )
    }

    private func handleCapturedImages(_ images: [UIImage], type: ProofMethod) {
        let dataList = images.compactMap { $0.jpegData(compressionQuality: 0.8) }
        let capturedAtList = Array(repeating: Date(), count: images.count)
        let assetLocalIdentifierList = Array(repeating: nil as String?, count: images.count)
        replaceCapturedProofs(
            images,
            dataList: dataList,
            type: type,
            capturedAtList: capturedAtList,
            assetLocalIdentifierList: assetLocalIdentifierList
        )
    }

    private func replaceCapturedProofs(
        _ images: [UIImage],
        dataList: [Data],
        type: ProofMethod,
        capturedAtList: [Date?],
        assetLocalIdentifierList: [String?]
    ) {
        guard !images.isEmpty,
              images.count == dataList.count,
              images.count == capturedAtList.count,
              images.count == assetLocalIdentifierList.count else { return }
        capturedProofs.removeAll { $0.type == .camera || $0.type == .screenshot }
        for (index, image) in images.enumerated() {
            addCapturedProof(
                image,
                data: dataList[index],
                type: type,
                capturedAt: capturedAtList[index],
                assetLocalIdentifier: assetLocalIdentifierList[index]
            )
        }
        capturedImage = images.last
    }

    private func addCapturedProof(
        _ image: UIImage,
        data: Data,
        type: ProofMethod,
        capturedAt: Date?,
        assetLocalIdentifier: String?
    ) {
        if type == .screenshot {
            guard let capturedAt else {
                proofAlertMessage = "We couldn't read the screenshot timestamp. Please take a new screenshot."
                showingProofAlert = true
                return
            }

            if !Calendar.current.isDateInToday(capturedAt) {
                proofAlertMessage = "That screenshot wasn't taken today. Please add a fresh screenshot."
                showingProofAlert = true
                return
            }
        }

        let hash = hashData(data)
        if type == .screenshot && isDuplicateScreenshot(hash: hash) {
            proofAlertMessage = "This screenshot was used before. Please add a new one."
            showingProofAlert = true
            return
        }

        // Save image to documents
        let imageDataForFile: Data?
        if type == .camera {
            imageDataForFile = data
        } else {
            imageDataForFile = image.jpegData(compressionQuality: 0.8)
        }

        if let imageData = imageDataForFile {
            let filename = "\(UUID().uuidString).jpg"
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(filename)

            try? imageData.write(to: fileURL)

            let proof = ProofItem(
                type: type,
                assetLocalIdentifier: assetLocalIdentifier,
                fileURL: fileURL.absoluteString,
                imageHash: hash,
                imageCapturedAt: capturedAt ?? Date()
            )
            capturedProofs.append(proof)
        }
    }

    private func loadAssetCreationDate(for item: PhotosPickerItem) -> Date? {
        guard let identifier = item.itemIdentifier else { return nil }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        return assets.firstObject?.creationDate
    }

    private func isDuplicateScreenshot(hash: String) -> Bool {
        let screenshotType = ProofMethod.screenshot
        let descriptor = FetchDescriptor<ProofItem>(
            predicate: #Predicate { $0.imageHash == hash && $0.type == screenshotType }
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        return !existing.isEmpty
    }

    private func hashData(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func submitProof() {
        // Add reflection proof if text exists
        if !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let reflectionProof = ProofItem(
                type: .reflection,
                text: reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            capturedProofs.append(reflectionProof)
        }

        onComplete(capturedProofs)
        dismiss()
    }
}

struct ProofMethodButton: View {
    let method: ProofMethod
    let hasProof: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(hasProof ? AppColors.success.opacity(0.15) : AppColors.primary.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: hasProof ? "checkmark" : method.icon)
                        .font(.system(size: 20))
                        .foregroundColor(hasProof ? AppColors.success : AppColors.primary)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(method.displayTitle)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)

                    Text(hasProof ? "Added" : "Tap to add")
                        .font(AppTypography.caption)
                        .foregroundColor(hasProof ? AppColors.success : AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textMuted)
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .fill(Color.white)
                    .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .strokeBorder(
                        hasProof ? AppColors.success : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct CapturedImagePreview: View {
    let image: UIImage
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .padding(AppSpacing.sm)
        }
    }
}

struct FriendVouchComingSoonSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            VStack(spacing: AppSpacing.md) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.primary)

                Text("Coming Soon")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)

                Text("Friend vouch will let your friends confirm your progress. Stay tuned!")
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            ShareLink(item: Constants.App.shareMessage) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 20))
                    Text("Invite Friend")
                        .font(AppTypography.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppColors.primary)
                .cornerRadius(AppCornerRadius.medium)
            }
            .padding(.horizontal, AppSpacing.lg)

            Button("Close") {
                dismiss()
            }
            .font(AppTypography.body)
            .foregroundColor(AppColors.textSecondary)

            Spacer()
        }
        .padding(AppSpacing.lg)
    }
}

#Preview {
    ProofCaptureView(
        goal: Goal(
            title: "Get healthier",
            microHabit: "Do 10 pushups",
            proofMethods: [.camera, .reflection]
        )
    ) { proofs in
        print("Proofs: \(proofs)")
    }
}
