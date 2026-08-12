import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const ExpirationDateTrackerApp());

class ExpirationDateTrackerApp extends StatelessWidget {
  const ExpirationDateTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B7A75),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAF9),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 90,
                height: 90,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF4EF),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.eco_rounded, color: Color(0xFF08756E), size: 48),
              ),
              const SizedBox(height: 28),
              Text('Welcome to FreshTrack', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text('Keep your food fresh and stop waste before it happens.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
              const SizedBox(height: 36),
              TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: const Icon(Icons.mail_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell())),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Log in'),
              ),
              TextButton(onPressed: () {}, child: const Text('Create an account')),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _loading = true;
  List<FoodItem> _items = [
    FoodItem('Greek yogurt', 'Dairy', DateTime.now().add(const Duration(days: 2)), Icons.icecream_outlined),
    FoodItem('Baby spinach', 'Produce', DateTime.now().add(const Duration(days: 3)), Icons.eco_outlined),
    FoodItem('Whole milk', 'Dairy', DateTime.now().add(const Duration(days: 6)), Icons.local_drink_outlined),
    FoodItem('Eggs', 'Dairy', DateTime.now().add(const Duration(days: 11)), Icons.egg_alt_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString('inventory');
    if (saved != null) {
      final decoded = (jsonDecode(saved) as List).cast<Map<String, dynamic>>();
      _items = decoded.map(FoodItem.fromJson).toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveItems() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('inventory', jsonEncode(_items.map((item) => item.toJson()).toList()));
  }

  void _addItem() async {
    final item = await showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddItemSheet(),
    );
    if (item != null) {
      setState(() => _items.add(item));
      _saveItems();
    }
  }

  Future<void> _editItem(FoodItem item) async {
    final updated = await showModalBottomSheet<FoodItem>(context: context, isScrollControlled: true, builder: (_) => AddItemSheet(item: item));
    if (updated != null) {
      setState(() => _items[_items.indexWhere((entry) => entry.id == item.id)] = updated);
      _saveItems();
    }
  }

  void _deleteItem(FoodItem item) {
    setState(() => _items.removeWhere((entry) => entry.id == item.id));
    _saveItems();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.name} removed')));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(items: _items, onInventory: () => setState(() => _index = 3), onAdd: _addItem),
      NotificationsPage(items: _items),
      CalendarPage(items: _items),
      InventoryPage(items: _items, onAdd: _addItem, onEdit: _editItem, onDelete: _deleteItem),
    ];
    return Scaffold(
      body: _loading ? const Center(child: CircularProgressIndicator()) : IndexedStack(index: _index, children: pages),
      floatingActionButton: _index == 3 ? FloatingActionButton(onPressed: _addItem, child: const Icon(Icons.add)) : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.kitchen_outlined), selectedIcon: Icon(Icons.kitchen), label: 'Inventory'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.items, required this.onInventory, required this.onAdd});
  final List<FoodItem> items;
  final VoidCallback onInventory;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final urgent = items.where((item) => item.daysLeft <= 3).toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Row(children: [
            const CircleAvatar(radius: 24, backgroundColor: Color(0xFFDDF4EF), child: Icon(Icons.person_outline, color: Color(0xFF08756E))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Good morning, Anita', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const Text('Let’s keep things fresh.')])) ,
            IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
          ]),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF08756E), borderRadius: BorderRadius.circular(24)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your freshness score', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              const Text('86%', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('${urgent.length} items need attention this week', style: const TextStyle(color: Colors.white)),
            ]),
          ),
          const SizedBox(height: 26),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Expiring soon', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), TextButton(onPressed: onInventory, child: const Text('View all'))]),
          ...urgent.map((item) => FoodCard(item: item)),
          const SizedBox(height: 16),
          Text('Quick actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: QuickAction(icon: Icons.add_box_outlined, label: 'Add item', onTap: onAdd)), const SizedBox(width: 12), Expanded(child: QuickAction(icon: Icons.kitchen_outlined, label: 'Inventory', onTap: onInventory))]),
        ],
      ),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key, required this.items});
  final List<FoodItem> items;

  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
    Text('Notifications', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
    const SizedBox(height: 6), const Text('Stay ahead of food expiration dates.'), const SizedBox(height: 20),
    ...items.where((item) => item.daysLeft <= 6).map((item) => Card(child: ListTile(
      leading: CircleAvatar(backgroundColor: item.daysLeft <= 3 ? const Color(0xFFFFE5E2) : const Color(0xFFFFF2D6), child: Icon(item.daysLeft <= 3 ? Icons.priority_high : Icons.schedule, color: item.daysLeft <= 3 ? Colors.red : Colors.orange)),
      title: Text('${item.name} expires ${item.daysLeft <= 0 ? 'today' : 'in ${item.daysLeft} days'}'), subtitle: Text('Use it soon or plan it into a meal.'), trailing: const Icon(Icons.chevron_right),
    ))),
  ]));
}

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key, required this.items});
  final List<FoodItem> items;

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]..sort((a, b) => a.expiry.compareTo(b.expiry));
    return SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      Text('Calendar', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 18),
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(children: [
        Text('EXPIRING THIS MONTH', style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 1)), const SizedBox(height: 12),
        Text('${DateTime.now().month}/${DateTime.now().year}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 14), const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text('S'), Text('M'), Text('T'), Text('W'), Text('T'), Text('F'), Text('S')]),
      ])),
      const SizedBox(height: 24), Text('Upcoming dates', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      ...sorted.map((item) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 4), leading: Container(width: 44, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFDDF4EF), borderRadius: BorderRadius.circular(12)), child: Text('${item.expiry.day}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF08756E)))), title: Text(item.name), subtitle: Text('${_monthName(item.expiry.month)} ${item.expiry.day}, ${item.expiry.year}'), trailing: Text('${item.daysLeft}d'))),
    ]));
  }
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key, required this.items, required this.onAdd, required this.onEdit, required this.onDelete});
  final List<FoodItem> items;
  final VoidCallback onAdd;
  final ValueChanged<FoodItem> onEdit;
  final ValueChanged<FoodItem> onDelete;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...{for (final item in widget.items) item.category}];
    final visible = widget.items.where((item) => (_category == 'All' || item.category == _category) && item.name.toLowerCase().contains(_query.toLowerCase())).toList()..sort((a, b) => a.expiry.compareTo(b.expiry));
    return SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('My inventory', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), IconButton(onPressed: widget.onAdd, icon: const Icon(Icons.add_circle_outline))]),
    const SizedBox(height: 12),
    TextField(onChanged: (value) => setState(() => _query = value), decoration: InputDecoration(hintText: 'Search items', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
    const SizedBox(height: 12),
    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: categories.map((category) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(category), selected: _category == category, onSelected: (_) => setState(() => _category = category)))).toList())),
    const SizedBox(height: 18),
    if (visible.isEmpty) const Padding(padding: EdgeInsets.all(36), child: Center(child: Text('No matching items. Add something to track it.'))),
    ...visible.map((item) => FoodCard(item: item, showCategory: true, onEdit: () => widget.onEdit(item), onDelete: () => widget.onDelete(item))),
  ]));
  }
}

class FoodCard extends StatelessWidget {
  const FoodCard({super.key, required this.item, this.showCategory = false, this.onEdit, this.onDelete});
  final FoodItem item;
  final bool showCategory;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    leading: CircleAvatar(backgroundColor: const Color(0xFFDDF4EF), child: Icon(item.icon, color: const Color(0xFF08756E))),
    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(showCategory ? item.category : 'Expires ${_monthName(item.expiry.month)} ${item.expiry.day}'),
    onTap: onEdit,
    onLongPress: onDelete,
    trailing: onEdit == null ? Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(item.daysLeft <= 0 ? 'Today' : '${item.daysLeft} days', style: TextStyle(fontWeight: FontWeight.bold, color: item.daysLeft <= 3 ? Colors.red : const Color(0xFF08756E))), if (showCategory) Text('Expires ${item.expiry.month}/${item.expiry.day}', style: const TextStyle(fontSize: 11))]) : PopupMenuButton<String>(onSelected: (choice) => choice == 'edit' ? onEdit!() : onDelete!(), itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))]),
  ));
}

class QuickAction extends StatelessWidget {
  const QuickAction({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(children: [Icon(icon, color: const Color(0xFF08756E)), const SizedBox(height: 8), Text(label)])));
}

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key, this.item});
  final FoodItem? item;

  @override State<AddItemSheet> createState() => _AddItemSheetState();
}
class _AddItemSheetState extends State<AddItemSheet> {
  late final TextEditingController _name;
  late DateTime _date;
  late String _category;
  @override void initState() { super.initState(); _name = TextEditingController(text: widget.item?.name ?? ''); _date = widget.item?.expiry ?? DateTime.now().add(const Duration(days: 7)); _category = widget.item?.category ?? 'Other'; }
  @override void dispose() { _name.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + MediaQuery.of(context).viewInsets.bottom), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text('Add an item', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 16),
    TextField(controller: _name, autofocus: true, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Item name', border: OutlineInputBorder())), const SizedBox(height: 12),
    DropdownButtonFormField<String>(initialValue: _category, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()), items: const ['Produce', 'Dairy', 'Meat', 'Pantry', 'Frozen', 'Beverages', 'Other'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) => setState(() => _category = value!)), const SizedBox(height: 12),
    OutlinedButton.icon(onPressed: () async { final date = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 3650))); if (date != null) setState(() => _date = date); }, icon: const Icon(Icons.calendar_today), label: Text('Expires ${_monthName(_date.month)} ${_date.day}, ${_date.year}')), const SizedBox(height: 12),
    FilledButton(onPressed: () { if (_name.text.trim().isNotEmpty) Navigator.pop(context, FoodItem(_name.text.trim(), _category, _date, _iconForCategory(_category), id: widget.item?.id)); }, child: Text(widget.item == null ? 'Save item' : 'Save changes')),
  ]));
}

class FoodItem {
  FoodItem(this.name, this.category, this.expiry, this.icon, {String? id}) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();
  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(json['name'] as String, json['category'] as String, DateTime.parse(json['expiry'] as String), _iconForCategory(json['category'] as String), id: json['id'] as String);
  final String name, category; final DateTime expiry; final IconData icon;
  final String id;
  int get daysLeft => DateUtils.dateOnly(expiry).difference(DateUtils.dateOnly(DateTime.now())).inDays;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'category': category, 'expiry': expiry.toIso8601String()};
}
String _monthName(int month) => const ['January','February','March','April','May','June','July','August','September','October','November','December'][month - 1];
IconData _iconForCategory(String category) => switch (category) { 'Produce' => Icons.eco_outlined, 'Dairy' => Icons.icecream_outlined, 'Meat' => Icons.restaurant_outlined, 'Frozen' => Icons.ac_unit, 'Beverages' => Icons.local_drink_outlined, 'Pantry' => Icons.inventory_2_outlined, _ => Icons.kitchen_outlined };
