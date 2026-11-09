import 'package:flutter/material.dart';

class BudgetPage extends StatefulWidget {
  final double monthlyExpenses;
  final double initialBudget;
  final Function(double) onBudgetChanged;
  final String currencySymbol;
  final double exchangeRate;

  const BudgetPage({
    super.key,
    required this.monthlyExpenses,
    required this.initialBudget,
    required this.onBudgetChanged,
    required this.currencySymbol,
    required this.exchangeRate,
  });

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  late TextEditingController budgetController;
  late double monthlyBudget;

  @override
  void initState() {
    super.initState();
    monthlyBudget = widget.initialBudget;
    budgetController = TextEditingController(
      text: (monthlyBudget * widget.exchangeRate).toStringAsFixed(2),
    );
  }

  void saveBudget() {
    final enteredAmount = double.tryParse(budgetController.text);
    final amount = enteredAmount == null || widget.exchangeRate <= 0
        ? null
        : enteredAmount / widget.exchangeRate;

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget.')),
      );
      return;
    }

    widget.onBudgetChanged(amount);

    setState(() {
      monthlyBudget = amount;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Monthly budget updated!')),
    );
  }

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Budget exchange rate: ${widget.exchangeRate}');
    debugPrint('Original budget: $monthlyBudget');
    debugPrint(
      'Converted budget: ${monthlyBudget * widget.exchangeRate}',
    );

    final displayedExpenses = widget.monthlyExpenses * widget.exchangeRate;
    final displayedBudget = monthlyBudget * widget.exchangeRate;

    final progress = monthlyBudget <= 0
        ? 0.0
        : (widget.monthlyExpenses / monthlyBudget).clamp(0.0, 1.0).toDouble();

    final exceeded = widget.monthlyExpenses > monthlyBudget;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budget'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Monthly Budget',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: budgetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Set Monthly Budget',
                prefixText: '${widget.currencySymbol} ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveBudget,
                child: const Text('Save Budget'),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Monthly Spending Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.currencySymbol}${displayedExpenses.toStringAsFixed(2)} spent',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              color: exceeded ? Colors.red : Colors.teal,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 16),
            Text(
              'Budget: ${widget.currencySymbol}${displayedBudget.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            Text(
              exceeded
                  ? 'You exceeded your budget!'
                  : 'Remaining: ${widget.currencySymbol}${(displayedBudget - displayedExpenses).toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: exceeded ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
