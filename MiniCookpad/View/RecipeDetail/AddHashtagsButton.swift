import SwiftUI

struct AddHashtagsButton: View {
    let item: RecipeDetailItem
    @Binding var showAddRecipeHashtags: Bool

    var body: some View {
        Button("#") { showAddRecipeHashtags = true }
            .font(.title3)
            .fontWeight(.bold)
            .accessibilityLabel("ハッシュタグを追加")
    }
}

#Preview {
    @Previewable @State var isPresented = false
    AddHashtagsButton(item: .init(recipe: .mock, hashtags: []), showAddRecipeHashtags: $isPresented)
}
