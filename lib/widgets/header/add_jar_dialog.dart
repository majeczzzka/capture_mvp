import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../models/jar_data.dart';
import '../../repositories/jar_repository.dart';
import '../../repositories/user_repository.dart';

/// A dialog for adding a new jar to Firestore.
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
  late final JarRepository _jarRepository;
  late final UserRepository _userRepository;

  @override
  void initState() {
    super.initState();
    _jarRepository = JarRepository(userId: widget.userId);
    _userRepository = UserRepository();
  }

  /// Saves the jar to Firestore and ensures all collaborators have access.
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

    print("🔥 Starting to save jar: ${_jarNameController.text.trim()}");

    List<String> collaboratorUserIds = [];

    // 🔥 Always include the owner as a collaborator
    collaboratorUserIds.add(widget.userId);

    // 🔥 Make sure we save the typed collaborator before looking it up
    if (_emailController.text.trim().isNotEmpty) {
      final enteredUsername = _emailController.text.trim();
      if (!_collaboratorEmails.contains(enteredUsername)) {
        _collaboratorEmails.add(enteredUsername); // ✅ Ensure it's added
      }
    }

    print("🔍 Checking usernames: $_collaboratorEmails");

    // 🔍 Convert usernames into user IDs using the repository
    for (String username in _collaboratorEmails) {
      print("🔍 Looking up user ID for username: $username");

      try {
        final userId = await _userRepository.getUserIdByUsername(username);

        if (userId != null) {
          collaboratorUserIds.add(userId);
          print("✅ Found user ID for $username: $userId");
        } else {
          print("⚠️ No user found for username: $username");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No matching user found for $username.'),
              backgroundColor: AppColors.background,
            ),
          );
        }
      } catch (e) {
        print("❌ Error verifying collaborator: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to verify collaborator.'),
            backgroundColor: AppColors.background,
          ),
        );
        return;
      }
    }

    print("✅ Final Collaborators List: $collaboratorUserIds");

    // Create JarData model
    final JarData jarData = JarData(
      id: '', // Will be assigned by Firestore
      name: _jarNameController.text.trim(),
      color: _selectedColor,
      collaborators: collaboratorUserIds,
      shared: collaboratorUserIds.length > 1,
      content: [], // Empty content for new jar
    );

    try {
      // Create the jar using the repository
      final jarId = await _jarRepository.createJar(jarData);

      if (jarId != null) {
        print("✅ Jar saved successfully: $jarId");
        Navigator.of(context).pop();
      } else {
        throw Exception('Failed to create jar');
      }
    } catch (e) {
      print('❌ Error saving jar: $e');
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
        width: double.maxFinite,
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.selectedFonts,
            ),
          ),
        ),
        TextButton(
          onPressed: _saveJar,
          child: Text(
            'Save',
            style: TextStyle(
              color: AppColors.selectedFonts,
            ),
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
