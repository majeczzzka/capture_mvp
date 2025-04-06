import 'package:flutter/material.dart';
import '../../models/jar_model.dart';
import 'avatar_stack.dart';
import '../../screens/jar_page.dart';
import '../../repositories/jar_repository.dart';

class JarItem extends StatelessWidget {
  final Jar jar;
  final String userId; // User ID required for jar-specific actions
  final String jarId; // Jar ID required for unique identification
  final List<String> collaborators;

  const JarItem({
    super.key,
    required this.jar,
    required this.userId,
    required this.jarId,
    required this.collaborators,
  });

  /// Shows a confirmation dialog for leaving a jar
  Future<void> _showLeaveJarDialog(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Jar'),
        content: const Text(
          "You won't see this jar anymore. Others can keep adding memories, but you won't have access unless they invite you back.\n\nAll content will be archived for 90 days before permanent deletion.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave Jar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (confirm) {
      try {
        final jarRepository = JarRepository(userId: userId);
        final success = await jarRepository.leaveJar(jarId);

        // Show a success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'You have left the jar.'
                  : 'Failed to leave jar. Please try again.'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to leave jar. Please try again.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkerColor = Color.fromARGB(
      jar.filterColor.alpha, // Keep the same alpha
      (jar.filterColor.red * 0.7).toInt(), // Reduce red by 30%
      (jar.filterColor.green * 0.7).toInt(), // Reduce green by 30%
      (jar.filterColor.blue * 0.7).toInt(), // Reduce blue by 30%
    );

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JarPage(
              jarTitle: jar.title,
              contributorAvatars: jar.images,
              jarColor: jar.filterColor,
              jarImage: jar.jarImage,
              userId: userId, // Pass userId to JarPage
              jarId: jarId, // Pass jarId to JarPage
              collaborators: collaborators,
            ),
          ),
        );
      },
      onLongPress: () => _showLeaveJarDialog(context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Jar Image with Color Filter
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              jar.filterColor.withOpacity(0.7),
              BlendMode.modulate,
            ),
            child: Image.asset(
              jar.jarImage,
              width: 200,
              height: 200,
            ),
          ),
          // Title Text on Jar
          Positioned(
            top: 100,
            child: SizedBox(
              width: 100, // Width of the jar image
              child: Text(
                jar.title,
                maxLines: 1, // Restrict to a single line
                overflow:
                    TextOverflow.ellipsis, // Add ellipsis if text overflows
                textAlign: TextAlign.center, // Center-align text
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: darkerColor,
                  fontSize: 20,
                ),
              ),
            ),
          ),

          // Contributor Avatars (using AvatarStack)
          Positioned(
            top: 130,
            child: AvatarStack(
              avatars: jar.images,
              radius: 13,
              overlap: 10,
            ),
          ),
        ],
      ),
    );
  }
}
