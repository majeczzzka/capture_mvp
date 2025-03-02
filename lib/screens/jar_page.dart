import 'package:flutter/material.dart';
import 'package:capture_mvp/utils/app_colors.dart';
import 'package:capture_mvp/widgets/jar/avatar_stack.dart';
import 'package:capture_mvp/widgets/nav/bottom_nav_bar.dart';
import 'package:capture_mvp/widgets/header/header_widget_jar.dart';
import 'package:capture_mvp/widgets/home/content_container.dart';
import 'package:capture_mvp/widgets/jar_page/multimedia_options.dart';
import 'package:capture_mvp/services/s3_service.dart';
import 'jar_content_page.dart';

class JarPage extends StatelessWidget {
  final String jarTitle;
  final List<Widget> contributorAvatars;
  final Color jarColor;
  final String jarImage;
  final String userId;
  final String jarId;
  final List<String> collaborators;

  const JarPage({
    super.key,
    required this.jarTitle,
    required this.contributorAvatars,
    required this.jarColor,
    required this.jarImage,
    required this.userId,
    required this.jarId,
    required this.collaborators,
  });

  Future<void> _deleteJar(BuildContext context) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Jar'),
        content: const Text(
            'Are you sure you want to delete this jar for all collaborators?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm) {
      try {
        final s3Service = S3Service(userId: userId);
        await s3Service.deleteJar(jarId, collaborators);

        // Close the page after deletion
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
          onPressed: () => Navigator.pop(context),
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
                        endIndent: 8),
                    const SizedBox(height: 32),
                    _buildJarImage(darkerColor, context),
                    const SizedBox(height: 24),
                    MultimediaOptions(
                      userId: userId,
                      jarId: jarId,
                      collaborators: collaborators,
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

  Widget _buildJarImage(Color darkerColor, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JarContentPage(
                jarTitle: jarTitle, userId: userId, jarId: jarId),
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
            child: Image.asset(jarImage, width: 250, height: 250),
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
                avatars: contributorAvatars, radius: 18, overlap: 10),
          ),
        ],
      ),
    );
  }
}
