import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/category_style.dart';
import '../l10n/app_localizations.dart';
import '../viewmodels/budget_viewmodel.dart';

// manage account-only categories without changing old expenses
class CustomCategoriesCard extends StatefulWidget {
  const CustomCategoriesCard({super.key});

  @override
  State<CustomCategoriesCard> createState() => _CustomCategoriesCardState();
}

class _CustomCategoriesCardState extends State<CustomCategoriesCard> {
  final _name = TextEditingController();

  // clear the field only after a successful save
  Future<void> _add() async {
    final success = await context.read<BudgetViewModel>().addCustomCategory(
      _name.text,
    );
    if (success && mounted) _name.clear();
  }

  // clear the failed entry after its retry succeeds
  Future<void> _retry() async {
    final success = await context
        .read<BudgetViewModel>()
        .retryCustomCategories();
    if (success && mounted) _name.clear();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<BudgetViewModel>();
    final state = model.state;
    final theme = Theme.of(context);
    final text = context.l10n;
    // prevent edits while categories are loading or saving
    final disabled =
        state.categoryLoading ||
        state.categorySaving ||
        state.categoryLoadError != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              text.text('settings.customCategories'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(text.text('settings.categoryLimit')),
            const SizedBox(height: 16),
            if (state.categoryLoading)
              LinearProgressIndicator(
                semanticsLabel: text.text('settings.loadingCategories'),
              )
            else if (state.categoryLoadError != null) ...[
              Text(text.message(state.categoryLoadError!)),
              TextButton(
                onPressed: model.reload,
                child: Text(text.text('settings.retryCategoryLoad')),
              ),
            ] else ...[
              TextField(
                key: const Key('customCategoryName'),
                controller: _name,
                enabled: !disabled,
                maxLength: 24,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: text.text('settings.categoryName'),
                  suffixIcon: IconButton(
                    onPressed: disabled ? null : _add,
                    tooltip: text.text('settings.addCategory'),
                    icon: const Icon(Icons.add),
                  ),
                ),
                onSubmitted: disabled ? null : (_) => _add(),
              ),
              if (state.customCategories.isEmpty)
                Text(text.text('settings.noCustomCategories'))
              else
                // show saved categories as removable chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in state.customCategories)
                      InputChip(
                        avatar: Icon(
                          CategoryStyle.icon(category),
                          size: 18,
                          color: CategoryStyle.color(category),
                        ),
                        label: Text(category),
                        onDeleted: state.categorySaving
                            ? null
                            : () => model.removeCustomCategory(category),
                        deleteButtonTooltipMessage: text.text(
                          'settings.removeCategory',
                          {'category': category},
                        ),
                      ),
                  ],
                ),
            ],
            if (state.categorySaving)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  semanticsLabel: text.text('settings.savingCategories'),
                ),
              ),
            if (state.categorySaveError != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  text.message(state.categorySaveError!),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: state.categorySaving ? null : _retry,
                  child: Text(text.text('settings.retryCategorySave')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
