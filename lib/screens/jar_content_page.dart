import 'package:capture_mvp/widgets/jar_content/jar_content_grid.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/nav/bottom_nav_bar.dart';
import '../widgets/header/header_widget.dart';
import '../widgets/home/content_container.dart';

/// Displays the contents of a specific jar.
class JarContentPage extends StatelessWidget {
  final String jarTitle;
  final String userId;
  final String jarId;
  final List<Map<String, String>> contents;

  const JarContentPage({
    super.key,
    required this.jarTitle,
    required this.userId,
    required this.jarId,
    required this.contents,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.fonts),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Expanded(
              child: ContentContainer(
                child: Column(
                  children: [
                    // Header Section
                    SizedBox(
                      height: 60,
                      child: HeaderWidget(
                        userId: userId,
                        onSearchChanged: (query) {},
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
                    // Content Grid Section
                    Expanded(
                      child: JarContentGrid(contents: contents),
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
}
