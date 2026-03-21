import SwiftUI

// MARK: - Screen 1: Profile (root)
struct ProfileView: View {
    @State private var profileTab: ProfileTab = .me
    @State private var contentTab: ContentTab = .posts
    @State private var activitySub: ActivitySubView = .grid
    @State private var modal: ProfileModal? = nil

    enum ProfileTab { case me, friends }
    enum ContentTab { case posts, activity }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBG.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        BerryHeaderView()
                        meFriendsToggle.padding(.top, 10)
                        ProfileHeaderView(onBellTap: { modal = .notifications },
                                          onGearTap: { modal = .settings },
                                          onAvatarTap: { modal = .profilePic })
                            .padding(.horizontal, 16).padding(.top, 10)

                        if profileTab == .me {
                            postsActivityTabs.padding(.top, 14)
                            switch contentTab {
                            case .posts:    postsContent
                            case .activity: activityContent
                            }
                        } else {
                            FriendsListView()
                        }
                        Color.clear.frame(height: 90)
                    }
                }
                BottomNavBar(selectedTab: .profile)
            }
            .ignoresSafeArea(edges: .bottom)

            if let m = modal {
                modalOverlay(for: m)
            }
        }
    }

    // MARK: Me / Friends toggle
    private var meFriendsToggle: some View {
        HStack(spacing: 0) {
            pillButton("Me",      selected: profileTab == .me)      { profileTab = .me;      contentTab = .posts; activitySub = .grid }
            pillButton("Friends", selected: profileTab == .friends)  { profileTab = .friends }
        }
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.appBlue.opacity(0.3), lineWidth: 1))
        .frame(width: 220)
    }

    private func pillButton(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.custom("Jost-Medium", size: 16))
                .foregroundColor(selected ? .white : .appBlue)
                .frame(width: 110, height: 36)
                .background(selected ? Color.appBlue : Color.clear)
                .clipShape(Capsule())
        }
    }

    // MARK: Posts / Activity tab bar
    private var postsActivityTabs: some View {
        HStack(spacing: 0) {
            tabLabel("Posts",    selected: contentTab == .posts)    { contentTab = .posts;    activitySub = .grid }
            tabLabel("Activity", selected: contentTab == .activity)  { contentTab = .activity; activitySub = .grid }
        }
        .overlay(alignment: .bottom) { Divider() }
    }

    private func tabLabel(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.custom("Jost-Medium", size: 16))
                    .foregroundColor(selected ? .appBlue : .gray)
                Rectangle().fill(selected ? Color.appBlue : Color.clear).frame(height: 2)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Posts content
    private var postsContent: some View {
        VStack(spacing: 0) {
            ForEach(samplePosts) { post in
                PostCardView(post: post)
                Divider()
            }
        }
        .background(Color.white)
    }

    // MARK: Activity content — routes to sub-screens
    @ViewBuilder
    private var activityContent: some View {
        switch activitySub {
        case .grid:
            ActivityGridView { tile in activitySub = tileDestination(tile) }
        case .saved:
            ActivitySavedNavView(onPosts: { activitySub = .savedPosts },
                                 onEvents: { activitySub = .savedEvents },
                                 onBack: { activitySub = .grid })
        case .savedPosts:
            ActivityPostGridView(title: "Saved Posts",
                                 posts: samplePosts,
                                 onPostTap: { p in modal = .postDetail(post: p) },
                                 onBack: { activitySub = .saved })
        case .savedEvents:
            ActivitySavedEventsView(onBack: { activitySub = .saved })
        case .likedPosts:
            ActivityPostGridView(title: "Liked Posts",
                                 posts: samplePosts,
                                 onPostTap: { p in modal = .postDetail(post: p) },
                                 onBack: { activitySub = .grid })
        case .comments:
            ActivityPostGridView(title: "Comments",
                                 posts: samplePosts,
                                 onPostTap: { p in modal = .commentDetail(post: p, showReplies: false) },
                                 onBack: { activitySub = .grid })
        }
    }

    private func tileDestination(_ tile: ActivityTile) -> ActivitySubView {
        switch tile {
        case .liked:    return .likedPosts
        case .saved:    return .saved
        case .comments: return .comments
        case .tagged:   return .grid
        }
    }

    // MARK: Modal overlay dispatcher
    @ViewBuilder
    private func modalOverlay(for m: ProfileModal) -> some View {
        switch m {
        case .settings:
            SettingsOverlay(
                onDismiss:       { modal = nil },
                onSignOut:       { modal = .signOut },
                onDeleteAccount: { modal = .deleteAccount(step: 1) }
            )
        case .notifications:
            NotificationsOverlay(onDismiss: { modal = nil })
        case .profilePic:
            ProfilePicOverlay(onDismiss: { modal = nil })
        case .signOut:
            SignOutOverlay(
                onBack:    { modal = .settings },
                onDismiss: { modal = nil }
            )
        case .deleteAccount(let step):
            DeleteAccountOverlay(
                step:      step,
                onBack:    { modal = step == 1 ? .settings : .deleteAccount(step: step - 1) },
                onNext:    { modal = step < 3 ? .deleteAccount(step: step + 1) : nil },
                onDismiss: { modal = nil }
            )
        case .postDetail(let post):
            PostDetailOverlay(post: post, onDismiss: { modal = nil })
        case .commentDetail(let post, let showReplies):
            CommentDetailOverlay(
                post: post,
                showReplies: showReplies,
                onExpandReplies: { modal = .commentDetail(post: post, showReplies: true) },
                onDismiss: { modal = nil }
            )
        }
    }
}

// MARK: - Berry Header
struct BerryHeaderView: View {
    var body: some View {
        ZStack {
            Color.white
            HStack(spacing: -8) {
                Circle().fill(Color(red: 0.27, green: 0.15, blue: 0.56))
                    .frame(width: 62, height: 62).offset(x: -8, y: 12)
                Circle().fill(Color(red: 0.30, green: 0.18, blue: 0.60))
                    .frame(width: 82, height: 82).offset(y: 20)
                Spacer()
                Circle().fill(Color(red: 0.27, green: 0.15, blue: 0.56))
                    .frame(width: 72, height: 72).offset(y: 16)
                Circle().fill(Color(red: 0.30, green: 0.18, blue: 0.60))
                    .frame(width: 58, height: 58).offset(x: 8, y: 8)
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 90)
        .clipped()
    }
}

// MARK: - Profile Header
struct ProfileHeaderView: View {
    var onBellTap:   () -> Void
    var onGearTap:   () -> Void
    var onAvatarTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: onAvatarTap) {
                ZStack {
                    Circle().fill(Color.appBluePale).frame(width: 72, height: 72)
                    Image(systemName: "person.fill")
                        .resizable().scaledToFit().frame(width: 36)
                        .foregroundColor(.appBlue)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Grace Lee").font(.custom("Jost-ExtraBold", size: 18))
                    Text("(she/her)").font(.custom("Jost-Medium", size: 13)).foregroundColor(.gray)
                    Spacer()
                    Button(action: onBellTap) {
                        Image(systemName: "bell.fill").font(.system(size: 18)).foregroundColor(.appBlue)
                    }
                    Button(action: onGearTap) {
                        Image(systemName: "gearshape.fill").font(.system(size: 18)).foregroundColor(.appBlue)
                    }
                }
                Text("UCSD, California, love food and pets!")
                    .font(.custom("Jost-Medium", size: 13)).foregroundColor(.gray)
            }
        }
        .overlay(alignment: .topLeading) {
            Button("Edit") {}
                .font(.custom("Jost-Medium", size: 13)).foregroundColor(.appBlue)
                .offset(x: 54, y: -8)
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
}
