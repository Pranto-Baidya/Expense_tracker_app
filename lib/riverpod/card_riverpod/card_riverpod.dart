
import 'package:expense_tracker_app/database/db_connection.dart';
import 'package:expense_tracker_app/models/budget_model.dart';
import 'package:expense_tracker_app/models/card_model.dart';
import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:expense_tracker_app/riverpod/budget_riverpod/budget_riverpod.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../screens/budgets_screen.dart';

final totalExpenseInAccountProvider = StateProvider<double>((ref)=>0.0);
final totalIncomeInAccountProvider = StateProvider<double>((ref)=>0.0);


final cardsProvider = StateNotifierProvider<CardNotifier,CardState>((ref){
  return CardNotifier(ref);
});

class CardState{
  final List<CardModel> cards;
  final bool isLoading;

  CardState({
    this.cards = const [],
    this.isLoading = false,
  });

  CardState copyWith({
    List<CardModel>? cards,
    bool? isLoading,
  }){
    return CardState(
        cards: cards ?? this.cards,
        isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CardNotifier extends StateNotifier<CardState>{

  final DatabaseConnection databaseConnection = DatabaseConnection();

  final Ref _ref;

  CardNotifier(this._ref) : super(CardState());

  Future<void> addCard(CardModel card)async{

    state = state.copyWith(isLoading: true);

    int id = await databaseConnection.insertCard(card);

    final newCard = CardModel(
        id: id,
        cardName: card.cardName,
        amount: card.amount,
        icon: card.icon,
        moneyType: card.moneyType,
        progress: card.progress
    );

    state = state.copyWith(
      cards: [newCard,...state.cards],
      isLoading: false
    );
  }

  Future<void> getCards()async{
    state = state.copyWith(isLoading: true,cards: []);

    final data = await databaseConnection.getAllCards();

    state = state.copyWith(
      cards: [...state.cards,...data],
      isLoading: false
    );

    calculateTotalExpenseAndIncomeInAccount();
  }

  Future<void> updateCard(CardModel card) async {
    state = state.copyWith(cards: state.cards, isLoading: true);

    final existingCard = state.cards.firstWhere((c) => c.id == card.id);


    double updatedInitialAmount;
    double updatedAmount = card.amount;


    if (card.initialAmount == 0 || card.initialAmount == existingCard.initialAmount) {

      double previousSpent = existingCard.initialAmount - existingCard.amount;

      updatedInitialAmount = updatedAmount + previousSpent;
    }
    else {
      updatedInitialAmount = card.initialAmount;
    }

    if (updatedInitialAmount < updatedAmount) {
      updatedInitialAmount = updatedAmount;
    }

    double newProgress = 0.0;
    if (updatedInitialAmount > 0) {
      double spent = updatedInitialAmount - updatedAmount;
      newProgress = (spent / updatedInitialAmount).clamp(0.0, 1.0);
    }

    final updatedCard = CardModel(
      id: card.id,
      cardName: card.cardName,
      amount: updatedAmount,
      initialAmount: updatedInitialAmount,
      icon: card.icon,
      moneyType: card.moneyType,
      progress: newProgress,
    );

    await databaseConnection.updateCard(updatedCard);

    final updatedCards = state.cards.map((i) {
      return i.id == card.id ? updatedCard : i;
    }).toList();

    state = state.copyWith(cards: updatedCards, isLoading: false);
  }


  Future<void> deleteCard(int id) async {
    state = state.copyWith(isLoading: true);

    final expenseNotifier = _ref.read(expenseProvider.notifier);
    final expenseState = _ref.read(expenseProvider);

    final budgetState = _ref.read(budgetProvider);
    final budgetNotifier = _ref.read(budgetProvider.notifier);

    final expensesToDelete = expenseState.expenses.where((exp) => exp.accountId == id).toList();

    for (var expense in expensesToDelete) {
      if (expense.moneyType == MoneyType.expense) {

        final matchingBudget = budgetState.budgets.firstWhere(
              (budget) => budget.categoryName == expense.category &&
              budget.date.year == expense.date.year &&
              budget.date.month == expense.date.month,
          orElse: () => BudgetModel(
            id: -1,
            categoryName: '',
            budget: 0,
            date: DateTime.now(),
          ),
        );

        if (matchingBudget.id != -1) {
          double updatedSpent = matchingBudget.spent - expense.amount;
          double updatedRemaining = matchingBudget.remaining + expense.amount;

          final updatedBudget = BudgetModel(
            id: matchingBudget.id,
            categoryName: matchingBudget.categoryName,
            budget: matchingBudget.budget,
            spent: updatedSpent.clamp(0.0, double.infinity),
            remaining: updatedRemaining,
            date: matchingBudget.date,
          );

          await budgetNotifier.updateBudgetFromExpense(updatedBudget);
        }
      }
    }


    List<ExpenseModel> remainingRecords = expenseState.expenses.where((exp) => exp.accountId != id).toList();

    await databaseConnection.deleteExpensesByAccountId(id);

    await databaseConnection.deleteCard(id);

    expenseNotifier.state = expenseNotifier.state.copyWith(
      expenses: remainingRecords,
      filteredRecord: remainingRecords,
    );

    state = state.copyWith(
      cards: state.cards.where((i) => i.id != id).toList(),
      isLoading: false,
    );

    final currentBudgetDate = _ref.read(selectedDateProviderForBudgets);
    budgetNotifier.filterBudgetsByMonth(currentBudgetDate);
  }

  Future<void> bulkDeleteCards(List<int> allAccIds)async{
    if(allAccIds.isEmpty) return;

    final idsToDelete = List<int>.from(allAccIds);

    for(var id in idsToDelete){
      try{
        await deleteCard(id);
      }
      catch(e){
        debugPrint('Error: $id: ${e.toString()}');
      }
    }
  }

  void calculateTotalExpenseAndIncomeInAccount(){
    final allRecords = _ref.read(expenseProvider).expenses;

    double totalExpense = 0;
    double totalIncome = 0;

    for(var a in allRecords){
      if(a.moneyType==MoneyType.expense){
        totalExpense+=a.amount;
      }
      else{
        totalIncome+= a.amount;
      }
    }

    _ref.read(totalExpenseInAccountProvider.notifier).state = totalExpense;
    _ref.read(totalIncomeInAccountProvider.notifier).state = totalIncome;
  }


  void calculateTotalAmountInAccount() async {

    final selectedAccountId = _ref.read(selectedAccountProvider);
    final enteredAmount = _ref.read(enteredAmountProvider);
    final moneyType = _ref.read(moneyTypeProvider);

    if(selectedAccountId==null){
      return;
    }

    final selectedCard = state.cards.firstWhere(
            (card)=>card.id==selectedAccountId,
        orElse: ()=>throw Exception('Invalid account')
    );

    double updatedAmount = selectedCard.amount;
    double updatedInitialAmount = selectedCard.initialAmount;
    double progress;

    if (moneyType == MoneyType.expense) {
      updatedAmount -= enteredAmount;
    } else if (moneyType == MoneyType.income) {
      updatedAmount += enteredAmount;
      updatedInitialAmount += enteredAmount;
    }

    final spent = updatedInitialAmount - updatedAmount;
    progress = (spent / updatedInitialAmount).clamp(0.0, 1.0);

    final newBalance = CardModel(
        id: selectedCard.id,
        cardName: selectedCard.cardName,
        amount: updatedAmount,
        initialAmount: updatedInitialAmount,
        icon: selectedCard.icon,
        moneyType: selectedCard.moneyType,
        progress: progress
    );

    await databaseConnection.updateCard(newBalance);

    state = state.copyWith(
      cards: state.cards.map((card)=>card.id==newBalance.id?newBalance:card).toList(),
    );
    await getCards();
    calculateTotalExpenseAndIncomeInAccount();
  }

}