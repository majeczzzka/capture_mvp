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
- Home Screen: Use the add button to create new jars and the search bar to filter jars.
- Bottom Navigation: Tap on icons to navigate between screens.
- Profile Screen: View and personalize user information.

### Project Structure

```bash
lib/
├── main.dart                 
├── models/
│   └── jar_model.dart       
├── screens/
│   ├── home_screen.dart     
│   ├── calendar_screen.dart  
│   ├── profile_screen.dart  
│   ├── splash_screen.dart  
│   └── jar_page.dart        
│   └── jar_creation_page.dart   
├── utils/
│   └── app_colors.dart       
└── widgets/
    ├── add_jar_dialog.dart 
    ├── functionality_icon.dart 
    ├── bottom_nav_bar.dart   
    ├── logo.dart 
    ├── search_bar.dart 
    ├── header_widget.dart    
    ├── search_bar.dart       
    ├── jar_grid.dart        
    ├── jar_item.dart         
    ├── greeting_widget.dart  
    └── avatar_stack.dart     

```

### Dependencies
- flutter: SDK for building natively compiled applications.
- Additional dependencies may be listed in pubspec.yaml.

