import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    required this.currencySymbol,
  });

  final double balance;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.teal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$currencySymbol${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Available Balance',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    super.key,
  });

  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
