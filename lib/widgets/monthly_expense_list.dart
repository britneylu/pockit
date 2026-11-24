import 'package:material_ui/material_ui.dart';

import '../core/category_style.dart';
import '../core/money.dart';
import '../models/currency.dart';
import '../models/expense.dart';
import '../l10n/app_localizations.dart';

// show every matching purchase without changing the monthly summary totals
class MonthlyExpenseList extends StatelessWidget {
  const MonthlyExpenseList({
    super.key,
    required this.expenses,
    this.category,
    required this.onClear,
    this.embedded = false,
  });
  final List<Expense> expenses;
  final String? category;
  final VoidCallback onClear;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = context.l10n;
    final categoryLabel = category == null ? null : text.category(category!);
    return Card(
      color: embedded ? Colors.transparent : null,
      elevation: embedded ? 0 : null,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: embedded ? EdgeInsets.zero : const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category == null
                        ? text.text('monthly.title')
                        : text.text('monthly.categoryTitle', {
                            'category': categoryLabel!,
                          }),
                    key: const Key('monthlyExpenseListTitle'),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (category != null)
                  IconButton(
                    onPressed: onClear,
                    tooltip: text.text('monthly.clearFilter'),
                    icon: const Icon(Icons.filter_alt_off_outlined),
                  ),
              ],
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                '${expenses.length} ${expenses.length == 1 ? 'expense' : 'expenses'}',
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (expenses.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  category == null
                      ? text.text('monthly.empty')
                      : text.text('monthly.emptyCategory', {
                          'category': categoryLabel!,
                        }),
                ),
              ),
            for (final expense in expenses)
              Padding(
                key: ValueKey('monthlyExpense-${expense.id}'),
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text(
                          expense.description.isEmpty
                              ? text.category(expense.category)
                              : expense.description,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          '${formatMinor(expense.amountMinor, expense.currency)} ${expense.currency.code}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${text.category(expense.category)} · ${text.date(expense.date)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: CategoryStyle.color(expense.category),
                          ),
                        ),
                        if (expense.currency != Currency.usd)
                          Text(
                            '${formatMinor(expense.amountUsdMinor, Currency.usd)} USD',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
