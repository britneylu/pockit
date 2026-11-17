import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/date_format.dart';
import '../viewmodels/converter_viewmodel.dart';
import '../widgets/currency_dropdown.dart';
import 'expense_form.dart';

// display currency conversion inputs and results
class ConverterScreen extends StatelessWidget {
  const ConverterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // rebuild the screen when conversion state changes
    final model = context.watch<ConverterViewModel>();
    final state = model.state;
    final quote = state.quote;
    final result = state.result;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'A world of possibilities.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text('Check a currency before your next adventure.'),
        const SizedBox(height: 24),
        // send amount edits to the viewmodel for local calculation
        TextField(
          key: const Key('amount'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            hintText: 'Enter an amount',
            suffixText: state.from.code,
            errorText: state.amountError,
          ),
          onChanged: model.setAmount,
        ),
        const SizedBox(height: 20),
        CurrencyDropdown(
          label: 'From',
          value: state.from,
          onChanged: model.setFrom,
        ),
        Center(
          child: IconButton.filledTonal(
            onPressed: model.swap,
            tooltip: 'Swap currencies',
            icon: const Icon(Icons.swap_vert),
          ),
        ),
        CurrencyDropdown(label: 'To', value: state.to, onChanged: model.setTo),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // keep the result title and refresh action on one line
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Conversion',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: state.status == ConversionStatus.loading
                          ? null
                          : model.refresh,
                      tooltip: 'Refresh rate',
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // show loading error or result content for the current request
                if (state.status == ConversionStatus.loading)
                  Semantics(
                    label: 'Fetching exchange rate',
                    child: const LinearProgressIndicator(),
                  )
                else if (state.status == ConversionStatus.error) ...[
                  Semantics(liveRegion: true, child: Text(state.error!)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: model.refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ] else ...[
                  if (result != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        '${result.toStringAsFixed(state.to.decimals)} ${state.to.code}',
                        key: const Key('conversionResult'),
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    )
                  else
                    Text(
                      state.amountError == null
                          ? 'Enter an amount'
                          : 'Check the amount above.',
                    ),
                  if (quote != null) ...[
                    const SizedBox(height: 10),
                    // combine the rate and date into one compact line
                    Text(
                      state.from == state.to
                          ? 'No exchange needed'
                          : '1 ${state.from.code} = ${quote.rate.toStringAsFixed(6)} ${state.to.code} · ${formatUsDate(quote.date)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (result != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        // prefill the form with the amount the user entered
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ExpenseForm(
                              initialAmount: state.amount.trim(),
                              initialCurrency: state.from,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add as expense'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Frankfurter rates may vary from your bank.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
