import 'package:material_ui/material_ui.dart';

import '../core/category_style.dart';
import '../models/expense.dart';

// reuse the same category menu across filters and expense forms
class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Category',
    this.includeAll = false,
    this.fieldKey,
  });

  static const allCategories = 'All categories';

  final String value;
  final ValueChanged<String>? onChanged;
  final String label;
  final bool includeAll;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final options = [if (includeAll) allCategories, ...expenseCategories];
    // keep legacy food values valid during hot reload and migration
    final selectedValue = normalizeExpenseCategory(value);
    return DropdownButtonFormField<String>(
      // rebuild the field when an outside filter changes its value
      key: fieldKey ?? ValueKey('$label-$selectedValue'),
      initialValue: selectedValue,
      isExpanded: true,
      itemHeight: 52,
      menuMaxHeight: 320,
      borderRadius: BorderRadius.circular(16),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
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
          child: Text(category, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
