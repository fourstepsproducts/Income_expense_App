class AppConstants {
  static const String appName = 'FinanceFlow';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String tokenKey = 'jwt_access_token';
  static const String refreshTokenKey = 'jwt_refresh_token';
  static const String userKey = 'current_user_profile';
  static const String currencyKey = 'selected_currency';

  // Payment Methods
  static const List<String> paymentMethods = [
    'Cash',
    'Bank Transfer',
    'UPI',
    'Credit Card',
    'Debit Card',
    'Other'
  ];

  // Currencies
  static const Map<String, String> currencySymbols = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'د.إ',
    'SGD': 'S\$',
    'JPY': '¥'
  };
}
