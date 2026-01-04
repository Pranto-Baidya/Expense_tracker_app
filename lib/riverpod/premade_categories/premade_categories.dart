import 'package:expense_tracker_app/riverpod/category_riverpod/category_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/category_model.dart';
import '../../screens/category_screen.dart';

final preMadeCategoryProvider = StateNotifierProvider<PreMadeCategoryNotifier,PreMadeCategoryState>((ref)=>PreMadeCategoryNotifier());

class PreMadeCategoryState {
  final List<CategoryModel> preMadeIncomeCategories;
  final List<CategoryModel> preMadeExpenseCategories;

  PreMadeCategoryState({
    required this.preMadeIncomeCategories,
    required this.preMadeExpenseCategories,
  });

  factory PreMadeCategoryState.defaultCategories() {
    return PreMadeCategoryState(
      preMadeIncomeCategories: [
        CategoryModel(
          categoryName: "Salary",
          icon: Icons.monetization_on,
          color: Colors.green,
          categoryType: CategoryType.income,
        ),
        CategoryModel(
          categoryName: "Bonus",
          icon: Icons.account_balance_wallet,
          color: Colors.blue,
          categoryType: CategoryType.income,
        ),
        CategoryModel(
          categoryName: "Coupons",
          icon: Icons.percent,
          color: Colors.orange,
          categoryType: CategoryType.income,
        ),
        CategoryModel(
          categoryName: "Grants",
          icon: Icons.card_giftcard,
          color: Colors.indigo,
          categoryType: CategoryType.income,
        ),
        CategoryModel(
          categoryName: "Rental",
          icon: Icons.date_range_sharp,
          color: Colors.pink,
          categoryType: CategoryType.income,
        ),
        CategoryModel(
          categoryName: "Refunds",
          icon:Icons.money,
          color: Colors.deepOrange,
          categoryType: CategoryType.income,
        ),
      ],
      preMadeExpenseCategories: [
        CategoryModel(
          categoryName: "Personal",
          icon: Icons.person,
          color: Colors.amber,
          categoryType: CategoryType.expense,
        ),
        CategoryModel(
          categoryName: "Family",
          icon: Icons.groups,
          color: Colors.deepPurpleAccent,
          categoryType: CategoryType.expense,
        ),
        CategoryModel(
          categoryName: "Shopping",
          icon: Icons.shopping_bag,
          color: Colors.purpleAccent,
          categoryType: CategoryType.expense,
        ),
        CategoryModel(
          categoryName: "Transport",
          icon: Icons.directions_car,
          color: Colors.red,
          categoryType: CategoryType.expense,
        ),
        CategoryModel(
          categoryName: "Health",
          icon: Icons.health_and_safety,
          color: Colors.teal,
          categoryType: CategoryType.expense,
        ),
        CategoryModel(
          categoryName: "Phone",
          icon: Icons.phone_android,
          color: Colors.black,
          categoryType: CategoryType.expense,
        ),
        CategoryModel(
          categoryName: "Bills",
          icon: Icons.receipt_long,
          color: Colors.cyan,
          categoryType: CategoryType.expense,
        ),
      ],
    );
  }

}

class PreMadeCategoryNotifier extends StateNotifier<PreMadeCategoryState>{

  PreMadeCategoryNotifier() : super(PreMadeCategoryState.defaultCategories());

  Future<void> initializePreMadeCategories(WidgetRef ref) async {

    SharedPreferences preferences = await SharedPreferences.getInstance();

    final categoryNotifier = ref.read(categoryProvider.notifier);

    await categoryNotifier.getAllCategories();

    final existingCategories = ref.read(categoryProvider).allCategories;

    if (existingCategories.isNotEmpty) {
      await preferences.setBool("hasInsertedDefaultCategories", true);
      return;
    }

    bool hasInserted = preferences.getBool("hasInsertedDefaultCategories") ?? false;

    if (!hasInserted) {
      for (var c in state.preMadeIncomeCategories) {
        await categoryNotifier.addCategory(c);
      }

      for (var c in state.preMadeExpenseCategories) {
        await categoryNotifier.addCategory(c);
      }

      await preferences.setBool("hasInsertedDefaultCategories", true);
    }
  }

}
