
import 'package:expense_tracker_app/database/db_connection.dart';
import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final totalExpenseProvider = StateProvider<double>((ref)=>0);
final totalIncomeProvider = StateProvider<double>((ref)=>0);
final totalMoneyProvider = StateProvider<double>((ref)=>0);

final expenseProvider = StateNotifierProvider<ExpenseNotifier,ExpenseState>((ref)=>ExpenseNotifier(ref));

class ExpenseState{
  final List<ExpenseModel> expenses;
  final List<ExpenseModel> filteredRecord;
  final bool isLoading;
  final bool hasMore;
  final int offset;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;

  ExpenseState({
    this.expenses = const [],
    this.filteredRecord = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.offset = 0,
    DateTime? selectedDate,
    TimeOfDay? selectedTime
  }):selectedDate = selectedDate ?? DateTime.now(),
     selectedTime = selectedTime ?? TimeOfDay.now();

  ExpenseState copyWith({
    List<ExpenseModel>? expenses,
    List<ExpenseModel>? filteredRecord,
    bool? isLoading,
    bool? hasMore,
    int? offset,
    DateTime? selectedDate,
    TimeOfDay? selectedTime
  }){
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      filteredRecord: filteredRecord ?? this.filteredRecord,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime
    );
  }
}

class ExpenseNotifier extends StateNotifier<ExpenseState>{

  final DatabaseConnection databaseConnection = DatabaseConnection();

  final Ref _ref;

  ExpenseNotifier(this._ref) : super(ExpenseState());

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

    filterRecordsByMonth(state.selectedDate!, state.selectedTime!);

  }

  Future<void> insertExpense(ExpenseModel expense)async{

    int id = await databaseConnection.insertExpense(expense);

    final newExpense = ExpenseModel(
        id: id,
        title: expense.title,
        amount: expense.amount,
        category: expense.category,
        date: expense.date,
        time: expense.time,
        moneyType: expense.moneyType,
        accountId: expense.accountId
    );

    state = state.copyWith(expenses: [newExpense,...state.expenses]);
    if (state.selectedDate != null && state.selectedTime!=null) {
      filterRecordsByMonth(expense.date,expense.time);
    }
  }


  Future<void> updateExpense(ExpenseModel expense)async{
    await databaseConnection.updateExpenses(expense);

    state = state.copyWith(
      expenses: state.expenses.map((e)=>e.id==expense.id? expense : e).toList()
    );
    if (state.selectedDate != null && state.selectedTime!=null) {
      filterRecordsByMonth(expense.date,expense.time);
    }
  }

  Future<void> deleteExpense(int id)async{
    await databaseConnection.deleteExpenses(id);
    state = state.copyWith(
      expenses: state.expenses.where((e)=>e.id!=id).toList()
    );
    if (state.selectedDate != null && state.selectedTime!=null) {
      filterRecordsByMonth(state.selectedDate!,state.selectedTime!);
    }
  }

  void filterRecordsByMonth(DateTime selectedDate, TimeOfDay selectedTime) {
    final filtered = state.expenses.where((item) {
      final expenseDate = item.date;
      return expenseDate.year == selectedDate.year && expenseDate.month == selectedDate.month;
    }).toList();

    state = state.copyWith(
      selectedDate: selectedDate,
      filteredRecord: filtered,
    );
    _calculateTotals();
  }

  void _calculateTotals(){
    double totalExpense = 0;
    double totalIncome = 0;

    for(var exp in state.filteredRecord){
      switch(exp.moneyType){
        case MoneyType.expense:
          totalExpense+=exp.amount;
        case MoneyType.income:
          totalIncome+=exp.amount;
      }
    }
    _ref.read(totalExpenseProvider.notifier).state = totalExpense;
    _ref.read(totalIncomeProvider.notifier).state = totalIncome;

    _ref.read(totalMoneyProvider.notifier).state = (totalIncome-totalExpense);
  }

  Future<void> refreshExpenses() async {
    state = state.copyWith(
      expenses: [],
      filteredRecord: [],
      offset: 0,
      hasMore: true,
    );
    await getExpenses();
  }
}