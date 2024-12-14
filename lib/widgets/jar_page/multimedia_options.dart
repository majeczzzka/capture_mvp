import 'package:flutter/material.dart';
import 'icon_column.dart';

/// A widget for displaying multimedia options for a jar.
class MultimediaOptions extends StatelessWidget {
  final String userId;
  final String jarId;

  const MultimediaOptions({
    super.key,
    required this.userId,
    required this.jarId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Displays the multimedia options
            IconColumn(
              icon: Icons.edit,
              label: "Note",
              userId: userId,
              jarId: jarId,
            ),
            IconColumn(
              icon: Icons.videocam,
              label: "Video",
              userId: userId,
              jarId: jarId,
            ),
            IconColumn(
              icon: Icons.photo,
              label: "Photo",
              userId: userId,
              jarId: jarId,
            ),
          ],
        ),
        // Adds spacing between the multimedia options
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconColumn(
              icon: Icons.mic,
              label: "Voice Note",
              userId: userId,
              jarId: jarId,
            ),
            const SizedBox(width: 24),
            IconColumn(
              icon: Icons.format_paint,
              label: "Template",
              userId: userId,
              jarId: jarId,
            ),
          ],
        ),
      ],
    );
  }
}
