import 'package:flutter/material.dart';

import '../format.dart';


class FineSummaryCard extends StatelessWidget {
  const FineSummaryCard({
    super.key,
    required this.totalFine,
    required this.activeLoanCount,
  });

  final int totalFine;
  final int activeLoanCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Outstanding fines', style: theme.textTheme.titleSmall),
                  Text(formatRupiah(totalFine),
                      style: theme.textTheme.headlineSmall),
                ],
              ),
            ),
            Text('Active loans: $activeLoanCount'),
          ],
        ),
      ),
    );
  }
}