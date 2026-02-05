import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:flutter/material.dart';

import 'expense_model.dart';
import 'history_model.dart';

class TrashModel {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final int accountId;
  final DateTime date;
  final TimeOfDay time;
  final MoneyType moneyType;
  final DateTime deletedAt;

  TrashModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.accountId,
    required this.date,
    required this.time,
    required this.moneyType,
    required this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'accountId': accountId,
      'date': date.toIso8601String(),
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'moneyType': moneyType.name,
      'deletedAt': deletedAt.toIso8601String(),
    };
  }

  factory TrashModel.fromMap(Map<String, dynamic> map) {
    return TrashModel(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      category: map['category'],
      accountId: map['accountId'],
      date: DateTime.parse(map['date']),
      time: TimeOfDay(hour: map['timeHour'], minute: map['timeMinute']),
      moneyType: map['moneyType'] == 'income' ? MoneyType.income : MoneyType.expense,
      deletedAt: DateTime.parse(map['deletedAt']),
    );
  }

  factory TrashModel.fromHistory(HistoryModel history) {
    return TrashModel(
      title: history.title,
      amount: history.amount,
      category: history.category,
      accountId: history.accountId,
      date: history.date,
      time: history.time,
      moneyType: history.moneyType,
      deletedAt: DateTime.now(),
    );
  }

  HistoryModel toHistoryModel() {
    return HistoryModel(
      title: title,
      amount: amount,
      category: category,
      accountId: accountId,
      date: date,
      time: time,
      moneyType: moneyType,
    );
  }

  ExpenseModel toExpenseModel(){
    return ExpenseModel(
        title: title,
        amount: amount,
        category: category,
        date: date,
        time: time,
        accountId: accountId,
        moneyType: moneyType
    );
  }
}