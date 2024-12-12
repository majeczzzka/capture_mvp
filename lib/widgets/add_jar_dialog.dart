import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';

/// A dialog widget for adding a new jar with a title input field and Firestore integration.
class AddJarDialog extends StatefulWidget {
  final String userId; // Pass the user ID dynamically
  const AddJarDialog({super.key, required this.userId});

  @override
  State<AddJarDialog> createState() => _AddJarDialogState();
}

class _AddJarDialogState extends State<AddJarDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _jarNameController =
      TextEditingController(); // Controller for jar name
  String _selectedColor = '#FFFFFF'; // Default color for the jar

  /// Saves the jar to Firestore
  Future<void> _saveJar() async {
    if (_formKey.currentState!.validate()) {
      final jarData = {
        'name': _jarNameController.text.trim(),
        'color': _selectedColor,
        'collaborators': [], // Default empty collaborators for now
        'content': [], // Default empty content
      };

      // Save jar data under the user's document in Firestore
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId) // Use the passed userId
            .collection('jars')
            .add(jarData);

        Navigator.of(context).pop(); // Close the dialog after saving
      } catch (e) {
        print('Error saving jar: $e'); // Handle any Firestore errors
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save jar. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: const Text(
        'Add a New Jar',
        style: TextStyle(color: AppColors.fonts),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Input field for jar name
            TextFormField(
              controller: _jarNameController,
              style: const TextStyle(color: AppColors.fonts),
              decoration: const InputDecoration(
                hintText: 'Enter jar name',
                hintStyle: TextStyle(color: AppColors.fonts),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Jar name cannot be empty'; // Validation message
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Dropdown for selecting jar color
            DropdownButtonFormField<String>(
              value: _selectedColor,
              decoration: const InputDecoration(
                labelText: 'Select Color',
                labelStyle: TextStyle(color: AppColors.fonts),
              ),
              dropdownColor: AppColors.background,
              items: [
                '#FFFFFF',
                '#FF5733',
                '#33FF57',
                '#3357FF',
              ].map((color) {
                return DropdownMenuItem(
                  value: color,
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        color:
                            Color(int.parse(color.replaceFirst('#', '0xFF'))),
                      ),
                      const SizedBox(width: 8),
                      Text(color,
                          style: const TextStyle(color: AppColors.fonts)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedColor = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        // Back button to close dialog
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Back',
            style: TextStyle(color: AppColors.fonts),
          ),
        ),
        // Save button to save data to Firestore
        ElevatedButton(
          onPressed: _saveJar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.selectedFonts,
          ),
          child: const Text(
            'Save',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _jarNameController.dispose();
    super.dispose();
  }
}
