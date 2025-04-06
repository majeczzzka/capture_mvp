import 'package:capture_mvp/services/s3_service.dart';
import 'package:capture_mvp/models/s3_item.dart';
import 'package:capture_mvp/widgets/calendar/grouped_content.dart'; // Assuming the groupedContent widget is in this file
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../repositories/calendar_repository.dart';

/// A widget that displays content in a calendar view.
class CalendarContent extends StatefulWidget {
  final String userId;

  const CalendarContent({Key? key, required this.userId}) : super(key: key);

  @override
  _CalendarContentState createState() => _CalendarContentState();
}

class _CalendarContentState extends State<CalendarContent> {
  late final CalendarRepository _calendarRepository;
  late Future<Map<String, List<Map<String, dynamic>>>> _contentFuture;

  @override
  void initState() {
    super.initState();
    _calendarRepository = CalendarRepository(userId: widget.userId);
    _refreshContent();
  }

  /// Force a refresh of the content
  void _refreshContent() {
    setState(() {
      _contentFuture = _calendarRepository.fetchAndGroupContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _contentFuture,
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
              userId: widget.userId,
              onContentChanged: _refreshContent, // Pass the refresh callback
            );
          },
        );
      },
    );
  }
}
