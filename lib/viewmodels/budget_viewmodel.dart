import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/money.dart';
import '../models/currency.dart';
import '../models/expense.dart';
import '../repositories/budget_repository.dart';
import 'auth_viewmodel.dart';

const _keep = Object();

// expose budget values and async feedback without mutable fields
@immutable
class BudgetState {
  const BudgetState({
    this.amountMinor,
    this._preferredCurrency = Currency.usd,
    this.loading = true,
    this.saving = false,
    this._currencyLoading = true,
    this._currencySaving = false,
    this._customCategories = const [],
    this._categoryLoading = true,
    this._categorySaving = false,
    this.transferring = false,
    this.loadError,
    this.saveError,
    this.currencyLoadError,
    this.currencySaveError,
    this.categoryLoadError,
    this.categorySaveError,
    this.transferError,
    this.message,
    this.currencyMessage,
    this.categoryMessage,
  });
  // budget fields use their own loading and saving status
  final int? amountMinor;
  final Currency? _preferredCurrency;
  final bool loading;
  final bool saving;
  // currency fields load and save independently from the budget
  final bool? _currencyLoading;
  final bool? _currencySaving;
  // category fields load and save independently from other settings
  final List<String>? _customCategories;
  final bool? _categoryLoading;
  final bool? _categorySaving;
  final bool transferring;
  final String? loadError;
  final String? saveError;
  final String? currencyLoadError;
  final String? currencySaveError;
  final String? categoryLoadError;
  final String? categorySaveError;
  final String? transferError;
  final String? message;
  final String? currencyMessage;
  final String? categoryMessage;
  // recover older state objects that remain alive after hot reload
  Currency get preferredCurrency => _preferredCurrency ?? Currency.usd;
  bool get currencyLoading => _currencyLoading ?? true;
  bool get currencySaving => _currencySaving ?? false;
  List<String> get customCategories => _customCategories ?? const [];
  bool get categoryLoading => _categoryLoading ?? true;
  bool get categorySaving => _categorySaving ?? false;
  // create a new snapshot while preserving unchanged values
  BudgetState copyWith({
    Object? amountMinor = _keep,
    Currency? preferredCurrency,
    bool? loading,
    bool? saving,
    bool? currencyLoading,
    bool? currencySaving,
    List<String>? customCategories,
    bool? categoryLoading,
    bool? categorySaving,
    bool? transferring,
    Object? loadError = _keep,
    Object? saveError = _keep,
    Object? currencyLoadError = _keep,
    Object? currencySaveError = _keep,
    Object? categoryLoadError = _keep,
    Object? categorySaveError = _keep,
    Object? transferError = _keep,
    Object? message = _keep,
    Object? currencyMessage = _keep,
    Object? categoryMessage = _keep,
  }) => BudgetState(
    amountMinor: identical(amountMinor, _keep)
        ? this.amountMinor
        : amountMinor as int?,
    preferredCurrency: preferredCurrency ?? this.preferredCurrency,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    currencyLoading: currencyLoading ?? this.currencyLoading,
    currencySaving: currencySaving ?? this.currencySaving,
    customCategories: customCategories ?? this.customCategories,
    categoryLoading: categoryLoading ?? this.categoryLoading,
    categorySaving: categorySaving ?? this.categorySaving,
    transferring: transferring ?? this.transferring,
    loadError: identical(loadError, _keep)
        ? this.loadError
        : loadError as String?,
    saveError: identical(saveError, _keep)
        ? this.saveError
        : saveError as String?,
    currencyLoadError: identical(currencyLoadError, _keep)
        ? this.currencyLoadError
        : currencyLoadError as String?,
    currencySaveError: identical(currencySaveError, _keep)
        ? this.currencySaveError
        : currencySaveError as String?,
    categoryLoadError: identical(categoryLoadError, _keep)
        ? this.categoryLoadError
        : categoryLoadError as String?,
    categorySaveError: identical(categorySaveError, _keep)
        ? this.categorySaveError
        : categorySaveError as String?,
    transferError: identical(transferError, _keep)
        ? this.transferError
        : transferError as String?,
    message: identical(message, _keep) ? this.message : message as String?,
    currencyMessage: identical(currencyMessage, _keep)
        ? this.currencyMessage
        : currencyMessage as String?,
    categoryMessage: identical(categoryMessage, _keep)
        ? this.categoryMessage
        : categoryMessage as String?,
  );
}

// manage the monthly limit and move guest settings into the signed in account
class BudgetViewModel extends ChangeNotifier {
  BudgetViewModel(this._auth, this._repositoryFor) {
    _auth.addListener(_accountChanged);
    _accountChanged();
  }
  final AuthViewModel _auth;
  final BudgetRepository Function(String) _repositoryFor;
  // hold guest budgets until the matching account can receive them
  final _pending = <String, int>{};
  // keep budget and currency updates independent
  StreamSubscription<int?>? _subscription;
  StreamSubscription<Currency>? _currencySubscription;
  StreamSubscription<List<String>>? _categorySubscription;
  late BudgetRepository _repository;
  BudgetState _state = const BudgetState();
  BudgetState get state => _state;
  String? _userId;
  bool _attached = false;
  bool _disposed = false;
  int _generation = 0;
  Currency? _pendingCurrency;
  List<String>? _pendingCategories;

  void _emit(BudgetState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  void _accountChanged() {
    final next = _auth.state.account?.id;
    if (_attached && next == _userId) return;
    // capture the guest value before replacing its repository
    if (_attached &&
        _userId == null &&
        next != null &&
        _state.amountMinor != null) {
      _pending[next] = _state.amountMinor!;
    }
    _userId = next;
    _attached = true;
    _repository = next == null
        ? MemoryBudgetRepository()
        : _repositoryFor(next);
    // discard retries that belong to the previous account
    _pendingCurrency = null;
    _pendingCategories = null;
    _state = const BudgetState();
    // avoid publishing state while an ancestor is still rebuilding
    final generation = ++_generation;
    scheduleMicrotask(() {
      if (!_disposed && generation == _generation) _listen(generation);
    });
  }

  Future<void> _listen(int generation) async {
    // ignore old events while cancellation finishes in the background
    unawaited(_subscription?.cancel());
    unawaited(_currencySubscription?.cancel());
    unawaited(_categorySubscription?.cancel());
    if (_disposed || generation != _generation) return;
    _emit(
      _state.copyWith(
        loading: true,
        currencyLoading: true,
        categoryLoading: true,
        loadError: null,
        currencyLoadError: null,
        categoryLoadError: null,
      ),
    );
    // listen to monthly budget changes
    _subscription = _repository.watch().listen(
      (amount) {
        if (_disposed || generation != _generation) return;
        _emit(
          _state.copyWith(amountMinor: amount, loading: false, loadError: null),
        );
      },
      onError: (Object error) {
        if (_disposed || generation != _generation) return;
        _emit(
          _state.copyWith(
            loading: false,
            loadError:
                'Couldn’t load your budget. Check your connection and retry.',
          ),
        );
      },
    );
    // listen to the preferred currency in the same settings document
    _currencySubscription = _repository.watchPreferredCurrency().listen(
      (currency) {
        if (_disposed || generation != _generation) return;
        _emit(
          _state.copyWith(
            preferredCurrency: currency,
            currencyLoading: false,
            currencyLoadError: null,
          ),
        );
      },
      onError: (Object error) {
        if (_disposed || generation != _generation) return;
        _emit(
          _state.copyWith(
            currencyLoading: false,
            currencyLoadError: 'Couldn’t load your preferred currency. Check your connection and retry.',
          ),
        );
      },
    );
    // listen to account-only custom categories
    _categorySubscription = _repository.watchCustomCategories().listen(
      (categories) {
        if (_disposed || generation != _generation) return;
        _emit(
          _state.copyWith(
            customCategories: List.unmodifiable(categories),
            categoryLoading: false,
            categoryLoadError: null,
          ),
        );
      },
      onError: (Object error) {
        if (_disposed || generation != _generation) return;
        _emit(
          _state.copyWith(
            categoryLoading: false,
            categoryLoadError: 'Couldn’t load custom categories. Check your connection and retry.',
          ),
        );
      },
    );
    await retryTransfer();
  }

  Future<void> reload() => _listen(++_generation);

  // validate and save a usd monthly budget
  Future<bool> save(String input) async {
    if (_disposed ||
        _state.loading ||
        _state.saving ||
        _state.transferring ||
        _state.loadError != null ||
        _state.transferError != null) {
      return false;
    }
    final generation = _generation;
    final repository = _repository;
    try {
      final amount = parseMinor(input, Currency.usd);
      _emit(_state.copyWith(saving: true, saveError: null, message: null));
      await repository.save(amount);
      if (_disposed || generation != _generation) return false;
      _emit(
        _state.copyWith(
          amountMinor: amount,
          saving: false,
          message: _userId == null
              ? 'Budget set for this session'
              : 'Monthly budget saved',
        ),
      );
      return true;
    } on FormatException catch (error) {
      if (!_disposed && generation == _generation) {
        _emit(
          _state.copyWith(
            saving: false,
            saveError: error.message,
            message: null,
          ),
        );
      }
    } catch (_) {
      if (!_disposed && generation == _generation) {
        _emit(
          _state.copyWith(
            saving: false,
            saveError:
                'Couldn’t save your budget. Check your connection and retry.',
            message: null,
          ),
        );
      }
    }
    return false;
  }

  // save the default currency used by new expense forms
  Future<bool> savePreferredCurrency(Currency currency) async {
    // block overlapping writes and writes after a load failure
    if (_disposed ||
        _state.currencyLoading ||
        _state.currencySaving ||
        _state.currencyLoadError != null) {
      return false;
    }
    final generation = _generation;
    final repository = _repository;
    _pendingCurrency = currency;
    // clear old feedback before starting the cloud write
    _emit(
      _state.copyWith(
        currencySaving: true,
        currencySaveError: null,
        currencyMessage: null,
      ),
    );
    try {
      await repository.savePreferredCurrency(currency);
      // ignore writes that finish after an account change
      if (_disposed || generation != _generation) return false;
      _emit(
        _state.copyWith(
          preferredCurrency: currency,
          currencySaving: false,
          currencyMessage: _userId == null
              ? 'Preferred currency set for this session'
              : 'Preferred currency saved',
        ),
      );
      _pendingCurrency = null;
      return true;
    } catch (_) {
      if (!_disposed && generation == _generation) {
        _emit(
          _state.copyWith(
            currencySaving: false,
            currencySaveError: 'Couldn’t save your preferred currency. Check your connection and retry.',
          ),
        );
      }
      return false;
    }
  }

  // retry the last currency choice after a failed write
  Future<bool> retryPreferredCurrency() {
    final currency = _pendingCurrency;
    return currency == null
        ? Future.value(false)
        : savePreferredCurrency(currency);
  }

  // validate and add one account-only category
  Future<bool> addCustomCategory(String input) async {
    if (_userId == null || _state.categoryLoading || _state.categorySaving) {
      return false;
    }
    final name = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    String? error;
    if (name.length < 2) {
      error = 'Use at least 2 characters.';
    } else if (name.length > 24) {
      error = 'Use 24 characters or fewer.';
    } else if (_state.customCategories.length >= 10) {
      error = 'You can add up to 10 custom categories.';
    } else {
      // compare names without case differences or legacy food labels
      final compare = normalizeExpenseCategory(name).toLowerCase();
      final names = [
        ...expenseCategories,
        ..._state.customCategories,
      ].map((category) => category.toLowerCase());
      if (names.contains(compare)) error = 'That category already exists.';
    }
    if (error != null) {
      _emit(_state.copyWith(categorySaveError: error, categoryMessage: null));
      return false;
    }
    return _saveCustomCategories([
      ..._state.customCategories,
      name,
    ], message: 'Category added');
  }

  // remove the choice without changing existing expenses
  Future<bool> removeCustomCategory(String category) => _saveCustomCategories(
    _state.customCategories.where((value) => value != category).toList(),
    message: 'Category removed',
  );

  Future<bool> _saveCustomCategories(
    List<String> categories, {
    required String message,
  }) async {
    if (_userId == null || _state.categoryLoading || _state.categorySaving) {
      return false;
    }
    final generation = _generation;
    final repository = _repository;
    _pendingCategories = List.unmodifiable(categories);
    // keep controls disabled until firestore confirms the write
    _emit(
      _state.copyWith(
        categorySaving: true,
        categorySaveError: null,
        categoryMessage: null,
      ),
    );
    try {
      await repository.saveCustomCategories(categories);
      // ignore a save completed for an older account
      if (_disposed || generation != _generation) return false;
      _emit(
        _state.copyWith(
          customCategories: List.unmodifiable(categories),
          categorySaving: false,
          categoryMessage: message,
        ),
      );
      _pendingCategories = null;
      return true;
    } catch (_) {
      if (!_disposed && generation == _generation) {
        _emit(
          _state.copyWith(
            categorySaving: false,
            categorySaveError:
                'Couldn’t save categories. Check your connection and retry.',
          ),
        );
      }
      return false;
    }
  }

  // retry the last category change after a failed write
  Future<bool> retryCustomCategories() {
    final categories = _pendingCategories;
    return categories == null
        ? Future.value(false)
        : _saveCustomCategories(categories, message: 'Categories saved');
  }

  Future<void> retryTransfer() async {
    final id = _userId;
    final amount = _pending[id];
    if (_disposed || id == null || amount == null || _state.transferring) {
      return;
    }
    final generation = _generation;
    final repository = _repository;
    _emit(_state.copyWith(transferring: true, transferError: null));
    try {
      final saved = await repository.saveIfUnset(amount);
      _pending.remove(id);
      if (_disposed || generation != _generation) return;
      _emit(
        _state.copyWith(
          amountMinor: saved,
          transferring: false,
          message: saved == amount
              ? 'Guest budget saved to your account'
              : 'Your existing account budget was kept',
        ),
      );
    } catch (_) {
      if (_disposed || generation != _generation) return;
      _emit(
        _state.copyWith(
          transferring: false,
          transferError: 'Couldn’t transfer your guest budget. Keep the app open and retry.',
        ),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _auth.removeListener(_accountChanged);
    _subscription?.cancel();
    _currencySubscription?.cancel();
    _categorySubscription?.cancel();
    super.dispose();
  }
}
