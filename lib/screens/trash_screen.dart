import 'package:flutter/material.dart';
import 'package:capture_mvp/models/s3_item.dart';
import 'package:capture_mvp/services/s3_service.dart';
import 'package:capture_mvp/utils/app_colors.dart';
import 'package:capture_mvp/widgets/nav/bottom_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// TrashScreen displays items that the user has deleted but can be restored.
class TrashScreen extends StatefulWidget {
  final String userId;

  const TrashScreen({super.key, required this.userId});

  @override
  _TrashScreenState createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<Map<String, dynamic>> _trashedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrashedItems();
  }

  Future<void> _loadTrashedItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all user's jars
      final jarsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('jars')
          .get();

      List<Map<String, dynamic>> allTrashedItems = [];

      // For each jar, get its deleted contents
      for (final jarDoc in jarsSnapshot.docs) {
        final String jarId = jarDoc.id;
        final String jarName = jarDoc.data()['name'] ?? 'Unnamed Jar';

        final S3Service s3Service = S3Service(userId: widget.userId);
        final List<S3Item> deletedItems =
            await s3Service.getDeletedJarContents(jarId);

        // Add each deleted item with its jar info
        for (final item in deletedItems) {
          allTrashedItems.add({
            'item': item,
            'jarId': jarId,
            'jarName': jarName,
          });
        }
      }

      // Sort by deletion date (newest first)
      allTrashedItems.sort((a, b) {
        final S3Item itemA = a['item'];
        final S3Item itemB = b['item'];
        return itemB.uploadedAt.compareTo(itemA.uploadedAt);
      });

      setState(() {
        _trashedItems = allTrashedItems;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading trashed items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreItem(String jarId, String itemUrl) async {
    try {
      final s3Service = S3Service(userId: widget.userId);
      await s3Service.restoreArchivedItem(jarId, itemUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item restored successfully')),
      );

      // Refresh the list
      _loadTrashedItems();
    } catch (e) {
      print('Error restoring item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to restore item: $e')),
      );
    }
  }

  Future<void> _permanentlyDeleteItem(
      String jarId, String itemUrl, List<String> collaborators) async {
    try {
      final s3Service = S3Service(userId: widget.userId);
      await s3Service.permanentlyDeleteItem(jarId, itemUrl, collaborators);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item permanently deleted')),
      );

      // Refresh the list
      _loadTrashedItems();
    } catch (e) {
      print('Error permanently deleting item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to permanently delete item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Trash', style: TextStyle(color: AppColors.fonts)),
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
        actions: [
          // Add empty trash button if there are items
          if (_trashedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: AppColors.fonts),
              onPressed: () {
                // Show confirmation dialog for emptying trash
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Empty Trash'),
                    content: const Text(
                      'This will permanently delete all items in trash. This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          // Implement empty trash functionality
                          for (final item in _trashedItems) {
                            await _permanentlyDeleteItem(
                              item['jarId'],
                              item['item'].url,
                              [], // Empty collaborators list since we're just deleting for this user
                            );
                          }
                        },
                        child: const Text('Empty Trash'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Empty Trash',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trashedItems.isEmpty
              ? const Center(
                  child: Text(
                    'No items in trash',
                    style: TextStyle(fontSize: 18, color: AppColors.fonts),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trashedItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final item = _trashedItems[index];
                    final S3Item s3Item = item['item'];
                    final String jarId = item['jarId'];
                    final String jarName = item['jarName'];

                    // Format the deletion date
                    final deletionDate =
                        s3Item.uploadedAt.toString().substring(0, 10);

                    return Stack(
                      children: [
                        // Media display
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  contentPadding: EdgeInsets.zero,
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      s3Item.type == 'photo'
                                          ? Image.network(
                                              s3Item.url,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  height: 180,
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child: Icon(
                                                        Icons.broken_image,
                                                        size: 50),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              height: 180,
                                              color: Colors.grey[200],
                                              child: Center(
                                                child: Icon(
                                                  s3Item.type == 'video'
                                                      ? Icons.videocam
                                                      : Icons.insert_drive_file,
                                                  size: 50,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('From: $jarName'),
                                            Text('Deleted: $deletionDate'),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    _restoreItem(
                                                        jarId, s3Item.url);
                                                  },
                                                  child: const Text('Restore'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                            'Permanently Delete'),
                                                        content: const Text(
                                                          'This item will be permanently deleted. This action cannot be undone.',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context),
                                                            child: const Text(
                                                                'Cancel'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                              _permanentlyDeleteItem(
                                                                  jarId,
                                                                  s3Item.url,
                                                                  []);
                                                            },
                                                            child: const Text(
                                                                'Delete Forever'),
                                                            style: TextButton
                                                                .styleFrom(
                                                              foregroundColor:
                                                                  Colors.red,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                  child: const Text(
                                                      'Delete Forever'),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: AspectRatio(
                              aspectRatio: 1.0,
                              child: s3Item.type == 'photo'
                                  ? Image.network(
                                      s3Item.url,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: Icon(Icons.broken_image,
                                                size: 50),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Icon(
                                          s3Item.type == 'video'
                                              ? Icons.videocam
                                              : Icons.insert_drive_file,
                                          size: 50,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        // Actions overlay (partially transparent)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.restore,
                                      color: Colors.white, size: 18),
                                  onPressed: () =>
                                      _restoreItem(jarId, s3Item.url),
                                  tooltip: 'Restore',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever,
                                      color: Colors.white, size: 18),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Permanently Delete'),
                                        content: const Text(
                                          'This item will be permanently deleted. This action cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _permanentlyDeleteItem(
                                                  jarId, s3Item.url, []);
                                            },
                                            child: const Text('Delete Forever'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  tooltip: 'Delete Forever',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
