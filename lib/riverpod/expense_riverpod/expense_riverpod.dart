
import 'package:expense_tracker_app/database/db_connection.dart';
import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:flutter_riverpod/legacy.dart';

final expenseProvider = StateNotifierProvider<ExpenseNotifier,ExpenseState>((ref)=>ExpenseNotifier());

class ExpenseState{
  final List<ExpenseModel> expenses;
  final List<ExpenseModel> filteredRecord;
  final bool isLoading;
  final bool hasMore;
  final int offset;

  ExpenseState({
    this.expenses = const [],
    this.filteredRecord = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.offset = 0
  });

  ExpenseState copyWith({
    List<ExpenseModel>? expenses,
    List<ExpenseModel>? filteredRecord,
    bool? isLoading,
    bool? hasMore,
    int? offset
  }){
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      filteredRecord: filteredRecord ?? this.filteredRecord,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset
    );
  }
}

class ExpenseNotifier extends StateNotifier<ExpenseState>{

  final DatabaseConnection databaseConnection = DatabaseConnection();

  ExpenseNotifier() : super(ExpenseState());

  final _limit = 10;

  Future<void> getExpenses()async{
    if(state.isLoading || !state.hasMore){
      return;
    }
    state = state.copyWith(isLoading: true);

    List<ExpenseModel> newExpenses = await databaseConnection.getAllExpenses(limit: _limit,offset: state.offset);

    state = state.copyWith(
      expenses: [...state.expenses,...newExpenses],
      offset: state.offset + _limit,
      hasMore: newExpenses.length == _limit,
      isLoading: false
    );
  }

  Future<void> insertExpense(ExpenseModel expense)async{

    int id = await databaseConnection.insertExpense(expense);

    final newExpense = ExpenseModel(
        id: id,
        title: expense.title,
        amount: expense.amount,
        category: expense.category,
        date: expense.date
    );

    state = state.copyWith(expenses: [newExpense,...state.expenses]);
    _autoFilter();
  }

  void _autoFilter() {
    final selectedMonth = DateTime.now();
    final filtered = state.expenses.where((item) {
      final expenseDate = DateTime.parse(item.date);
      return expenseDate.year == selectedMonth.year &&
          expenseDate.month == selectedMonth.month;
    }).toList();

    state = state.copyWith(filteredRecord: filtered);
  }


  Future<void> updateExpense(ExpenseModel expense)async{
    await databaseConnection.updateExpenses(expense);

    state = state.copyWith(
      expenses: state.expenses.map((e)=>e.id==expense.id? expense : e).toList()
    );
    _autoFilter();
  }

  Future<void> deleteExpense(int id)async{
    await databaseConnection.deleteExpenses(id);
    state = state.copyWith(
      expenses: state.expenses.where((e)=>e.id!=id).toList()
    );
    _autoFilter();
  }

  void filterRecordsByMonth(DateTime selectedTime) {
    final filtered = state.expenses.where((item) {
      final expenseDate = DateTime.parse(item.date);
      return expenseDate.year == selectedTime.year &&
          expenseDate.month == selectedTime.month;
    }).toList();

    state = state.copyWith(filteredRecord: filtered);
  }
}