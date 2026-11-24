import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/money.dart';
import '../l10n/app_localizations.dart';
import '../models/currency.dart';
import '../models/expense.dart';
import '../viewmodels/budget_viewmodel.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../widgets/category_dropdown.dart';
import '../widgets/currency_dropdown.dart';

// use the same form to add and edit expenses
class ExpenseForm extends StatefulWidget {
  const ExpenseForm({
    super.key,
    this.expense,
    this.initialAmount,
    this.initialCurrency,
  });
  final Expense? expense;
  final String? initialAmount;
  final Currency? initialCurrency;
  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _description;
  late Currency _currency;
  late String _category;
  late DateTime _date;
  String? _error;
  @override
  // prefill saved values when editing an expense
  void initState() {
    super.initState();
    final expense = widget.expense;
    // keep an existing currency or use the saved preference for new entries
    _currency =
        expense?.currency ??
        widget.initialCurrency ??
        context.read<BudgetViewModel>().state.preferredCurrency;
    // normalize old food expenses before opening the category menu
    _category = normalizeExpenseCategory(expense?.category ?? 'Dining');
    _date = expense?.date ?? DateUtils.dateOnly(DateTime.now());
    _amount = TextEditingController(
      text: expense == null
          ? widget.initialAmount ?? ''
          : formatMinor(expense.amountMinor, expense.currency),
    );
    _description = TextEditingController(text: expense?.description ?? '');
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  // validate inputs and let the viewmodel handle conversion and storage
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _error = null);
    final model = context.read<ExpensesViewModel>();
    final success = await model.saveExpense(
      original: widget.expense,
      amount: _amount.text,
      currency: _currency,
      category: _category,
      description: _description.text,
      date: _date,
    );
    // avoid updating the form after it has closed
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(
        () => _error =
            model.lastSaveError ?? context.l10n.text('expenseForm.saveError'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // disable inputs while the expense is being saved
    final saving = context.watch<ExpensesViewModel>().state.saving;
    // update the menu when account categories change
    final customCategories = context
        .watch<BudgetViewModel>()
        .state
        .customCategories;
    final text = context.l10n;
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text.text(
              widget.expense == null ? 'addExpense' : 'expenseForm.edit',
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    TextFormField(
                      key: const Key('expenseAmount'),
                      controller: _amount,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: text.text('expenseForm.amount'),
                      ),
                      validator: (value) {
                        try {
                          parseMinor(value ?? '', _currency);
                          return null;
                        } on FormatException catch (error) {
                          return error.message;
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    CurrencyDropdown(
                      fieldKey: const Key('expenseCurrency'),
                      label: text.text('expenseForm.currency'),
                      value: _currency,
                      onChanged: saving
                          ? null
                          : (value) => setState(() => _currency = value),
                    ),
                    const SizedBox(height: 16),
                    CategoryDropdown(
                      fieldKey: const Key('expenseCategory'),
                      value: _category,
                      // preserve a removed category while editing its expense
                      additionalCategories: [
                        ...customCategories,
                        if (!expenseCategories.contains(_category)) _category,
                      ],
                      onChanged: saving
                          ? null
                          : (value) => setState(() => _category = value),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        text.text('expenseForm.date', {
                          'date': text.date(_date),
                        }),
                      ),
                      onPressed: saving
                          ? null
                          : () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (date != null && mounted) {
                                setState(() => _date = date);
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _description,
                      enabled: !saving,
                      maxLength: 200,
                      decoration: InputDecoration(
                        labelText: text.text('expenseForm.description'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(text.text('expenseForm.rateHelp')),
                    if (widget.expense != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        text.text('expenseForm.savedRate', {
                          'amount': formatMinor(
                            widget.expense!.amountUsdMinor,
                            Currency.usd,
                          ),
                          'date': text.date(widget.expense!.rateDate),
                        }),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          text.message(_error!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: saving ? null : _save,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        text.text(
                          saving ? 'expenseForm.saving' : 'expenseForm.save',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
