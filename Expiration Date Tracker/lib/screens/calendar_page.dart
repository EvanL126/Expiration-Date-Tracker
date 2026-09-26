import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../widgets/food_card.dart';

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
