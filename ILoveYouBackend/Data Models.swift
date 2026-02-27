import Foundation

User{
    userName: String
    password: String
    email: String
    fruit: String
    phoneNumber: String
    name: String
    dateOfBirth: Date
    pronouns: String
    location: CLLocation2D
    createdAt: Date
    updatesAt: Date
    postsCollectionID: String
    activitiesCollectionID: String
    invitedEventsCollectionID: String
    notificationsCollectionID: String
    friendIDs: [String]
    friendRequestsCollectionID: String
    groupsCollectionID: String
    chatsCollectionID: String
    isPrivate: Bool
    isDeleted: Bool
    deleteReason: String
}