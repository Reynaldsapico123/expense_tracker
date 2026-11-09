
class Transaction {
  const Transaction({
    this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  final int? id;
  final String name;
  final double amount;
  final String type;
  final String category;
  final DateTime date;

  bool get isIncome => type == 'Income';
}
