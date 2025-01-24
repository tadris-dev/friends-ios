import Combine
import Foundation
import MatrixRustSDK
import OSLog

/// Manages the room list service and provides a way to observe its state and entries.
class RoomListServiceHandler: RoomListServiceStateListener, RoomListServiceSyncIndicatorListener {
    
    private let logger = Logger(category: "RoomListServiceHandler")
    
    private var peopleProcessing: EntriesProcessing
    private var invitesProcessing: EntriesProcessing
    
    private let stateSubject = CurrentValueSubject<RoomListServiceState, Never>(.initial)
    private let showSyncIndicatorSubject = CurrentValueSubject<Bool, Never>(false)
    private var stateListenerHandle: TaskHandle?
    private var showSyncIndicatorHandle: TaskHandle?
    
    var showSyncIndicator: Bool { showSyncIndicatorSubject.value }
    var showSyncIndicatorPublisher: AnyPublisher<Bool, Never> { showSyncIndicatorSubject.eraseToAnyPublisher() }
    var state: RoomListServiceState { stateSubject.value }
    var statePublisher: AnyPublisher<RoomListServiceState, Never> { stateSubject.eraseToAnyPublisher() }
    var people: [RoomListItem] { peopleProcessing.entriesSubject.value }
    var peoplePublisher: AnyPublisher<[RoomListItem], Never> { peopleProcessing.entriesSubject.eraseToAnyPublisher() }
    var invites: [RoomListItem] { invitesProcessing.entriesSubject.value }
    var invitesPublisher: AnyPublisher<[RoomListItem], Never> { invitesProcessing.entriesSubject.eraseToAnyPublisher() }
    
    // MARK: Initialisation
    
    init() {
        self.peopleProcessing = EntriesProcessing(logger: logger)
        self.invitesProcessing = EntriesProcessing(logger: logger)
    }
    
    func setup(roomListService: RoomListService) async throws {
        guard state == .initial else { return }
        stateListenerHandle = roomListService.state(listener: self)
        showSyncIndicatorHandle = roomListService.syncIndicator(delayBeforeShowingInMs: 1000, delayBeforeHidingInMs: 0, listener: self)
        let roomList = try await roomListService.allRooms()
        peopleProcessing.setup(roomList: roomList, filter: .category(expect: .people))
        invitesProcessing.setup(roomList: roomList, filter: .invite)
    }
    
    func reset() {
        stateListenerHandle?.cancel()
        stateListenerHandle = nil
        showSyncIndicatorHandle?.cancel()
        showSyncIndicatorHandle = nil
        stateSubject.send(.initial)
        showSyncIndicatorSubject.send(false)
        peopleProcessing.reset()
        invitesProcessing.reset()
    }
    
    // MARK: RoomListServiceStateListener
    
    func onUpdate(state: RoomListServiceState) {
        logger.info("Received room list service state update: \(String(describing: state)).")
        stateSubject.send(state)
    }
    
    // MARK: RoomListServiceSyncIndicatorListener
    
    func onUpdate(syncIndicator: RoomListServiceSyncIndicator) {
        logger.info("Received room list service sync indicator update: \(String(describing: syncIndicator)).")
        switch syncIndicator {
        case .show:
            showSyncIndicatorSubject.send(true)
        case .hide:
            showSyncIndicatorSubject.send(false)
        }
    }
    
    // MARK: RoomListEntriesListener
    
    class EntriesProcessing: RoomListEntriesListener {
        
        private let logger: Logger
        private var result: RoomListEntriesWithDynamicAdaptersResult?
        
        let entriesSubject = CurrentValueSubject<[RoomListItem], Never>([])
        
        init(logger: Logger) {
            self.logger = logger
        }
        
        func setup(roomList: RoomList, filter: RoomListEntriesDynamicFilterKind) {
            result = roomList.entriesWithDynamicAdapters(pageSize: .max, listener: self)
            _ = result?.controller().setFilter(kind: filter)
        }
        
        func reset() {
            result = nil
            entriesSubject.send([])
        }
        
        private func processUpdate(_ update: RoomListEntriesUpdate, on entries: [RoomListItem]) -> [RoomListItem] {
            var changes = [CollectionDifference<RoomListItem>.Change]()
            switch update {
            case .append(let values):
                for (index, value) in values.enumerated() {
                    changes.append(.insert(offset: entries.count + index, element: value, associatedWith: nil))
                }
            case .clear:
                for (index, entry) in entries.enumerated() {
                    changes.append(.remove(offset: index, element: entry, associatedWith: nil))
                }
            case .insert(let index, let value):
                changes.append(.insert(offset: Int(index), element: value, associatedWith: nil))
            case .popBack:
                guard let value = entries.last else { fatalError() }
                changes.append(.remove(offset: entries.count - 1, element: value, associatedWith: nil))
            case .popFront:
                changes.append(.remove(offset: 0, element: entries[0], associatedWith: nil))
            case .pushBack(let value):
                changes.append(.insert(offset: entries.count, element: value, associatedWith: nil))
            case .pushFront(let value):
                changes.append(.insert(offset: 0, element: value, associatedWith: nil))
            case .remove(let index):
                changes.append(.remove(offset: Int(index), element: entries[Int(index)], associatedWith: nil))
            case .reset(let values):
                for (index, entry) in entries.enumerated() {
                    changes.append(.remove(offset: index, element: entry, associatedWith: nil))
                }
                for (index, value) in values.enumerated() {
                    changes.append(.insert(offset: index, element: value, associatedWith: nil))
                }
            case .set(let index, let value):
                changes.append(.remove(offset: Int(index), element: value, associatedWith: nil))
                changes.append(.insert(offset: Int(index), element: value, associatedWith: nil))
            case .truncate(let length):
                for (index, entry) in entries.enumerated() where index >= length {
                    changes.append(.remove(offset: index, element: entry, associatedWith: nil))
                }
            }
            guard let difference = CollectionDifference(changes), let newItems = entries.applying(difference) else { return entries }
            return newItems
        }
        
        // MARK: RoomListEntriesListener
        
        func onUpdate(roomEntriesUpdate: [RoomListEntriesUpdate]) {
            logger.info("Received room entries update.")
            var entries = entriesSubject.value
            entries = roomEntriesUpdate.reduce(entries) { currentItems, update in
                processUpdate(update, on: currentItems)
            }
            entriesSubject.send(entries)
        }
    }
}
