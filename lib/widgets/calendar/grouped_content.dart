import 'package:capture_mvp/utils/app_colors.dart';
import 'package:capture_mvp/widgets/calendar/content_grid_item.dart';
import 'package:flutter/material.dart';
import '../../utils/month_util.dart';

/// A grouped content widget that displays content in a grid view.
class GroupedContent extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> contentList;
  final String userId;
  final VoidCallback? onContentChanged;

  const GroupedContent({
    super.key,
    required this.title,
    required this.contentList,
    required this.userId,
    this.onContentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final yearMonth = title.split('-');
    final year = yearMonth[0];
    final month = int.parse(yearMonth[1]);
    // Display the month and year
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Text(
            '${MonthUtil.getMonthName(month)} $year',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.selectedFonts,
            ),
          ),
        ),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: contentList.length,
          itemBuilder: (context, index) {
            final content = contentList[index];
            return ContentItem(
              content: content,
              userId: userId,
              jarId: content['jarId'],
              onContentChanged: onContentChanged,
            );
          },
        ),
        const SizedBox(height: 16), // Space after each group
      ],
    );
  }
}
