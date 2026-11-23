import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/currency.dart';

// store one recurring monthly limit in usd cents
abstract interface class BudgetRepository {
  // stream the recurring monthly budget
  Stream<int?> watch();
  // stream the default currency for new expenses
  Stream<Currency> watchPreferredCurrency();
  // stream account-only custom expense categories
  Stream<List<String>> watchCustomCategories();
  // save the budget without replacing other settings
  Future<void> save(int amountMinor);
  // save the currency without replacing the budget
  Future<void> savePreferredCurrency(Currency currency);
  // save custom categories without replacing other settings
  Future<void> saveCustomCategories(List<String> categories);
  // import a guest budget only when no account budget exists
  Future<int> saveIfUnset(int amountMinor);
}

class FirestoreBudgetRepository implements BudgetRepository {
  // keep both settings in one private account document
  FirestoreBudgetRepository(String userId, {FirebaseFirestore? firestore})
    : _document = (firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('preferences');
  final DocumentReference<Map<String, dynamic>> _document;

  @override
  // watch cloud budget changes from other sessions
  Stream<int?> watch() => _document.snapshots().map(
    (snapshot) => snapshot.data()?['monthlyBudgetMinor'] as int?,
  );

  @override
  // use usd when an older settings document has no preference yet
  Stream<Currency> watchPreferredCurrency() =>
      _document.snapshots().map((snapshot) {
        final code = snapshot.data()?['preferredEntryCurrency'] as String?;
        for (final currency in Currency.values) {
          if (currency.code == code) return currency;
        }
        return Currency.usd;
      });

  @override
  // use an empty list for older settings documents
  Stream<List<String>> watchCustomCategories() =>
      _document.snapshots().map((snapshot) {
        final values = snapshot.data()?['customCategories'];
        if (values is! List) return const [];
        return values.whereType<String>().toList(growable: false);
      });

  Map<String, dynamic> _fields(int amountMinor) => {
    'monthlyBudgetMinor': amountMinor,
    'reportingCurrency': 'USD',
    'updatedAt': FieldValue.serverTimestamp(),
  };
  @override
  Future<void> save(int amountMinor) =>
      _document.set(_fields(amountMinor), SetOptions(merge: true));

  @override
  // merge the preference without replacing the saved budget
  Future<void> savePreferredCurrency(Currency currency) => _document.set({
    'preferredEntryCurrency': currency.code,
    'reportingCurrency': 'USD',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  @override
  Future<void> saveCustomCategories(List<String> categories) => _document.set({
    'customCategories': categories,
    'reportingCurrency': 'USD',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  @override
  // keep an existing account budget when importing a guest budget
  Future<int> saveIfUnset(int amountMinor) =>
      _document.firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(_document);
        final existing = snapshot.data()?['monthlyBudgetMinor'] as int?;
        if (existing != null) return existing;
        transaction.set(
          _document,
          _fields(amountMinor),
          SetOptions(merge: true),
        );
        return amountMinor;
      });
}

// keep guest settings in memory for the current session
class MemoryBudgetRepository implements BudgetRepository {
  // keep guest values only for the current app session
  int? amountMinor;
  Currency preferredCurrency = Currency.usd;
  List<String> customCategories = const [];
  final _listeners = <MultiStreamController<int?>>{};
  final _currencyListeners = <MultiStreamController<Currency>>{};
  final _categoryListeners = <MultiStreamController<List<String>>>{};
  @override
  // send the current guest budget to each new listener
  Stream<int?> watch() => Stream.multi((listener) {
    _listeners.add(listener);
    listener.add(amountMinor);
    listener.onCancel = () => _listeners.remove(listener);
  });
  @override
  // update all screens that use the guest budget
  Future<void> save(int amountMinor) async {
    this.amountMinor = amountMinor;
    for (final listener in _listeners) {
      listener.add(amountMinor);
    }
  }

  @override
  // notify open forms when the guest preference changes
  Stream<Currency> watchPreferredCurrency() => Stream.multi((listener) {
    _currencyListeners.add(listener);
    listener.add(preferredCurrency);
    listener.onCancel = () => _currencyListeners.remove(listener);
  });

  @override
  Future<void> savePreferredCurrency(Currency currency) async {
    preferredCurrency = currency;
    for (final listener in _currencyListeners) {
      listener.add(currency);
    }
  }

  @override
  // send the current category list to each new listener
  Stream<List<String>> watchCustomCategories() => Stream.multi((listener) {
    _categoryListeners.add(listener);
    listener.add(customCategories);
    listener.onCancel = () => _categoryListeners.remove(listener);
  });

  @override
  // notify open screens after an in memory update
  Future<void> saveCustomCategories(List<String> categories) async {
    customCategories = List.unmodifiable(categories);
    for (final listener in _categoryListeners) {
      listener.add(customCategories);
    }
  }

  @override
  // preserve an existing value during guest transfer
  Future<int> saveIfUnset(int amountMinor) async {
    if (this.amountMinor == null) await save(amountMinor);
    return this.amountMinor!;
  }
}
