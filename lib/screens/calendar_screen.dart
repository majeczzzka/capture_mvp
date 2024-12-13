import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import '../utils/app_shadows.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/header_widget.dart';

/// CalendarScreen displays user content organized by month and year.
class CalendarScreen extends StatelessWidget {
  final String userId; // User ID for fetching content

  const CalendarScreen({
    super.key,
    required this.userId,
  });

  Color parseColor(String colorString) {
    return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
  }

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
                icon: const Icon(Icons.arrow_back, color: AppColors.fonts),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.subtleShadowList,
          ),
          child: Column(
            children: [
              // Header Section
              SizedBox(
                height: 60,
                child: HeaderWidget(
                  userId: userId,
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
              const SizedBox(height: 16),
              // Content Display Section
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('jars')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Failed to load content',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      );
                    }

                    // Collect all content from all jars
                    final contentData = <Map<String, dynamic>>[];
                    for (final jar in snapshot.data?.docs ?? []) {
                      final data = jar.data() as Map<String, dynamic>;
                      final jarName = data['name'] as String? ?? 'Unknown Jar';
                      final jarColor = data['color'] as String? ?? '#000000';

                      // Check if the 'content' field exists and is a List
                      final jarContent = data.containsKey('content') &&
                              data['content'] is List<dynamic>
                          ? data['content'] as List<dynamic>
                          : [];

                      for (final content in jarContent) {
                        // Ensure each content has the required fields
                        if (content is Map<String, dynamic> &&
                            content.containsKey('type') &&
                            content.containsKey('data') &&
                            content.containsKey('date')) {
                          contentData.add({
                            'type': content['type'],
                            'data': content['data'],
                            'date': DateTime.tryParse(content['date']) ??
                                DateTime.now(),
                            'jarName': jarName,
                            'jarColor': jarColor,
                          });
                        } else {
                          print("Invalid content structure: $content");
                        }
                      }
                    }

                    // Sort content by date
                    contentData.sort((a, b) => b['date'].compareTo(a['date']));

                    // Group content by month and year
                    final groupedContent =
                        <String, List<Map<String, dynamic>>>{};
                    for (final content in contentData) {
                      final date = content['date'] as DateTime;
                      final key =
                          '${date.year}-${date.month.toString().padLeft(2, '0')}';
                      groupedContent.putIfAbsent(key, () => []).add(content);
                    }

                    if (contentData.isEmpty) {
                      return const Center(
                        child: Text(
                          'No content available',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: groupedContent.keys.length,
                      itemBuilder: (context, index) {
                        final key = groupedContent.keys.toList()[index];
                        final contentList = groupedContent[key]!;
                        final yearMonth = key.split('-');
                        final year = yearMonth[0];
                        final month = int.parse(yearMonth[1]);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 8.0),
                              child: Text(
                                '${_monthName(month)} $year',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.fonts,
                                ),
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                              ),
                              itemCount: contentList.length,
                              itemBuilder: (context, gridIndex) {
                                final content = contentList[gridIndex];
                                return GestureDetector(
                                  onTap: () {
                                    print("${content['type']} tapped");
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        content['type'] == 'video'
                                            ? Icons.videocam
                                            : content['type'] == 'note'
                                                ? Icons.notes
                                                : content['type'] == 'photo'
                                                    ? Icons.photo
                                                    : content['type'] ==
                                                            'voice note'
                                                        ? Icons.mic
                                                        : content['type'] ==
                                                                'template'
                                                            ? Icons.format_paint
                                                            : Icons.error,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        content['type'].toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        content['jarName'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: parseColor(
                                              content['jarColor'] as String),
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  /// Helper method to get month name
  String _monthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return monthNames[month - 1];
  }
}
