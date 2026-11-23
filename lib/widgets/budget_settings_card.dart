import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/money.dart';
import '../models/currency.dart';
import '../viewmodels/budget_viewmodel.dart';

// edit the recurring monthly usd limit without changing expense amounts
class BudgetSettingsCard extends StatefulWidget {
  const BudgetSettingsCard({super.key, required this.guest});
  final bool guest;
  @override
  State<BudgetSettingsCard> createState() => _BudgetSettingsCardState();
}

class _BudgetSettingsCardState extends State<BudgetSettingsCard> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  late BudgetViewModel _model;
  bool _dirty = false;
  int? _lastAmount;
  @override
  void initState() {
    super.initState();
    _model = context.read<BudgetViewModel>();
    _model.addListener(_syncAmount);
    _syncAmount();
  }

  // apply loaded values without replacing an unfinished edit
  void _syncAmount() {
    final amount = _model.state.amountMinor;
    if (!_dirty && amount != _lastAmount) {
      _amount.text = amount == null ? '' : formatMinor(amount, Currency.usd);
      _lastAmount = amount;
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final success = await _model.save(_amount.text);
    if (!mounted) return;
    if (success) {
      _dirty = false;
      _syncAmount();
    }
  }

  @override
  void dispose() {
    _model.removeListener(_syncAmount);
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetViewModel>().state;
    final theme = Theme.of(context);
    final disabled =
        state.loading ||
        state.saving ||
        state.transferring ||
        state.loadError != null ||
        state.transferError != null;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Monthly budget', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Set a monthly spending limit in USD.'),
              const SizedBox(height: 16),
              if (state.loading)
                const LinearProgressIndicator(semanticsLabel: 'Loading budget'),
              if (state.loadError != null) ...[
                Text(state.loadError!),
                TextButton(
                  onPressed: _model.reload,
                  child: const Text('Retry loading budget'),
                ),
              ] else ...[
                Text(
                  state.amountMinor == null
                      ? 'No budget yet'
                      : 'Current budget: ${formatMinor(state.amountMinor!, Currency.usd)} USD',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('monthlyBudget'),
                  controller: _amount,
                  enabled: !disabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Budget amount',
                    prefixText: '\$ ',
                    suffixText: 'USD',
                    hintText: '1200.00',
                  ),
                  onChanged: (_) => _dirty = true,
                  validator: (value) {
                    try {
                      parseMinor(value ?? '', Currency.usd);
                      return null;
                    } on FormatException catch (error) {
                      return error.message;
                    }
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: disabled ? null : _save,
                  icon: const Icon(Icons.savings_outlined),
                  label: Text(
                    state.saving
                        ? 'Saving… connection required'
                        : 'Save budget',
                  ),
                ),
              ],
              if (state.transferring)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('Saving your guest budget to this account…'),
                ),
              if (state.transferError != null) ...[
                Text(state.transferError!),
                TextButton(
                  onPressed: _model.retryTransfer,
                  child: const Text('Retry budget transfer'),
                ),
              ],
              if (state.saveError != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      state.saveError!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: disabled ? null : _save,
                    child: const Text('Retry saving budget'),
                  ),
                ),
              ],
              if (state.message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(state.message!),
                  ),
                ),
              // only guests need an extra storage reminder
              if (widget.guest) ...[
                const SizedBox(height: 12),
                Text(
                  'Transfers when you sign in unless the account already has a budget.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
