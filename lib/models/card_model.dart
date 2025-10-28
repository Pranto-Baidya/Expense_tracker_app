import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CardModel{
  final int? id;
  final String cardName;
  final double amount;
  final IconData icon;

  CardModel({
    this.id,
    required this.cardName,
    required this.amount,
    required this.icon
  });

  factory CardModel.fromMap(Map<String,dynamic> map){
    return CardModel(
        id: map['id'],
        cardName: map['cardName'],
        amount: map['amount'],
        icon: IconData(
          map['iconCode'] ?? Icons.credit_card.codePoint,
          fontFamily: 'MaterialIcons'
        )
    );
  }

  Map<String,dynamic> toMap(){
    Map<String,dynamic> data = {
      'id' : id,
      'cardName' : cardName,
      'amount' : amount,
      'iconCode' : icon.codePoint
    };
    return data;
  }
}