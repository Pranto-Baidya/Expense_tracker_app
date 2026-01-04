
import 'package:expense_tracker_app/database/db_connection.dart';
import 'package:expense_tracker_app/models/category_model.dart';
import 'package:expense_tracker_app/riverpod/budget_riverpod/budget_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../screens/budgets_screen.dart';
import '../../screens/category_screen.dart';
import '../expense_riverpod/expense_riverpod.dart';

final categoryProvider = StateNotifierProvider<CategoryNotifier,CategoryState>((ref)=>CategoryNotifier(ref));

class CategoryState{
  final List<CategoryModel> allCategories;
  final List<CategoryModel> allIncomeCategories;
  final List<CategoryModel> allExpenseCategories;
  final String error;
  final bool isLoading;

  CategoryState({
    this.allCategories = const [],
    this.allIncomeCategories = const [],
    this.allExpenseCategories = const [],
    this.error = '',
    this.isLoading = false
  });

  CategoryState copyWith({
    List<CategoryModel>? allCategories,
    String? error,
    List<CategoryModel>? allIncomeCategories,
    List<CategoryModel>? allExpenseCategories,
    bool? isLoading
  }){
    return CategoryState(
      allCategories: allCategories ?? this.allCategories,
      allIncomeCategories: allIncomeCategories ?? this.allIncomeCategories,
      allExpenseCategories: allExpenseCategories ?? this.allExpenseCategories,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading
    );
  }
}

class CategoryNotifier extends StateNotifier<CategoryState>{

  final Ref ref;

  final DatabaseConnection databaseConnection = DatabaseConnection();

  CategoryNotifier(this.ref) : super(CategoryState());

  Future<void> getAllCategories()async{
    try{

      state = state.copyWith(error: '',isLoading: true);

      final data = await databaseConnection.getAllCategories();

      state = state.copyWith(
          allCategories : data,
          allIncomeCategories: data.where((i)=>i.categoryType==CategoryType.income).toList(),
          allExpenseCategories: data.where((i)=>i.categoryType==CategoryType.expense).toList(),
          error: '',
          isLoading: false
      );
    }
    catch(e){
      state = state.copyWith(error: e.toString(),isLoading: false);
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      final id = await databaseConnection.addCategory(category);

      final newCategory = CategoryModel(
        categoryId: id,
        categoryName: category.categoryName,
        categoryType: category.categoryType,
        icon: category.icon,
        color: category.color
      );

      final newList = [newCategory, ...state.allCategories];

      state = state.copyWith(
        allCategories: newList,
        allIncomeCategories: newList.where((c) => c.categoryType == CategoryType.income).toList(),
        allExpenseCategories: newList.where((c) => c.categoryType == CategoryType.expense).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }


  Future<void> updateCategory(CategoryModel category) async {
    try {
      await databaseConnection.updateCategory(category);

      final updated = CategoryModel(
        categoryId: category.categoryId,
        categoryName: category.categoryName,
        categoryType: category.categoryType,
        icon: category.icon,
        color: category.color
      );

      final updatedList = state.allCategories.map((c) {
        return c.categoryId == category.categoryId ? updated : c;
      }).toList();

      state = state.copyWith(
        allCategories: updatedList,
        allIncomeCategories: updatedList.where((c) => c.categoryType == CategoryType.income).toList(),
        allExpenseCategories: updatedList.where((c) => c.categoryType == CategoryType.expense).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }


  Future<void> deleteCategory(int id) async {
    try{

      final categoryToDelete = state.allCategories.firstWhere((c)=>c.categoryId==id, orElse: () => throw Exception('Category not found'));

      final budgetNotifier = ref.read(budgetProvider.notifier);
      final allBudgets = ref.read(budgetProvider).budgets;
      final allRecords = ref.read(expenseProvider).expenses;
      final recordNotifier = ref.read(expenseProvider.notifier);

      final budgetsToDelete = allBudgets.where((budget) => budget.categoryName == categoryToDelete.categoryName).toList();

      final recordsToDelete = allRecords.where((r)=>r.category==categoryToDelete.categoryName).toList();

      for(var budget in budgetsToDelete){
        if(budget.id != null) {
          await budgetNotifier.deleteBudget(budget.id!);
        }
      }

      for(var r in recordsToDelete){
        if(r.id!=null){
          await recordNotifier.deleteExpense(r.id!);
        }
      }

      await databaseConnection.deleteCategory(id);

      final updatedList = state.allCategories.where((i)=>i.categoryId!=id).toList();

      state = state.copyWith(
        allCategories: updatedList,
        allIncomeCategories: updatedList.where((c) => c.categoryType == CategoryType.income).toList(),
        allExpenseCategories: updatedList.where((c) => c.categoryType == CategoryType.expense).toList(),
      );

      await budgetNotifier.getAllBudgetsList();
      await recordNotifier.getExpenses();
      final selectedDate = ref.read(selectedDateProviderForBudgets);
      budgetNotifier.filterBudgetsByMonth(selectedDate);
    }
    catch(e){
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> bulkDeleteCategories(List<int> allCatIds)async{
    if(allCatIds.isEmpty) return;

    List<int> idsToDelete = List<int>.from(allCatIds);

    for(var id in idsToDelete){
      try{
        await deleteCategory(id);
      }
      catch(e){
        debugPrint('Error: $id : ${e.toString()}');
      }
    }
  }
}