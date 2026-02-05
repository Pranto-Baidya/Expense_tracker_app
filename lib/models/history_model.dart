

import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:flutter/material.dart';

class HistoryModel{
  final int? id;
  final String title;
  final double amount;
  final String category;
  final int accountId;
  final DateTime date;
  final TimeOfDay time;
  final MoneyType moneyType;

  HistoryModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.accountId,
    required this.date,
    required this.time,
    required this.moneyType
  });

  factory HistoryModel.fromMap(Map<String,dynamic> map){

    final convTime = (map['time'] as String).split(':');

    final decodedTime = TimeOfDay(
        hour: int.parse(convTime[0]),
        minute: int.parse(convTime[1])
    );

    return HistoryModel(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      category: map['category'],
      accountId: map['accountId'],
      date: DateTime.parse(map['date'] as String),
      time: decodedTime,
      moneyType: map['moneyType'] == 'income'? MoneyType.income : MoneyType.expense
    );
  }

  Map<String,dynamic> toMap(){

    final formattedTime = '${time.hour.toString().padLeft(2,"0")}:${time.minute.toString().padLeft(2,'0')}';

    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category' : category,
      'accountId' : accountId,
      'date' : date.toIso8601String(),
      'time': formattedTime,
      'moneyType': moneyType.name
    };
  }
}