import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../core/category_style.dart';
import '../core/date_format.dart';
import '../core/money.dart';
import '../models/currency.dart';
import '../models/expense.dart';

// open editing by tapping the row and expose deletion to screen readers
class ExpenseListItem extends StatelessWidget {
  const ExpenseListItem({
    super.key,
    required this.expense,
    this.onTap,
    this.onDelete,
  });
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = expense.description.isEmpty
        ? expense.category
        : expense.description;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (expense.description.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            expense.category,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
    final amount = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${formatMinor(expense.amountMinor, expense.currency)} ${expense.currency.code}',
          textAlign: TextAlign.right,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.primary,
          ),
        ),
        if (expense.currency != Currency.usd)
          Tooltip(
            message:
                '1 ${expense.currency.code} = ${expense.exchangeRate} USD\nRate date: ${formatUsDate(expense.rateDate)}',
            child: Text(
              '≈ ${formatMinor(expense.amountUsdMinor, Currency.usd)} USD',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
    return Semantics(
      button: onTap != null,
      customSemanticsActions: onDelete == null
          ? null
          : {const CustomSemanticsAction(label: 'Delete expense'): onDelete!},
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CategoryStyle.tint(expense.category, strength: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CategoryStyle.icon(expense.category),
                    size: 20,
                    color: CategoryStyle.color(expense.category),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 220 ||
                          MediaQuery.textScalerOf(context).scale(14) > 18) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            details,
                            const SizedBox(height: 6),
                            amount,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: details),
                          const SizedBox(width: 12),
                          Expanded(child: amount),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
