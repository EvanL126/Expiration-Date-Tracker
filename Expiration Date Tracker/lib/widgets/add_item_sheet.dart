import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/food_item.dart';
import '../services/notification_service.dart';
import '../screens/barcode_scanner_page.dart';
import '../data/barcode_catalog.dart';

typedef BarcodeScanner = Future<String?> Function(BuildContext context);

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key, this.item, this.scanBarcode});
  final FoodItem? item;
  final BarcodeScanner? scanBarcode;
  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  late final TextEditingController _name;
  late DateTime _date;
  late String _category, _location;
  late int _quantity;
  late Set<int> _reminders;
  String? _barcode;
  XFile? _photo;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _name = TextEditingController(text: i?.name ?? '');
    _date = i?.expiry ?? DateTime.now().add(const Duration(days: 7));
    _category = i?.category ?? 'Other';
    _location = i?.location ?? 'Fridge';
    _quantity = i?.quantity ?? 1;
    _reminders = {
      ...(i?.reminderDays ?? {1, 3})
    };
    _barcode = i?.barcode;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = widget.scanBarcode == null
        ? await Navigator.push<String>(context,
            MaterialPageRoute(builder: (_) => const BarcodeScannerPage()))
        : await widget.scanBarcode!(context);
    if (code != null && mounted) {
      final matchedName = barcodeNames[code];
      setState(() {
        _barcode = code;
        if (matchedName != null) {
          _name.text = matchedName;
          _category = barcodeCategories[code] ?? 'Other';
        }
      });
      if (matchedName == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Barcode saved. Enter the product name before saving the item.')));
      }
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final photo = await ImagePicker().pickImage(
          source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600);
      if (photo != null && mounted) setState(() => _photo = photo);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Could not open the photo. Please choose it again.')));
      }
    }
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
                Card.outlined(
                    child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Barcode',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text(
                                  'Scan a product to match its barcode with this inventory item.'),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                  onPressed: _scan,
                                  icon: const Icon(Icons.qr_code_scanner),
                                  label: Text(_barcode == null
                                      ? 'Scan barcode'
                                      : 'Scan again')),
                              if (_barcode != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5F1),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: ListTile(
                                        leading: const Icon(Icons.qr_code_2),
                                        title: Text(barcodeNames[_barcode] ??
                                            'Unknown product'),
                                        subtitle: Text('Barcode: $_barcode')))
                              ]
                            ]))),
                const SizedBox(height: 20),
                Text('Item details',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(_photo == null
                        ? 'Add item photo'
                        : 'Change item photo')),
                if (_photo != null || widget.item?.photoImage != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image(
                          image: _photo != null
                              ? FileImage(File(_photo!.path))
                              : widget.item!.photoImage!,
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
                    onPressed: () => NotificationService.enableAndTest(context),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Enable and test notifications')),
                FilledButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            if (_name.text.trim().isEmpty) return;
                            setState(() => _saving = true);
                            try {
                              final photo = _photo == null
                                  ? widget.item?.localPhoto
                                  : base64Encode(await _photo!.readAsBytes());
                              if (!context.mounted) return;
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
                                      localPhoto: photo,
                                      barcode: _barcode));
                            } catch (_) {
                              if (!context.mounted) return;
                              setState(() => _saving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Could not read the photo. Choose it again and retry.')));
                            }
                          },
                    child: Text(
                        widget.item == null ? 'Save item' : 'Save changes'))
              ])));
}

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
