import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/currency.dart';

class CurrencyService {
  static const String _currencyKey = 'selected_currency';

  Future<Currency> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_currencyKey);

    if (savedCode != null) {
      return Currency.supportedCurrencies.firstWhere(
        (currency) => currency.code == savedCode,
        orElse: _detectCurrency,
      );
    }

    return _detectCurrency();
  }

  Currency _detectCurrency() {
    final countryCode = PlatformDispatcher.instance.locale.countryCode;

    switch (countryCode) {
      case 'PH':
        return Currency.supportedCurrencies[0];
      case 'US':
        return Currency.supportedCurrencies[1];
      case 'GB':
        return Currency.supportedCurrencies[3];
      case 'JP':
        return Currency.supportedCurrencies[4];
      case 'SG':
        return Currency.supportedCurrencies[5];
      case 'AU':
        return Currency.supportedCurrencies[6];
      case 'CA':
        return Currency.supportedCurrencies[7];
      case 'IN':
        return Currency.supportedCurrencies[8];
      default:
        return Currency.supportedCurrencies[0];
    }
  }

  Future<void> saveCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, code);
  }
}
