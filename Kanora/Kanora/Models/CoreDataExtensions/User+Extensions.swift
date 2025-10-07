//
//  User+Extensions.swift
//  Kanora
//
//  Created by Claude on 06/10/2025.
//

import Foundation
import CoreData

extension User {
    /// Convenience initializer for creating a new User
    convenience init(
        username: String,
        email: String? = nil,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)
        self.id = UUID()
        self.username = username
        self.email = email
        self.createdAt = Date()
        self.isActive = true
    }

    /// Fetch request for active users only
    static func activeUsersFetchRequest() -> NSFetchRequest<User> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "username", ascending: true)]
        return request
    }

    /// Find user by username
    static func findByUsername(
        _ username: String,
        in context: NSManagedObjectContext
    ) -> User? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "username == %@", username)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Update last login timestamp
    func updateLastLogin() {
        self.lastLoginAt = Date()
    }
}
