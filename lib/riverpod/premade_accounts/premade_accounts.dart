

import 'package:expense_tracker_app/models/card_model.dart';
import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final premadeAccountsProvider = StateNotifierProvider<PreMadeAccountsNotifier,PreMadeAccountState>((ref)=>PreMadeAccountsNotifier());

class PreMadeAccountState{
  final List<CardModel> defaultAccounts;

  PreMadeAccountState({required this.defaultAccounts});

  factory PreMadeAccountState.allDefaultAccounts(){
    return PreMadeAccountState(
        defaultAccounts: [
          CardModel(
              cardName: 'Bank',
              amount: 10000,
              icon: Icons.account_balance
          ),
          CardModel(
              cardName: 'Card',
              amount: 5000,
              icon: Icons.credit_card
          ),
          CardModel(
              cardName: 'Wallet',
              amount: 3000,
              icon: Icons.wallet
          ),
        ]
    );
  }

}


class PreMadeAccountsNotifier extends StateNotifier<PreMadeAccountState>{
  PreMadeAccountsNotifier() : super(PreMadeAccountState.allDefaultAccounts());

  Future<void> initializePreMadeAccounts(WidgetRef ref)async{
    SharedPreferences preferences = await SharedPreferences.getInstance();

    final cardNotifier = ref.read(cardsProvider.notifier);

    await cardNotifier.getCards();

    final existingCards = ref.read(cardsProvider).cards;

    if(existingCards.isNotEmpty){
      await preferences.setBool('hasInsertedDefaultCards', true);
      return;
    }

    bool hasInserted = preferences.getBool('hasInsertedDefaultCards') ?? false;

    if(!hasInserted){
      for(var acc in state.defaultAccounts){
        await cardNotifier.addCard(acc);
      }
    }

    await preferences.setBool('hasInsertedDefaultCards',true);
  }
}