# Capture

Capture is a modern Flutter application designed to help users store and share memories in digital "jars". The app allows users to upload photos, videos, and other media to themed collections that can be shared with friends and family.

## Features

- **Memory Jars**: Create themed collections to store your memories
- **Media Support**: Upload photos and videos to your jars
- **Collaboration**: Share jars with friends and family
- **Calendar View**: Browse your memories chronologically
- **Cloud Storage**: All content is securely stored in the cloud using AWS S3
- **Real-time Updates**: Changes sync instantly across all collaborators

## Tech Stack

- **Frontend**: Flutter
- **Backend Services**:
  - Firebase Firestore for database
  - AWS Amplify for storage
  - Firebase Authentication for user management
- **Media Handling**: Support for images and videos with thumbnail generation

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Firebase project
- AWS Amplify account
- Android Studio or VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/capture_mvp.git
   cd capture_mvp
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Configure Firebase:
   - Create a new Firebase project
   - Add your Android/iOS app to the Firebase project
   - Download and add the configuration files (GoogleService-Info.plist for iOS)

4. Configure AWS Amplify:
   - Create an Amplify project
   - Set up Storage category
   - Run amplify init and amplify push in your project

5. Run the app:
   ```
   flutter run
   ```

## Project Structure

- `lib/models/`: Data models
- `lib/screens/`: UI screens
- `lib/services/`: Business logic and API services
- `lib/widgets/`: Reusable UI components
- `lib/utils/`: Utility functions and constants

## Testing

The application includes unit tests for critical components:

```
flutter test
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
