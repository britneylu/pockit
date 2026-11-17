import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/core/date_format.dart';
import 'package:pockit/models/currency.dart';
import 'package:pockit/models/expense.dart';
import 'package:pockit/widgets/expense_list_item.dart';

void main() {
  test('us dates preserve calendar fields and pad month and day', () {
    expect(formatUsDate(DateTime(2026, 11, 14)), '11/14/2026');
    expect(formatUsDate(DateTime(2024, 2, 29)), '02/29/2024');
    expect(formatUsDate(DateTime(2026, 1, 1)), '01/01/2026');
  });
  testWidgets(
    'amounts align to the list edge in both layouts and rate dates use us format',
    (tester) async {
      for (final width in [400.0, 280.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: ExpenseListItem(
                    expense: Expense(
                      id: 'foreign',
                      amountMinor: 1000,
                      currency: Currency.eur,
                      amountUsdMinor: 1100,
                      exchangeRate: 1.1,
                      rateDate: DateTime(2026, 11, 13),
                      category: 'Food',
                      description: 'Lunch',
                      date: DateTime(2026, 11, 14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final card = tester.getRect(find.byType(ExpenseListItem));
        expect(
          tester.getRect(find.text('10.00 EUR')).right,
          closeTo(card.right - 4, 0.1),
        );
        expect(
          tester.getRect(find.text('≈ 11.00 USD')).right,
          closeTo(card.right - 4, 0.1),
        );
      }
      expect(find.byType(Tooltip), findsOneWidget);
      expect(
        tester.widget<Tooltip>(find.byType(Tooltip)).message,
        contains('Rate date: 11/13/2026'),
      );
    },
  );
}
