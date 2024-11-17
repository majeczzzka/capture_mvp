import 'package:capture_mvp/widgets/avatar_stack.dart';
import 'package:flutter/material.dart';
import 'package:capture_mvp/utils/app_colors.dart';
import 'package:capture_mvp/utils/app_shadows.dart';
import 'package:capture_mvp/widgets/bottom_nav_bar.dart';

class JarPage extends StatelessWidget {
  final String jarTitle;
  final List<String> contributorAvatars;
  final Color jarColor;
  final String jarImage;

  const JarPage({
    super.key,
    required this.jarTitle,
    required this.contributorAvatars,
    required this.jarColor,
    required this.jarImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            : null,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Jar Image and Overlay (Title and Avatars)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            jarColor.withOpacity(0.7),
                            BlendMode.modulate,
                          ),
                          child: Image.asset(
                            jarImage,
                            width: 300,
                            height: 300,
                          ),
                        ),
                        // Display jar title
                        Positioned(
                          top: 130,
                          child: Text(
                            jarTitle,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 30,
                              shadows: [
                                Shadow(
                                  offset: Offset(1.5,
                                      1.5), // Slight horizontal and vertical offset
                                  blurRadius: 3.0, // Blur effect for the shadow
                                  color: Colors
                                      .black26, // Shadow color with some transparency
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 180,
                          child: AvatarStack(
                            images: contributorAvatars,
                            radius: 18,
                            overlap: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Icons in two rows
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildIconColumn(
                              context,
                              Icons.edit,
                              "note",
                              onTap: () {
                                // Handle note action
                                print("Note tapped");
                              },
                            ),
                            _buildIconColumn(
                              context,
                              Icons.videocam,
                              "video",
                              onTap: () {
                                // Handle video action
                                print("Video tapped");
                              },
                            ),
                            _buildIconColumn(
                              context,
                              Icons.photo,
                              "photo",
                              onTap: () {
                                // Handle photo action
                                print("Photo tapped");
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
                              "voice",
                              onTap: () {
                                // Handle voice action
                                print("Voice tapped");
                              },
                            ),
                            SizedBox(
                                width: 24), // Space between the last two icons
                            _buildIconColumn(
                              context,
                              Icons.format_paint,
                              "templates",
                              onTap: () {
                                // Handle templates action
                                print("Templates tapped");
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

  // Helper method for creating icons with labels and onTap action
  Widget _buildIconColumn(
    BuildContext context,
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
          8), // Adds a rounded border for the ripple effect
      splashColor:
          AppColors.selectedFonts.withOpacity(0.3), // Customize ripple color
      child: Padding(
        padding:
            const EdgeInsets.all(8.0), // Adds padding for a better touch target
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
