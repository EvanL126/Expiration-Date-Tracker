import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'models/food_item.dart';
import 'models/user_profile.dart';
import 'services/local_store.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'recipes_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();
  runApp(const ExpirationDateTrackerApp());
}

class ExpirationDateTrackerApp extends StatelessWidget {
  const ExpirationDateTrackerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'FreshTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF08756E)),
          scaffoldBackgroundColor: const Color(0xFFF7FAF9),
          inputDecorationTheme: InputDecorationTheme(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
      home: const AuthenticationGate());
}

class AuthenticationGate extends StatelessWidget {
  const AuthenticationGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.hasData ? const AppShell() : const LoginPage();
      });
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController(), _password = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _busy = true);
    final ok = await LocalStore.authenticate(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AppShell()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Enter the email and password used to create your account.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 56),
                          child: IntrinsicHeight(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                const Spacer(),
                                Center(
                                    child: Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFDDF4EF),
                                            borderRadius:
                                                BorderRadius.circular(28)),
                                        child: const Icon(Icons.eco_rounded,
                                            color: Color(0xFF08756E),
                                            size: 48))),
                                const SizedBox(height: 28),
                                Text('Welcome to FreshTrack',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w800)),
                                const SizedBox(height: 10),
                                Text(
                                    'Keep your food fresh and stop waste before it happens.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(color: Colors.black54)),
                                const SizedBox(height: 32),
                                TextField(
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                        labelText: 'Email address',
                                        prefixIcon: Icon(Icons.mail_outline))),
                                const SizedBox(height: 14),
                                TextField(
                                    controller: _password,
                                    obscureText: true,
                                    onSubmitted: (_) => _login(),
                                    decoration: const InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: Icon(Icons.lock_outline))),
                                const SizedBox(height: 24),
                                FilledButton(
                                    onPressed: _busy ? null : _login,
                                    style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16)),
                                    child:
                                        Text(_busy ? 'Logging in…' : 'Log in')),
                                TextButton(
                                    onPressed: () async {
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const CreateAccountPage()));
                                      if (mounted) setState(() {});
                                    },
                                    child: const Text('Create an account')),
                                const Spacer(),
                              ]))),
                    ))),
      );
}

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key, this.register});
  final Future<void> Function(UserProfile, String)? register;
  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _form = GlobalKey<FormState>(),
      _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController(),
      _confirmPassword = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await (widget.register ?? LocalStore.register)(
          UserProfile(name: _name.text.trim(), email: _email.text.trim()),
          _password.text);
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() => _error = switch (error.code) {
              'email-already-in-use' =>
                'An account already uses this email. Go back and log in.',
              'invalid-email' => 'Enter a valid email address.',
              'weak-password' =>
                'Choose a stronger password with at least 6 characters.',
              'operation-not-allowed' =>
                'Email/password sign-up is disabled. Enable it in Firebase Authentication.',
              'invalid-api-key' ||
              'api-key-not-valid' =>
                'The Firebase API key is invalid. Update the app’s Firebase configuration.',
              'network-request-failed' =>
                'Unable to connect. Check your internet connection and try again.',
              'too-many-requests' =>
                'Too many attempts. Please try again later.',
              'profile-setup-failed' =>
                'Your account was created, but your profile could not be saved. Go back and log in. If this continues, check the Firebase database setup.',
              _ =>
                'Unable to create account (${error.code}). Please try again.',
            });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to create account. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                  key: _form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Start wasting less today.',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        TextFormField(
                            controller: _name,
                            enabled: !_busy,
                            decoration: const InputDecoration(
                                labelText: 'Your name',
                                prefixIcon: Icon(Icons.person_outline)),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Please enter your name'
                                : null),
                        const SizedBox(height: 14),
                        TextFormField(
                            controller: _email,
                            enabled: !_busy,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icon(Icons.mail_outline)),
                            validator: (v) => v == null ||
                                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                        .hasMatch(v.trim())
                                ? 'Enter a valid email'
                                : null),
                        const SizedBox(height: 14),
                        TextFormField(
                            controller: _password,
                            enabled: !_busy,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline)),
                            validator: (v) => v == null || v.length < 6
                                ? 'Use at least 6 characters'
                                : null),
                        const SizedBox(height: 14),
                        TextFormField(
                            controller: _confirmPassword,
                            enabled: !_busy,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _create(),
                            decoration: const InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon: Icon(Icons.lock_outline)),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Please confirm your password'
                                : v != _password.text
                                    ? 'Passwords do not match'
                                    : null),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Semantics(
                              liveRegion: true,
                              child: Text(_error!,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error))),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: _busy ? null : _create,
                            style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16)),
                            child: Text(
                                _busy ? 'Creating account…' : 'Create account'))
                      ])))));
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _loading = true;
  String? _loadError;
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
  Future<FoodItem> _uploadPendingPhoto(FoodItem item) async {
    final path = item.localImagePath;
    if (path == null) return item;
    final url = await StorageService.uploadItemPhoto(
        itemId: item.id, image: File(path));
    return item.copyWith(photoUrl: url, localImagePath: '');
  }

  Future<void> _add() async {
    final item = await showModalBottomSheet<FoodItem>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const AddItemSheet());
    if (item != null) {
      final saved = await _uploadPendingPhoto(item);
      setState(() => _items.add(saved));
      await _save();
      await NotificationService.schedule(saved);
    }
  }

  Future<void> _edit(FoodItem item) async {
    final updated = await showModalBottomSheet<FoodItem>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => AddItemSheet(item: item));
    if (updated != null) {
      final saved = await _uploadPendingPhoto(updated);
      setState(() => _items[_items.indexWhere((e) => e.id == item.id)] = saved);
      await _save();
      await NotificationService.schedule(saved);
    }
  }

  Future<void> _delete(FoodItem item) async {
    setState(() => _items.removeWhere((e) => e.id == item.id));
    await _save();
    await StorageService.deleteItemPhoto(item.id);
    await NotificationService.cancel(item);
  }

  void _quantity(FoodItem item, int diff) {
    final i = _items.indexWhere((e) => e.id == item.id);
    setState(() => _items[i] =
        item.copyWith(quantity: (item.quantity + diff).clamp(0, 999)));
    _save();
  }

  void _detail(FoodItem item) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              ItemDetailPage(item: item, onEdit: () => _edit(item))));
  @override
  Widget build(BuildContext context) {
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
        floatingActionButton: _index == 3 && !_loading && _loadError == null
            ? FloatingActionButton(
                onPressed: _add, child: const Icon(Icons.add))
            : null,
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

class HomePage extends StatelessWidget {
  const HomePage(
      {super.key,
      required this.name,
      required this.items,
      required this.onInventory,
      required this.onAdd,
      required this.onDetail,
      required this.onSettings});
  final String name;
  final List<FoodItem> items;
  final VoidCallback onInventory, onAdd, onSettings;
  final ValueChanged<FoodItem> onDetail;
  @override
  Widget build(BuildContext context) {
    final stocked = items.where((i) => i.quantity > 0).toList();
    final urgent = stocked.where((i) => i.daysLeft <= 3).toList()
      ..sort((a, b) => a.expiry.compareTo(b.expiry));
    final score = stocked.isEmpty
        ? null
        : (100 * stocked.where((i) => i.daysLeft > 3).length / stocked.length)
            .round();
    return SafeArea(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
          Row(children: [
            const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFDDF4EF),
                child: Icon(Icons.person_outline, color: Color(0xFF08756E))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Good morning, $name',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const Text('Let’s keep things fresh.')
                ])),
            IconButton(
                onPressed: onSettings,
                tooltip: 'Profile and settings',
                icon: const Icon(Icons.settings_outlined))
          ]),
          const SizedBox(height: 24),
          Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFF08756E),
                  borderRadius: BorderRadius.circular(24)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your freshness score',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(score == null ? '—' : '$score%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text(
                        'Share of stocked items fresh for more than 3 days',
                        style: TextStyle(color: Colors.white70)),
                    Text('${urgent.length} items need attention within 3 days',
                        style: const TextStyle(color: Colors.white))
                  ])),
          const SizedBox(height: 26),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Expiring soon',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(onPressed: onInventory, child: const Text('View all'))
          ]),
          if (urgent.isEmpty)
            const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nothing needs attention right now.')),
          ...urgent.map((i) => FoodCard(item: i, onTap: () => onDetail(i))),
          const SizedBox(height: 16),
          Text('Quick actions',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: QuickAction(
                    icon: Icons.add_box_outlined,
                    label: 'Add item',
                    onTap: onAdd)),
            const SizedBox(width: 12),
            Expanded(
                child: QuickAction(
                    icon: Icons.kitchen_outlined,
                    label: 'Inventory',
                    onTap: onInventory))
          ])
        ]));
  }
}

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key, required this.items, required this.onDetail});
  final List<FoodItem> items;
  final ValueChanged<FoodItem> onDetail;
  @override
  Widget build(BuildContext context) {
    final alerts = items
        .where((i) => i.quantity > 0 && i.daysLeft <= 7)
        .toList()
      ..sort((a, b) => a.expiry.compareTo(b.expiry));
    return SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
      Text('Alerts',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('Tap an alert for food guidance and recipe ideas.'),
      const SizedBox(height: 20),
      if (alerts.isEmpty)
        const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: Text('You are all caught up.'))),
      ...alerts.map((i) => Card(
          child: ListTile(
              onTap: () => onDetail(i),
              leading: CircleAvatar(
                  backgroundColor: i.daysLeft <= 3
                      ? const Color(0xFFFFE5E2)
                      : const Color(0xFFFFF2D6),
                  child: Icon(
                      i.daysLeft <= 3 ? Icons.priority_high : Icons.schedule)),
              title: Text('${i.name} • ${i.expiryLabel}'),
              subtitle: const Text('Use it soon or plan it into a meal.'),
              trailing: const Icon(Icons.chevron_right))))
    ]));
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.items, required this.onDetail});
  final List<FoodItem> items;
  final ValueChanged<FoodItem> onDetail;
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selected;
  void _move(int offset) => setState(() {
        _month = DateTime(_month.year, _month.month + offset);
        _selected = null;
      });
  @override
  Widget build(BuildContext context) {
    final items = widget.items
        .where((i) =>
            i.quantity > 0 &&
            i.expiry.year == _month.year &&
            i.expiry.month == _month.month &&
            (_selected == null || i.expiry.day == _selected!.day))
        .toList()
      ..sort((a, b) => a.expiry.compareTo(b.expiry));
    final offset = _month.weekday - 1;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    return SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
      Text('Calendar', style: Theme.of(context).textTheme.headlineSmall),
      Row(children: [
        IconButton(
            tooltip: 'Previous month',
            onPressed: () => _move(-1),
            icon: const Icon(Icons.chevron_left)),
        Expanded(
            child: Text('${monthName(_month.month)} ${_month.year}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium)),
        IconButton(
            tooltip: 'Next month',
            onPressed: () => _move(1),
            icon: const Icon(Icons.chevron_right)),
      ]),
      Row(children: [
        for (final day in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
          Expanded(child: Center(child: Text(day)))
      ]),
      const SizedBox(height: 8),
      GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisExtent: 60),
          itemCount: ((offset + days + 6) ~/ 7) * 7,
          itemBuilder: (context, index) {
            final day = index - offset + 1;
            if (day < 1 || day > days) return const SizedBox.shrink();
            final date = DateTime(_month.year, _month.month, day);
            final count = widget.items
                .where((i) =>
                    i.quantity > 0 && DateUtils.isSameDay(i.expiry, date))
                .length;
            return Semantics(
                button: true,
                selected: DateUtils.isSameDay(_selected, date),
                label:
                    '${monthName(date.month)} $day, ${date.year}, $count expirations',
                child: InkWell(
                    onTap: () => setState(() => _selected = date),
                    child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            color: DateUtils.isSameDay(_selected, date)
                                ? const Color(0xFFB2DFDB)
                                : const Color(0xFFF1F7F5),
                            borderRadius: BorderRadius.circular(8)),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('$day'),
                              if (count > 0)
                                const Icon(Icons.circle,
                                    size: 6, color: Color(0xFF08756E)),
                            ]))));
          }),
      const SizedBox(height: 16),
      Text(
          _selected == null
              ? 'Expirations this month'
              : 'Expirations on ${monthName(_selected!.month)} ${_selected!.day}',
          style: Theme.of(context).textTheme.titleLarge),
      if (_selected != null)
        TextButton(
            onPressed: () => setState(() => _selected = null),
            child: const Text('Show whole month')),
      if (items.isEmpty)
        const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No expirations for this period.')),
      ...items.map((i) => FoodCard(item: i, onTap: () => widget.onDetail(i))),
    ]));
  }
}

class InventoryPage extends StatefulWidget {
  const InventoryPage(
      {super.key,
      required this.items,
      required this.onAdd,
      required this.onEdit,
      required this.onDelete,
      required this.onQuantity});
  final List<FoodItem> items;
  final VoidCallback onAdd;
  final ValueChanged<FoodItem> onEdit, onDelete;
  final void Function(FoodItem, int) onQuantity;
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String _query = '', _category = 'All', _location = 'All locations';
  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      ...{for (final i in widget.items) i.category}
    ];
    final locations = [
      'All locations',
      ...{for (final i in widget.items) i.location}
    ];
    if (!categories.contains(_category)) _category = 'All';
    if (!locations.contains(_location)) _location = 'All locations';
    final visible = widget.items
        .where((i) =>
            (_category == 'All' || i.category == _category) &&
            (_location == 'All locations' || i.location == _location) &&
            i.name.toLowerCase().contains(_query.toLowerCase()))
        .toList()
      ..sort((a, b) => a.expiry.compareTo(b.expiry));
    return SafeArea(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
                child: Text('My inventory',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold))),
            IconButton(
                onPressed: widget.onAdd,
                icon: const Icon(Icons.add_circle_outline))
          ]),
          const SizedBox(height: 12),
          TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                  hintText: 'Search items',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderSide: BorderSide.none))),
          const SizedBox(height: 12),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: categories
                      .map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                              label: Text(c),
                              selected: _category == c,
                              onSelected: (_) =>
                                  setState(() => _category = c))))
                      .toList())),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
              key: ValueKey(_location),
              isExpanded: true,
              initialValue: _location,
              decoration: const InputDecoration(labelText: 'Storage location'),
              items: locations
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) => setState(() => _location = v!)),
          const SizedBox(height: 18),
          if (visible.isEmpty)
            const Padding(
                padding: EdgeInsets.all(36),
                child: Center(
                    child:
                        Text('No matching items. Add something to track it.'))),
          ...visible.map((i) => FoodCard(
              item: i,
              showControls: true,
              onTap: () => widget.onEdit(i),
              onDelete: () => widget.onDelete(i),
              onDecrease: () => widget.onQuantity(i, -1),
              onIncrease: () => widget.onQuantity(i, 1)))
        ]));
  }
}

class FoodCard extends StatelessWidget {
  const FoodCard(
      {super.key,
      required this.item,
      required this.onTap,
      this.showControls = false,
      this.onDelete,
      this.onDecrease,
      this.onIncrease});
  final FoodItem item;
  final VoidCallback onTap;
  final bool showControls;
  final VoidCallback? onDelete, onDecrease, onIncrease;
  @override
  Widget build(BuildContext context) => Card(
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                              backgroundColor: const Color(0xFFDDF4EF),
                              backgroundImage: item.photoUrl == null
                                  ? null
                                  : NetworkImage(item.photoUrl!),
                              child: item.photoUrl == null
                                  ? Icon(item.icon,
                                      color: const Color(0xFF08756E))
                                  : null),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Text('${item.category} • ${item.location}'),
                                Text(item.expiryLabel,
                                    style: TextStyle(
                                        color: item.daysLeft <= 3
                                            ? Colors.red
                                            : const Color(0xFF08756E))),
                              ])),
                          if (showControls)
                            PopupMenuButton<String>(
                                tooltip: 'Item actions',
                                onSelected: (v) =>
                                    v == 'delete' ? onDelete?.call() : onTap(),
                                itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 'edit', child: Text('Edit')),
                                      PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete')),
                                    ]),
                        ]),
                    if (showControls) ...[
                      const SizedBox(height: 10),
                      Text(item.quantityGuidance),
                      Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Quantity: '),
                            IconButton(
                                tooltip: 'Decrease quantity',
                                onPressed:
                                    item.quantity > 0 ? onDecrease : null,
                                icon: const Icon(Icons.remove_circle_outline)),
                            Text('${item.quantity}'),
                            IconButton(
                                tooltip: 'Increase quantity',
                                onPressed: onIncrease,
                                icon: const Icon(Icons.add_circle_outline)),
                          ]),
                    ],
                  ]))));
}

class QuickAction extends StatelessWidget {
  const QuickAction(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Icon(icon, color: const Color(0xFF08756E)),
            const SizedBox(height: 8),
            Text(label)
          ])));
}

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key, this.item});
  final FoodItem? item;
  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  late final TextEditingController _name;
  late DateTime _date;
  late String _category, _location;
  late int _quantity;
  late Set<int> _reminders;
  XFile? _photo;
  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _name = TextEditingController(text: i?.name ?? '');
    _date = i?.expiry ?? DateTime.now().add(const Duration(days: 7));
    _category = i?.category ?? 'Other';
    _location = i?.location ?? 'Fridge';
    _quantity = i?.quantity ?? 1;
    _reminders = {...?i?.reminderDays};
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await Navigator.push<String>(
        context, MaterialPageRoute(builder: (_) => const BarcodeScannerPage()));
    if (code != null && mounted) {
      setState(() {
        _name.text = barcodeNames[code] ?? 'Scanned item ($code)';
        _category = barcodeCategories[code] ?? 'Other';
      });
    }
  }

  Future<void> _pickPhoto() async {
    final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600);
    if (photo != null && mounted) setState(() => _photo = photo);
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
      initialChildSize: .82,
      minChildSize: .55,
      maxChildSize: .96,
      expand: false,
      builder: (context, controller) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
          child: ListView(
              controller: controller,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Center(
                    child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(3)))),
                const SizedBox(height: 18),
                Text(widget.item == null ? 'Add an item' : 'Edit item',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                    onPressed: _scan,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan barcode')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(_photo == null
                        ? 'Add item photo'
                        : 'Change item photo')),
                if (_photo != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_photo!.path),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover))
                ],
                const SizedBox(height: 12),
                TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Item name')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      'Produce',
                      'Dairy',
                      'Meat',
                      'Pantry',
                      'Frozen',
                      'Beverages',
                      'Other'
                    ]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                    initialValue: _location,
                    decoration:
                        const InputDecoration(labelText: 'Storage location'),
                    items: const [
                      'Fridge',
                      'Freezer',
                      'Pantry',
                      'Medicine cabinet',
                      'Counter'
                    ]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _location = v!)),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('Quantity'),
                  const Spacer(),
                  IconButton(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline)),
                  Text('$_quantity',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: const Icon(Icons.add_circle_outline))
                ]),
                Card(
                    color: const Color(0xFFE8F5F1),
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline,
                                  color: Color(0xFF08756E)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child:
                                      Text(_guidanceFor(_category, _quantity)))
                            ]))),
                OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 3650)));
                      if (date != null) setState(() => _date = date);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                        'Expires ${monthName(_date.month)} ${_date.day}, ${_date.year}')),
                const SizedBox(height: 12),
                Text('Reminder days',
                    style: Theme.of(context).textTheme.titleSmall),
                Wrap(
                    spacing: 8,
                    children: [1, 3, 7]
                        .map((d) => FilterChip(
                            label: Text('$d day${d == 1 ? '' : 's'} before'),
                            selected: _reminders.contains(d),
                            onSelected: (s) => setState(() =>
                                s ? _reminders.add(d) : _reminders.remove(d))))
                        .toList()),
                TextButton.icon(
                    onPressed: NotificationService.requestPermission,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Allow expiry notifications')),
                FilledButton(
                    onPressed: () {
                      if (_name.text.trim().isNotEmpty) {
                        Navigator.pop(
                            context,
                            FoodItem(
                                id: widget.item?.id,
                                name: _name.text.trim(),
                                category: _category,
                                expiry: _date,
                                location: _location,
                                quantity: _quantity,
                                reminderDays: _reminders,
                                photoUrl: widget.item?.photoUrl,
                                localImagePath: _photo?.path));
                      }
                    },
                    child: Text(
                        widget.item == null ? 'Save item' : 'Save changes'))
              ])));
}

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});
  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool _done = false;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Scan barcode')),
      body: MobileScanner(onDetect: (capture) {
        final codes = capture.barcodes;
        final code = codes.isEmpty ? null : codes.first.rawValue;
        if (!_done && code != null) {
          _done = true;
          Navigator.pop(context, code);
        }
      }));
}

const barcodeNames = {
  '041383090011': 'Greek yogurt',
  '041383090028': 'Whole milk'
};
const barcodeCategories = {'041383090011': 'Dairy', '041383090028': 'Dairy'};
String _guidanceFor(String category, int quantity) => switch (category) {
      'Produce' =>
        '$quantity ${quantity == 1 ? 'portion is' : 'portions are'} enough for 1–2 meals. Only buy more if you have a plan.',
      'Dairy' =>
        'For most households, $quantity item${quantity == 1 ? '' : 's'} is a good 3–5 day supply after opening.',
      'Meat' =>
        'Portion $quantity serving${quantity == 1 ? '' : 's'} into meal-sized packs before storing.',
      _ =>
        'Track $quantity item${quantity == 1 ? '' : 's'} and restock only when you are down to one.'
    };

class ItemDetailPage extends StatelessWidget {
  const ItemDetailPage({super.key, required this.item, required this.onEdit});
  final FoodItem item;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(item.name), actions: [
        IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined))
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: const Color(0xFFE8F5F1),
                borderRadius: BorderRadius.circular(20)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.expiryLabel,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF08756E))),
              const SizedBox(height: 8),
              Text(
                  'Expires ${monthName(item.expiry.month)} ${item.expiry.day} • ${item.location}')
            ])),
        const SizedBox(height: 22),
        Text('Quantity guidance',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(item.quantityGuidance),
        const SizedBox(height: 24),
        Text('Recipe suggestions',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
            'Meal ideas based on this item. Find cooking steps in Recipes.'),
        const SizedBox(height: 10),
        ..._recipesFor(item).map((r) => Card(
            child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.auto_awesome)),
                title: Text(r.$1),
                subtitle: Text(r.$2),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${r.$1} added to your meal ideas'))))))
      ]));
}

List<(String, String)> _recipesFor(FoodItem item) => switch (item.category) {
      'Produce' => [
          (
            'Quick sauté',
            'Pair ${item.name} with garlic, olive oil, and grains.'
          ),
          ('Fresh salad', 'Toss ${item.name} into a bright, low-waste lunch.')
        ],
      'Dairy' => [
          ('Creamy pasta', 'Use ${item.name} in a quick sauce or topping.'),
          ('Breakfast bowl', 'Make a simple breakfast using ${item.name}.')
        ],
      _ => [
          (
            'Use-it-up bowl',
            'Build a flexible meal around ${item.name} and pantry staples.'
          ),
          ('Weekend prep', 'Turn ${item.name} into portions for the week.')
        ]
    };

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.profile, required this.onSaved});
  final UserProfile? profile;
  final ValueChanged<UserProfile> onSaved;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile?.name ?? '');
    _email = TextEditingController(text: widget.profile?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Profile & settings')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const CircleAvatar(radius: 38, child: Icon(Icons.person, size: 40)),
        const SizedBox(height: 22),
        TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 14),
        TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 24),
        FilledButton(
            onPressed: () async {
              final p = UserProfile(
                  name: _name.text.trim(), email: _email.text.trim());
              await LocalStore.updateProfile(p);
              widget.onSaved(p);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save profile')),
        const SizedBox(height: 16),
        ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Expiry notifications'),
            subtitle:
                const Text('Enable reminders for items before they expire'),
            trailing: const Icon(Icons.chevron_right),
            onTap: NotificationService.requestPermission),
        const Divider(),
        ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () async {
              await LocalStore.signOut();
              if (mounted) Navigator.pop(context);
            })
      ]));
}
