import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';
import '../services/local_store.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../widgets/add_item_sheet.dart';
import 'home_page.dart';
import 'alerts_page.dart';
import 'calendar_page.dart';
import 'inventory_page.dart';
import 'recipes_page.dart';
import 'item_detail_page.dart';
import 'profile_page.dart';
import 'tutorial_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _loading = true;
  String? _loadError;
  bool _showTutorial = false;
  UserProfile? _profile;
  List<FoodItem> _items = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      _profile = await LocalStore.loadProfile();
      _showTutorial = !((_profile?.tutorialCompleted ?? true) ||
          await LocalStore.hasCompletedTutorial());
      if (!_showTutorial && _profile != null) {
        _profile = UserProfile(
          name: _profile!.name,
          email: _profile!.email,
          tutorialCompleted: true,
        );
      }
      _items = await LocalStore.loadItems();
    } catch (_) {
      _loadError =
          'Unable to load your inventory. Check your connection and try again.';
    }
    if (mounted) setState(() => _loading = false);
    if (_loadError == null) {
      for (final item in _items) {
        try {
          await NotificationService.schedule(item);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Inventory loaded, but reminders could not be scheduled.')));
          }
          break;
        }
      }
    }
  }

  Future<void> _save() => LocalStore.saveItems(_items);

  Future<void> _scheduleAfterSave(FoodItem item) async {
    try {
      if (item.reminderDays.isNotEmpty &&
          !await NotificationService.requestPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Item saved. Enable notifications in Android settings to receive reminders.')));
        }
        return;
      }
      await NotificationService.schedule(item);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Item saved, but its reminders could not be scheduled.')));
      }
    }
  }

  Future<void> _syncPhoto(FoodItem item) async {
    try {
      final url = await StorageService.uploadItemPhoto(
          itemId: item.id, bytes: base64Decode(item.localPhoto!));
      final index = _items.indexWhere((current) => current.id == item.id);
      if (!mounted ||
          index < 0 ||
          _items[index].localPhoto != item.localPhoto) {
        return;
      }
      setState(() => _items[index] = _items[index].copyWith(photoUrl: url));
      await _save();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Photo saved on this device. Cloud photo backup is unavailable.')));
      }
    }
  }

  Future<void> _add() async {
    final item = await showModalBottomSheet<FoodItem>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const AddItemSheet());
    if (item != null) {
      final saved = item;
      setState(() => _items.add(saved));
      await _save();
      await _scheduleAfterSave(saved);
      if (saved.localPhoto != null) _syncPhoto(saved);
    }
  }

  Future<void> _edit(FoodItem item) async {
    final updated = await showModalBottomSheet<FoodItem>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => AddItemSheet(item: item));
    if (updated != null) {
      final saved = updated;
      setState(() => _items[_items.indexWhere((e) => e.id == item.id)] = saved);
      await _save();
      await _scheduleAfterSave(saved);
      if (saved.localPhoto != null) _syncPhoto(saved);
    }
  }

  Future<void> _delete(FoodItem item) async {
    setState(() => _items.removeWhere((e) => e.id == item.id));
    await _save();
    await NotificationService.cancel(item);
    if (item.photoUrl != null) await StorageService.deleteItemPhoto(item.id);
  }

  Future<void> _quantity(FoodItem item, int diff) async {
    final i = _items.indexWhere((e) => e.id == item.id);
    setState(() => _items[i] =
        item.copyWith(quantity: (item.quantity + diff).clamp(0, 999)));
    await _save();
    await NotificationService.schedule(_items[i]);
  }

  void _detail(FoodItem item) => Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (_) => StatefulBuilder(
              builder: (context, refresh) => ItemDetailPage(
                  item: _items.firstWhere((current) => current.id == item.id,
                      orElse: () => item),
                  onEdit: () async {
                    final current = _items.firstWhere(
                        (current) => current.id == item.id,
                        orElse: () => item);
                    await _edit(current);
                    if (context.mounted) refresh(() {});
                  }))));
  @override
  Widget build(BuildContext context) {
    if (!_loading && _loadError == null && _showTutorial) {
      return TutorialPage(onComplete: () async {
        if (mounted) {
          setState(() {
            _showTutorial = false;
            if (_profile != null) {
              _profile = UserProfile(
                name: _profile!.name,
                email: _profile!.email,
                tutorialCompleted: true,
              );
            }
          });
        }
        try {
          await LocalStore.completeTutorial();
        } catch (_) {
          // Saving progress must never prevent entry into the app.
        }
      });
    }
    final pages = [
      HomePage(
          name: _profile?.name ?? 'there',
          items: _items,
          onInventory: () => setState(() => _index = 3),
          onAdd: _add,
          onDetail: _detail,
          onSettings: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProfilePage(
                      profile: _profile,
                      onSaved: (p) => setState(() => _profile = p))))),
      AlertsPage(items: _items, onDetail: _detail),
      CalendarPage(items: _items, onDetail: _detail),
      InventoryPage(
          items: _items,
          onAdd: _add,
          onEdit: _edit,
          onDelete: _delete,
          onQuantity: _quantity),
      RecipesPage(items: _items),
    ];
    return Scaffold(
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_loadError!),
                          TextButton(
                              onPressed: _load, child: const Text('Retry')),
                        ])))
                : IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications),
                  label: 'Alerts'),
              NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'Calendar'),
              NavigationDestination(
                  icon: Icon(Icons.kitchen_outlined),
                  selectedIcon: Icon(Icons.kitchen),
                  label: 'Inventory'),
              NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Recipes')
            ]));
  }
}
