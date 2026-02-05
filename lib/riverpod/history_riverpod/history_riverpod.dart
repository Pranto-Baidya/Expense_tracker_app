
import 'package:expense_tracker_app/database/db_connection.dart';
import 'package:expense_tracker_app/models/history_model.dart';
import 'package:flutter_riverpod/legacy.dart';

final historyProvider = StateNotifierProvider<HistoryNotifier,HistoryState>((ref)=>HistoryNotifier());

class HistoryState{
  final List<HistoryModel> histories;
  final bool isLoading;
  final String error;

  HistoryState({
    this.histories = const [],
    this.isLoading = false,
    this.error = ''
  });

  HistoryState copyWith({
    List<HistoryModel>? histories,
    bool? isLoading,
    String? error
  }){
    return HistoryState(
        histories: histories ?? this.histories,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState>{

  HistoryNotifier() : super(HistoryState());

  final DatabaseConnection _databaseConnection = DatabaseConnection();

  Future<void> getAllHistoryList()async{
    try {
      state = state.copyWith(isLoading: true);

      final data = await _databaseConnection.getAllHistory();

      state = state.copyWith(
          histories: data,
          isLoading: false
      );
    }
    catch(e){
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addHistory(HistoryModel hist)async{
    try{
      state = state.copyWith(isLoading: true);

      final data = await _databaseConnection.addToHistory(hist);

      final newHist = HistoryModel(
          id: data,
          title: hist.title,
          amount: hist.amount,
          category: hist.category,
          accountId: hist.accountId,
          date: hist.date,
          time: hist.time,
          moneyType: hist.moneyType
      );
      state = state.copyWith(
        histories: [newHist, ...state.histories],
        isLoading: false
      );
    }
    catch(e){
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateHistories(HistoryModel hist)async{
    state = state.copyWith(isLoading: true);

    try{
      await _databaseConnection.updateHistory(hist);

      final updatedHist = HistoryModel(
          id: hist.id,
          title: hist.title,
          amount: hist.amount,
          category: hist.category,
          accountId: hist.accountId,
          date: hist.date,
          time: hist.time,
          moneyType: hist.moneyType
      );

      state = state.copyWith(
        histories: state.histories.map((i)=>i.id==updatedHist.id? updatedHist : i).toList(),
        isLoading: false
      );

    }
    catch(e){
      state = state.copyWith(isLoading: false,error: e.toString());
    }
  }

  Future<void> deleteHist(int id)async{
    try{
      state = state.copyWith(isLoading: true);

      await _databaseConnection.deleteHistory(id);

      state = state.copyWith(
        histories: state.histories.where((i)=>i.id!=id).toList(),
        isLoading: false
      );
    }
    catch(e){
      state = state.copyWith(isLoading: false,error: e.toString());
    }
  }

  Future<void> clearAllHistory()async{

    state = state.copyWith(isLoading: true);

    try{
      await _databaseConnection.emptyHistory();
      state = state.copyWith(
        histories: [],
        isLoading: false
      );
    }
    catch(e){
      state = state.copyWith(isLoading: false,error: e.toString());
    }
  }


}