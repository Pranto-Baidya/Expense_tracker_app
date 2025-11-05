

import 'package:expense_tracker_app/database/db_connection.dart';
import 'package:expense_tracker_app/models/budget_model.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final budgetProvider = StateNotifierProvider<BudgetNotifier,BudgetState>((ref)=>BudgetNotifier(ref));

class BudgetState{
  final List<BudgetModel> budgets;


  BudgetState({
    this.budgets = const []
  });

  BudgetState copyWith({List<BudgetModel>? budgets}){
    return BudgetState(
      budgets: budgets ?? this.budgets
    );
  }
}

class BudgetNotifier extends StateNotifier<BudgetState>{

  final DatabaseConnection databaseConnection = DatabaseConnection();

  final Ref ref;

  BudgetNotifier(this.ref) : super(BudgetState());

  Future<void> getAllBudgetsList()async{
    state = state.copyWith(budgets: []);

    final data = await databaseConnection.getAllBudgets();

    state = state.copyWith(
      budgets: [...state.budgets,...data]
    );
  }

  Future<void> addBudget(BudgetModel budget)async{
    int id = await databaseConnection.insertBudget(budget);

    final newBudget = BudgetModel(
        id: id,
        categoryName: budget.categoryName,
        budget: budget.budget,
        date: budget.date
    );

    state = state.copyWith(
      budgets: [newBudget,...state.budgets]
    );
  }

  Future<void> updateBudget(BudgetModel budget)async{

    final selectedBudgetedCategory = state.budgets.firstWhere((i)=>i.id==budget.id);

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
      budgets: state.budgets.map((budj)=>budj.id == budget.id? updatedBudget : budj).toList()
    );
  }

  Future<void> deleteBudget(int id)async{
    await databaseConnection.deleteBudget(id);

    state = state.copyWith(
      budgets: state.budgets.where((i)=>i.id!=id).toList()
    );
  }

  Future<void> updateBudgetFromExpense(BudgetModel updatedBudget) async {
    await databaseConnection.updateBudget(updatedBudget);

    state = state.copyWith(
      budgets: state.budgets.map((b) => b.id == updatedBudget.id ? updatedBudget : b).toList(),
    );
  }


  void calculateAmount()async{

    final selectedCategory = ref.read(categoryProvider);
    final enteredAmount = ref.read(enteredAmountProvider);
    final moneyType = ref.read(moneyTypeProvider);

    final selectedCategoryForBudget = state.budgets.firstWhere((i)=>i.categoryName==selectedCategory,orElse: ()=>throw Exception('Not found'));

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


}