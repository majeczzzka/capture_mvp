import 'package:capture_mvp/widgets/jar_content/content_item.dart';
import 'package:flutter/material.dart';

/// A grid view displaying jar contents.
class JarContentGrid extends StatelessWidget {
  final List<Map<String, String>> contents;

  const JarContentGrid({
    super.key,
    required this.contents,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thickness: 3,
      radius: const Radius.circular(10),
      interactive: true,
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: contents.length,
        itemBuilder: (context, index) {
          final content = contents[index];
          return ContentItemWidget(content: content);
        },
      ),
    );
  }
}
