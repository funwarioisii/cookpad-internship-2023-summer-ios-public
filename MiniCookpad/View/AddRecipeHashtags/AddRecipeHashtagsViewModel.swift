import Foundation
import Observation

@MainActor
@Observable
final class AddRecipeHashtagsViewModel {
    var text = ""
    private(set) var isSaving = false
    private(set) var errorMessage: String?
    private let store: RecipeStore
    private let recipeID: Int64

    var canSave: Bool { !isSaving && !Self.normalize(text).isEmpty }

    init(recipeID: Int64, store: RecipeStore) {
        self.recipeID = recipeID
        self.store = store
    }

    static func normalize(_ text: String) -> String {
        text.replacingOccurrences(of: "　", with: " ")
            .replacingOccurrences(of: "＃", with: "#")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func save() async -> Bool {
        guard canSave else { return false }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await store.addHashtags(recipeID: recipeID, value: Self.normalize(text))
            return true
        } catch {
            guard !(error is CancellationError), !Task.isCancelled else { return false }
            errorMessage = "追加できませんでした。入力を確認して、もう一度お試しください。"
            return false
        }
    }
}
