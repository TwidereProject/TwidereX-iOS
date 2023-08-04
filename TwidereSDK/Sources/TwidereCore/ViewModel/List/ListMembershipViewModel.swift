//
//  ListMembershipViewModel.swift
//  
//
//  Created by MainasuK on 2022-3-23.
//

import os.log
import Foundation

public protocol ListMembershipViewModelDelegate: AnyObject {
    func listMembershipViewModel(_ viewModel: ListMembershipViewModel, didAddUser user: UserRecord)
    func listMembershipViewModel(_ viewModel: ListMembershipViewModel, didRemoveUser user: UserRecord)
}

public final class ListMembershipViewModel {

    let logger = Logger(subsystem: "ListMembershipViewModel", category: "ViewModel")
    
    public var id = UUID()
    public weak var delegate: ListMembershipViewModelDelegate?
    
    // input
    let api: APIService
    public let list: ListRecord
    
    // output
    @Published public var owner: UserRecord?
    @Published public var ownerUserIdentifier: UserIdentifier?
    
    @Published public var members = Set<UserRecord>()
    @Published public var workingMembers = Set<UserRecord>()
    
    public init(
        api: APIService,
        list: ListRecord
    ) {
        self.api = api
        self.list = list
        // end init
        
        let managedObjectContext = api.backgroundManagedObjectContext
        Task {
            self.owner = await managedObjectContext.perform {
                guard let owner = list.object(in: managedObjectContext)?.owner else { return nil }
                return .init(object: owner)
            }
            self.ownerUserIdentifier = await managedObjectContext.perform {
                guard let owner = list.object(in: managedObjectContext)?.owner else { return nil }
                return owner.userIdentifer
            }
        }
    }
    
}

extension ListMembershipViewModel {
    
    @MainActor
    public func add(
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async throws {
        guard !workingMembers.contains(user) else { return }
        workingMembers.insert(user)
        defer { workingMembers.remove(user) }
        
        do {
            _ = try await api.addListMember(
                list: list,
                user: user,
                authenticationContext: authenticationContext
            )
            members.insert(user)
            delegate?.listMembershipViewModel(self, didAddUser: user)
        } catch {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): add list member failure: \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    public func remove(
        user: UserRecord,
        authenticationContext: AuthenticationContext
    ) async throws {
        guard !workingMembers.contains(user) else { return }
        workingMembers.insert(user)
        defer { workingMembers.remove(user) }
        
        do {
            _ = try await api.removeListMember(
                list: list,
                user: user,
                authenticationContext: authenticationContext
            )
            members.remove(user)
            delegate?.listMembershipViewModel(self, didRemoveUser: user)
        } catch {
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): add list member failure: \(error.localizedDescription)")
            throw error
        }
    }
    
}

// MARK: - ListMembershipViewModel
extension ListMembershipViewModel: Hashable {
    public static func == (lhs: ListMembershipViewModel, rhs: ListMembershipViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
