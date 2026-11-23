import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/money.dart';
import '../models/currency.dart';
import '../models/expense.dart';
import '../models/expense_date_group.dart';
import '../models/exchange_rate.dart';
import '../repositories/expense_repository.dart';
import '../services/currency_service.dart';

// expose expenses and status through a read only state snapshot
@immutable
class ExpensesState {
  ExpensesState({
    List<Expense> expenses = const [],
    DateTime? month,
    this.loading = false,
    this.saving = false,
    this.error,
    this.filter,
    this.saveError,
  }) : expenses = List.unmodifiable(expenses),
       _month = DateTime(
         (month ?? DateTime.now()).year,
         (month ?? DateTime.now()).month,
       );
  final List<Expense> expenses;
  final DateTime? _month;
  final bool loading;
  final bool saving;
  final String? error;
  final String? saveError;
  final String? filter;
  // recover old state objects kept alive by hot reload
  DateTime get month {
    final value = _month;
    final now = DateTime.now();
    return value ?? DateTime(now.year, now.month);
  }

  // limit purchases to the selected month
  List<Expense> get monthly => List.unmodifiable(
    expenses.where(
      (expense) =>
          expense.date.year == month.year && expense.date.month == month.month,
    ),
  );
  // apply the category filter without changing stored expenses
  List<Expense> get visible => List.unmodifiable(
    monthly.where((e) => filter == null || e.category == filter),
  );
  // group after filtering and order dates newest first
  List<ExpenseDateGroup> get dateGroups {
    final ordered = [...visible]
      ..sort((a, b) {
        final order = b.date.compareTo(a.date);
        return order == 0 ? b.id.compareTo(a.id) : order;
      });
    final groups = <DateTime, List<Expense>>{};
    for (final expense in ordered) {
      final date = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      groups.putIfAbsent(date, () => []).add(expense);
    }
    return List.unmodifiable(
      groups.entries.map(
        (entry) => ExpenseDateGroup(date: entry.key, expenses: entry.value),
      ),
    );
  }
}

// coordinate expense validation conversion and storage
class ExpensesViewModel extends ChangeNotifier {
  ExpensesViewModel(
    this._repository,
    this._currencyService, {
    List<String> Function()? customCategories,
  }) : _customCategories = customCategories ?? (() => const []);
  final ExpenseRepository _repository;
  final CurrencyService _currencyService;
  // read current categories without rebuilding the expense model
  final List<String> Function() _customCategories;
  ExpensesState _state = ExpensesState(loading: true);
  StreamSubscription<List<Expense>>? _subscription;
  int _generation = 0;
  ExpensesState get state => _state;
  bool _disposed = false;
  // replace the state snapshot and notify listening widgets
  void _emit({
    List<Expense>? expenses,
    bool loading = false,
    bool saving = false,
    String? error,
    String? saveError,
  }) {
    if (_disposed) return;
    _state = ExpensesState(
      expenses: expenses ?? _state.expenses,
      loading: loading,
      saving: saving,
      error: error,
      saveError: saveError,
      filter: _state.filter,
      month: _state.month,
    );
    notifyListeners();
  }

  // replace the expense listener and wait for its first result
  Future<void> load() async {
    if (_state.saving || _disposed) return;
    // ignore events from an older subscription
    final generation = ++_generation;
    // start the replacement stream without waiting for the old listener
    unawaited(_subscription?.cancel());
    if (_disposed || generation != _generation) return;
    _emit(loading: true);
    final first = Completer<void>();
    _subscription = _repository.watch().listen(
      (values) {
        if (_disposed || generation != _generation) return;
        // show the newest purchases first
        final expenses = [...values]..sort((a, b) => b.date.compareTo(a.date));
        _emit(
          expenses: expenses,
          saving: _state.saving,
          saveError: _state.saveError,
        );
        if (!first.isCompleted) first.complete();
      },
      onError: (Object error) {
        if (_disposed || generation != _generation) return;
        _emit(
          saving: _state.saving,
          error: 'Couldn’t load cloud expenses. Check your connection and Firestore access rules, then retry.',
        );
        if (!first.isCompleted) first.complete();
      },
      onDone: () {
        if (!first.isCompleted) first.complete();
      },
    );
    return first.future;
  }

  // update the visible category while keeping the current data
  void setFilter(String? category) {
    _state = ExpensesState(
      expenses: _state.expenses,
      loading: _state.loading,
      saving: _state.saving,
      error: _state.error,
      saveError: _state.saveError,
      filter: category,
      month: _state.month,
    );
    notifyListeners();
  }

  // move to the previous calendar month
  void previousMonth() =>
      selectMonth(DateTime(_state.month.year, _state.month.month - 1));

  // move to the next calendar month
  void nextMonth() =>
      selectMonth(DateTime(_state.month.year, _state.month.month + 1));

  // return to the current calendar month
  void currentMonth() => selectMonth(DateTime.now());

  // update the visible month without reloading stored expenses
  void selectMonth(DateTime month) {
    _state = ExpensesState(
      expenses: _state.expenses,
      month: month,
      loading: _state.loading,
      saving: _state.saving,
      error: _state.error,
      saveError: _state.saveError,
      filter: _state.filter,
    );
    notifyListeners();
  }

  // validate and save a new or edited expense
  Future<bool> saveExpense({
    Expense? original,
    required String amount,
    required Currency currency,
    required String category,
    required String description,
    required DateTime date,
  }) async {
    if (_state.saving || _state.loading || _state.error != null) return false;
    _emit(saving: true);
    try {
      final minor = parseMinor(amount, currency);
      // keep removed custom categories valid on their original expenses
      final allowed =
          expenseCategories.contains(category) ||
          _customCategories().contains(category) ||
          original?.category == category;
      if (!allowed) {
        throw const FormatException('Choose a category.');
      }
      final today = DateTime.now();
      if (date.isAfter(DateTime(today.year, today.month, today.day))) {
        throw const FormatException('Choose today or an earlier date.');
      }
      // keep the saved conversion when only descriptive fields change
      final preserve =
          original != null &&
          original.amountMinor == minor &&
          original.currency == currency &&
          original.date == date;
      // reuse the saved rate or fetch a fresh conversion into usd
      final quote = preserve
          ? ExchangeRate(rate: original.exchangeRate, date: original.rateDate)
          : currency == Currency.usd
          ? ExchangeRate(rate: 1, date: date)
          : await _currencyService.fetchRate(currency, Currency.usd);
      final expense = Expense(
        id: original?.id ?? _repository.newId(),
        amountMinor: minor,
        currency: currency,
        amountUsdMinor: preserve
            ? original.amountUsdMinor
            : convertToUsdMinor(minor, currency, quote.rate),
        exchangeRate: quote.rate,
        rateDate: quote.date,
        category: category,
        description: description.trim(),
        date: date,
      );
      if (_disposed) return false;
      // wait for the expense write to finish before reporting success
      await _repository.upsert(expense);
      if (_disposed) return false;
      _emit();
      return true;
    } on FormatException catch (error) {
      _emit(saveError: error.message);
    } catch (_) {
      _emit(
        saveError: 'Couldn’t save this expense. Check your connection or device storage and retry. Your changes are still here.',
      );
    }
    return false;
  }

  String? get lastSaveError => _state.saveError;
  Future<bool> delete(Expense expense) => _change(expense, restore: false);
  Future<bool> restore(Expense expense) => _change(expense, restore: true);
  // delete or restore an expense while preventing overlapping writes
  Future<bool> _change(Expense expense, {required bool restore}) async {
    if (_state.loading || _state.saving || _state.error != null) return false;
    _emit(saving: true);
    try {
      if (restore) {
        await _repository.upsert(expense);
      } else {
        await _repository.delete(expense.id);
      }
      if (_disposed) return false;
      _emit();
      return true;
    } catch (_) {
      _emit();
      return false;
    }
  }

  @override
  // cancel cloud updates when the account workspace closes
  void dispose() {
    _disposed = true;
    _generation++;
    _subscription?.cancel();
    super.dispose();
  }
}
