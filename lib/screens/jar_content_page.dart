import 'package:capture_mvp/widgets/jar_content/jar_content_grid.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/nav/bottom_nav_bar.dart';
import '../widgets/header/header_widget.dart';
import '../widgets/home/content_container.dart';
import '../services/s3_service.dart';
import '../models/s3_item.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Displays the contents of a specific jar.
class JarContentPage extends StatefulWidget {
  final String jarTitle;
  final String userId;
  final String jarId;

  const JarContentPage({
    super.key,
    required this.jarTitle,
    required this.userId,
    required this.jarId,
  });

  @override
  _JarContentPageState createState() => _JarContentPageState();
}

class _JarContentPageState extends State<JarContentPage> {
  List<S3Item> items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    List<S3Item> fetchedItems =
        await S3Service(userId: widget.userId).getJarContents(widget.jarId);
    final content = fetchedItems.map((item) => item.toJson()).toList();
    print("📂 Content in jar: $content");
    setState(() {
      items = fetchedItems;
    });
  }

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
                        userId: widget.userId,
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
                        widget.jarTitle,
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
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: items.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.7,
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];

                          return Card(
                            child: Column(
                              children: [
                                Expanded(
                                  child: Image.network(
                                    item.url, // Use the S3 URL to display the image
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print("⚠️ Error loading image: $error");
                                      return Icon(Icons.broken_image,
                                          size: 50, color: Colors.red);
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    item.type.toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
