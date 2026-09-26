import 'package:flutter/material.dart';

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
