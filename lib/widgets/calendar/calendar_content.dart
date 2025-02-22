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
  @override
  Widget build(BuildContext context) {
    // Initialize the stream directly in the build method
    final Stream<QuerySnapshot> stream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('jars')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
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

        // Collect and group content
        final groupedContent = _extractAndGroupContent(snapshot.data);

        if (groupedContent.isEmpty) {
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

            // Call the groupedContent widget or function
            return GroupedContent(
              title: key,
              contentList: contentList,
            );
          },
        );
      },
    );
  }

  /// Extracts and groups content data from the Firestore snapshot.
  Map<String, List<Map<String, dynamic>>> _extractAndGroupContent(
      QuerySnapshot? snapshot) {
    final contentData = <Map<String, dynamic>>[];

    for (final jar in snapshot?.docs ?? []) {
      final data = jar.data() as Map<String, dynamic>;
      final jarName = data['name'] ?? 'Unknown Jar';
      final jarColor = data['color'] ?? '#000000';

      if (data.containsKey('content') && data['content'] is List<dynamic>) {
        final jarContent = data['content'] as List<dynamic>;
        for (final content in jarContent) {
          if (content is Map<String, dynamic> &&
              content.containsKey('type') &&
              content.containsKey('data') &&
              content.containsKey('date')) {
            // Log the image URL
            print('Image URL: ${content['data']}'); // Log the URL for debugging

            contentData.add({
              'type': content['type'],
              'data': content['data'], // Ensure this is the image URL
              'date': content['date'] is Timestamp
                  ? (content['date'] as Timestamp).toDate()
                  : DateTime.tryParse(content['date'].toString()) ??
                      DateTime.now(),
              'jarName': jarName,
              'jarColor': jarColor,
            });
          }
        }
      }
    }

    // Sort and group by year-month
    contentData.sort((a, b) => b['date'].compareTo(a['date']));
    final groupedContent = <String, List<Map<String, dynamic>>>{};

    for (final content in contentData) {
      final date = content['date'] as DateTime;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      groupedContent.putIfAbsent(key, () => []).add(content);
    }

    return groupedContent;
  }
}
