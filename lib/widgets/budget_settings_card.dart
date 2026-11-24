import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/money.dart';
import '../l10n/app_localizations.dart';
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
    final text = context.l10n;
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
              Text(
                text.text('settings.budget'),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(text.text('settings.budgetHelp')),
              const SizedBox(height: 16),
              if (state.loading)
                LinearProgressIndicator(
                  semanticsLabel: text.text('settings.loadingBudget'),
                ),
              if (state.loadError != null) ...[
                Text(text.message(state.loadError!)),
                TextButton(
                  onPressed: _model.reload,
                  child: Text(text.text('settings.retryBudgetLoad')),
                ),
              ] else ...[
                Text(
                  state.amountMinor == null
                      ? text.text('settings.noBudget')
                      : text.text('settings.currentBudget', {
                          'amount': formatMinor(
                            state.amountMinor!,
                            Currency.usd,
                          ),
                        }),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('monthlyBudget'),
                  controller: _amount,
                  enabled: !disabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: text.text('settings.budgetAmount'),
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
                        ? text.text('settings.savingBudget')
                        : text.text('settings.saveBudget'),
                  ),
                ),
              ],
              if (state.transferring)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(text.text('settings.guestBudgetSaving')),
                ),
              if (state.transferError != null) ...[
                Text(text.message(state.transferError!)),
                TextButton(
                  onPressed: _model.retryTransfer,
                  child: Text(text.text('settings.retryBudgetTransfer')),
                ),
              ],
              if (state.saveError != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      text.message(state.saveError!),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: disabled ? null : _save,
                    child: Text(text.text('settings.retryBudgetSave')),
                  ),
                ),
              ],
              if (state.message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(text.message(state.message!)),
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
