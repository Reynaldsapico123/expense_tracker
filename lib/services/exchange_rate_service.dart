
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateService {
  static const String baseCurrency = 'PHP';

  Future<double> getRate(String targetCurrency) async {
    if (targetCurrency == baseCurrency) {
      return 1.0;
    }

    final prefs = await SharedPreferences.getInstance();

    final cacheKey = 'exchange_rate_${baseCurrency}_$targetCurrency';
    final dateKey = 'exchange_rate_date_$targetCurrency';

    try {
      final url = Uri.parse(
        'https://api.frankfurter.dev/v2/rate/$baseCurrency/$targetCurrency',
      );

      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Could not fetch exchange rate.');
      }

      final data = jsonDecode(response.body);

      final rate = (data['rate'] as num).toDouble();

      final rateDate = data['date']?.toString() ??
          DateTime.now().toIso8601String();

      await prefs.setDouble(cacheKey, rate);
      await prefs.setString(dateKey, rateDate);

      return rate;
    } catch (error) {
      final cachedRate = prefs.getDouble(cacheKey);

      if (cachedRate != null) {
        return cachedRate;
      }

      throw Exception(
        'No internet connection and no saved exchange rate available.',
      );
    }
  }

  Future<String?> getLastUpdated(String targetCurrency) async {
    if (targetCurrency == baseCurrency) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(
      'exchange_rate_date_$targetCurrency',
    );
  }
}
