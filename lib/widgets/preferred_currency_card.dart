import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../viewmodels/budget_viewmodel.dart';
import '../l10n/app_localizations.dart';
import 'currency_dropdown.dart';

// choose the currency preselected on new expense forms
class PreferredCurrencyCard extends StatelessWidget {
  const PreferredCurrencyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<BudgetViewModel>();
    final state = model.state;
    final theme = Theme.of(context);
    final text = context.l10n;
    // disable changes until the current preference is ready
    final disabled =
        state.currencyLoading ||
        state.currencySaving ||
        state.currencyLoadError != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              text.text('settings.defaultCurrency'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (state.currencyLoading)
              LinearProgressIndicator(
                semanticsLabel: text.text('settings.loadingCurrency'),
              )
            else if (state.currencyLoadError != null) ...[
              Text(text.message(state.currencyLoadError!)),
              TextButton(
                onPressed: model.reload,
                child: Text(text.text('settings.retryCurrencyLoad')),
              ),
            ] else
              // save the preference as soon as a currency is selected
              CurrencyDropdown(
                fieldKey: ValueKey(
                  'preferredCurrency-${state.preferredCurrency.code}',
                ),
                label: text.text('settings.newExpenses'),
                value: state.preferredCurrency,
                onChanged: disabled ? null : model.savePreferredCurrency,
              ),
            if (state.currencySaving)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  semanticsLabel: text.text('settings.savingCurrency'),
                ),
              ),
            if (state.currencySaveError != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    text.message(state.currencySaveError!),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: state.currencySaving
                      ? null
                      : model.retryPreferredCurrency,
                  child: Text(text.text('settings.retryCurrencySave')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
