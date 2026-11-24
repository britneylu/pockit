import 'package:material_ui/material_ui.dart';

import '../core/category_style.dart';
import '../l10n/app_localizations.dart';
import '../models/expense.dart';

// reuse the same category menu across filters and expense forms
class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.includeAll = false,
    this.fieldKey,
    this.additionalCategories = const [],
  });

  static const allCategories = 'All categories';

  final String value;
  final ValueChanged<String>? onChanged;
  final String? label;
  final bool includeAll;
  final Key? fieldKey;
  final List<String> additionalCategories;

  @override
  Widget build(BuildContext context) {
    final options = <String>[
      if (includeAll) allCategories,
      ...expenseCategories,
    ];
    // avoid duplicate values when editing a custom category
    for (final category in additionalCategories) {
      if (!options.contains(category)) options.add(category);
    }
    // keep legacy food values valid during hot reload and migration
    final selectedValue = normalizeExpenseCategory(value);
    final fieldLabel = label ?? context.l10n.text('category.label');
    return DropdownButtonFormField<String>(
      // rebuild the field when an outside filter changes its value
      key: fieldKey ?? ValueKey('$fieldLabel-$selectedValue'),
      initialValue: selectedValue,
      isExpanded: true,
      itemHeight: 52,
      menuMaxHeight: 320,
      borderRadius: BorderRadius.circular(16),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: fieldLabel,
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      ),
      items: options
          .map(
            (category) => DropdownMenuItem(
              value: category,
              child: _CategoryLabel(category: category),
            ),
          )
          .toList(),
      onChanged: onChanged == null
          ? null
          : (category) {
              if (category != null) onChanged!(category);
            },
    );
  }
}

// pair each category with its shared icon and color
class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final all = category == CategoryDropdown.allCategories;
    final color = all
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : CategoryStyle.color(category);
    return Row(
      children: [
        Icon(
          all ? Icons.filter_list : CategoryStyle.icon(category),
          size: 19,
          color: color,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            all
                ? context.l10n.text('category.all')
                : context.l10n.category(category),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
