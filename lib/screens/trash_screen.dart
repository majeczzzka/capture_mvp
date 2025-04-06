import 'package:flutter/material.dart';
import 'package:capture_mvp/models/s3_item.dart';
import 'package:capture_mvp/utils/app_colors.dart';
import 'package:capture_mvp/widgets/nav/bottom_nav_bar.dart';
import 'package:capture_mvp/widgets/trash/trash_item.dart';
import 'package:capture_mvp/repositories/storage_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// TrashScreen displays items that the user has deleted but can be restored.
class TrashScreen extends StatefulWidget {
  final String userId;

  const TrashScreen({super.key, required this.userId});

  @override
  _TrashScreenState createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  late StorageRepository _repository;
  List<Map<String, dynamic>> _trashedItems = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _repository = StorageRepository(userId: widget.userId);
    _loadTrashedItems();
  }

  Future<void> _loadTrashedItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print("🔍 DEBUG: Starting to load trashed items");

      // Get all deleted items using the repository
      final List<Map<String, dynamic>> allTrashedItems =
          await _repository.getAllDeletedItems();

      print("📊 DEBUG: Total items in trash: ${allTrashedItems.length}");

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
      print('❌ ERROR loading trashed items: $e');
      setState(() {
        _errorMessage = 'Failed to load trashed items: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreItem(Map<String, dynamic> item) async {
    final S3Item s3Item = item['item'];
    final String jarId = item['jarId'];
    final bool isArchived = item['isArchived'] ?? false;

    // Don't try to restore archived items
    if (isArchived) {
      print("ℹ️ Cannot restore item from archived jar: $jarId");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Items from jars you\'ve left cannot be restored.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    try {
      // For active jars, restore the specific item that was deleted
      await _repository.restoreArchivedItem(jarId, s3Item.url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item restored successfully')),
      );

      // Refresh the list
      await _loadTrashedItems();
    } catch (e) {
      print('Error restoring item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to restore item: ${e.toString()}')),
      );
    }
  }

  Future<void> _permanentlyDeleteItem(
      String jarId, String itemUrl, bool isArchived) async {
    try {
      if (isArchived) {
        // For archived items, delete from archived_jars collection
        await _repository.deleteArchivedJarItem(jarId, itemUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Item permanently deleted from archive')),
        );

        // Refresh the list
        await _loadTrashedItems();
      } else {
        // For regular deleted items, permanently delete them
        await _repository.permanentlyDeleteItem(jarId, itemUrl);
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

  void _showItemDetails(Map<String, dynamic> item) {
    final S3Item s3Item = item['item'];
    final String jarName = item['jarName'];
    final bool isArchived = item['isArchived'] ?? false;

    showDialog(
      context: context,
      builder: (context) => TrashItemDetailsDialog(
        item: s3Item,
        jarName: jarName,
        isArchived: isArchived,
        onRestore: () {
          Navigator.of(context).pop();
          _restoreItem(item);
        },
        onDelete: () {
          Navigator.of(context).pop();
          _confirmDelete(item);
        },
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    final bool isArchived = item['isArchived'] ?? false;
    final String messageText = isArchived
        ? 'This item will be permanently deleted from your trash. This action cannot be undone.'
        : 'This item will be permanently deleted. This action cannot be undone.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete'),
        content: Text(messageText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _permanentlyDeleteItem(
                item['jarId'],
                item['item'].url,
                isArchived,
              );
            },
            child: const Text('Delete Forever'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyTrash() {
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
                  isArchived,
                );
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trash emptied successfully')),
              );
            },
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
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
          // Empty trash button
          if (_trashedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: AppColors.fonts),
              onPressed: _confirmEmptyTrash,
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

          // Error message if any
          if (_errorMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.red.shade100,
              child: Text(
                _errorMessage,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
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
                          return TrashItem(
                            item: item['item'],
                            jarId: item['jarId'],
                            jarName: item['jarName'],
                            isArchived: item['isArchived'] ?? false,
                            onTap: () => _showItemDetails(item),
                            onRestore: () => _restoreItem(item),
                            onDelete: () => _confirmDelete(item),
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
