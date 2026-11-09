import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../services/currency_service.dart';

class CurrencySettingsPage extends StatefulWidget {
  final Currency currentCurrency;
  final Function(Currency) onCurrencyChanged;

  const CurrencySettingsPage({
    super.key,
    required this.currentCurrency,
    required this.onCurrencyChanged,
  });

  @override
  State<CurrencySettingsPage> createState() => _CurrencySettingsPageState();
}

class _CurrencySettingsPageState extends State<CurrencySettingsPage> {
  late Currency selectedCurrency;

  @override
  void initState() {
    super.initState();
    selectedCurrency = widget.currentCurrency;
  }

  Future<void> saveSelection() async {
    await CurrencyService().saveCurrency(selectedCurrency.code);
    widget.onCurrencyChanged(selectedCurrency);
    debugPrint('Selected currency: ${selectedCurrency.code}');
    debugPrint('Selected symbol: ${selectedCurrency.symbol}');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Currency updated successfully!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Settings'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Your Currency',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the currency you want to use in the app.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RadioGroup<String>(
                groupValue: selectedCurrency.code,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedCurrency = Currency.supportedCurrencies.firstWhere(
                      (currency) => currency.code == value,
                    );
                  });
                },
                child: ListView.builder(
                  itemCount: Currency.supportedCurrencies.length,
                  itemBuilder: (context, index) {
                    final currency = Currency.supportedCurrencies[index];

                    return RadioListTile<String>(
                      value: currency.code,
                      title: Text(currency.name),
                      subtitle: Text(currency.code),
                      secondary: Text(
                        currency.symbol,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Save Currency'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
