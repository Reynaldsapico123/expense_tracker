
import 'package:flutter/material.dart';

import '../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.currencySymbol,
    required this.exchangeRate,
    required this.onEdit,
    required this.onDelete,
  });

  final Transaction transaction;
  final String currencySymbol;
  final double exchangeRate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = transaction.isIncome ? Colors.green : Colors.red;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            transaction.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
          ),
        ),
        title: Text(transaction.name),
        subtitle: Text(
          '${transaction.type} • ${transaction.category}\n'
          '${transaction.date.day}/${transaction.date.month}/'
          '${transaction.date.year}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${transaction.isIncome ? '+' : '-'}$currencySymbol'
              '${(transaction.amount * exchangeRate).toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
