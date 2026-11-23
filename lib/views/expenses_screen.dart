import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/date_format.dart';
import '../core/money.dart';
import '../models/expense.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../viewmodels/budget_viewmodel.dart';
import 'expense_form.dart';
import '../widgets/category_dropdown.dart';
import '../widgets/expense_list_item.dart';
import '../widgets/month_selector.dart';

// show purchases grouped by date with tap editing and swipe deletion
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  // confirm deletion and offer an undo action after success
  Future<void> _delete(BuildContext context, Expense expense) async {
    final model = context.read<ExpensesViewModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text(
          '${formatMinor(expense.amountMinor, expense.currency)} ${expense.currency.code} · ${expense.category}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await model.delete(expense);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Expense deleted' : 'Couldn’t delete. Please retry.',
        ),
        action: success
            ? SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  final restored = await model.restore(expense);
                  if (!restored) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Couldn’t restore. Please retry.'),
                      ),
                    );
                  }
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExpensesViewModel>();
    // rebuild the filter when account categories change
    final customCategories = context
        .watch<BudgetViewModel>()
        .state
        .customCategories;
    // read the current expense list and loading status
    final state = model.state;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Every purchase, in perspective.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text('Original currency. One clear USD total.'),
        const SizedBox(height: 24),
        MonthSelector(
          month: state.month,
          monthKey: const Key('expensesMonth'),
          onPrevious: model.previousMonth,
          onNext: model.nextMonth,
          onCurrent: model.currentMonth,
          onSelected: model.selectMonth,
        ),
        const SizedBox(height: 12),
        // keep the category menu compact and scrollable
        CategoryDropdown(
          value: state.filter ?? CategoryDropdown.allCategories,
          includeAll: true,
          // keep categories from older expenses available as filters
          additionalCategories: {
            ...customCategories,
            ...state.expenses.map((expense) => expense.category),
          }.toList(),
          onChanged: (value) => model.setFilter(
            value == CategoryDropdown.allCategories ? null : value,
          ),
        ),
        const SizedBox(height: 16),
        // handle loading errors and empty results before showing date groups
        if (state.loading)
          const LinearProgressIndicator()
        else if (state.error != null) ...[
          Text(state.error!),
          TextButton(
            onPressed: model.load,
            child: const Text('Retry loading expenses'),
          ),
        ] else if (state.visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              state.expenses.isEmpty
                  ? 'No expenses yet. Add your first purchase to get started.'
                  : state.monthly.isEmpty
                  ? 'No expenses in this month.'
                  : 'No expenses in this category.',
            ),
          )
        else
          for (final group in state.dateGroups) ...[
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 6),
              child: Semantics(
                header: true,
                child: Text(
                  formatUsDate(group.date),
                  key: ValueKey('expenseDate-${formatUsDate(group.date)}'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            for (final expense in group.expenses)
              Dismissible(
                key: ValueKey(expense.id),
                direction: state.saving
                    ? DismissDirection.none
                    : DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline),
                ),
                confirmDismiss: (_) async {
                  await _delete(context, expense);
                  return false;
                },
                child: ExpenseListItem(
                  expense: expense,
                  onTap: state.saving
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ExpenseForm(expense: expense),
                          ),
                        ),
                  onDelete: state.saving
                      ? null
                      : () => _delete(context, expense),
                ),
              ),
          ],
      ],
    );
  }
}
