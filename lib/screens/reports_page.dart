
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/transaction.dart';

class ReportsPage extends StatelessWidget {
  final List<Transaction> transactions;
  final String currencySymbol;
  final double exchangeRate;

  const ReportsPage({
    super.key,
    required this.transactions,
    required this.currencySymbol,
    required this.exchangeRate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final monthlyExpenses = transactions.where((transaction) {
      return transaction.type == 'Expense' &&
          transaction.date.month == now.month &&
          transaction.date.year == now.year;
    }).toList();

    final Map<String, double> categoryTotals = {};

    for (final transaction in monthlyExpenses) {
      categoryTotals[transaction.category] =
          (categoryTotals[transaction.category] ?? 0) +
              transaction.amount;
    }

    final total = categoryTotals.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );
    final displayedTotal = total * exchangeRate;

    final colors = [
      Colors.teal,
      Colors.orange,
      Colors.blue,
      Colors.red,
      Colors.purple,
      Colors.green,
      Colors.pink,
      Colors.brown,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Reports'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense Breakdown',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${_monthName(now.month)} ${now.year}',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            if (total == 0)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text(
                    'No expenses recorded this month.',
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 45,
                    sections: categoryTotals.entries
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                      final amount = entry.value.value;
                      final color =
                          colors[entry.key % colors.length];

                      return PieChartSectionData(
                        color: color,
                        value: amount,
                        title:
                            '${(amount / total * 100).toStringAsFixed(0)}%',
                        radius: 75,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Total Expenses: $currencySymbol${displayedTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Category Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              ...categoryTotals.entries
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                final category = entry.value.key;
                final amount = entry.value.value;
                final color =
                    colors[entry.key % colors.length];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 8,
                    backgroundColor: color,
                  ),
                  title: Text(category),
                  trailing: Text(
                    '$currencySymbol${(amount * exchangeRate).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }
}
