import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/transaction.dart' as model;

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'expense_tracker.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  Future<int> insertTransaction(model.Transaction transaction) async {
  final db = await database;

  return await db.insert(
    'transactions',
    {
      'name': transaction.name,
      'amount': transaction.amount,
      'type': transaction.type,
      'category': transaction.category,
      'date': transaction.date.toIso8601String(),
    },
  );
}

  Future<List<model.Transaction>> getTransactions() async {
    final db = await database;

    final maps = await db.query(
      'transactions',
      orderBy: 'id DESC',
    );

    return maps.map((map) {
      return model.Transaction(
      id: map['id']! as int,
        name: map['name']! as String,
        amount: (map['amount']! as num).toDouble(),
        type: map['type']! as String,
        category: map['category']! as String,
        date: DateTime.parse(map['date']! as String),
      );
    }).toList();
  }

  Future<int> updateTransaction(model.Transaction transaction) async {
    final db = await database;

    return await db.update(
      'transactions',
      {
        'name': transaction.name,
        'amount': transaction.amount,
        'type': transaction.type,
        'category': transaction.category,
        'date': transaction.date.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;

    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
