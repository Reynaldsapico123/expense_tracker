class Currency {
  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  final String code;
  final String name;
  final String symbol;

  static const List<Currency> supportedCurrencies = [
    Currency(code: 'PHP', name: 'Philippine Peso', symbol: '₱'),
    Currency(code: 'USD', name: 'US Dollar', symbol: r'$'),
    Currency(code: 'EUR', name: 'Euro', symbol: '€'),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£'),
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
    Currency(code: 'SGD', name: 'Singapore Dollar', symbol: r'S$'),
    Currency(code: 'AUD', name: 'Australian Dollar', symbol: r'A$'),
    Currency(code: 'CAD', name: 'Canadian Dollar', symbol: r'C$'),
    Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
  ];
}
