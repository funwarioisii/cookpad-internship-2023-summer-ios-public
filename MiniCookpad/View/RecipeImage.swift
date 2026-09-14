import SwiftUI

/// URLがない状態・取得待ち・取得失敗を区別する。サイズは呼び出し側が決める。
struct RecipeImage: View {
    let url: URL?

    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    placeholder(symbol: "photo.badge.exclamationmark")
                case .empty:
                    if url == nil {
                        placeholder(symbol: "photo")
                    } else {
                        ZStack { Color(.secondarySystemBackground); ProgressView() }
                    }
                @unknown default:
                    placeholder(symbol: "photo")
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .accessibilityHidden(true)
    }

    private func placeholder(symbol: String) -> some View {
        ZStack {
            Color(.secondarySystemBackground)
            Image(systemName: symbol).foregroundStyle(.secondary)
        }
    }
}
