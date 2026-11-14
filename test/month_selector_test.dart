import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/widgets/month_selector.dart';

void main() {
  testWidgets('month title opens direct month and year selection', (
    tester,
  ) async {
    var month = DateTime(2026, 11);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => MonthSelector(
              month: month,
              monthKey: const Key('testMonth'),
              onPrevious: () {},
              onNext: () {},
              onCurrent: () {},
              onSelected: (value) => setState(() => month = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('testMonth')));
    await tester.pumpAndSettle();
    expect(find.text('Choose month and year'), findsOneWidget);
    final monthWheel = tester.widget<CupertinoPicker>(
      find.byType(CupertinoPicker).first,
    );
    final yearWheel = tester.widget<CupertinoPicker>(
      find.byType(CupertinoPicker).last,
    );
    monthWheel.onSelectedItemChanged!(2);
    yearWheel.onSelectedItemChanged!(25);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('March 2025'), findsOneWidget);
  });
}
