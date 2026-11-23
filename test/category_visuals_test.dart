import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/core/category_style.dart';
import 'package:pockit/models/category_spending.dart';
import 'package:pockit/models/currency.dart';
import 'package:pockit/models/expense.dart';
import 'package:pockit/widgets/category_breakdown.dart';
import 'package:pockit/widgets/category_dropdown.dart';
import 'package:pockit/widgets/expense_list_item.dart';

void main() {
  testWidgets('legacy food selection appears as dining', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryDropdown(value: 'Food', onChanged: (_) {}),
        ),
      ),
    );

    expect(find.text('Dining'), findsOneWidget);
    expect(find.text('Food'), findsNothing);
  });

  test('every supported category has a distinct stable color', () {
    expect(
      expenseCategories
          .map((category) => CategoryStyle.color(category).toARGB32())
          .toSet()
          .length,
      expenseCategories.length,
    );
    expect(CategoryStyle.color('Pets'), isNot(CategoryStyle.color('Other')));
    expect(CategoryStyle.icon('Pets'), Icons.label_outline);
  });
  testWidgets(
    'ring shows spending without a budget and card accents match its legend',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const CategoryBreakdown(
                    categories: [
                      CategorySpending(
                        category: 'Dining',
                        amountUsdMinor: 7500,
                        expenseCount: 2,
                        share: 0.75,
                      ),
                      CategorySpending(
                        category: 'Travel',
                        amountUsdMinor: 2500,
                        expenseCount: 1,
                        share: 0.25,
                      ),
                    ],
                  ),
                  ExpenseListItem(
                    expense: Expense(
                      id: 'food',
                      amountMinor: 7500,
                      currency: Currency.usd,
                      amountUsdMinor: 7500,
                      exchangeRate: 1,
                      rateDate: DateTime(2026),
                      category: 'Dining',
                      description: 'Lunch',
                      date: DateTime(2026),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('categoryDonut')), findsOneWidget);
      expect(find.text('100.00'), findsOneWidget);
      final dot = tester.widget<Container>(
        find.byKey(const ValueKey('categoryColor-Dining')),
      );
      expect(
        (dot.decoration as BoxDecoration).color,
        CategoryStyle.color('Dining'),
      );
      expect(
        find.descendant(
          of: find.byType(ExpenseListItem),
          matching: find.byType(Card),
        ),
        findsNothing,
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.restaurant_outlined));
      expect(icon.color, CategoryStyle.color('Dining'));
    },
  );
  testWidgets('empty and rounded zero totals show a neutral ring', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CategoryBreakdown(categories: [])),
      ),
    );
    expect(find.byKey(const Key('categoryDonut')), findsOneWidget);
    expect(find.text('No spending\nyet'), findsOneWidget);
    expect(find.text('No expenses for this month yet.'), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryBreakdown(
            categories: [
              CategorySpending(
                category: 'Dining',
                amountUsdMinor: 0,
                expenseCount: 1,
                share: 0,
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('0.00'), findsOneWidget);
    expect(find.text('0.0% of spending · 1 expense'), findsOneWidget);
  });
}
