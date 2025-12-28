

import 'package:expense_tracker_app/database/db_connection.dart';
import 'package:expense_tracker_app/models/budget_model.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../screens/budgets_screen.dart';

final budgetProvider = StateNotifierProvider<BudgetNotifier,BudgetState>((ref)=>BudgetNotifier(ref));

class BudgetState{
  final List<BudgetModel> budgets;
  final List<BudgetModel> filteredBudgets;
  final bool isLoading;

  BudgetState({
    this.budgets = const [],
    this.filteredBudgets = const [],
    this.isLoading = false
  });

  BudgetState copyWith({List<BudgetModel>? budgets,List<BudgetModel>? filteredBudgets,bool? isLoading}){
    return BudgetState(
      budgets: budgets ?? this.budgets,
      filteredBudgets: filteredBudgets ?? this.filteredBudgets,
      isLoading: isLoading ?? this.isLoading
    );
  }
}

class BudgetNotifier extends StateNotifier<BudgetState>{

  final DatabaseConnection databaseConnection = DatabaseConnection();

  final Ref ref;

  BudgetNotifier(this.ref) : super(BudgetState());

  Future<void> getAllBudgetsList()async{
    state = state.copyWith(isLoading: true);

    final data = await databaseConnection.getAllBudgets();

    state = state.copyWith(
      budgets: data,
      isLoading: false
    );
  }

  Future<void> addBudget(BudgetModel budget)async{
    state = state.copyWith(isLoading: true);
    int id = await databaseConnection.insertBudget(budget);

    final newBudget = BudgetModel(
        id: id,
        categoryName: budget.categoryName,
        budget: budget.budget,
        date: ref.read(selectedDateProviderForBudgets.notifier).state
    );

    state = state.copyWith(
        budgets: [newBudget,...state.budgets],
        isLoading: false
    );

    filterBudgetsByMonth(budget.date);

    final allExpenses = ref.read(expenseProvider).expenses;

    final matchingExpenses = allExpenses.where((expense) {
      return
          expense.category == budget.categoryName &&
          expense.date.month == budget.date.month &&
          expense.date.year == budget.date.year &&
          expense.moneyType == MoneyType.expense;
    }).toList();

    if (matchingExpenses.isNotEmpty) {
      double totalSpent = matchingExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
      double remaining = budget.budget - totalSpent;

      final updatedBudget = BudgetModel(
          id: id,
          categoryName: budget.categoryName,
          budget: budget.budget,
          spent: totalSpent,
          remaining: remaining,
          date: budget.date
      );

      await databaseConnection.updateBudget(updatedBudget);

      state = state.copyWith(
        budgets: state.budgets.map((b) => b.id == id ? updatedBudget : b).toList(),
      );

      filterBudgetsByMonth(budget.date);
    }
  }

  Future<void> updateBudget(BudgetModel budget)async{

    state = state.copyWith(isLoading: true);

    final selectedBudgetedCategory = state.budgets.firstWhere((i)=>i.id==budget.id,orElse: ()=>throw Exception('Not found'));

    final remaining = budget.budget-selectedBudgetedCategory.spent;

    final updatedBudget = BudgetModel(
       id: selectedBudgetedCategory.id,
       categoryName: selectedBudgetedCategory.categoryName,
       budget: budget.budget,
       spent: selectedBudgetedCategory.spent,
       remaining: remaining,
       date: selectedBudgetedCategory.date
   );

    await databaseConnection.updateBudget(updatedBudget);

    state = state.copyWith(
      budgets: state.budgets.map((budj)=>budj.id == budget.id? updatedBudget : budj).toList(),
      isLoading: false
    );

    filterBudgetsByMonth(budget.date);
  }

  Future<void> deleteBudget(int id) async {
    await databaseConnection.deleteBudget(id);

    final updatedBudgets = state.budgets.where((i) => i.id != id).toList();

    state = state.copyWith(budgets: updatedBudgets);

    final selectedDate = ref.read(selectedDateProviderForBudgets);

    filterBudgetsByMonth(selectedDate);
  }


  Future<void> updateBudgetFromExpense(BudgetModel updatedBudget) async {
    await databaseConnection.updateBudget(updatedBudget);

    state = state.copyWith(
      budgets: state.budgets.map((b) => b.id == updatedBudget.id ? updatedBudget : b).toList(),
    );

    filterBudgetsByMonth(updatedBudget.date);
  }

  Future<void> bulkDeleteBudgets(List<int> allBudgetIds)async{
    if(allBudgetIds.isEmpty) return;

    List<int> idsToDelete = List<int>.from(allBudgetIds);

    for(var id in idsToDelete){
      try{
        await deleteBudget(id);
      }
      catch(e){
        debugPrint('Error $id : ${e.toString()}');
      }
    }
  }

  void filterBudgetsByMonth(DateTime selectedDate){
    state = state.copyWith(
      filteredBudgets: state.budgets.where((data){
        final yearInBudgets = data.date.year;
        final monthInBudgets = data.date.month;
        return selectedDate.year==yearInBudgets && selectedDate.month==monthInBudgets;
      }).toList()
    );
  }



  void calculateAmount(DateTime selectedDate)async{

    final selectedCategory = ref.read(categoryPickerProvider);
    final enteredAmount = ref.read(enteredAmountProvider);
    final moneyType = ref.read(moneyTypeProvider);


    final selectedCategoryForBudget = state.filteredBudgets.firstWhere((i)=>i.categoryName==selectedCategory,orElse: ()=>throw Exception('Not found'));

    final isSameMonth = selectedDate.year==selectedCategoryForBudget.date.year && selectedDate.month==selectedCategoryForBudget.date.month;

    if(!isSameMonth){
      return;
    }

    if(moneyType!=MoneyType.expense){
      return;
    }

    double currentAmount = selectedCategoryForBudget.budget;
    double spent = selectedCategoryForBudget.spent;

    if(moneyType==MoneyType.expense){
      spent += enteredAmount;
    }

    double remaining = currentAmount-spent;

    final newBudget = BudgetModel(
        id: selectedCategoryForBudget.id,
        categoryName: selectedCategoryForBudget.categoryName,
        budget: currentAmount,
        spent: spent,
        remaining: remaining,
        date: selectedCategoryForBudget.date
    );

    await databaseConnection.updateBudget(newBudget);

    state = state.copyWith(
      budgets: state.budgets.map((current)=>current.id==newBudget.id?newBudget:current).toList()
    );

    await getAllBudgetsList();

  }

  void calculateAmountForEdit(DateTime selectedDate, double oldAmount)async{

    final newAmount = ref.read(enteredAmountProvider);
    final selectedCategory = ref.read(categoryPickerProvider);
    final moneyType = ref.read(moneyTypeProvider);

    final selectedCategoryForBudget = state.filteredBudgets.firstWhere((i)=> i.categoryName==selectedCategory);

    final isSameMonth = selectedDate.month==selectedCategoryForBudget.date.month && selectedDate.year==selectedCategoryForBudget.date.year;

    if(!isSameMonth){
      return;
    }

    if(moneyType!=MoneyType.expense){
      return;
    }

    double currentBudget = selectedCategoryForBudget.budget;
    double spent = selectedCategoryForBudget.spent;

    if (moneyType == MoneyType.expense) {
      spent = spent - oldAmount + newAmount;
    }

    double remaining = currentBudget - spent;

    final updated = BudgetModel(
        id: selectedCategoryForBudget.id,
        categoryName: selectedCategoryForBudget.categoryName,
        budget: currentBudget,
        spent: spent,
        remaining: remaining,
        date: selectedDate
    );

    await databaseConnection.updateBudget(updated);

    state = state.copyWith(
      budgets: state.budgets.map((i)=>i.id == updated.id?updated:i).toList()
    );
    await getAllBudgetsList();
  }


}