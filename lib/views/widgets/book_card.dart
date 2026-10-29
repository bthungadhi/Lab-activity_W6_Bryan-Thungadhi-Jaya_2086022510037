import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../viewmodels/library_view_model.dart';
import '../format.dart';
import 'status_chip.dart';

class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.status,
    required this.onBorrow,
  });

  final Book book;
  final BookStatus status;
  final VoidCallback onBorrow;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.menu_book, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(book.author),
                  Text('Replacement: ${formatRupiah(book.replacementPrice)}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(label: status.label, status: status),
                if (status == BookStatus.available)
                  FilledButton.tonal(
                    key: ValueKey('borrow-${book.id}'),
                    onPressed: onBorrow,
                    child: const Text('Borrow'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}