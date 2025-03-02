import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_avatar/random_avatar.dart';
import '../jar/jar_item.dart';
import '../../models/jar_model.dart';
import '../jar_content/jar_content_grid.dart';

/// A grid widget that displays a list of jars fetched from Firestore, filtered by a search query.
class JarGrid extends StatelessWidget {
  final String searchQuery; // Search query to filter jars by title
  final String userId; // User ID to fetch jars for a specific user
  final List<String> collaborators;

  const JarGrid({
    super.key,
    required this.searchQuery,
    required this.userId,
    required this.collaborators,
  });

  /// ✅ **Fetches jars where the user is a collaborator**
  Stream<QuerySnapshot> _getJarsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('jars') // ✅ Fetch only the jars specific to this user
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getJarsStream(), // ✅ Listen for real-time updates
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

        final jarDocs = snapshot.data?.docs ?? [];

        // Filter jars by search query (case-insensitive)
        final filteredJars = jarDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final jarName = data['name'] ?? 'Untitled Jar';
          return jarName.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();

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
            final doc = filteredJars[index];
            final data = doc.data() as Map<String, dynamic>;

            // 🔥 Ensure we fetch the collaborators correctly
            final collaboratorAvatars =
                (data['collaborators'] as List<dynamic>? ?? [])
                    .map((collaboratorId) => RandomAvatar(
                          collaboratorId.hashCode.toString(),
                          height: 20,
                          width: 20,
                        ))
                    .toList();

            // 🔥 Ensure avatars are valid, fallback if empty
            final avatars = collaboratorAvatars.isNotEmpty
                ? collaboratorAvatars
                : [
                    const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    )
                  ];

            final jar = Jar(
              title: data['name'] ?? 'Untitled Jar',
              filterColor:
                  Color(int.parse(data['color'].replaceFirst('#', '0xFF'))),
              images: avatars,
              jarImage: 'assets/images/jar.png',
              collaborators: List<String>.from(data['collaborators'] ?? []),
            );

            return JarItem(
              jar: jar,
              userId: userId,
              jarId: doc.id,
              collaborators: List<String>.from(data['collaborators'] ?? []),
            );
          },
        );
      },
    );
  }
}
