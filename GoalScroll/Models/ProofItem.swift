import Foundation
import SwiftData

// MARK: - Proof Item Model

/// Represents a piece of proof submitted for habit completion verification
@Model
final class ProofItem {

    // MARK: - Properties

    var id: UUID
    var type: ProofMethod
    var assetLocalIdentifier: String?
    var fileURL: String?
    var imageHash: String?
    var imageCapturedAt: Date?
    var text: String?
    var createdAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        type: ProofMethod,
        assetLocalIdentifier: String? = nil,
        fileURL: String? = nil,
        imageHash: String? = nil,
        imageCapturedAt: Date? = nil,
        text: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.assetLocalIdentifier = assetLocalIdentifier
        self.fileURL = fileURL
        self.imageHash = imageHash
        self.imageCapturedAt = imageCapturedAt
        self.text = text
        self.createdAt = createdAt
    }
}
