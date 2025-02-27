import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_avatar/random_avatar.dart';
import '../jar/jar_item.dart';
import '../../models/jar_model.dart';

/// A grid widget that displays a list of jars fetched from Firestore, filtered by a search query.
class JarGrid extends StatelessWidget {
  final String searchQuery; // Search query to filter jars by title
  final String userId; // User ID to fetch jars for a specific user

  const JarGrid({
    super.key,
    required this.searchQuery,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    // Fetch jars from Firestore in real-time for the specified user
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users') // Reference to users collection
          .doc(userId) // Reference to the specific user document
          .collection('jars') // Reference to the jars subcollection
          .snapshots(), // Real-time snapshot stream
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Failed to load jars',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          );
        }

        // Extract jar data from Firestore documents
        final jarDocs = snapshot.data?.docs ?? [];

        // Filter jars by search query (case-insensitive)
        final filteredJars = jarDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final jarName = data['name'] ?? 'Untitled Jar';
          return jarName.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();

        // Handle empty state
        if (filteredJars.isEmpty) {
          return const Center(
            child: Text(
              'No matching jars',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // Display a grid of filtered jars
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

            // Get owner avatar
            final ownerAvatar = RandomAvatar(
              (data['owner'] as String?)?.hashCode.toString() ?? '',
              height: 20,
              width: 20,
            );

            // Get collaborator avatars
            final collaboratorAvatars =
                (data['collaborators'] as List<dynamic>? ?? [])
                    .map((collaboratorId) => RandomAvatar(
                          collaboratorId.hashCode.toString(),
                          height: 20,
                          width: 20,
                        ))
                    .toList();

            // Combine owner and collaborator avatars
            final allAvatars = [
              ownerAvatar, // Always add the owner first
              ...collaboratorAvatars, // Add collaborators
            ];

            // Map Firestore data to Jar object
            final jar = Jar(
              title: data['name'] ?? 'Untitled Jar',
              filterColor:
                  Color(int.parse(data['color'].replaceFirst('#', '0xFF'))),
              images: allAvatars, // Use combined avatars list
              jarImage: 'assets/images/jar.png', // Placeholder jar image
              collaborators: List<String>.from(data['collaborators'] ?? []),
            );

            // Pass all required arguments to JarItem
            return JarItem(
              jar: jar,
              userId: userId,
              jarId: doc.id, // Use Firestore document ID as jarId
            );
          },
        );
      },
    );
  }
}
