import 'package:capture_mvp/widgets/avatar_stack.dart';
import 'package:flutter/material.dart';
import 'package:capture_mvp/utils/app_colors.dart';
import 'package:capture_mvp/utils/app_shadows.dart';
import 'package:capture_mvp/widgets/bottom_nav_bar.dart';
import 'package:capture_mvp/widgets/header_widget_jar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'jar_content_page.dart';

class JarPage extends StatelessWidget {
  final String jarTitle;
  final List<Widget> contributorAvatars;
  final Color jarColor;
  final String jarImage;
  final String userId; // User ID for Firestore
  final String jarId; // Jar ID for Firestore

  const JarPage({
    super.key,
    required this.jarTitle,
    required this.contributorAvatars,
    required this.jarColor,
    required this.jarImage,
    required this.userId,
    required this.jarId,
  });

  /// Deletes the current jar from Firestore
  Future<void> _deleteJar(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId)
          .delete();

      // Navigate back after deletion
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jar deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to delete jar. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkerColor = Color.fromARGB(
      jarColor.alpha,
      (jarColor.red * 0.7).toInt(),
      (jarColor.green * 0.7).toInt(),
      (jarColor.blue * 0.7).toInt(),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.subtleShadowList,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 60,
                      child: HeaderWidgetJar(
                        onSearchChanged: (query) {
                          print("Searching in JarPage for: $query");
                        },
                        userId: userId,
                        jarId: jarId,
                        onDeletePressed: () => _deleteJar(context),
                      ),
                    ),
                    const Divider(
                      thickness: 1,
                      color: AppColors.fonts,
                      indent: 8,
                      endIndent: 8,
                    ),
                    const SizedBox(height: 32),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JarContentPage(
                              jarTitle: jarTitle,
                              userId: userId,
                              jarId: jarId,
                              contents: [
                                {'type': 'note', 'data': 'Sample Note 1'},
                                {'type': 'video', 'data': ''},
                                {'type': 'photo', 'data': 'Sample Photo'},
                              ],
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              jarColor.withOpacity(0.7),
                              BlendMode.modulate,
                            ),
                            child: Image.asset(
                              jarImage,
                              width: 250,
                              height: 250,
                            ),
                          ),
                          Positioned(
                            top: 110,
                            child: SizedBox(
                              width: 120, // Width of the jar image
                              child: Text(
                                jarTitle,
                                maxLines: 1, // Restrict to a single line
                                overflow: TextOverflow
                                    .ellipsis, // Add ellipsis if text overflows
                                textAlign:
                                    TextAlign.center, // Center-align text
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkerColor,
                                  fontSize: 25,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 145,
                            child: AvatarStack(
                              avatars: contributorAvatars,
                              radius: 18,
                              overlap: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Multimedia Options
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildIconColumn(
                              context,
                              Icons.edit,
                              "Note",
                            ),
                            _buildIconColumn(
                              context,
                              Icons.videocam,
                              "Video",
                            ),
                            _buildIconColumn(
                              context,
                              Icons.photo,
                              "Photo",
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildIconColumn(
                              context,
                              Icons.mic,
                              "Voice Note",
                            ),
                            const SizedBox(width: 24),
                            _buildIconColumn(
                              context,
                              Icons.format_paint,
                              "Template",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Widget _buildIconColumn(
    BuildContext context,
    IconData icon,
    String label, // Use the label for both display and content type
  ) {
    return InkWell(
      onTap: () async {
        // Show the popup dialog to select a date
        DateTime? selectedDate = await showDialog<DateTime>(
          context: context,
          builder: (context) {
            DateTime? tempSelectedDate = DateTime.now();
            return AlertDialog(
              title: Text('Select Date for $label'),
              content: SizedBox(
                height: 400, // Increased height for better layout
                width: 300, // Ensure the dialog has enough width
                child: Column(
                  children: [
                    Expanded(
                      child: CalendarDatePicker(
                        initialDate: tempSelectedDate!,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        onDateChanged: (date) {
                          tempSelectedDate = date;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close without saving
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, tempSelectedDate); // Save and close
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );

        if (selectedDate != null) {
          // Save the selected date to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('jars')
              .doc(jarId)
              .update({
            'content': FieldValue.arrayUnion([
              {
                'type':
                    label.toLowerCase(), // Use the label for the content type
                'icon': icon.toString(), // Save the icon as a string
                'data': 'Sample $label content', // Placeholder content
                'date':
                    selectedDate.toIso8601String(), // Save the selected date
              },
            ])
          });
        }
      },
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
