import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../repositories/media_repository.dart';
import 'icon_column.dart';

/// Widget that displays multimedia options for adding content to a jar
class MultimediaOptions extends StatefulWidget {
  final String userId;
  final String jarId;
  final List<String> collaborators;
  final Function(String)? onContentAdded;

  const MultimediaOptions({
    super.key,
    required this.userId,
    required this.jarId,
    required this.collaborators,
    this.onContentAdded,
  });

  @override
  _MultimediaOptionsState createState() => _MultimediaOptionsState();
}

class _MultimediaOptionsState extends State<MultimediaOptions> {
  late MediaRepository _mediaRepository;
  ScaffoldMessengerState? _scaffoldMessenger;

  // Define which content types are currently active
  final Map<String, bool> _activeContentTypes = {
    'note': false,
    'video': true,
    'photo': true,
    'voice note': false,
    'template': false,
  };

  @override
  void initState() {
    super.initState();
    _mediaRepository = MediaRepository(userId: widget.userId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  Future<void> _addContent(String type) async {
    if (!_activeContentTypes[type]!) {
      _scaffoldMessenger?.showSnackBar(
        SnackBar(content: Text("$type functionality is not yet available.")),
      );
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      XFile? pickedFile;

      if (type == 'photo') {
        pickedFile = await picker.pickImage(source: ImageSource.gallery);
      } else if (type == 'video') {
        pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      }

      if (pickedFile == null) return;
      await _uploadMedia(pickedFile, type);
    } catch (e) {
      print('❌ Error picking $type: $e');
      _scaffoldMessenger?.showSnackBar(
        SnackBar(content: Text("Failed to pick $type: $e")),
      );
    }
  }

  Future<void> _uploadMedia(XFile media, String type) async {
    try {
      _scaffoldMessenger?.showSnackBar(
        const SnackBar(content: Text("Uploading media...")),
      );

      // Use repositories instead of services directly
      // This would typically be implemented in MediaRepository
      // For now we're maintaining compatibility with existing code
      final success = await _mediaRepository.uploadMedia(
        widget.jarId,
        media.path,
        type,
        widget.collaborators,
      );

      if (success) {
        _scaffoldMessenger?.showSnackBar(
          SnackBar(content: Text("$type uploaded successfully!")),
        );

        // Notify parent that content was added
        if (widget.onContentAdded != null) {
          widget.onContentAdded!(type);
        }
      } else {
        _scaffoldMessenger?.showSnackBar(
          SnackBar(content: Text("Failed to upload $type.")),
        );
      }
    } catch (e) {
      print('❌ Error uploading $type: $e');
      _scaffoldMessenger?.showSnackBar(
        SnackBar(content: Text("Error uploading $type: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconColumn(
              icon: Icons.edit,
              label: "Note",
              isEnabled: _activeContentTypes['note']!,
              onTap: () => _addContent('note'),
              iconColor: Colors.grey[800],
              textColor: Colors.grey[800],
            ),
            IconColumn(
              icon: Icons.videocam,
              label: "Video",
              isEnabled: _activeContentTypes['video']!,
              onTap: () => _addContent('video'),
              iconColor: Colors.grey[800],
              textColor: Colors.grey[800],
            ),
            IconColumn(
              icon: Icons.photo,
              label: "Photo",
              isEnabled: _activeContentTypes['photo']!,
              onTap: () => _addContent('photo'),
              iconColor: Colors.grey[800],
              textColor: Colors.grey[800],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconColumn(
              icon: Icons.mic,
              label: "Voice Note",
              isEnabled: _activeContentTypes['voice note']!,
              onTap: () => _addContent('voice note'),
              iconColor: Colors.grey[800],
              textColor: Colors.grey[800],
            ),
            const SizedBox(width: 24),
            IconColumn(
              icon: Icons.format_paint,
              label: "Template",
              isEnabled: _activeContentTypes['template']!,
              onTap: () => _addContent('template'),
              iconColor: Colors.grey[800],
              textColor: Colors.grey[800],
            ),
          ],
        ),
      ],
    );
  }
}
