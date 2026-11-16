import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/models/currency.dart';
import 'package:pockit/widgets/currency_dropdown.dart';

void main() {
  test('currency menu puts the selection first and usd second', () {
    expect(CurrencyDropdown.orderedCurrencies(Currency.jpy), [
      Currency.jpy,
      Currency.usd,
      Currency.aud,
      Currency.cad,
      Currency.cny,
      Currency.eur,
      Currency.gbp,
      Currency.krw,
    ]);
  });
}
