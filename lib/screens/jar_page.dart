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
  final List<String> contributorAvatars;
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
                            child: Text(
                              jarTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: darkerColor,
                                fontSize: 25,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 145,
                            child: AvatarStack(
                              images: contributorAvatars,
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
                              onTap: () {
                                print("Add Note tapped");
                              },
                            ),
                            _buildIconColumn(
                              context,
                              Icons.videocam,
                              "Video",
                              onTap: () {
                                print("Add Video tapped");
                              },
                            ),
                            _buildIconColumn(
                              context,
                              Icons.photo,
                              "Photo",
                              onTap: () {
                                print("Add Photo tapped");
                              },
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
                              "Voice",
                              onTap: () {
                                print("Add Voice tapped");
                              },
                            ),
                            const SizedBox(width: 24),
                            _buildIconColumn(
                              context,
                              Icons.format_paint,
                              "Templates",
                              onTap: () {
                                print("Add Templates tapped");
                              },
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

  // Helper for Icons with Labels
  Widget _buildIconColumn(
    BuildContext context,
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      splashColor: AppColors.selectedFonts.withOpacity(0.3),
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
