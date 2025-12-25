import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/saved_item.dart';
import '../services/saved_items_service.dart';
import 'package:intl/intl.dart';

class SavedItemsPage extends StatefulWidget {
  const SavedItemsPage({super.key});

  @override
  State<SavedItemsPage> createState() => _SavedItemsPageState();
}

class _SavedItemsPageState extends State<SavedItemsPage> {
  final SavedItemsService _service = SavedItemsService();
  List<SavedItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    final items = await _service.loadSavedItems();

    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _deleteItem(SavedItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.itemName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _service.deleteItem(item.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          _loadItems();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete item'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _editItem(SavedItem item) async {
    final nameController = TextEditingController(text: item.itemName);
    final priceController = TextEditingController(text: item.itemPrice.toStringAsFixed(2));

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Item Price',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text);

              if (name.isNotEmpty && price != null && price > 0) {
                Navigator.pop(context, {
                  'name': name,
                  'price': price,
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    priceController.dispose();

    if (result != null) {
      final newPrice = result['price'] as double;
      final newWorkTimeHours = newPrice / item.hourlyWage;

      final updatedItem = item.copyWith(
        itemName: result['name'] as String,
        itemPrice: newPrice,
        workTimeHours: newWorkTimeHours,
      );

      final success = await _service.updateItem(updatedItem);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          _loadItems();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update item'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  String _formatWorkTime(Map<String, dynamic> workTime) {
    final hours = workTime['hours'] as int;
    final minutes = workTime['minutes'] as int;

    if (hours == 0) {
      return '$minutes minute${minutes != 1 ? 's' : ''}';
    } else if (minutes == 0) {
      return '$hours hour${hours != 1 ? 's' : ''}';
    } else {
      return '$hours hour${hours != 1 ? 's' : ''} $minutes minute${minutes != 1 ? 's' : ''}';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${DateFormat.jm().format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat.jm().format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Items'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved items yet',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save items from the calculator to see them here',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final workTime = item.getWorkTime();

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.itemName,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${item.itemPrice.toStringAsFixed(2)}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: theme.colorScheme.primary,
                                  onPressed: () => _editItem(item),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () => _deleteItem(item),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 20,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Work time: ${_formatWorkTime(workTime)}',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  size: 20,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Hourly wage: \$${item.hourlyWage.toStringAsFixed(2)}/hr',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Saved: ${_formatDate(item.savedAt)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
