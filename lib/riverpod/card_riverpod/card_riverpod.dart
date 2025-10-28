
import 'package:expense_tracker_app/database/db_connection.dart';
import 'package:expense_tracker_app/models/card_model.dart';
import 'package:flutter_riverpod/legacy.dart';

final cardsProvider = StateNotifierProvider<CardNotifier,CardState>((ref){
  return CardNotifier();
});

class CardState{
  final List<CardModel> cards;
  final bool isLoading;

  CardState({
    this.cards = const [],
    this.isLoading = false
  });

  CardState copyWith({
    List<CardModel>? cards,
    bool? isLoading
  }){
    return CardState(
        cards: cards ?? this.cards,
        isLoading: isLoading ?? this.isLoading
    );
  }
}

class CardNotifier extends StateNotifier<CardState>{

  final DatabaseConnection databaseConnection = DatabaseConnection();

  CardNotifier() : super(CardState());

  Future<void> addCard(CardModel card)async{

    state = state.copyWith(isLoading: true);

    int id = await databaseConnection.insertCard(card);

    final newCard = CardModel(
        id: id,
        cardName: card.cardName,
        amount: card.amount,
        icon: card.icon
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


}