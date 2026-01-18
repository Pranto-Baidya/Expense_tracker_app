import 'dart:convert';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CardModel {
  final int? id;
  final String cardName;
  final double amount;
  final double initialAmount;
  final IconData icon;
  final double progress;
  final MoneyType moneyType;
  CardModel({
    this.id,
    required this.cardName,
    required this.amount,
    double? initialAmount,
    required this.icon,
    this.progress = 0,
    this.moneyType = MoneyType.expense,
  }) : initialAmount = initialAmount ?? amount;
  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'],
      cardName: map['cardName'],
      amount: map['amount'],
      initialAmount: map['initialAmount'] ?? map['amount'],
      icon: IconData(
        map['iconCode'] ?? Icons.credit_card.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      progress: map['progress'],
      moneyType: map['moneyType'] == 'income'
          ? MoneyType.income
          : MoneyType.expense,
    );
  }
  Map<String, dynamic> toMap() {
    Map<String, dynamic> data = {
      'id': id,
      'cardName': cardName,
      'amount': amount,
      'initialAmount': initialAmount,
      'iconCode': icon.codePoint,
      'progress': progress,
      'moneyType': moneyType.name,
    };
    return data;
  }
}
