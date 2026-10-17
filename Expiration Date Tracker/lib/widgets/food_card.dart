import 'package:flutter/material.dart';
import '../models/food_item.dart';

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
                              backgroundImage: item.photoImage,
                              child: item.photoImage == null
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
                                if (item.barcode != null)
                                  Text('Barcode: ${item.barcode}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
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
