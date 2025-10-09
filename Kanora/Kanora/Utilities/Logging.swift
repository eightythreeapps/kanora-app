import Foundation
import os

/// Lightweight logging abstraction for the app that wraps Apple's `Logger`
/// while respecting build configurations.
struct AppLogger {
    enum Level {
        case debug
        case info
        case warning
        case error

        var osLogType: OSLogType {
            switch self {
            case .debug:
                return .debug
            case .info:
                return .info
            case .warning:
                return .default
            case .error:
                return .error
            }
        }
    }

    struct Category: RawRepresentable, ExpressibleByStringLiteral, Hashable {
        let rawValue: String

        init(rawValue: String) {
            self.rawValue = rawValue
        }

        init(stringLiteral value: StringLiteralType) {
            self.rawValue = value
        }

        static let general: Category = "General"
        static let audioPlayer: Category = "AudioPlayerService"
        static let fileImport: Category = "FileImportService"
        static let libraryService: Category = "LibraryService"
        static let importViewModel: Category = "ImportViewModel"
        static let persistence: Category = "Persistence"
        static let designSystem: Category = "DesignSystem"
        static let playerViewModel: Category = "PlayerViewModel"
        static let baseViewModel: Category = "BaseViewModel"
        static let importView: Category = "ImportView"
        static let libraryView: Category = "LibraryView"
        static let preview: Category = "Preview"
        static let coreDataTest: Category = "CoreDataTestUtilities"
        static let appLifecycle: Category = "KanoraApp"
    }

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.kanora.app"

    private let logger: Logger

    init(category: Category = .general) {
        self.logger = Logger(subsystem: Self.subsystem, category: category.rawValue)
    }

    func debug(_ message: @autoclosure () -> String, file: StaticString = #fileID, line: UInt = #line) {
        log(message(), level: .debug, file: file, line: line)
    }

    func info(_ message: @autoclosure () -> String, file: StaticString = #fileID, line: UInt = #line) {
        log(message(), level: .info, file: file, line: line)
    }

    func warning(_ message: @autoclosure () -> String, file: StaticString = #fileID, line: UInt = #line) {
        log(message(), level: .warning, file: file, line: line)
    }

    func error(_ message: @autoclosure () -> String, file: StaticString = #fileID, line: UInt = #line) {
        log(message(), level: .error, file: file, line: line)
    }

    private func log(_ message: @autoclosure () -> String, level: Level, file: StaticString, line: UInt) {
        let composedMessage = "[\(file):\(line)] \(message())"

        #if DEBUG
        logger.log(level: level.osLogType, "\(composedMessage, privacy: .public)")
        #else
        guard level != .debug else { return }
        logger.log(level: level.osLogType, "\(composedMessage, privacy: .public)")
        #endif
    }
}

extension AppLogger {
    static let audioPlayer = AppLogger(category: .audioPlayer)
    static let fileImport = AppLogger(category: .fileImport)
    static let libraryService = AppLogger(category: .libraryService)
    static let importViewModel = AppLogger(category: .importViewModel)
    static let persistence = AppLogger(category: .persistence)
    static let designSystem = AppLogger(category: .designSystem)
    static let playerViewModel = AppLogger(category: .playerViewModel)
    static let baseViewModel = AppLogger(category: .baseViewModel)
    static let importView = AppLogger(category: .importView)
    static let libraryView = AppLogger(category: .libraryView)
    static let preview = AppLogger(category: .preview)
    static let coreDataTest = AppLogger(category: .coreDataTest)
    static let appLifecycle = AppLogger(category: .appLifecycle)
}
