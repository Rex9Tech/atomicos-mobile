// lib/helpers/money.helper.dart
import '../constants/payment.constants.dart';

/// Currencies stored as WHOLE units (no minor unit) — displayed without /100.
const Set<String> zeroDecimalCurrencyCodes = {'mmk'};

bool isZeroDecimalCurrency(String currency) =>
    zeroDecimalCurrencyCodes.contains(currency.toLowerCase());

/// 9900 -> "9,900"
String withThousandsSeparator(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buffer';
}

/// Format a payment amount stored in the payment tables.
///
/// USD/SGD use minor units (divided by 100 for display); zero-decimal
/// currencies such as MMK are stored as whole units (whole kyats) — the same
/// value the MMQR gateway charges.
String formatPaymentAmount(int amount, String currency) {
  final code = currency.toLowerCase();
  final symbol = code == PaymentCurrencies.mmk
      ? PaymentCurrencies.mmkSymbol
      : code == PaymentCurrencies.sgd
      ? PaymentCurrencies.sgdSymbol
      : PaymentCurrencies.usdSymbol;

  if (isZeroDecimalCurrency(code)) {
    return '$symbol${withThousandsSeparator(amount)}';
  }
  return '$symbol${(amount / 100.0).toStringAsFixed(2)}';
}
