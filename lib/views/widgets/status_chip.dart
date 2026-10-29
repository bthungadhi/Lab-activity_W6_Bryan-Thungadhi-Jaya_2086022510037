import 'package:flutter/material.dart';

import '../../viewmodels/library_view_model.dart';


class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.status});

  final String label;
  final BookStatus? status;

  Color get _color {
    switch (status) {
      case BookStatus.available:
        return Colors.green.shade700;
      case BookStatus.borrowed:
        return Colors.blue.shade700;
      case BookStatus.overdue:
        return Colors.orange.shade800;
      case BookStatus.missing:
        return Colors.red.shade700;
      case null:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: _color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
