# Integration Tests for Capture App

This directory contains integration tests for the Capture app. These tests verify that key user flows work correctly from end to end.

## Available Tests

1. **App Initialization and Login (`app_test.dart`)**

   - Verifies that the app launches correctly
   - Tests the user login flow

2. **Jar Content Flow (`jar_content_test.dart`)**

   - Navigates to a jar and checks content viewing
   - Tests content upload functionality (skipped in CI environment)

3. **Jar Creation (`jar_creation_test.dart`)**
   - Tests the creation of a new jar
   - Verifies collaborator adding functionality

## Running the Tests

### On a Physical Mobile Device

To run tests on a mobile device/simulator:

```bash
flutter test integration_test/app_test.dart -d <device_id>
```

To run all integration tests:

```bash
flutter test integration_test
```

### Platform Considerations

- **iOS**: These tests are primarily designed to run on mobile devices/simulators. This is the recommended testing platform.

  ```xml
  <key>LSMinimumSystemVersion</key>
  <string>10.15</string>
  ```

### Prerequisites

1. Make sure you have a test account available in your Firebase project
2. The device should have internet connectivity
3. For content upload tests, the device should have access to camera and gallery

## Test Environment Setup

The tests are designed to handle both authenticated and unauthenticated states. They will:

1. Check if the user is already logged in
2. If not, attempt to log in with test credentials
3. Proceed with the specific test flow

## Troubleshooting

If tests fail, check the following:

1. **Authentication Issues**: Verify that the test credentials are valid in your Firebase environment
2. **UI Changes**: If the app's UI has changed, the selectors in the tests may need updating
3. **Timing Issues**: Some tests include delays (`tester.pumpAndSettle()`) to wait for animations and network operations. Adjust these if necessary.
4. **Firebase Configuration**: Ensure Firebase is properly initialized in the test environment
5. **Platform Compatibility**: Some tests may only work on specific platforms (iOS/Android) due to plugin limitations

## Adding New Tests

When adding new integration tests:

1. Follow the existing pattern with clear test grouping
2. Handle both authenticated and unauthenticated starting states
3. Use the `TestUtils` class for common operations
4. Consider using `markTestSkipped()` for tests that can't run reliably in CI
5. Test on multiple platforms if possible to ensure cross-platform compatibility
