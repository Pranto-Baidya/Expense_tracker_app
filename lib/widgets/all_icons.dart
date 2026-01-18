import 'package:flutter/material.dart';

class IconHandler {

  static IconData getIcon(int codePoint) {
    switch (codePoint) {
      case 0xe0b2: return Icons.attach_money;
      case 0xe041: return Icons.account_balance;
      case 0xe042: return Icons.account_balance_wallet;
      case 0xf0153: return Icons.savings;
      case 0xef25: return Icons.sanitizer_outlined;
      case 0xe4a2: return Icons.photo;
      case 0xe406: return Icons.money_off;
      case 0xe19f: return Icons.credit_card;
      case 0xf028c: return Icons.wallet;
      case 0xe481: return Icons.payment;
      case 0xf0101: return Icons.request_page;
      case 0xe59c: return Icons.shopping_cart;
      case 0xf37d: return Icons.shopping_bag;
      case 0xf533: return Icons.baby_changing_station;
      case 0xe248: return Icons.fastfood;
      case 0xe374: return Icons.local_cafe;
      case 0xe298: return Icons.flight_takeoff;
      case 0xe1d7: return Icons.directions_car;
      case 0xe318: return Icons.home;
      case 0xef67: return Icons.deck_outlined;
      case 0xef14: return Icons.receipt_long;
      case 0xe37e: return Icons.lightbulb;
      case 0xe6e0: return Icons.wifi;
      case 0xe4cf: return Icons.phone_android;
      case 0xf1bd: return Icons.medical_services;
      case 0xf080: return Icons.health_and_safety;
      case 0xe40f: return Icons.movie;
      case 0xe5f0: return Icons.sports_esports;
      case 0xf59a: return Icons.checkroom;
      case 0xe559: return Icons.school;
      case 0xe4a1: return Icons.pets;
      case 0xe151: return Icons.celebration;
      case 0xe297: return Icons.flight;
      case 0xe5ca: return Icons.spa;
      case 0xe10d: return Icons.brush;
      case 0xf64f: return Icons.cleaning_services;
      case 0xe610: return Icons.subscriptions;
      case 0xf3a8: return Icons.sports_bar;
      case 0xf418: return Icons.sports_cricket;
      case 0xf66a: return Icons.currency_bitcoin;
      case 0xe5ab: return Icons.show_chart;

      case 0xe148:
      default:
        return Icons.category;
    }
  }
}