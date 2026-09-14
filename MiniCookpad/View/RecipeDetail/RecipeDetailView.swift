import SwiftUI

struct RecipeDetailView: View {
    @State private var viewModel: RecipeDetailViewModel
    @State private var showAddRecipeHashtags = false

    init(recipeID: Int64, store: RecipeStore) {
        _viewModel = State(initialValue: RecipeDetailViewModel(recipeID: recipeID, store: store))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let message = viewModel.errorMessage {
                    Text(message).foregroundStyle(.secondary)
                    Button("再試行") { Task { await viewModel.request() } }
                }
                if let item = viewModel.recipeDetailItem {
                    RecipeImage(url: URL(string: item.recipe.imageUrl ?? ""))
                        .aspectRatio(1, contentMode: .fit)
                    VStack(alignment: .leading, spacing: 16) {
                        Text(item.recipe.title).font(.title2).bold()
                        HStack {
                            RecipeImage(url: URL(string: item.recipe.user.imageUrl ?? ""))
                                .frame(width: 30, height: 30).clipShape(Circle())
                            Text(item.recipe.user.name).foregroundStyle(.secondary)
                        }
                        if !item.hashtags.isEmpty {
                            Text(item.hashtags.map { "#\($0.name)" }.joined(separator: " "))
                                .font(.subheadline).bold()
                                .padding(8)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 6))
                                .accessibilityIdentifier("detailHashtags")
                        }
                        Text(item.recipe.description).font(.body)
                        Text("材料").font(.headline)
                        ForEach(item.recipe.ingredients.filter { !$0.name.isEmpty }) { ingredient in
                            HStack(alignment: .top) {
                                Text(ingredient.name)
                                Spacer()
                                Text(ingredient.quantity ?? "")
                            }
                            Divider()
                        }
                        Text("作り方").font(.headline)
                        ForEach(Array(item.recipe.steps.enumerated()), id: \.element.id) { offset, step in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(offset + 1). \(step.memo)")
                                if let imageURL = step.imageUrl {
                                    RecipeImage(url: URL(string: imageURL))
                                        .frame(height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            Divider()
                        }
                    }
                    .padding(.horizontal)
                } else if viewModel.isLoading {
                    ProgressView("読み込み中").frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom)
        }
        .task { await viewModel.request() }
        .refreshable { await viewModel.request() }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let item = viewModel.recipeDetailItem {
                ToolbarItem(placement: .topBarTrailing) {
                    AddHashtagsButton(item: item, showAddRecipeHashtags: $showAddRecipeHashtags)
                        .accessibilityLabel("ハッシュタグを追加")
                        .accessibilityIdentifier("addHashtags")
                }
            }
        }
        .sheet(isPresented: $showAddRecipeHashtags) {
            if let item = viewModel.recipeDetailItem {
                AddRecipeHashtagsView(item: item, store: viewModel.store)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipeID: 1, store: RecipeStore(client: StubAPIClient()))
    }
}
