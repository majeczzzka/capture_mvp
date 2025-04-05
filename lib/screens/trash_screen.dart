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
      print("🔍 DEBUG: Starting to load trashed items");
      final s3Service = S3Service(userId: widget.userId);
      final List<Map<String, dynamic>> allTrashedItems = [];

      // 1. Fetch deleted items from active jars
      print("📂 DEBUG: Fetching jars for user: ${widget.userId}");
      final jarsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('jars')
          .get();

      print("📊 DEBUG: Found ${jarsSnapshot.docs.length} active jars");

      for (final jarDoc in jarsSnapshot.docs) {
        final String jarId = jarDoc.id;
        final String jarName = jarDoc.data()['name'] ?? 'Unnamed Jar';

        print("🏺 DEBUG: Processing jar: $jarName (ID: $jarId)");

        final List<S3Item> deletedItems =
            await s3Service.getDeletedJarContents(jarId);

        print(
            "🗑️ DEBUG: Found ${deletedItems.length} deleted items in jar: $jarName");

        for (final item in deletedItems) {
          allTrashedItems.add({
            'item': item,
            'jarId': jarId,
            'jarName': jarName,
            'isArchived': false,
          });
        }
      }

      // 2. Fetch content from archived jars
      print("📦 DEBUG: Fetching archived jar content");
      final List<Map<String, dynamic>> archivedContent =
          await s3Service.getArchivedContent();
      print("📦 DEBUG: Found ${archivedContent.length} items in archived jars");

      allTrashedItems.addAll(archivedContent);

      // 3. Sort by deletion date (newest first)
      allTrashedItems.sort((a, b) {
        final S3Item itemA = a['item'];
        final S3Item itemB = b['item'];
        return itemB.uploadedAt.compareTo(itemA.uploadedAt);
      });

      print("📊 DEBUG: Total items in trash: ${allTrashedItems.length}");

      setState(() {
        _trashedItems = allTrashedItems;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ ERROR loading trashed items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreItem(Map<String, dynamic> item) async {
    try {
      final s3Service = S3Service(userId: widget.userId);
      final String jarId = item['jarId'];
      final S3Item s3Item = item['item'];
      final bool isArchived = item['isArchived'] ?? false;

      if (isArchived) {
        // For archived jars (when a user has left a jar), restoration is not allowed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Items from jars you\'ve left cannot be restored. These items will be automatically deleted after 90 days.',
              style: TextStyle(color: Colors.white),
            ),
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        // For active jars, restore the specific item that was deleted
        await s3Service.restoreArchivedItem(jarId, s3Item.url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item restored successfully')),
        );

        // Refresh the list
        await _loadTrashedItems();
      }
    } catch (e) {
      print('Error restoring item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to restore item: ${e.toString()}')),
      );
    }
  }

  Future<void> _permanentlyDeleteItem(String jarId, String itemUrl,
      List<String> collaborators, bool isArchived) async {
    try {
      final s3Service = S3Service(userId: widget.userId);

      if (isArchived) {
        // For archived items, we'll still delete them from the archived_jars collection
        // Get the archived jar document
        final archivedJarRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('archived_jars')
            .doc(jarId);

        final archivedJarDoc = await archivedJarRef.get();
        if (archivedJarDoc.exists) {
          // Get the current content
          final jarData = archivedJarDoc.data();
          if (jarData != null && jarData.containsKey('content')) {
            List<dynamic> contentList = List.from(jarData['content'] ?? []);

            // Remove the specific item that matches the URL
            contentList.removeWhere((item) =>
                item is Map &&
                item.containsKey('data') &&
                item['data'] == itemUrl);

            // Update the jar document with the modified content list
            await archivedJarRef.update({'content': contentList});

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Item permanently deleted from archive')),
            );

            // Refresh the list
            await _loadTrashedItems();
          }
        }
      } else {
        // For regular deleted items, permanently delete them
        await s3Service.permanentlyDeleteItem(jarId, itemUrl, collaborators);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item permanently deleted')),
        );

        // Refresh the list
        await _loadTrashedItems();
      }
    } catch (e) {
      print('Error permanently deleting item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to permanently delete item: ${e.toString()}')),
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
          // Only keep the empty trash button
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
                      'This will permanently delete all restorable items in trash. Non-restorable items from left jars will also be removed from view.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          // Implement empty trash functionality for all items
                          for (final item in _trashedItems) {
                            final bool isArchived = item['isArchived'] ?? false;
                            await _permanentlyDeleteItem(
                              item['jarId'],
                              item['item'].url,
                              [], // Empty collaborators list since we're just deleting for this user
                              isArchived,
                            );
                          }

                          // Show message about what was done
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Trash emptied successfully')),
                          );
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
      body: Column(
        children: [
          // Info text about 90-day auto-deletion
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.amber.shade100,
            child: const Text(
              'Items from jars you\'ve left will be automatically deleted after 90 days',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Main content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _trashedItems.isEmpty
                    ? const Center(
                        child: Text(
                          'No items in trash',
                          style:
                              TextStyle(fontSize: 18, color: AppColors.fonts),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _trashedItems.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                          final bool isArchived = item['isArchived'] ?? false;

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
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      print(
                                                          'Error loading image in dialog: $error');
                                                      return Container(
                                                        height: 180,
                                                        color: Colors.grey[300],
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                                Icons
                                                                    .broken_image,
                                                                size: 50,
                                                                color: Colors
                                                                    .grey[600]),
                                                            const SizedBox(
                                                                height: 8),
                                                            Text(
                                                              'Image unavailable\n(access expired)',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .grey[600],
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                    // Add a loading placeholder
                                                    loadingBuilder: (context,
                                                        child,
                                                        loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) return child;
                                                      return Container(
                                                        height: 180,
                                                        color: Colors.grey[200],
                                                        child: Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            value: loadingProgress
                                                                        .expectedTotalBytes !=
                                                                    null
                                                                ? loadingProgress
                                                                        .cumulativeBytesLoaded /
                                                                    loadingProgress
                                                                        .expectedTotalBytes!
                                                                : null,
                                                            strokeWidth: 2,
                                                          ),
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
                                                            : Icons
                                                                .insert_drive_file,
                                                        size: 50,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text('From: $jarName'),
                                                  Text(
                                                      'Deleted: $deletionDate'),
                                                  if (isArchived)
                                                    const Text(
                                                        'Status: From jar you\'ve left (cannot be restored)',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        )),
                                                  const SizedBox(height: 16),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                          _restoreItem(item);
                                                        },
                                                        child: Text(isArchived
                                                            ? 'View Only'
                                                            : 'Restore Item'),
                                                        style: TextButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              isArchived
                                                                  ? Colors.grey
                                                                  : Colors.blue,
                                                          textStyle:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                          // Show confirmation dialog for all items
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (context) =>
                                                                    AlertDialog(
                                                              title: const Text(
                                                                  'Permanently Delete'),
                                                              content: Text(
                                                                isArchived
                                                                    ? 'This item will be permanently deleted from your trash. This action cannot be undone.'
                                                                    : 'This item will be permanently deleted. This action cannot be undone.',
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
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.pop(
                                                                        context);
                                                                    _permanentlyDeleteItem(
                                                                        jarId,
                                                                        s3Item
                                                                            .url,
                                                                        [],
                                                                        isArchived);
                                                                  },
                                                                  child: const Text(
                                                                      'Delete Forever'),
                                                                  style: TextButton
                                                                      .styleFrom(
                                                                    foregroundColor:
                                                                        Colors
                                                                            .red,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                        child: Text(
                                                          'Delete Forever',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
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
                                              print(
                                                  'Error loading image: $error');
                                              return Container(
                                                color: Colors.grey[300],
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.broken_image,
                                                        size: 40,
                                                        color:
                                                            Colors.grey[600]),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Image unavailable',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            // Add a loading placeholder
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Container(
                                                color: Colors.grey[200],
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                                    strokeWidth: 2,
                                                  ),
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

                              // Archived indicator
                              if (isArchived)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade700,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'Non-Restorable',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.restore,
                                            color: Colors.white, size: 18),
                                        onPressed: () => _restoreItem(item),
                                        tooltip: isArchived
                                            ? 'Cannot Restore'
                                            : 'Restore Item',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_forever,
                                            color: Colors.white, size: 18),
                                        onPressed: () {
                                          // Show confirmation dialog for all items now
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                  'Permanently Delete'),
                                              content: Text(
                                                isArchived
                                                    ? 'This item will be permanently deleted from your trash. This action cannot be undone.'
                                                    : 'This item will be permanently deleted. This action cannot be undone.',
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
                                                        item['jarId'],
                                                        item['item'].url,
                                                        [],
                                                        isArchived);
                                                  },
                                                  child: const Text(
                                                      'Delete Forever'),
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
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
