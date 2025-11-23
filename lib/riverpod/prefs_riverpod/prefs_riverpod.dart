
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final prefsProvider = StateNotifierProvider<PrefsNotifier,bool>((ref){
  return PrefsNotifier();
});

class PrefsNotifier extends StateNotifier<bool>{

  PrefsNotifier() : super(false){
    _loadPref();
  }

  Future<void> _loadPref()async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final val =  preferences.getBool('notification') ?? false;
    state = val;
  }

  Future<void> savePref(bool value)async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool('notification', value);
    state = value;
  }
}