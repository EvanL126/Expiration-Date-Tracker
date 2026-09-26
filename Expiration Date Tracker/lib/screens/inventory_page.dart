import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../widgets/food_card.dart';

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
