import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';

class MultimediaOptions extends StatelessWidget {
  final String userId;
  final String jarId;

  const MultimediaOptions({
    super.key,
    required this.userId,
    required this.jarId,
  });

  Future<void> _addContentWithDate(
      BuildContext context, String type, IconData icon) async {
    // Only handle photo and video for now
    if (type.toLowerCase() == 'photo') {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image =
            await picker.pickImage(source: ImageSource.gallery);

        if (image == null) return;
        await _uploadMedia(context, image, type, icon);
      } catch (e) {
        print('Image picker error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to pick image: $e")),
        );
      }
      return;
    }

    if (type.toLowerCase() == 'video') {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? video = await picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration:
              const Duration(minutes: 10), // Optional: limit video duration
        );

        if (video == null) return;

        // Check file size before uploading (optional)
        final File videoFile = File(video.path);
        final size = await videoFile.length();
        if (size > 100 * 1024 * 1024) {
          // 100MB limit
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "Video file is too large. Please choose a smaller video.")),
          );
          return;
        }

        await _uploadMedia(context, video, type, icon);
      } catch (e) {
        print('Video picker error: $e');
        String errorMessage = 'Failed to pick video';
        if (e.toString().contains('permission')) {
          errorMessage =
              'Please grant permission to access your videos in Settings';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
      return;
    }

    // For other types (Note, Voice Note, Template), do nothing for now
    print('${type.toLowerCase()} functionality not implemented yet');
  }

  Future<void> _uploadMedia(
      BuildContext context, XFile media, String type, IconData icon) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uploading media...")),
      );

      print('Checking Amplify configuration status: ${Amplify.isConfigured}');

      final file = File(media.path);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(media.path)}';

      final key = 'uploads/$userId/$jarId/$fileName';
      print('Starting S3 upload for key: $key');

      final uploadResult = await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(file.path),
        key: key,
        options: const StorageUploadFileOptions(
          accessLevel: StorageAccessLevel.guest,
        ),
      );
      print('Upload completed: ${uploadResult.toString()}');

      final getUrlOperation = await Amplify.Storage.getUrl(key: key);
      final String mediaUrl = (await getUrlOperation.result).url.toString();
      print('Got S3 URL: $mediaUrl');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jars')
          .doc(jarId)
          .update({
        'content': FieldValue.arrayUnion([
          {
            'type': type.toLowerCase(),
            'icon': icon.codePoint,
            'data': mediaUrl,
            'date': DateTime.now().toIso8601String(),
          }
        ])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${type.toLowerCase()} uploaded successfully!")),
      );
    } catch (e, stackTrace) {
      print('Detailed S3 upload error: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload ${type.toLowerCase()}: $e")),
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
            _buildIconColumn(context, Icons.edit, "Note"),
            _buildIconColumn(context, Icons.videocam, "Video"),
            _buildIconColumn(context, Icons.photo, "Photo"),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconColumn(context, Icons.mic, "Voice Note"),
            const SizedBox(width: 24),
            _buildIconColumn(context, Icons.format_paint, "Template"),
          ],
        ),
      ],
    );
  }

  Widget _buildIconColumn(BuildContext context, IconData icon, String label) {
    return InkWell(
      onTap: () => _addContentWithDate(context, label, icon),
      borderRadius: BorderRadius.circular(8),
      splashColor: Colors.grey.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
