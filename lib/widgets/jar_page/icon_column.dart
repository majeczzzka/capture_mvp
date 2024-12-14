import 'package:flutter/material.dart';

// Jar and its content as a column
class IconColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String userId;
  final String jarId;

  const IconColumn({
    super.key,
    required this.icon,
    required this.label,
    required this.userId,
    required this.jarId,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {},
      borderRadius: BorderRadius.circular(8),
      splashColor: Colors.grey.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
