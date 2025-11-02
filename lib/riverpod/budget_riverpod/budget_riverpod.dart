

import 'package:expense_tracker_app/database/db_connection.dart';
import 'package:expense_tracker_app/models/budget_model.dart';
import 'package:flutter_riverpod/legacy.dart';

final budgetProvider = StateNotifierProvider<BudgetNotifier,BudgetState>((ref)=>BudgetNotifier());

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

  BudgetNotifier() : super(BudgetState());

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
    await databaseConnection.updateBudget(budget);

    state = state.copyWith(
      budgets: state.budgets.map((budj)=>budj.id == budget.id? budget : budj).toList()
    );
  }

  Future<void> deleteBudget(int id)async{
    await databaseConnection.deleteBudget(id);

    state = state.copyWith(
      budgets: state.budgets.where((i)=>i.id!=id).toList()
    );
  }
}