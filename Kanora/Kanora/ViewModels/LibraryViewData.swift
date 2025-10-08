import Foundation
import CoreData

struct LibraryViewData: Identifiable, Hashable {
    let id: Library.ID
    let name: String
    let path: String
    let createdAt: Date?
    let updatedAt: Date?

    init(id: Library.ID, name: String, path: String, createdAt: Date?, updatedAt: Date?) {
        self.id = id
        self.name = name
        self.path = path
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(library: Library) {
        let identifier = library.id ?? UUID()
        if library.id == nil {
            library.id = identifier
        }

        self.init(
            id: identifier,
            name: library.name ?? String(localized: "library.unknown"),
            path: library.path ?? "",
            createdAt: library.createdAt,
            updatedAt: library.updatedAt
        )
    }
}
