import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/currency.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/currency_service.dart';
import '../services/exchange_rate_service.dart';
import '../services/export_service.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_page.dart';
import 'budget_page.dart';
import 'currency_settings_page.dart';
import 'reports_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Transaction> transactions = [];
  String searchQuery = '';
  String selectedFilter = 'All';
  String selectedSort = 'Newest first';
  DateTime selectedMonth = DateTime.now();

  int get monthlyTransactionCount {
    return transactions.where((transaction) {
      return transaction.date.month == selectedMonth.month &&
          transaction.date.year == selectedMonth.year;
    }).length;
  }

  double get monthlyIncome {
    return transactions
        .where((transaction) =>
            transaction.type == 'Income' &&
            transaction.date.month == selectedMonth.month &&
            transaction.date.year == selectedMonth.year)
        .fold(0.0, (total, transaction) => total + transaction.amount);
  }

  double get monthlyExpense {
    return transactions
        .where((transaction) =>
            transaction.type == 'Expense' &&
            transaction.date.month == selectedMonth.month &&
            transaction.date.year == selectedMonth.year)
        .fold(0.0, (total, transaction) => total + transaction.amount);
  }
  double get monthlySavings {
  return monthlyIncome - monthlyExpense;
}

  final DatabaseService databaseService = DatabaseService();

  double monthlyBudget = 10000;
  Currency selectedCurrency = Currency.supportedCurrencies.first;
  double exchangeRate = 1.0;
  String? lastUpdatedDate;

  @override
  void initState() {
    super.initState();
    loadTransactions();
    loadBudget();
    loadCurrency();
  }

  Future<void> loadTransactions() async {
    try {
      final savedTransactions = await databaseService.getTransactions();

      if (!mounted) return;

      setState(() {
        transactions.addAll(savedTransactions);
      });
    } catch (error) {
      debugPrint('Database unavailable: $error');
    }
  }

  Future<void> refreshTransactions() async {
    try {
      final savedTransactions = await databaseService.getTransactions();

      if (!mounted) return;

      setState(() {
        transactions
          ..clear()
          ..addAll(savedTransactions);
      });
    } catch (error) {
      debugPrint('Could not refresh transactions: $error');
    }
  }

  Future<void> loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBudget = prefs.getDouble('monthly_budget');

    if (!mounted) return;

    setState(() {
      monthlyBudget = savedBudget ?? 10000;
    });
  }

  Future<void> saveBudget(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_budget', amount);

    if (!mounted) return;

    setState(() {
      monthlyBudget = amount;
    });
  }

  Future<void> loadCurrency() async {
    final currency = await CurrencyService().getCurrency();

    if (!mounted) return;

    setState(() {
      selectedCurrency = currency;
    });

    await loadExchangeRate();
  }

  Future<void> loadExchangeRate() async {
    try {
      final service = ExchangeRateService();
      final rate = await service.getRate(selectedCurrency.code);
      final updatedDate = await service.getLastUpdated(selectedCurrency.code);

      if (!mounted) return;

      setState(() {
        exchangeRate = rate;
        lastUpdatedDate = updatedDate;
      });

      debugPrint('Current exchange rate: $exchangeRate');
      debugPrint('Last updated: $lastUpdatedDate');
    } catch (error) {
      debugPrint('Exchange rate error: $error');
    }
  }

  double get totalIncome {
    return transactions
        .where((transaction) =>
            transaction.type == 'Income' &&
            transaction.date.month == selectedMonth.month &&
            transaction.date.year == selectedMonth.year)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double get totalExpenses {
    return transactions
        .where((transaction) =>
            transaction.type == 'Expense' &&
            transaction.date.month == selectedMonth.month &&
            transaction.date.year == selectedMonth.year)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double get balance => totalIncome - totalExpenses;

  double get monthlyExpenses {
    return monthlyExpense;
  }

  double convertAmount(double amount) {
    return amount * exchangeRate;
  }

  String formatAmount(double amount) {
    return '${selectedCurrency.symbol}${convertAmount(amount).toStringAsFixed(2)}';
  }

  Future<void> openAddTransaction() async {
    final newTransaction = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(
          currencySymbol: selectedCurrency.symbol,
          exchangeRate: exchangeRate,
        ),
      ),
    );

    if (newTransaction != null) {
      Transaction transactionToAdd = newTransaction;

      try {
        final id = await databaseService.insertTransaction(newTransaction);

        transactionToAdd = Transaction(
          id: id,
          name: newTransaction.name,
          amount: newTransaction.amount,
          type: newTransaction.type,
          category: newTransaction.category,
          date: newTransaction.date,
        );
      } catch (error) {
        debugPrint('Could not save transaction to database: $error');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Transaction added for this session. Database storage is unavailable on this platform.',
              ),
            ),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        transactions.insert(0, transactionToAdd);
      });
    }
  }

  Future<void> editTransaction(Transaction transaction) async {
    final updatedTransaction = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(
          currencySymbol: selectedCurrency.symbol,
          exchangeRate: exchangeRate,
          transaction: transaction,
        ),
      ),
    );

    if (updatedTransaction == null || !mounted) return;

    try {
      if (updatedTransaction.id != null) {
        await databaseService.updateTransaction(updatedTransaction);
      }
    } catch (error) {
      debugPrint('Could not update transaction: $error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update transaction.')),
        );
      }
      return;
    }

    setState(() {
      final index = transactions.indexWhere(
        (item) => transaction.id != null
            ? item.id == transaction.id
            : identical(item, transaction),
      );

      if (index != -1) {
        transactions[index] = updatedTransaction;
      }
    });
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text(
          'Are you sure you want to delete "${transaction.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (transaction.id != null) {
        await databaseService.deleteTransaction(transaction.id!);
      }
    } catch (error) {
      debugPrint('Could not delete transaction: $error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete transaction.')),
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      transactions.removeWhere(
        (item) => transaction.id != null
            ? item.id == transaction.id
            : identical(item, transaction),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction deleted.')),
    );
  }

  Future<void> exportTransactions() async {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions available to export.'),
        ),
      );
      return;
    }

    try {
      await ExportService.shareTransactionsCsv(transactions);
    } catch (error) {
      debugPrint('Export error: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not export transactions.'),
        ),
      );
    }
  }

  void openBudgetPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetPage(
          monthlyExpenses: monthlyExpenses,
          initialBudget: monthlyBudget,
          currencySymbol: selectedCurrency.symbol,
          exchangeRate: exchangeRate,
          onBudgetChanged: (newBudget) {
            saveBudget(newBudget);
          },
        ),
      ),
    );
  }

  void openCurrencySettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CurrencySettingsPage(
          currentCurrency: selectedCurrency,
          onCurrencyChanged: (currency) async {
            setState(() {
              selectedCurrency = currency;
              exchangeRate = 1.0;
            });

            await loadExchangeRate();
          },
        ),
      ),
    );
  }

  void openReportsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportsPage(
          transactions: transactions,
          currencySymbol: selectedCurrency.symbol,
          exchangeRate: exchangeRate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Expense Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: openCurrencySettings,
            icon: const Icon(Icons.currency_exchange),
            tooltip: 'Currency Settings',
          ),
          IconButton(
            onPressed: openReportsPage,
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Monthly Reports',
          ),
          IconButton(
            onPressed: openBudgetPage,
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Monthly Budget',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshTransactions,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Balance',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            BalanceCard(
              balance: convertAmount(balance),
              currencySymbol: selectedCurrency.symbol,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '1 PHP = ${exchangeRate.toStringAsFixed(6)} '
                '${selectedCurrency.code}'
                '${lastUpdatedDate == null ? '' : ' • Updated $lastUpdatedDate'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: buildSummaryCard(
                    'Income',
                    formatAmount(totalIncome),
                    Icons.arrow_downward,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: buildSummaryCard(
                    'Expenses',
                    formatAmount(totalExpenses),
                    Icons.arrow_upward,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.white,
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.pie_chart, color: Colors.teal),
                title: const Text(
                  'Monthly Budget',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${formatAmount(monthlyExpenses)} spent '
                  'of ${formatAmount(monthlyBudget)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: openBudgetPage,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          selectedMonth = DateTime(
                            selectedMonth.year,
                            selectedMonth.month - 1,
                          );
                        });
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),
                    TextButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedMonth,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          initialDatePickerMode: DatePickerMode.year,
                        );

                        if (pickedDate != null) {
                          setState(() {
                            selectedMonth = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                            );
                          });
                        }
                      },
                      child: Text(
                        '${selectedMonth.month}/${selectedMonth.year}',
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final now = DateTime.now();

                        if (selectedMonth.year < now.year ||
                            (selectedMonth.year == now.year &&
                                selectedMonth.month < now.month)) {
                          setState(() {
                            selectedMonth = DateTime(
                              selectedMonth.year,
                              selectedMonth.month + 1,
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total transactions: $monthlyTransactionCount',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: exportTransactions,
              icon: const Icon(Icons.file_download),
              label: const Text('Export CSV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly Income',
                            style: TextStyle(color: Colors.green),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${selectedCurrency.symbol}${(monthlyIncome * exchangeRate).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly Expense',
                            style: TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${selectedCurrency.symbol}${(monthlyExpense * exchangeRate).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Savings',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Income - Expenses',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      formatAmount(monthlySavings),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: monthlySavings >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
const SizedBox(height: 12),

TextField(
  decoration: InputDecoration(
    hintText: 'Search transactions...',
    prefixIcon: const Icon(Icons.search),
    suffixIcon: searchQuery.isNotEmpty
        ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                searchQuery = '';
              });
            },
          )
        : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: Colors.white,
  ),
  onChanged: (value) {
    setState(() {
      searchQuery = value.toLowerCase();
    });
  },
),

const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Income', 'Expense'].map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: selectedFilter == filter,
                      selectedColor: Colors.teal,
                      labelStyle: TextStyle(
                        color: selectedFilter == filter
                            ? Colors.white
                            : Colors.black,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedSort,
              decoration: const InputDecoration(
                labelText: 'Sort transactions',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sort),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Newest first',
                  child: Text('Newest first'),
                ),
                DropdownMenuItem(
                  value: 'Oldest first',
                  child: Text('Oldest first'),
                ),
                DropdownMenuItem(
                  value: 'Highest amount',
                  child: Text('Highest amount'),
                ),
                DropdownMenuItem(
                  value: 'Lowest amount',
                  child: Text('Lowest amount'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedSort = value;
                  });
                }
              },
            ),

            const SizedBox(height: 12),
            if (transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No transactions yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            ...(() {
              final filteredTransactions = transactions.where((transaction) {
                final matchesSearch =
                    transaction.name.toLowerCase().contains(searchQuery) ||
                    transaction.category
                        .toLowerCase()
                        .contains(searchQuery) ||
                    transaction.type.toLowerCase().contains(searchQuery);

                final matchesFilter = selectedFilter == 'All' ||
                    transaction.type == selectedFilter;
                final matchesMonth =
                    transaction.date.month == selectedMonth.month &&
                    transaction.date.year == selectedMonth.year;

                return matchesSearch && matchesFilter && matchesMonth;
              }).toList();

              filteredTransactions.sort((a, b) {
                switch (selectedSort) {
                  case 'Oldest first':
                    return a.date.compareTo(b.date);
                  case 'Highest amount':
                    return b.amount.compareTo(a.amount);
                  case 'Lowest amount':
                    return a.amount.compareTo(b.amount);
                  default:
                    return b.date.compareTo(a.date);
                }
              });

              if (filteredTransactions.isEmpty) {
                return [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 50,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No matching transactions found.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              }

              return filteredTransactions.map(
                (transaction) => TransactionTile(
                  transaction: transaction,
                  currencySymbol: selectedCurrency.symbol,
                  exchangeRate: exchangeRate,
                  onEdit: () => editTransaction(transaction),
                  onDelete: () => deleteTransaction(transaction),
                ),
              ).toList();
            })(),
          ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddTransaction,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget buildSummaryCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
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
