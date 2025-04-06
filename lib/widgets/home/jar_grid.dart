import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';
import '../jar/jar_item.dart';
import '../../models/jar_model.dart';
import '../../models/jar_data.dart';
import '../../repositories/jar_repository.dart';
import '../../utils/app_colors.dart'; // Import for colors

/// A grid widget that displays a list of jars fetched from Firestore, filtered by a search query.
class JarGrid extends StatelessWidget {
  final String searchQuery; // Search query to filter jars by title
  final String userId; // User ID to fetch jars for a specific user
  final List<String> collaborators;
  final JarRepository jarRepository;

  const JarGrid({
    super.key,
    required this.searchQuery,
    required this.userId,
    required this.collaborators,
    required this.jarRepository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JarData>>(
      stream: jarRepository.getFilteredJarsStream(searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Failed to load jars',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          );
        }

        final filteredJars = snapshot.data ?? [];

        if (filteredJars.isEmpty) {
          return const Center(
            child: Text(
              'No matching jars',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: filteredJars.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.7,
          ),
          itemBuilder: (context, index) {
            final jarData = filteredJars[index];

            // Create avatars for collaborators
            final collaboratorAvatars = jarData.collaborators
                .map((collaboratorId) => RandomAvatar(
                      collaboratorId.hashCode.toString(),
                      height: 20,
                      width: 20,
                    ))
                .toList();

            // Ensure avatars are valid, fallback if empty
            final avatars = collaboratorAvatars.isNotEmpty
                ? collaboratorAvatars
                : [
                    const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    )
                  ];

            // Convert JarData to JarDisplayModel
            final displayJar = JarDisplayModel.fromJarData(
              jarData,
              avatars,
              defaultImage: 'assets/images/jar.png',
            );

            return JarItem(
              jar:
                  displayJar, // The typedef ensures this works with existing code
              userId: userId,
              jarId: jarData.id,
              collaborators: jarData.collaborators,
            );
          },
        );
      },
    );
  }
}
