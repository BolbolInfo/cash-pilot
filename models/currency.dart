class AppCurrency {
  final String code;
  final String symbol;
  final String name;

  const AppCurrency({required this.code, required this.symbol, required this.name});

  static const all = [
    AppCurrency(code: 'USD', symbol: '\$', name: 'US Dollar'),
    AppCurrency(code: 'EUR', symbol: '€', name: 'Euro'),
    AppCurrency(code: 'GBP', symbol: '£', name: 'British Pound'),
    AppCurrency(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    AppCurrency(code: 'CAD', symbol: 'CA\$', name: 'Canadian Dollar'),
    AppCurrency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    AppCurrency(code: 'CHF', symbol: 'Fr', name: 'Swiss Franc'),
    AppCurrency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    AppCurrency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    AppCurrency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real'),
    AppCurrency(code: 'MXN', symbol: 'MX\$', name: 'Mexican Peso'),
    AppCurrency(code: 'KRW', symbol: '₩', name: 'South Korean Won'),
    AppCurrency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
    AppCurrency(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
    AppCurrency(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal'),
    AppCurrency(code: 'TND', symbol: 'DT', name: 'Tunisian Dinar'),
    AppCurrency(code: 'MAD', symbol: 'MAD', name: 'Moroccan Dirham'),
    AppCurrency(code: 'EGP', symbol: 'E£', name: 'Egyptian Pound'),
    AppCurrency(code: 'ZAR', symbol: 'R', name: 'South African Rand'),
    AppCurrency(code: 'NGN', symbol: '₦', name: 'Nigerian Naira'),
  ];

  static AppCurrency fromCode(String code) =>
      all.firstWhere((c) => c.code == code, orElse: () => all.first);
}
