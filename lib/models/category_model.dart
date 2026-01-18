import 'package:expense_tracker_app/screens/category_screen.dart';
import 'package:flutter/material.dart';

class CategoryModel {
  final int? categoryId;
  final String categoryName;
  final CategoryType categoryType;
  final IconData icon;
  final Color color;
  CategoryModel({
    this.categoryId,
    required this.categoryName,
    this.categoryType = CategoryType.income,
    required this.icon,
    this.color = const Color(0xFF14B8A6),
  });
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      categoryId: map['categoryId'],
      categoryName: map['categoryName'] as String,
      categoryType: map['categoryType'] == 'income'
          ? CategoryType.income
          : CategoryType.expense,
      icon: IconData(
        (map['iconCode'] as int?) ?? Icons.category.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      color: Color(map['colorCode'] as int),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      if (categoryId != null) 'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryType': categoryType.name,
      'iconCode': icon.codePoint,
      'colorCode': color.value,
    };
  }
}
