import SwiftUI

// MARK: - Shared colour tokens
extension Color {
    static let appBlue      = Color(red: 0.11, green: 0.23, blue: 0.78)
    static let appBlueMid   = Color(red: 0.20, green: 0.35, blue: 0.87)
    static let appBlueDark  = Color(red: 0.07, green: 0.13, blue: 0.55)
    static let appBluePale  = Color(red: 0.88, green: 0.90, blue: 0.98)
    static let appBG        = Color(red: 0.96, green: 0.96, blue: 1.00)
}

// MARK: - Data models
struct PostItem: Identifiable {
    let id = UUID()
    var author: String
    var group: String
    var date: String
    var tags: [String]
    var likes: Int
    var comments: Int
    var caption: String
    var hasPhoto: Bool
}

struct FriendItem: Identifiable {
    let id = UUID()
    var name: String
    var subtitle: String
}

struct EventItem: Identifiable {
    let id = UUID()
    var title: String
    var date: String
    var org: String
}

// MARK: - Sample data
let samplePosts: [PostItem] = [
    .init(author: "Grace Lee", group: "UCSD Art Group", date: "July 11th, Fri",
          tags: ["Ellie", "Strawberry Picking"], likes: 15, comments: 3,
          caption: "Went to the lovely Temecula Berry Co today!", hasPhoto: true),
    .init(author: "Grace Lee", group: "UCSD Art Group", date: "July 11th, 2026",
          tags: [], likes: 15, comments: 3,
          caption: "Guys, what did we think of the new *insert film*", hasPhoto: false)
]

let sampleFriends: [FriendItem] = (0..<7).map { _ in
    .init(name: "Jimmy Patrick", subtitle: ["Friend", "UCSD Blueberries"].randomElement()!)
}

let sampleEvents: [EventItem] = (0..<6).map { _ in
    .init(title: "Movie Night", date: "Jan 25, 8-10pm", org: "UCSD\nBlueberries")
}

// MARK: - Navigation / Modal state
enum ProfileModal: Identifiable {
    case settings
    case notifications
    case profilePic
    case signOut
    case deleteAccount(step: Int)   // steps 1, 2, 3
    case postDetail(post: PostItem)
    case commentDetail(post: PostItem, showReplies: Bool)

    var id: String {
        switch self {
        case .settings:                    return "settings"
        case .notifications:               return "notifications"
        case .profilePic:                  return "profilePic"
        case .signOut:                     return "signOut"
        case .deleteAccount(let s):        return "delete\(s)"
        case .postDetail(let p):           return "post\(p.id)"
        case .commentDetail(let p, _):     return "comment\(p.id)"
        }
    }
}

enum ActivitySubView {
    case grid           // 4-tile picker
    case saved          // 2 big nav buttons
    case savedPosts     // grid of saved posts
    case savedEvents    // upcoming + past
    case likedPosts     // grid
    case comments       // grid
}
