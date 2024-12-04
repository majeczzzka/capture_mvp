import 'package:flutter/material.dart';
import 'package:capture_mvp/utils/app_shadows.dart';
import '../utils/app_colors.dart';
import '../widgets/header_widget.dart';
import '../widgets/bottom_nav_bar.dart';

class JarContentPage extends StatelessWidget {
  final String jarTitle;
  final List<Map<String, String>> contents;

  const JarContentPage({
    super.key,
    required this.jarTitle,
    required this.contents,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0, // Removes shadow
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.fonts),
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white, // Unified container background
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.subtleShadowList,
                ),
                child: Column(
                  children: [
                    // Header Section
                    SizedBox(
                      height: 60,
                      child: HeaderWidget(
                        onSearchChanged: (query) {
                          print("Search query: $query");
                        },
                      ),
                    ),
                    const Divider(
                      thickness: 1,
                      color: AppColors.fonts,
                      indent: 8,
                      endIndent: 8,
                    ),
                    const SizedBox(height: 8),
                    // Title Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        jarTitle,
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.fonts,
                          decorationThickness: 1,
                          fontSize: 24,
                          fontWeight: FontWeight.normal,
                          color: AppColors.fonts,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Scrollable Grid Section
                    Expanded(
                      child: Scrollbar(
                        thickness: 3, // Thickness of the scrollbar
                        radius: const Radius.circular(10), // Rounded corners
                        trackVisibility: false,
                        interactive:
                            true, // Allow interaction with the scrollbar
                        child: GridView.builder(
                          padding: const EdgeInsets.only(
                              bottom: 16.0), // Space below grid
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // Two items per row
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                          ),
                          itemCount: contents.length,
                          itemBuilder: (context, index) {
                            final content = contents[index];
                            return GestureDetector(
                              onTap: () {
                                print("${content['type']} tapped");
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (content['type'] == 'image')
                                    Image.asset(
                                      content['data']!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                  else
                                    Icon(
                                      content['type'] == 'video'
                                          ? Icons.videocam
                                          : content['type'] == 'note'
                                              ? Icons.notes
                                              : Icons.mic,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    content['type']!.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
                height: 16), // Adds space between content and BottomNavBar
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
