import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_item.dart';

class SavedItemsService {
  static const String _storageKey = 'saved_items';

  Future<List<SavedItem>> loadSavedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => SavedItem.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveItem(SavedItem item) async {
    try {
      final items = await loadSavedItems();
      items.add(item);
      return await _saveItemsToStorage(items);
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateItem(SavedItem updatedItem) async {
    try {
      final items = await loadSavedItems();
      final index = items.indexWhere((item) => item.id == updatedItem.id);

      if (index == -1) {
        return false;
      }

      items[index] = updatedItem;
      return await _saveItemsToStorage(items);
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      final items = await loadSavedItems();
      items.removeWhere((item) => item.id == id);
      return await _saveItemsToStorage(items);
    } catch (e) {
      return false;
    }
  }

  Future<bool> _saveItemsToStorage(List<SavedItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((item) => item.toJson()).toList();
      final jsonString = json.encode(jsonList);
      return await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      return false;
    }
  }
}
