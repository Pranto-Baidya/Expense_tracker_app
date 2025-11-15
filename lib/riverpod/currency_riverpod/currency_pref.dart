

import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final newCurrencyProvider = StateNotifierProvider<CurrencyNotifier,CurrencyState>((ref)=>CurrencyNotifier());

class CurrencyState{
  final String currency;

  CurrencyState({this.currency = ''});

  CurrencyState copyWith({String? currency}){
    return CurrencyState(currency: currency ?? this.currency);
  }
}

class CurrencyNotifier extends StateNotifier<CurrencyState>{
  CurrencyNotifier() : super(CurrencyState()){
    _loadSavedCurrency();
  }

  Future<void> _loadSavedCurrency()async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final curr = preferences.getString('currency') ?? '';
    state = state.copyWith(currency: curr);
  }

  Future<void> saveCurrency(String currency)async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString('currency', currency);
    state = state.copyWith(currency: currency);
  }
}