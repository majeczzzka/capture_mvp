import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:capture_mvp/models/jar_model.dart';

void main() {
  group('Jar Model Tests', () {
    test('Should create a valid Jar with required parameters', () {
      // Arrange
      final String testTitle = 'Family Memories';
      final Color testColor = Colors.blue;
      final List<Widget> testImages = [
        CircleAvatar(backgroundColor: Colors.red),
        CircleAvatar(backgroundColor: Colors.green),
      ];
      final String testJarImage = 'assets/images/jar1.png';
      final List<String> testCollaborators = ['user1', 'user2'];

      // Act
      final Jar jar = Jar(
        id: 'test-jar-id',
        title: testTitle,
        filterColor: testColor,
        images: testImages,
        jarImage: testJarImage,
        collaborators: testCollaborators,
      );

      // Assert
      expect(jar.title, equals(testTitle));
      expect(jar.filterColor, equals(testColor));
      expect(jar.images, equals(testImages));
      expect(jar.jarImage, equals(testJarImage));
      expect(jar.collaborators, equals(testCollaborators));
      expect(jar.collaborators.length, equals(2));
    });

    test('Should create a Jar with empty collaborators list', () {
      // Arrange
      final String testTitle = 'Personal Journal';
      final Color testColor = Colors.green;
      final List<Widget> testImages = [];
      final String testJarImage = 'assets/images/jar2.png';
      final List<String> testCollaborators = [];

      // Act
      final Jar jar = Jar(
        id: 'personal-jar-id',
        title: testTitle,
        filterColor: testColor,
        images: testImages,
        jarImage: testJarImage,
        collaborators: testCollaborators,
      );

      // Assert
      expect(jar.title, equals(testTitle));
      expect(jar.filterColor, equals(testColor));
      expect(jar.images, isEmpty);
      expect(jar.jarImage, equals(testJarImage));
      expect(jar.collaborators, isEmpty);
    });

    test('Should keep references to lists provided in constructor', () {
      // Arrange
      final List<Widget> testImages = [
        CircleAvatar(backgroundColor: Colors.yellow),
      ];
      final List<String> testCollaborators = ['user1'];

      // Act
      final Jar jar = Jar(
        id: 'reference-test-id',
        title: 'Test Jar',
        filterColor: Colors.purple,
        images: testImages,
        jarImage: 'assets/images/jar3.png',
        collaborators: testCollaborators,
      );

      // Modify the original lists
      testImages.add(CircleAvatar(backgroundColor: Colors.orange));
      testCollaborators.add('user2');

      // Assert - jar lists should reflect changes since they're the same objects
      expect(jar.images.length, equals(2));
      expect(jar.collaborators.length, equals(2));
      expect(jar.collaborators, contains('user2'));
    });
  });
}
