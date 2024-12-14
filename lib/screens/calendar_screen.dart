import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/nav/bottom_nav_bar.dart';
import '../widgets/header/header_widget.dart';
import '../widgets/calendar/calendar_content.dart';
import '../widgets/home/content_container.dart';

/// CalendarScreen displays user content organized by month and year.
class CalendarScreen extends StatelessWidget {
  final String userId;

  const CalendarScreen({
    super.key,
    required this.userId,
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
                icon: const Icon(Icons.arrow_back, color: AppColors.fonts),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            : null,
      ),
      body: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16.0), // Adjusted padding
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
                    const SizedBox(height: 16),
                    // Content Section
                    Expanded(
                      child: CalendarContent(userId: userId),
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
