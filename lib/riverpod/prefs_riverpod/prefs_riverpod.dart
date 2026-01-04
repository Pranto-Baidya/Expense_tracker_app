
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

final tipPrefProvider = StateNotifierProvider<TipPrefNotifier, bool>((ref) {
  return TipPrefNotifier();
});

class TipPrefNotifier extends StateNotifier<bool> {
  TipPrefNotifier() : super(true) {
    loadTip();
  }

  Future<void> loadTip() async {
    final prefs = await SharedPreferences.getInstance();
    bool data = prefs.getBool('save') ?? true;
    state = data;
  }

  Future<void> save(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('save', value);
    state = value;
  }
}


final collapseDashboardPrefProvider = StateNotifierProvider<CollapseDashBoardPrefNotifier,bool>((ref)=>CollapseDashBoardPrefNotifier());

class CollapseDashBoardPrefNotifier extends StateNotifier<bool>{

  CollapseDashBoardPrefNotifier() : super(false){
    _loadCollapsePref();
  }

  Future<void> _loadCollapsePref()async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final val = preferences.getBool('collapse') ?? false;
    state = val;
  }

  Future<void> saveCollapsePref(bool value)async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool('collapse', value);
    state = value;
  }

}

final onBoardProvider = StateNotifierProvider<SaveOnBoardNotifier,bool>((ref)=>SaveOnBoardNotifier());

class SaveOnBoardNotifier extends StateNotifier<bool>{

  SaveOnBoardNotifier() : super(false);

  Future<void> loadOnBoardPref()async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    bool data = preferences.getBool('onBoard') ?? false;
    state = data;
  }

  Future<void> saveOnBoardingAppearance(bool val)async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onBoard', val);
    state = val;
  }
}
