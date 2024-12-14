import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MultimediaOptions extends StatelessWidget {
  final String userId;
  final String jarId;

  const MultimediaOptions({
    super.key,
    required this.userId,
    required this.jarId,
  });

  Future<void> _addContentWithDate(
      BuildContext context, String type, IconData icon) async {
    // Show Date Picker Dialog
    final DateTime? selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        DateTime tempDate = DateTime.now(); // Default date
        return AlertDialog(
          title: Text("Select Date for $type"),
          content: SizedBox(
            height: 400,
            width: 300,
            child: CalendarDatePicker(
              initialDate: tempDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              onDateChanged: (date) {
                tempDate = date;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog without saving
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, tempDate); // Return selected date
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (selectedDate != null) {
      try {
        // Save content with selected date into Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('jars')
            .doc(jarId)
            .update({
          'content': FieldValue.arrayUnion([
            {
              'type': type.toLowerCase(),
              'icon': icon.codePoint, // Save the icon for rendering
              'data': 'Sample $type content',
              'date': selectedDate.toIso8601String(), // Save the date
            }
          ])
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$type added successfully!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add $type: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildIconColumn(context, Icons.edit, "Note"),
            _buildIconColumn(context, Icons.videocam, "Video"),
            _buildIconColumn(context, Icons.photo, "Photo"),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconColumn(context, Icons.mic, "Voice Note"),
            const SizedBox(width: 24),
            _buildIconColumn(context, Icons.format_paint, "Template"),
          ],
        ),
      ],
    );
  }

  Widget _buildIconColumn(BuildContext context, IconData icon, String label) {
    return InkWell(
      onTap: () => _addContentWithDate(context, label, icon),
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
