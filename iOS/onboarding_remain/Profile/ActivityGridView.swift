import SwiftUI

// MARK: - Screen 3: Activity Grid
enum ActivityTile: CaseIterable {
    case liked, saved, comments, tagged

    var icon: String {
        switch self {
        case .liked:    return "heart.fill"
        case .saved:    return "bookmark.fill"
        case .comments: return "bubble.left.fill"
        case .tagged:   return "bubble.left.and.bubble.right.fill"
        }
    }
}

struct ActivityGridView: View {
    var onTileTap: (ActivityTile) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(ActivityTile.allCases, id: \.self) { tile in
                Button { onTileTap(tile) } label: {
                    Image(systemName: tile.icon)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 130)
                        .background(Color.appBlueMid).cornerRadius(16)
                }
            }
        }
        .padding(16).background(Color.white)
    }
}
