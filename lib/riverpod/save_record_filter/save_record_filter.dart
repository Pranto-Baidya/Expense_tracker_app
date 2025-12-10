import 'package:expense_tracker_app/screens/all_screens.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FilterRecordOptions{daily,weekly,monthly,yearly}

final saveRecordFilterProvider = StateNotifierProvider<SaveRecordFilter,FilterRecordOptions>((ref){
  return SaveRecordFilter();
});

class SaveRecordFilter extends StateNotifier<FilterRecordOptions>{

  SaveRecordFilter() : super(FilterRecordOptions.monthly){
    _loadFilter();
  }

  Future<void> _loadFilter()async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final value = preferences.getString('saveFilter');
    if(value!=null){
      state = FilterRecordOptions.values.firstWhere((i)=> i.name == value, orElse: ()=>FilterRecordOptions.monthly);
    }
  }

  Future<void> saveFilter(FilterRecordOptions filter)async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString('saveFilter', filter.name);
    state = filter;
  }
}