import 'package:flutter/material.dart';

import '../../models/loan.dart';
import '../../viewmodels/library_view_model.dart';
import '../format.dart';
import 'status_chip.dart';


class LoanCard extends StatelessWidget {
  const LoanCard({
    super.key,
    required this.loan,
    required this.bookTitle,
    required this.statusText,
    required this.fine,
    this.status,
    this.onReturn,
    this.onSettle,
  });

  final Loan loan;
  final String bookTitle;
  final String statusText;
  final BookStatus? status; 
  final int fine;
  final VoidCallback? onReturn;
  final VoidCallback? onSettle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(bookTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                StatusChip(label: statusText, status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Student: ${loan.studentId}'),
            Text('Borrowed: ${formatDate(loan.borrowDate)}'),
            Text('Due: ${formatDate(loan.dueDate)}'),
            if (loan.returnDate != null)
              Text('Returned: ${formatDate(loan.returnDate!)}'),
            Text(
              'Outstanding fine: ${formatRupiah(fine)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: fine > 0 ? Colors.red.shade700 : null,
              ),
            ),
            if (onReturn != null || onSettle != null)
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (onReturn != null)
                      FilledButton(
                        key: ValueKey('return-${loan.id}'),
                        onPressed: onReturn,
                        child: const Text('Return'),
                      ),
                    if (onSettle != null)
                      OutlinedButton(
                        key: ValueKey('settle-${loan.id}'),
                        onPressed: onSettle,
                        child: const Text('Mark fine as paid'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}