import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transaction.dart';

class ExportService {
  static String transactionsToCsv(List<Transaction> transactions) {
    final rows = <List<dynamic>>[
      ['Name', 'Type', 'Category', 'Amount', 'Date'],
      ...transactions.map((transaction) {
        return [
          transaction.name,
          transaction.type,
          transaction.category,
          transaction.amount.toStringAsFixed(2),
          transaction.date.toIso8601String().split('T').first,
        ];
      }),
    ];

    final csvData = const ListToCsvConverter().convert(rows);
    return '\uFEFF$csvData';
  }

  static Future<void> shareTransactionsCsv(
    List<Transaction> transactions,
  ) async {
    final csvData = transactionsToCsv(transactions);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            utf8.encode(csvData),
            mimeType: 'text/csv',
          ),
        ],
        fileNameOverrides: ['transactions.csv'],
        title: 'Export Transactions',
      ),
    );
  }
}
