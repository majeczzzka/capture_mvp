import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';

/// A dialog for adding a new jar to the user's collection.
class AddJarDialog extends StatefulWidget {
  final String userId;

  const AddJarDialog({super.key, required this.userId});

  @override
  State<AddJarDialog> createState() => _AddJarDialogState();
}

class _AddJarDialogState extends State<AddJarDialog> {
  final _jarNameController = TextEditingController();
  final _emailController = TextEditingController();
  final List<String> _collaboratorEmails = [];
  String _selectedColor = '#fbb4a5';

  /// Saves the jar to the user's collection and collaborator collections.
  Future<void> _saveJar() async {
    if (_jarNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Jar name cannot be empty!'),
          backgroundColor: AppColors.background,
        ),
      );
      return;
    }

    /// Check if the email is not empty
    if (_emailController.text.trim().isNotEmpty) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: _emailController.text.trim())
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          _collaboratorEmails.add(_emailController.text.trim());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No matching user found.'),
              backgroundColor: AppColors.background,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to verify collaborator.'),
            backgroundColor: AppColors.background,
          ),
        );
        return;
      }
    }

    final jarData = {
      'name': _jarNameController.text.trim(),
      'color': _selectedColor,
      'collaborators': _collaboratorEmails,
      'owner': widget.userId, // Add owner ID for identification
    };

    try {
      // Add jar to the owner's collection
      final jarRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('jars')
          .add(jarData);

      // Add jar to collaborators' collections
      for (String collaborator in _collaboratorEmails) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: collaborator)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final collaboratorId = querySnapshot.docs.first.id;

          await FirebaseFirestore.instance
              .collection('users')
              .doc(collaboratorId)
              .collection('jars')
              .doc(jarRef.id) // Use the same jar ID
              .set({
            'name': _jarNameController.text.trim(),
            'color': _selectedColor,
            'shared': true, // Indicate this jar is shared
            'owner': widget.userId, // Reference to the owner
          });
        }
      }

      Navigator.of(context).pop();
    } catch (e) {
      print('Error saving jar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save jar.'),
          backgroundColor: AppColors.background,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(
        'Add a New Jar',
        style: TextStyle(
          color: AppColors.selectedFonts,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite, // Ensures content takes up available width
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _jarNameController,
              decoration: InputDecoration(
                labelText: 'Jar Name',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.selectedFonts),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.selectedFonts),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Dropdown for selecting jar color
            DropdownButtonFormField<String>(
              value: _selectedColor,
              items: [
                '#fbb4a5',
                '#f8fba5',
                '#d9fba5',
                '#a5fbcf',
                '#a5c8fb',
              ].map((color) {
                return DropdownMenuItem(
                  // Display color preview in dropdown
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
                      Text(
                        color,
                        style: TextStyle(
                          color: AppColors.selectedFonts,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedColor = value;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Select Color',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.selectedFonts),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.selectedFonts),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Collaborator email field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Collaborator Username',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.selectedFonts),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.selectedFonts),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actions: [
        // Cancel button and Save button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.selectedFonts,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _saveJar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.selectedFonts,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Save',
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _jarNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
