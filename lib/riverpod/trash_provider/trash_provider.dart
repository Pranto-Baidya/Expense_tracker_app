
import 'package:expense_tracker_app/database/db_connection.dart';
import 'package:expense_tracker_app/models/trash_model.dart';
import 'package:flutter_riverpod/legacy.dart';

final trashProvider = StateNotifierProvider<TrashNotifier,TrashState>((ref)=>TrashNotifier());

class TrashState{
  final List<TrashModel> allTrash;
  final bool isLoading;

  TrashState({
    this.allTrash = const [],
    this.isLoading = false
  });

  TrashState copyWith({List<TrashModel>? allTrash, bool? isLoading}){
    return TrashState(
        allTrash: allTrash ?? this.allTrash,
        isLoading: isLoading ?? this.isLoading
    );
  }
}

class TrashNotifier extends StateNotifier<TrashState>{
  TrashNotifier() : super(TrashState());

  final DatabaseConnection _databaseConnection = DatabaseConnection();

  Future<void> getAllTrashData()async{
    state = state.copyWith(isLoading: true);

    try {
      final data = await _databaseConnection.getAllTrashes();
      state = state.copyWith(
          allTrash: data,
          isLoading: false
      );
    }
    catch(e){
      print('Error loading trash: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addToTrash(TrashModel trash) async {
    try {
      await _databaseConnection.insertTrash(trash);
      await getAllTrashData();
    } catch (e) {
      print('Error adding to trash: $e');
    }
  }

  Future<void> permanentlyDelete(int id) async {
    try {
      await _databaseConnection.deleteTrash(id);
      await getAllTrashData();
    } catch (e) {
      print('Error permanently deleting: $e');
    }
  }

  Future<void> cleanOldTrash({int daysOld = 30}) async {
    try {
      await _databaseConnection.deleteOldTrash(daysOld: daysOld);
      await getAllTrashData();
    } catch (e) {
      print('Error cleaning old trash: $e');
    }
  }

  Future<void> emptyTrash()async{
    try{
      await _databaseConnection.clearAllTrash();
      state = state.copyWith(allTrash: []);
    }
    catch(e){
      print('Error cleaning old trash: $e');
    }
  }
}
