import SwiftUI

struct AddRecipeHashtagsView: View {
    let item: RecipeDetailItem
    @State private var viewModel: AddRecipeHashtagsViewModel
    @Environment(\.dismiss) private var dismiss

    init(item: RecipeDetailItem, store: RecipeStore) {
        self.item = item
        _viewModel = State(initialValue: AddRecipeHashtagsViewModel(recipeID: item.recipe.id, store: store))
    }

    var body: some View {
        @Bindable var model = viewModel
        NavigationStack {
            Form {
                Section {
                    HStack {
                        AsyncImage(url: URL(string: item.recipe.imageUrl ?? "")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray
                        }
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text(item.recipe.title).font(.headline)
                            Text("by \(item.recipe.user.name)").foregroundStyle(.secondary)
                        }
                    }
                }
                Section("ハッシュタグ") {
                    TextField("#タグ1 #タグ2（スペース区切り）", text: $model.text, axis: .vertical)
                        .disabled(viewModel.isSaving)
                        .accessibilityIdentifier("hashtagsInput")
                }
                if let message = viewModel.errorMessage {
                    Section { Text(message).foregroundStyle(.red) }
                }
                Section {
                    Button {
                        // 保存は完了まで待ち、成功した結果を共有Storeへ反映する。
                        Task {
                            if await viewModel.save() { dismiss() }
                        }
                    } label: {
                        HStack {
                            if viewModel.isSaving { ProgressView() }
                            Text(viewModel.isSaving ? "追加中…" : "ハッシュタグを追加する")
                        }
                    }
                    .disabled(!viewModel.canSave)
                    .accessibilityIdentifier("saveHashtags")
                }
            }
            .navigationTitle("ハッシュタグ追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }.disabled(viewModel.isSaving)
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isSaving)
    }
}

#Preview {
    AddRecipeHashtagsView(
        item: .init(recipe: .mock, hashtags: []),
        store: RecipeStore(client: StubAPIClient())
    )
}
