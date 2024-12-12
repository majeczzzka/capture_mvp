import 'package:capture_mvp/widgets/header_widget.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_shadows.dart';
import '../widgets/bottom_nav_bar.dart';

class CalendarScreen extends StatelessWidget {
  final List<Map<String, dynamic>> contentData = [
    {
      'type': 'note',
      'data': 'This is a sample note from jar 1.',
      'date': DateTime(2023, 6, 10),
    },
    {
      'type': 'photo',
      'data': 'assets/images/profile_picture.jpg',
      'date': DateTime(2024, 5, 15),
    },
    {
      'type': 'video',
      'data': 'assets/example_video.mp4',
      'date': DateTime(2023, 8, 22),
    },
    {
      'type': 'note',
      'data': 'This is a sample note from jar 2.',
      'date': DateTime(2023, 6, 12),
    },
  ];
  final String userId;

  CalendarScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // Sort content by date
    contentData.sort((a, b) => b['date'].compareTo(a['date']));

    // Group content by month and year
    final groupedContent = <String, List<Map<String, dynamic>>>{};
    for (final content in contentData) {
      final date = content['date'] as DateTime;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      if (!groupedContent.containsKey(key)) {
        groupedContent[key] = [];
      }
      groupedContent[key]!.add(content);
    }

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
            color: Colors.white, // Same as other pages
            borderRadius: BorderRadius.circular(16), // Rounded edges
            boxShadow: AppShadows.subtleShadowList, // Subtle shadow
          ),
          child: Column(
            children: [
              // Header Section Inside the Container
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
              // Scrollable Content Section with Scrollbar
              Expanded(
                child: Scrollbar(
                  thickness: 3,
                  radius: const Radius.circular(10),
                  child: Padding(
                    padding:
                        const EdgeInsets.only(bottom: 16.0), // Add space here
                    child: ListView.builder(
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
                                vertical: 8.0,
                                horizontal: 8.0,
                              ),
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
                                      if (content['type'] == 'photo')
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
                                              : Icons.notes,
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
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  // Helper to get month name
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
