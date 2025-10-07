# Core Data Model Documentation

## Overview

The Kanora app uses Core Data for persisting music library information. The data model is designed to support a comprehensive music management system with support for multiple libraries, playlists, and detailed track metadata.

## Entity Relationship Diagram

```
User (1) ──────< (M) Library (1) ──────< (M) Artist (1) ──────< (M) Album (1) ──────< (M) Track
                        │                                                                  │
                        │                                                                  │
                        └─────< (M) Playlist (1) ──────< (M) PlaylistItem (M) ────────────┘
```

## Entities

### User

Represents a user of the application.

**Attributes:**
- `id`: UUID - Primary identifier
- `username`: String - Unique username
- `email`: String? - Optional email address
- `createdAt`: Date - Account creation timestamp
- `lastLoginAt`: Date? - Last login timestamp
- `preferences`: Data? - JSON-encoded user preferences
- `isActive`: Bool - Whether the account is active

**Relationships:**
- `libraries`: To-Many → Library - User's music libraries

**Uniqueness Constraints:**
- `id` must be unique
- `username` must be unique

### Library

Represents a music library belonging to a user.

**Attributes:**
- `id`: UUID - Primary identifier
- `name`: String - Library name
- `path`: String - File system path to library
- `type`: String - Library type (default: "local")
- `isDefault`: Bool - Whether this is the default library
- `createdAt`: Date - Creation timestamp
- `updatedAt`: Date - Last update timestamp
- `lastScannedAt`: Date? - Last scan timestamp

**Relationships:**
- `user`: To-One → User - Library owner
- `artists`: To-Many → Artist - Artists in the library
- `playlists`: To-Many → Playlist - Playlists in the library

**Deletion Rules:**
- Deleting a library cascades to artists and playlists
- Deleting a user nullifies the library relationship

### Artist

Represents a musical artist or band.

**Attributes:**
- `id`: UUID - Primary identifier
- `name`: String - Artist name
- `sortName`: String? - Name for sorting (e.g., "Beatles, The")
- `mbid`: String? - MusicBrainz identifier
- `biography`: String? - Artist biography
- `imagePath`: String? - Path to artist image
- `createdAt`: Date - Creation timestamp
- `updatedAt`: Date - Last update timestamp

**Relationships:**
- `library`: To-One → Library - Parent library
- `albums`: To-Many → Album - Artist's albums

**Deletion Rules:**
- Deleting an artist cascades to albums
- Deleting a library nullifies the artist relationship

### Album

Represents a music album.

**Attributes:**
- `id`: UUID - Primary identifier
- `title`: String - Album title
- `sortTitle`: String? - Title for sorting
- `year`: Int32? - Release year
- `releaseDate`: Date? - Full release date
- `genre`: String? - Album genre
- `mbid`: String? - MusicBrainz identifier
- `artworkPath`: String? - Path to album artwork
- `trackCount`: Int32 - Number of tracks (calculated)
- `totalDuration`: Double - Total duration in seconds (calculated)
- `createdAt`: Date - Creation timestamp
- `updatedAt`: Date - Last update timestamp

**Relationships:**
- `artist`: To-One → Artist - Album artist
- `tracks`: To-Many → Track - Album tracks

**Deletion Rules:**
- Deleting an album cascades to tracks
- Deleting an artist nullifies the album relationship

**Calculated Properties:**
- `trackCount` and `totalDuration` are updated via `updateCalculatedProperties()` method

### Track

Represents an individual music track.

**Attributes:**
- `id`: UUID - Primary identifier
- `title`: String - Track title
- `trackNumber`: Int16? - Track number on album
- `discNumber`: Int16? - Disc number (for multi-disc albums)
- `duration`: Double - Duration in seconds
- `filePath`: String - File system path (unique)
- `fileSize`: Int64 - File size in bytes
- `format`: String - Audio format (e.g., "mp3", "flac")
- `codec`: String? - Audio codec
- `bitrate`: Int32? - Bitrate in kbps
- `sampleRate`: Int32? - Sample rate in Hz
- `channels`: Int16? - Number of audio channels
- `composer`: String? - Track composer
- `genre`: String? - Track genre
- `year`: Int32? - Track year
- `lyrics`: String? - Track lyrics
- `mbid`: String? - MusicBrainz identifier
- `playCount`: Int32 - Number of times played
- `lastPlayedAt`: Date? - Last play timestamp
- `rating`: Int16? - User rating (0-5)
- `createdAt`: Date - Creation timestamp
- `updatedAt`: Date - Last update timestamp

**Relationships:**
- `album`: To-One → Album - Parent album
- `playlistItems`: To-Many → PlaylistItem - Playlist memberships

**Uniqueness Constraints:**
- `id` must be unique
- `filePath` must be unique

**Deletion Rules:**
- Deleting a track cascades to playlist items
- Deleting an album nullifies the track relationship

### Playlist

Represents a music playlist.

**Attributes:**
- `id`: UUID - Primary identifier
- `name`: String - Playlist name
- `desc`: String? - Playlist description
- `isSmart`: Bool - Whether this is a smart playlist
- `smartCriteria`: Data? - JSON-encoded smart playlist criteria
- `createdAt`: Date - Creation timestamp
- `updatedAt`: Date - Last update timestamp

**Relationships:**
- `library`: To-One → Library - Parent library
- `items`: To-Many → PlaylistItem - Playlist items

**Deletion Rules:**
- Deleting a playlist cascades to playlist items
- Deleting a library nullifies the playlist relationship

**Smart Playlists:**
Smart playlists use criteria stored in `smartCriteria` to automatically populate based on track properties.

### PlaylistItem

Represents a track's membership in a playlist.

**Attributes:**
- `id`: UUID - Primary identifier
- `position`: Int32 - Position in playlist (0-based)
- `addedAt`: Date - When track was added to playlist

**Relationships:**
- `playlist`: To-One → Playlist - Parent playlist
- `track`: To-One → Track - Referenced track

**Deletion Rules:**
- Deleting a playlist item nullifies relationships
- Parent playlist or track deletion cascades to items

## Data Model Versioning

The current data model version is `Kanora.xcdatamodel` (v1.0).

### Migration Strategy

- **Lightweight Migrations**: Preferred for simple changes (adding attributes, relationships)
- **Custom Migrations**: Required for complex schema changes
- **Version History**: Maintained in `.xcdatamodeld` bundle

### Future Versions

When creating new model versions:
1. Editor → Add Model Version in Xcode
2. Update `.xccurrentversion` to point to new version
3. Implement migration mapping if needed
4. Test migration thoroughly

## Performance Considerations

### Indexing

Uniqueness constraints on the following provide automatic indexing:
- User: `id`, `username`
- Library: `id`
- Artist: `id`
- Album: `id`
- Track: `id`, `filePath`
- Playlist: `id`
- PlaylistItem: `id`

### Fetch Request Optimization

All entity extensions provide optimized fetch requests with:
- Appropriate predicates
- Efficient sort descriptors
- Fetch limits where applicable

### Batch Operations

Use `NSBatchDeleteRequest` and `NSBatchUpdateRequest` for bulk operations to improve performance.

## Best Practices

### Creating Entities

Always use convenience initializers from extensions:
```swift
let artist = Artist(
    name: "The Beatles",
    sortName: "Beatles, The",
    library: library,
    context: context
)
```

### Finding or Creating

Use `findOrCreate` methods to avoid duplicates:
```swift
let artist = Artist.findOrCreate(
    name: "The Beatles",
    in: library,
    context: context
)
```

### Updating Calculated Properties

Remember to update calculated properties:
```swift
album.updateCalculatedProperties()
```

### Saving Context

Always handle errors when saving:
```swift
do {
    try context.save()
} catch {
    print("Error saving context: \(error)")
}
```

## Testing

Use `CoreDataTestUtilities` for testing:
```swift
// Create in-memory controller
let controller = CoreDataTestUtilities.createInMemoryController()

// Create sample data
CoreDataTestUtilities.createSampleData(in: controller.container.viewContext)

// Verify integrity
let issues = CoreDataTestUtilities.verifyDataIntegrity(
    in: controller.container.viewContext
)
```

## See Also

- [PersistenceController.swift](../Kanora/Kanora/Models/Persistence.swift)
- [Core Data Extensions](../Kanora/Kanora/Models/CoreDataExtensions/)
- [Apple Core Data Documentation](https://developer.apple.com/documentation/coredata)
