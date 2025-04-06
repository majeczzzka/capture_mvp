import 'package:flutter/material.dart';
import 'logo.dart';
import '../../utils/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import '../../repositories/media_repository.dart';

/// A header widget for jar content pages with a plus button to add content.
class HeaderWidgetContent extends StatelessWidget {
  final String userId;
  final String jarId;
  final List<String> collaborators;
  final Function()? onContentAdded;

  const HeaderWidgetContent({
    super.key,
    required this.userId,
    required this.jarId,
    required this.collaborators,
    this.onContentAdded,
  });

  void _showAddContentBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return ContentAddSheet(
          userId: userId,
          jarId: jarId,
          collaborators: collaborators,
          onContentAdded: onContentAdded,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Logo(), // Display logo left-aligned
        IconButton(
          icon: const Icon(Icons.add_circle, color: AppColors.fonts, size: 30),
          onPressed: () => _showAddContentBottomSheet(context),
          tooltip: 'Add content',
        ),
      ],
    );
  }
}

/// A beautiful bottom sheet for adding content to a jar
class ContentAddSheet extends StatefulWidget {
  final String userId;
  final String jarId;
  final List<String> collaborators;
  final Function()? onContentAdded;

  const ContentAddSheet({
    Key? key,
    required this.userId,
    required this.jarId,
    required this.collaborators,
    this.onContentAdded,
  }) : super(key: key);

  @override
  State<ContentAddSheet> createState() => _ContentAddSheetState();
}

class _ContentAddSheetState extends State<ContentAddSheet> {
  late MediaRepository _mediaRepository;
  bool _isUploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _mediaRepository = MediaRepository(userId: widget.userId);
  }

  Future<void> _addContent(String type) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadError = null;
      });

      final ImagePicker picker = ImagePicker();
      XFile? pickedFile;

      if (type == 'photo') {
        pickedFile = await picker.pickImage(source: ImageSource.gallery);
      } else if (type == 'video') {
        pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      }

      if (pickedFile == null) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Upload the media
      final success = await _mediaRepository.uploadMedia(
        widget.jarId,
        pickedFile.path,
        type,
        widget.collaborators,
      );

      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$type added successfully!")),
          );

          // Notify parent and close sheet
          if (widget.onContentAdded != null) {
            widget.onContentAdded!();
          }
          Navigator.pop(context);
        } else {
          setState(() {
            _uploadError = "Failed to upload $type";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadError = "Error: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle for bottom sheet
          Container(
            height: 5,
            width: 40,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),

          // Title
          const Text(
            'Add to Jar',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.fonts,
            ),
          ),
          const SizedBox(height: 24),

          // Grid of options
          _isUploading
              ? const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        'Uploading...',
                        style: TextStyle(color: AppColors.fonts),
                      ),
                    ],
                  ),
                )
              : GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildOptionCard(
                      icon: Icons.photo,
                      label: 'Photo',
                      color: Colors.blue,
                      onTap: () => _addContent('photo'),
                    ),
                    _buildOptionCard(
                      icon: Icons.videocam,
                      label: 'Video',
                      color: Colors.red,
                      onTap: () => _addContent('video'),
                    ),
                    _buildOptionCard(
                      icon: Icons.mic,
                      label: 'Voice Note',
                      color: Colors.orange,
                      onTap: null, // Disabled
                      isDisabled: true,
                    ),
                    _buildOptionCard(
                      icon: Icons.note_alt,
                      label: 'Note',
                      color: Colors.green,
                      onTap: null, // Disabled
                      isDisabled: true,
                    ),
                  ],
                ),

          // Error message if any
          if (_uploadError != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _uploadError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[100] : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled ? Colors.grey[300]! : color.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isDisabled ? Colors.grey[400] : color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isDisabled ? Colors.grey[500] : color,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isDisabled)
              const Text(
                'Coming soon',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
