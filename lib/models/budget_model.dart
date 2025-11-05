
import 'package:expense_tracker_app/screens/records_screen.dart';

class BudgetModel{
  final int? id;
  final String categoryName;
  final double budget;
  final double spent;
  final double remaining;
  final DateTime date;
  final MoneyType moneyType;

  BudgetModel({
    this.id,
    required this.categoryName,
    required this.budget,
    this.spent = 0.0,
    this.remaining = 0.0,
    required this.date,
    this.moneyType = MoneyType.expense
  });

  factory BudgetModel.fromMap(Map<String,dynamic> map){
    return BudgetModel(
        id: map['id'],
        categoryName: map['categoryName'] as String,
        budget: (map['budget'] as num).toDouble(),
        spent: (map['spent'] as num).toDouble(),
        remaining: (map['remaining'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
        moneyType: map['moneyType'] == 'income'? MoneyType.income : MoneyType.expense
    );
  }

  Map<String,dynamic> toMap(){
    Map<String,dynamic> data = {
      'id' : id,
      'categoryName' : categoryName,
      'budget' : budget,
      'spent' : spent,
      'remaining' : remaining,
      'date' : date.toIso8601String(),
      'moneyType' : moneyType.name
    };
    return data;
  }
}