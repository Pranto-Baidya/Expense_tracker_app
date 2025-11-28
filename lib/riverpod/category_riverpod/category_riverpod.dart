
import 'package:expense_tracker_app/database/db_connection.dart';
import 'package:expense_tracker_app/models/category_model.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../screens/category_screen.dart';

final categoryProvider = StateNotifierProvider<CategoryNotifier,CategoryState>((ref)=>CategoryNotifier());

class CategoryState{
  final List<CategoryModel> allCategories;
  final List<CategoryModel> allIncomeCategories;
  final List<CategoryModel> allExpenseCategories;
  final String error;

  CategoryState({
    this.allCategories = const [],
    this.allIncomeCategories = const [],
    this.allExpenseCategories = const [],
    this.error = ''
  });

  CategoryState copyWith({
    List<CategoryModel>? allCategories,
    String? error,
    List<CategoryModel>? allIncomeCategories,
    List<CategoryModel>? allExpenseCategories
  }){
    return CategoryState(
      allCategories: allCategories ?? this.allCategories,
      allIncomeCategories: allIncomeCategories ?? this.allIncomeCategories,
      allExpenseCategories: allExpenseCategories ?? this.allExpenseCategories,
      error: error ?? this.error
    );
  }
}

class CategoryNotifier extends StateNotifier<CategoryState>{

  final DatabaseConnection databaseConnection = DatabaseConnection();

  CategoryNotifier() : super(CategoryState());

  Future<void> getAllCategories()async{
    try{

      state = state.copyWith(error: '');

      final data = await databaseConnection.getAllCategories();

      state = state.copyWith(
          allCategories : data,
          allIncomeCategories: data.where((i)=>i.categoryType==CategoryType.income).toList(),
          allExpenseCategories: data.where((i)=>i.categoryType==CategoryType.expense).toList(),
          error: ''
      );
    }
    catch(e){
      state = state.copyWith(error: e.toString());
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
    try {
      await databaseConnection.deleteCategory(id);

      final updatedList = state.allCategories.where((c) => c.categoryId != id).toList();

      state = state.copyWith(
        allCategories: updatedList,
        allIncomeCategories: updatedList.where((c) => c.categoryType == CategoryType.income).toList(),
        allExpenseCategories: updatedList.where((c) => c.categoryType == CategoryType.expense).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

}