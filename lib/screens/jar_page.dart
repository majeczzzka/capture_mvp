import 'package:capture_mvp/utils/app_colors.dart';
import 'package:capture_mvp/widgets/jar/avatar_stack.dart';
import 'package:capture_mvp/widgets/nav/bottom_nav_bar.dart';
import 'package:capture_mvp/widgets/header/header_widget_jar.dart';
import 'package:capture_mvp/widgets/home/content_container.dart';
import 'package:capture_mvp/widgets/jar_page/multimedia_options.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'jar_content_page.dart';

/// Displays the contents of a specific jar.
class JarPage extends StatelessWidget {
  final String jarTitle;
  final List<Widget> contributorAvatars;
  final Color jarColor;
  final String jarImage;
  final String userId;
  final String jarId;

  const JarPage({
    super.key,
    required this.jarTitle,
    required this.contributorAvatars,
    required this.jarColor,
    required this.jarImage,
    required this.userId,
    required this.jarId,
  });

  Future<void> _deleteJar(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId)
          .delete();
      // Close the dialog and show a success message
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
            Expanded(
              child: ContentContainer(
                child: Column(
                  children: [
                    // Header Section
                    SizedBox(
                      height: 60,
                      child: HeaderWidgetJar(
                        onSearchChanged: (query) {},
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
                    // Jar Image and Contributors
                    _buildJarImage(darkerColor, context),
                    const SizedBox(height: 24),
                    // Multimedia Options
                    MultimediaOptions(
                      userId: userId,
                      jarId: jarId,
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

  // Builds the jar image with the title and contributors.
  Widget _buildJarImage(Color darkerColor, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JarContentPage(
              jarTitle: jarTitle,
              userId: userId,
              jarId: jarId,
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
              width: 120,
              child: Text(
                jarTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
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
    );
  }
}
