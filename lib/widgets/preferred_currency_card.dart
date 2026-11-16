import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/currency.dart';
import '../viewmodels/budget_viewmodel.dart';

// choose the currency preselected on new expense forms
class PreferredCurrencyCard extends StatelessWidget {
  const PreferredCurrencyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<BudgetViewModel>();
    final state = model.state;
    final theme = Theme.of(context);
    // disable changes until the current preference is ready
    final disabled =
        state.currencyLoading ||
        state.currencySaving ||
        state.currencyLoadError != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Default currency', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            if (state.currencyLoading)
              const LinearProgressIndicator(
                semanticsLabel: 'Loading preferred currency',
              )
            else if (state.currencyLoadError != null) ...[
              Text(state.currencyLoadError!),
              TextButton(
                onPressed: model.reload,
                child: const Text('Retry loading currency'),
              ),
            ] else
              // save the preference as soon as a currency is selected
              DropdownButtonFormField<Currency>(
                // rebuild the field when a cloud update changes the value
                key: ValueKey(
                  'preferredCurrency-${state.preferredCurrency.code}',
                ),
                initialValue: state.preferredCurrency,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'New expenses'),
                items: Currency.values
                    .map(
                      (currency) => DropdownMenuItem(
                        value: currency,
                        child: Text('${currency.code} · ${currency.label}'),
                      ),
                    )
                    .toList(),
                onChanged: disabled
                    ? null
                    : (currency) {
                        if (currency != null) {
                          model.savePreferredCurrency(currency);
                        }
                      },
              ),
            if (state.currencySaving)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  semanticsLabel: 'Saving preferred currency',
                ),
              ),
            if (state.currencySaveError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    state.currencySaveError!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
