# Capture App

## Table of Contents

- [Features](#features)
- [Screens](#screens)
- [Getting Started](#getting-started)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Dependencies](#dependencies)

## Features

- **Jar Creation**: Add new jars with titles and avatars of contributors.
- **Search Functionality**: A custom search bar with back and clear options to filter jars in real-time.
- **Bottom Navigation**: A navigation bar to switch between the Home, Calendar, and Profile screens.
- **Profile Management**: Simple profile screen for personalization.

## Screens

1. **Home Screen**: Displays a grid of jars and a personalized greeting.
2. **Jar Details Page**: Opens on clicking a jar, showing details and images.
3. **Calendar Screen**: Shows a placeholder view for calendar features.
4. **Profile Screen**: Displays a simple profile view.

## Getting Started

To get a local copy up and running, follow these steps.

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Compatible IDE (e.g., VSCode, Android Studio)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/capture_mvp.git
   cd capture_mvp
3. Intall Dependencies
   ```bash
   flutter pub get
5. Run App
   ```bash
   flutter run

### Usage
Home Screen: Use the add button to create new jars and the search bar to filter jars.
Bottom Navigation: Tap on icons to navigate between screens.
Profile Screen: View and personalize user information.

### Project Structure

lib/
├── main.dart                 # Main entry point of the app
├── models/
│   └── jar_model.dart        # Data model for jars
├── screens/
│   ├── home_screen.dart      # Home screen with jar grid
│   ├── calendar_screen.dart  # Calendar screen
│   ├── profile_screen.dart   # Profile screen
│   └── jar_page.dart         # Detailed view of individual jars
├── utils/
│   └── app_colors.dart       # Color theme for the app
└── widgets/
    ├── bottom_nav_bar.dart   # Custom bottom navigation bar
    ├── header_widget.dart    # Header with search and add functionalities
    ├── search_bar.dart       # Custom search bar widget
    ├── jar_grid.dart         # Grid view of jars
    ├── jar_item.dart         # Individual jar item in the grid
    ├── greeting_widget.dart  # Personalized greeting widget
    └── avatar_stack.dart     # Stack of avatars for jars

### Dependencies
flutter: SDK for building natively compiled applications.
Additional dependencies may be listed in pubspec.yaml.

