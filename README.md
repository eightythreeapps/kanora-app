# Kanora

Native macOS music player and library manager built with Swift and SwiftUI. Supports CD ripping, local playback, and remote streaming via REST API.

## Overview

Kanora is a Mac Catalyst application designed for comprehensive music management with multi-host and remote access capabilities. Built with modern iOS/macOS development practices, it provides a native experience for organizing, playing, and streaming your music collection.

## Features (Planned)

- **Music Library Management**: Import, organize, and browse your music collection
- **CD Ripping**: Import music directly from CDs
- **Audio Playback**: Native playback using AVFoundation
- **REST API**: Embedded HTTP server for remote access and control
- **Multi-Platform**: Mac Catalyst support with iPad compatibility
- **Remote Access**: Control playback and access your library from other devices

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode 15.0 or later
- Swift 5.9+

## Project Structure

```
Kanora/
├── App/              # Application entry point and configuration
├── Models/           # Core Data models and persistence layer
├── ViewModels/       # MVVM view models for business logic
├── Views/            # SwiftUI views
│   ├── Library/      # Library browsing views
│   ├── Playback/     # Playback control views
│   ├── Settings/     # Settings and preferences
│   └── Components/   # Reusable UI components
├── Services/         # Business logic layer
│   ├── Audio/        # Audio playback service
│   ├── Library/      # Library management
│   ├── Network/      # REST API and networking
│   └── Import/       # File import and CD ripping
├── Utilities/        # Helper functions and extensions
└── Resources/        # Assets, localization, etc.
```

## Architecture

Kanora follows the **Model-View-ViewModel (MVVM)** architecture pattern:

- **Models**: Core Data entities for persistence
- **Views**: SwiftUI views for UI presentation
- **ViewModels**: Business logic and state management
- **Services**: Encapsulated business logic and external interactions

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/eightythreeapps/kanora-app.git
cd kanora-app
```

### 2. Install SwiftLint (Optional but Recommended)

```bash
brew install swiftlint
```

SwiftLint is configured in `.swiftlint.yml` and will automatically run during builds.

### 3. Open in Xcode

```bash
open Kanora/Kanora.xcodeproj
```

### 4. Configure Code Signing

1. Select the Kanora project in Xcode
2. Choose the Kanora target
3. Go to "Signing & Capabilities"
4. Select your development team

### 5. Build and Run

- Select "My Mac (Designed for iPad)" as the destination
- Press Cmd+R to build and run

## Development

### Code Style

This project uses SwiftLint to enforce consistent code style. The configuration is in `.swiftlint.yml`.

### Core Data

The Core Data stack is managed by `PersistenceController` in the Models folder. The data model is defined in `Kanora.xcdatamodeld`.

### Testing

- **Unit Tests**: Located in `KanoraTests/`
- **UI Tests**: Located in `KanoraUITests/`

Run tests with Cmd+U or through Xcode's test navigator.

## Build Configurations

- **Debug**: For development with debugging enabled
- **Release**: Optimized for distribution

## Technologies

- **SwiftUI**: Modern declarative UI framework
- **Core Data**: Data persistence and management
- **AVFoundation**: Audio playback
- **Vapor** (planned): REST API server
- **Mac Catalyst**: Native Mac app from iOS codebase

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

[License information to be added]

## Contact

eightythreeapps - [GitHub](https://github.com/eightythreeapps)

Project Link: [https://github.com/eightythreeapps/kanora-app](https://github.com/eightythreeapps/kanora-app)

## Roadmap

See the [Issues](https://github.com/eightythreeapps/kanora-app/issues) and [Milestones](https://github.com/eightythreeapps/kanora-app/milestones) for planned features and development progress.
