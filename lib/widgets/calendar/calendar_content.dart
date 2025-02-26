import 'package:capture_mvp/services/s3_service.dart';
import 'package:capture_mvp/models/s3_item.dart';
import 'package:capture_mvp/widgets/calendar/grouped_content.dart'; // Assuming the groupedContent widget is in this file
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A widget that displays content in a calendar view.
class CalendarContent extends StatefulWidget {
  final String userId;

  const CalendarContent({Key? key, required this.userId}) : super(key: key);

  @override
  _CalendarContentState createState() => _CalendarContentState();
}

class _CalendarContentState extends State<CalendarContent> {
  Future<Map<String, List<Map<String, dynamic>>>>
      _fetchAndGroupContent() async {
    final List<Map<String, dynamic>> contentData = [];

    final jarsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('jars')
        .get();

    for (final jar in jarsSnapshot.docs) {
      final data = jar.data() as Map<String, dynamic>;
      final jarId = jar.id; // Get the jar ID
      final jarName = data['name'] ?? 'Unknown Jar';
      final jarColor = data['color'] ?? '#000000';

      // Fetch images from AWS S3
      List<S3Item> s3Items =
          await S3Service(userId: widget.userId).getJarContents(jarId);

      for (final s3Item in s3Items) {
        contentData.add({
          'type': 'image',
          'data': s3Item.url,
          'date': s3Item.uploadedAt ?? DateTime.now(),
          'jarName': jarName,
          'jarColor': jarColor,
        });
      }
    }

    // Sort and group by year-month
    contentData.sort((a, b) => b['date'].compareTo(a['date']));
    final Map<String, List<Map<String, dynamic>>> groupedContent = {};

    for (final content in contentData) {
      final date = content['date'] as DateTime;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      groupedContent.putIfAbsent(key, () => []).add(content);
    }

    return groupedContent;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _fetchAndGroupContent(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Failed to load content',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          );
        }

        final groupedContent = snapshot.data;

        if (groupedContent == null || groupedContent.isEmpty) {
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

            return GroupedContent(
              title: key,
              contentList: contentList,
            );
          },
        );
      },
    );
  }
}
