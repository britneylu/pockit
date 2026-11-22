import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';
import 'expense_repository.dart';

// every operation is scoped to the signed-in account, never a shared collection
class FirestoreExpenseRepository implements ExpenseRepository {
  FirestoreExpenseRepository({
    required String userId,
    FirebaseFirestore? firestore,
  }) : _collection = (firestore ?? FirebaseFirestore.instance)
           .collection('users')
           .doc(userId)
           .collection('expenses');
  final CollectionReference<Map<String, dynamic>> _collection;
  @override
  String newId() => _collection.doc().id;

  // store dates as timestamps and let the server set the update time
  static Map<String, dynamic> encode(Expense expense) => {
    ...expense.toJson()
      ..remove('id')
      ..remove('date')
      ..remove('rateDate'),
    'expenseDate': Timestamp.fromDate(expense.date),
    'rateDate': Timestamp.fromDate(expense.rateDate),
    'updatedAt': FieldValue.serverTimestamp(),
  };
  // restore the expense model using the document id
  static Expense decode(String id, Map<String, dynamic> data) =>
      Expense.fromJson({
        ...data,
        'id': id,
        'date': (data['expenseDate'] as Timestamp).toDate().toIso8601String(),
        'rateDate': (data['rateDate'] as Timestamp).toDate().toIso8601String(),
      });
  @override
  // turn live firestore snapshots into expense lists
  Stream<List<Expense>> watch() => _collection.snapshots().map((snapshot) {
    final legacy = snapshot.docs
        .where((doc) => doc.data()['category'] == 'Food')
        .toList();
    if (legacy.isNotEmpty) unawaited(_migrateFood(legacy));
    return snapshot.docs.map((doc) => decode(doc.id, doc.data())).toList();
  });

  // update legacy cloud records after displaying them as dining
  Future<void> _migrateFood(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) async {
    try {
      await Future.wait(
        documents.map(
          (doc) => doc.reference.update({
            'category': 'Dining',
            'updatedAt': FieldValue.serverTimestamp(),
          }),
        ),
      );
    } on FirebaseException {
      // keep the local normalized value when migration must retry later
    }
  }

  @override
  // write one document without replacing other expenses
  Future<void> upsert(Expense expense) =>
      _collection.doc(expense.id).set(encode(expense));
  @override
  Future<void> delete(String id) => _collection.doc(id).delete();
}
