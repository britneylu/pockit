import 'expense.dart';

// keep purchases from the same calendar date together
class ExpenseDateGroup {
  ExpenseDateGroup({required this.date, required List<Expense> expenses})
    : expenses = List.unmodifiable(expenses);
  final DateTime date;
  final List<Expense> expenses;
}
