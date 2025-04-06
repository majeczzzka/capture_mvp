import 'package:flutter/material.dart';

/// A column with an icon and label that can be tapped
class IconColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;
  final bool isEnabled;

  const IconColumn({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor = Colors.grey,
    this.textColor = Colors.grey,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      splashColor:
          isEnabled ? Colors.grey.withOpacity(0.3) : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isEnabled ? iconColor : Colors.grey.shade300),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  color: isEnabled ? textColor : Colors.grey.shade300),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
