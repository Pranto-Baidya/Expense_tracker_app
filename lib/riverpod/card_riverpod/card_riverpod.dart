
import 'package:expense_tracker_app/database/db_connection.dart';
import 'package:expense_tracker_app/models/card_model.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';


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
  }

  Future<void> updateCard(CardModel card)async{
    state = state.copyWith(
      isLoading: true
    );

    await databaseConnection.updateCard(card);

    state = state.copyWith(
      cards: state.cards.map((i)=>i.id==card.id? card : i).toList(),
      isLoading: false
    );
  }

  Future<void> deleteCard(int id)async{

    state = state.copyWith(isLoading: true);

    await databaseConnection.deleteCard(id);

    state = state.copyWith(
      cards: state.cards.where((i)=>i.id!=id).toList(),
      isLoading: false
    );
  }

  void calculateTotalAmountInAccount() async {

    final selectedAccountId = _ref.read(selectedAccountProvider);
    final enteredAmount = _ref.read(enteredAmountProvider);
    final moneyType = _ref.read(moneyTypeProvider);

    if(selectedAccountId==null){
      return;
    }

    final selectedCard = state.cards.firstWhere((card)=>card.id==selectedAccountId,orElse: ()=>throw Exception('Invalid account'));

    double updatedAmount = selectedCard.amount;
    double progress = selectedCard.progress;

    if (moneyType == MoneyType.expense) {
      updatedAmount -= enteredAmount;
      progress = (enteredAmount / (selectedCard.amount == 0 ? 1 : selectedCard.amount)).clamp(0.0, 1.0);
    }
    else if(moneyType==MoneyType.income){
      updatedAmount+=enteredAmount;
      progress = 0.0;
    }

    final newBalance = CardModel(
        id: selectedCard.id,
        cardName: selectedCard.cardName,
        amount: updatedAmount,
        icon: selectedCard.icon,
        moneyType: selectedCard.moneyType,
        progress: progress
    );

    await databaseConnection.updateCard(newBalance);

    state = state.copyWith(
      cards: state.cards.map((card)=>card.id==newBalance.id?newBalance:card).toList(),
    );
  }

}