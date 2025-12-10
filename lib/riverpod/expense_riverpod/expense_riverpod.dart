
import 'package:expense_tracker_app/database/db_connection.dart';
import 'package:expense_tracker_app/models/budget_model.dart';
import 'package:expense_tracker_app/models/card_model.dart';
import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:expense_tracker_app/riverpod/budget_riverpod/budget_riverpod.dart';
import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

final totalExpenseProvider = StateProvider<double>((ref)=>0);
final totalIncomeProvider = StateProvider<double>((ref)=>0);
final totalMoneyProvider = StateProvider<double>((ref)=>0);

final expenseProvider = StateNotifierProvider<ExpenseNotifier,ExpenseState>((ref)=>ExpenseNotifier(ref));

class ExpenseState{

  final List<ExpenseModel> expenses;
  final List<ExpenseModel> filteredRecord;
  final List<ExpenseModel> searchRecords;
  final bool isLoading;
  final bool hasMore;
  final int offset;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final DateTime weekStart; 
  final DateTime weekEnd;
  final String activeFilter;

  ExpenseState({
    this.expenses = const [],
    this.filteredRecord = const [],
    this.searchRecords = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.offset = 0,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    DateTime? weekStart,  
    DateTime? weekEnd,
    this.activeFilter = 'monthly'
  }):selectedDate = selectedDate ?? DateTime.now(),
        selectedTime = selectedTime ?? TimeOfDay.now(),
        weekStart = weekStart ?? _getWeekStart(selectedDate),
        weekEnd = weekEnd ??_getWeekEnd(selectedDate);     

  
  static DateTime _getWeekStart(DateTime? date) {
    final currentDate = date ?? DateTime.now();
    final int dayNo = currentDate.weekday;
    return currentDate.subtract(Duration(days: dayNo - 1));
  }

  static DateTime _getWeekEnd(DateTime? date) {
    final weekStart = _getWeekStart(date);
    return weekStart.add(Duration(days: 6));
  }

  ExpenseState copyWith({
    List<ExpenseModel>? expenses,
    List<ExpenseModel>? filteredRecord,
    List<ExpenseModel>? searchRecords,
    bool? isLoading,
    bool? hasMore,
    int? offset,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    DateTime? weekStart,
    DateTime? weekEnd,
    String? activeFilter,
  }) {

    final newSelectedDate = selectedDate ?? this.selectedDate;

    return ExpenseState(
      expenses: expenses ?? this.expenses,
      filteredRecord: filteredRecord ?? this.filteredRecord,
      searchRecords: searchRecords ?? this.searchRecords,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      selectedDate: newSelectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      weekStart: weekStart ?? this.weekStart,
      weekEnd:   weekEnd ?? this.weekEnd,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

}

class ExpenseNotifier extends StateNotifier<ExpenseState>{

  final DatabaseConnection databaseConnection = DatabaseConnection();

  final Ref _ref;

  ExpenseNotifier(this._ref) : super(ExpenseState());


  Future<void> getExpenses() async {
    state = state.copyWith(isLoading: true);

    final allExpenses = await databaseConnection.getAllExpenses();

    state = state.copyWith(
      expenses: allExpenses,
      hasMore: false,
      isLoading: false,
    );

    filterRecordsByMonth(state.selectedDate, state.selectedTime);
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

    // Apply the current active filter instead of always monthly
    switch(state.activeFilter) {
      case 'daily':
        filterRecordsByDay(state.selectedDate);
        break;
      case 'weekly':
        filterRecordsByWeek(state.selectedDate);
        break;
      case 'yearly':
        filterRecordsByYear(state.selectedDate);
        break;
      default:
        filterRecordsByMonth(state.selectedDate, state.selectedTime);
        break;
    }
  }



  Future<void> updateExpense(ExpenseModel expense)async{
    await databaseConnection.updateExpenses(expense);

    state = state.copyWith(
        expenses: state.expenses.map((e)=>e.id==expense.id? expense : e).toList()
    );

    // Apply the current active filter instead of always monthly
    switch(state.activeFilter) {
      case 'daily':
        filterRecordsByDay(state.selectedDate);
        break;
      case 'weekly':
        filterRecordsByWeek(state.selectedDate);
        break;
      case 'yearly':
        filterRecordsByYear(state.selectedDate);
        break;
      default:
        filterRecordsByMonth(state.selectedDate, state.selectedTime);
        break;
    }
  }

  Future<void> deleteExpense(int id) async {
    final selectedRecord = state.filteredRecord.firstWhere(
          (data) => data.id == id,
      orElse: () => throw Exception('Record not found'),
    );

    final selectedCard = _ref.read(cardsProvider).cards.firstWhere(
          (card) => card.id == selectedRecord.accountId,
      orElse: () => throw Exception('Card not found'),
    );

    final budgetList = _ref.read(budgetProvider).budgets;
    BudgetModel? selectedBudget;

    if (budgetList.any((budget) => budget.categoryName == selectedRecord.category)) {
      selectedBudget = budgetList.firstWhere(
              (cat) => cat.categoryName == selectedRecord.category,
          orElse: () => throw Exception('Not found')
      );
    }

    double updatedAmount = selectedCard.amount;
    double updatedProgress = selectedCard.progress;

    if (selectedRecord.moneyType == MoneyType.expense) {
      updatedAmount += selectedRecord.amount;
    } else if (selectedRecord.moneyType == MoneyType.income) {
      updatedAmount -= selectedRecord.amount;
    }

    if (selectedCard.amount > 0) {
      double spentAmount = selectedCard.amount * selectedCard.progress;
      updatedProgress = (spentAmount / (updatedAmount == 0 ? 1 : updatedAmount)).clamp(0.0, 1.0);
    }

    final updatedCard = CardModel(
        id: selectedCard.id,
        cardName: selectedCard.cardName,
        amount: updatedAmount,
        icon: selectedCard.icon,
        moneyType: selectedCard.moneyType,
        progress: updatedProgress
    );

    await databaseConnection.updateCard(updatedCard);

    final cardNotifier = _ref.read(cardsProvider.notifier);

    cardNotifier.state = cardNotifier.state.copyWith(
        cards: cardNotifier.state.cards.map((card) {
          return card.id == updatedCard.id ? updatedCard : card;
        }).toList()
    );

    if (selectedBudget != null) {
      double updatedSpent = selectedBudget.spent;
      double updatedRemaining = selectedBudget.remaining;

      if (selectedRecord.moneyType == MoneyType.expense) {
        updatedSpent -= selectedRecord.amount;
        updatedRemaining += selectedRecord.amount;
      }

      final updatedBudget = BudgetModel(
          id: selectedBudget.id,
          categoryName: selectedBudget.categoryName,
          budget: selectedBudget.budget,
          spent: updatedSpent,
          remaining: updatedRemaining,
          date: selectedBudget.date
      );

      await _ref.read(budgetProvider.notifier).updateBudgetFromExpense(updatedBudget);
    }

    await databaseConnection.deleteExpenses(id);

    state = state.copyWith(
      expenses: state.expenses.where((e) => e.id != id).toList(),
      filteredRecord: state.filteredRecord.where((e) => e.id != id).toList(),
    );

    _calculateTotals();
  }

  void setActiveFilter(String currentFilter){
    state = state.copyWith(activeFilter: currentFilter);
  }

  Future<void> bulkDeleteSelectedRecords(List<int> allIds) async {
    if (allIds.isEmpty) {
      return;
    }

    final idsToDelete = List<int>.from(allIds);

    for (var id in idsToDelete) {
      try {
        await deleteExpense(id);
      } catch (e) {
        debugPrint("Failed to delete record $id: $e");
      }
    }

    switch(state.activeFilter) {
      case 'daily':
        filterRecordsByDay(state.selectedDate);
        break;
      case 'weekly':
        filterRecordsByWeek(state.selectedDate);
        break;
      case 'yearly':
        filterRecordsByYear(state.selectedDate);
        break;
      default:
        filterRecordsByMonth(state.selectedDate, state.selectedTime);
        break;
    }
  }

  void searchForRecords(String query){
    if(query.isEmpty){
      state = state.copyWith(
        searchRecords: []
      );
      return;
    }
    state = state.copyWith(
      searchRecords: state.expenses.where((data){
        return data.title.toLowerCase().contains(query.toLowerCase())
            || data.category.toLowerCase().contains(query.toLowerCase())
            || data.amount.toString().toLowerCase().contains(query.toLowerCase());
      }).toList()
    );
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

  void filterRecordsByDay(DateTime selectedDay){
    final filtered = state.expenses.where((date){
      return date.date.year==selectedDay.year && date.date.day == selectedDay.day;
    }).toList();
    state = state.copyWith(
      selectedDate: selectedDay,
      filteredRecord: filtered
    );
    _calculateTotals();
  }

  void filterRecordsByYear(DateTime selectedYear){
    final filtered = state.expenses.where((date)=>date.date.year==selectedYear.year).toList();
    state = state.copyWith(
      selectedDate: selectedYear,
      filteredRecord: filtered
    );
    _calculateTotals();
  }

  void filterRecordsByWeek(DateTime selectedWeek) {
    final int dayNo = selectedWeek.weekday;

    final DateTime weekStart = selectedWeek.subtract(Duration(days: dayNo - 1));
    final DateTime weekEnd = weekStart.add(Duration(days: 6));

    final normalizedWeekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final normalizedWeekEnd = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);

    final filtered = state.expenses.where((exp) {
      final normalizedExpDate = DateTime(exp.date.year, exp.date.month, exp.date.day);

      final isInRange = normalizedExpDate.compareTo(normalizedWeekStart) >= 0 && normalizedExpDate.compareTo(normalizedWeekEnd) <= 0;

      return isInRange;
    }).toList();


    state = state.copyWith(
      selectedDate: selectedWeek,
      weekStart: weekStart,
      weekEnd: weekEnd,
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
          break;
        case MoneyType.income:
          totalIncome+=exp.amount;
          break;
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