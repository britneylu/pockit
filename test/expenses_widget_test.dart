import 'package:pockit/repositories/budget_repository.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/app.dart';
import 'package:pockit/models/expense.dart';
import 'package:pockit/models/currency.dart';

import 'helpers/memory_expense_repository.dart';
import 'helpers/fake_auth_service.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('expense form validates, saves, edits, deletes and undoes', (
    tester,
  ) async {
    final repo = MemoryExpenseRepository();
    await tester.pumpWidget(
      PockitApp(
        budgetRepositoryFactory: (_) => MemoryBudgetRepository(),
        authService: FakeAuthService(),
        expenseRepositoryFactory: (_) => repo,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(
      find.text('No expenses yet. Add your first purchase to get started.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Add expense'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Save expense'));
    expect(find.text('Enter a positive amount.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '12.50');
    await tester.enterText(find.byType(TextFormField).last, 'Coffee');
    await tapVisible(tester, find.text('Save expense'));
    expect(repo.expenses.single.amountUsdMinor, 1250);
    expect(find.text('Coffee'), findsOneWidget);
    await tapVisible(tester, find.text('Coffee'));
    await tester.enterText(find.byType(TextFormField).last, 'Lunch');
    await tapVisible(tester, find.text('Save expense'));
    expect(repo.expenses.single.description, 'Lunch');
    await tester.ensureVisible(find.byType(Dismissible));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(repo.expenses, isEmpty);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(repo.expenses.single.description, 'Lunch');
  });
  testWidgets(
    'purchases share date headings and open editing by tapping a row',
    (tester) async {
      final repo = MemoryExpenseRepository();
      Expense expense(String id, DateTime date) => Expense(
        id: id,
        amountMinor: 100,
        currency: Currency.usd,
        amountUsdMinor: 100,
        exchangeRate: 1,
        rateDate: date,
        category: 'Dining',
        description: id,
        date: date,
      );
      repo.expenses = [
        expense('Coffee', DateTime(2026, 11, 14, 8)),
        expense('Lunch', DateTime(2026, 11, 14, 12)),
        expense('Dinner', DateTime(2026, 11, 13)),
      ];
      await tester.pumpWidget(
        PockitApp(
          authService: FakeAuthService(),
          expenseRepositoryFactory: (_) => repo,
          budgetRepositoryFactory: (_) => MemoryBudgetRepository(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();
      expect(find.text('11/14/2026'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Dinner'), 150);
      await tester.pumpAndSettle();
      expect(find.text('11/13/2026'), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      expect(find.byTooltip('Edit expense'), findsNothing);
      expect(find.byTooltip('Delete expense'), findsNothing);
      await tester.tap(find.text('Lunch'));
      await tester.pumpAndSettle();
      expect(find.text('Edit expense'), findsOneWidget);
    },
  );

  testWidgets('expense month controls show purchases from one month', (
    tester,
  ) async {
    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1, 12);
    Expense expense(String id, DateTime date) => Expense(
      id: id,
      amountMinor: 100,
      currency: Currency.usd,
      amountUsdMinor: 100,
      exchangeRate: 1,
      rateDate: date,
      category: 'Dining',
      description: id,
      date: date,
    );
    final repo = MemoryExpenseRepository()
      ..expenses = [
        expense('Current purchase', now),
        expense('Old purchase', previous),
      ];
    await tester.pumpWidget(
      PockitApp(
        authService: FakeAuthService(),
        expenseRepositoryFactory: (_) => repo,
        budgetRepositoryFactory: (_) => MemoryBudgetRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(find.text('Current purchase'), findsOneWidget);
    expect(find.text('Old purchase'), findsNothing);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('Current purchase'), findsNothing);
    expect(find.text('Old purchase'), findsOneWidget);
  });
}
