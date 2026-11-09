
import 'package:flutter/material.dart';

import '../models/transaction.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({
    super.key,
    required this.currencySymbol,
    required this.exchangeRate,
    this.transaction,
  });

  final String currencySymbol;
  final double exchangeRate;
  final Transaction? transaction;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  final List<String> categories = [
    'Food',
    'Transportation',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Salary',
    'Other',
  ];

  String selectedType = 'Expense';
  String selectedCategory = 'Food';
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    final transaction = widget.transaction;

    if (transaction != null) {
      nameController.text = transaction.name;
      amountController.text =
          (transaction.amount * widget.exchangeRate).toStringAsFixed(2);
      selectedType = transaction.type;
      selectedCategory = transaction.category;
      selectedDate = transaction.date;
    }
  }

  void saveTransaction() {
    final name = nameController.text.trim();
    final amount = double.tryParse(amountController.text);

    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid name and amount.'),
        ),
      );
      return;
    }

    final transaction = Transaction(
      id: widget.transaction?.id,
      name: name,
      amount: amount / widget.exchangeRate,
      type: selectedType,
      category: selectedCategory,
      date: selectedDate,
    );

    Navigator.pop(context, transaction);
  }

  Future<void> pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate != null) {
      setState(() => selectedDate = pickedDate);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Transaction Name',
                hintText: 'Example: Food',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${widget.currencySymbol} ',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              decoration: const InputDecoration(
                labelText: 'Transaction Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Income', child: Text('Income')),
                DropdownMenuItem(value: 'Expense', child: Text('Expense')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedType = value;
                    selectedCategory =
                        value == 'Income' ? 'Salary' : 'Food';
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Transaction Date'),
              subtitle: Text(
                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: pickDate,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saveTransaction,
                icon: const Icon(Icons.save),
                label: Text(
                  isEditing ? 'Update Transaction' : 'Save Transaction',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
