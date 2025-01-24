import Combine
import MatrixRustSDK
import OSLog
import SwiftUI

class FriendService: ObservableObject {
    
    private let logger = Logger(category: "FriendService")
    private let matrixClient: MatrixClient
    private var cancellables: Set<AnyCancellable> = []
    
    @Published var friends: [Friend] = []
    @Published var receivedFriendRequests: [FriendRequest] = []
    @Published var sentFriendRequests: [FriendRequest] = []
    
    init(matrixClient: MatrixClient) {
        self.matrixClient = matrixClient
        
        matrixClient.roomListServiceHandler.peoplePublisher.sink { roomListItems in
            Task {
                var friends = [Friend]()
                var sentRequests = [FriendRequest]()
                for roomListItem in roomListItems {
                    do {
                        guard roomListItem.isDirect() else { throw "Room is not direct." }
                        guard await roomListItem.isEncrypted() else { throw "Room is not encrypted." }
                        if !roomListItem.isTimelineInitialized() {
                            try await roomListItem.initTimeline(eventTypeFilter: nil, internalIdPrefix: nil)
                        }
                        let fullRoom = try roomListItem.fullRoom()
                        let membersIter = try await fullRoom.members()
                        guard membersIter.len() <= 2 else { throw "Room has more than two members." }
                        let members = membersIter.nextChunk(chunkSize: 2) ?? []
                        let person = members.first { $0.userId != fullRoom.ownUserId() }
                        guard let person else { throw "Room does not contain any other people." }
                        let userId = person.userId
                        let name = person.displayName ?? userId
                        let avatarUrl = URL(string: person.avatarUrl ?? "")
                        if person.membership == .invite {
                            sentRequests.append(FriendRequest(userId: userId, name: name, avatarUrl: avatarUrl))
                        } else if person.membership == .join {
                            friends.append(Friend(userId: userId, name: name, avatarUrl: avatarUrl))
                        } else {
                            throw "Other member has invalid membership: \(String(describing: person.membership))"
                        }
                    } catch {
                        self.logger.warning("Failed to cast person room list item for room \(roomListItem.id(), privacy: .sensitive(mask: .hash)): \((error as NSError).debugDescription)")
                    }
                }
                await MainActor.run { [friends, sentRequests] in
                    self.friends = friends
                    self.sentFriendRequests = sentRequests
                }
            }
        }
        .store(in: &cancellables)
        
        matrixClient.roomListServiceHandler.invitesPublisher.sink { roomListItems in
            Task {
                var receivedRequests = [FriendRequest]()
                for roomListItem in roomListItems {
                    do {
                        guard roomListItem.membership() == .invited else { throw "Room is not an invite." }
                        let invitedRoom = try roomListItem.invitedRoom()
                        guard invitedRoom.isDirect() else { throw "Room is not direct." }
                        // TODO: Find reliable way to check if room is encrypted
                        // guard try invitedRoom.isEncrypted() else { throw "Room is not encrypted." }
                        guard let inviter = await invitedRoom.inviter() else { throw "Room has no inviter." }
                        let userId = inviter.userId
                        let name = inviter.displayName ?? userId
                        let avatarUrl = URL(string: inviter.avatarUrl ?? "")
                        let request = FriendRequest(userId: userId, name: name, avatarUrl: avatarUrl)
                        receivedRequests.append(request)
                    } catch {
                        self.logger.warning("Failed to cast invite room list item for room \(roomListItem.id(), privacy: .sensitive(mask: .hash)): \((error as NSError).debugDescription)")
                    }
                }
                await MainActor.run { [receivedRequests] in
                    self.receivedFriendRequests = receivedRequests
                }
            }
        }
        .store(in: &cancellables)
    }
    
    func sendFriendRequest(to userId: String) async throws {
        try await matrixClient.sendInvite(to: userId)
    }
}
