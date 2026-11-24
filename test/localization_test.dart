import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/app.dart';
import 'package:pockit/repositories/budget_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_auth_service.dart';
import 'helpers/memory_expense_repository.dart';

void main() {
  testWidgets('language selection changes the app and stays saved', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      PockitApp(
        authService: FakeAuthService(account: null),
        expenseRepositoryFactory: (_) => MemoryExpenseRepository(),
        budgetRepositoryFactory: (_) => MemoryBudgetRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('languageSelector')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('语言'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('interface_language'), 'zh');
  });
}
