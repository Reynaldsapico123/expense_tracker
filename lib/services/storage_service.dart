import '../models/transaction.dart';

class StorageService {
  final List<Transaction> _transactions = [];

  List<Transaction> get transactions => List.unmodifiable(_transactions);

  void addTransaction(Transaction transaction) {
    _transactions.insert(0, transaction);
  }
}
