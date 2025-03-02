import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:capture_mvp/services/s3_service.dart';

class MultimediaOptions extends StatefulWidget {
  final String userId;
  final String jarId;
  final List<String> collaborators;

  const MultimediaOptions({
    super.key,
    required this.userId,
    required this.jarId,
    required this.collaborators,
  });

  @override
  _MultimediaOptionsState createState() => _MultimediaOptionsState();
}

class _MultimediaOptionsState extends State<MultimediaOptions> {
  late S3Service _s3Service;
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    _s3Service = S3Service(userId: widget.userId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  Future<void> _addContent(String type) async {
    if (type != 'photo' && type != 'video') {
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

      await _s3Service.uploadFileToJar(
          widget.jarId, media.path, widget.collaborators, type);
      await _s3Service.syncJarContentAcrossCollaborators(widget.jarId);

      _scaffoldMessenger?.showSnackBar(
        SnackBar(content: Text("$type uploaded successfully!")),
      );
    } catch (e) {
      print('❌ Error uploading $type: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildIconColumn("Note", Icons.edit, isActive: false),
            _buildIconColumn("Video", Icons.videocam, isActive: true),
            _buildIconColumn("Photo", Icons.photo, isActive: true),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconColumn("Voice Note", Icons.mic, isActive: false),
            const SizedBox(width: 24),
            _buildIconColumn("Template", Icons.format_paint, isActive: false),
          ],
        ),
      ],
    );
  }

  Widget _buildIconColumn(String label, IconData icon,
      {required bool isActive}) {
    return InkWell(
      onTap: isActive ? () => _addContent(label.toLowerCase()) : null,
      borderRadius: BorderRadius.circular(8),
      splashColor: isActive ? Colors.grey.withOpacity(0.3) : null,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.grey[800] : Colors.grey[400]),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: isActive ? Colors.grey[800] : Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}
