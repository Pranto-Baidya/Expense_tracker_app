import 'dart:ui';

import 'package:expense_tracker_app/widgets/app_colors.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final accentColorProvider = StateNotifierProvider<AccentColorNotifier,Color>((ref)=>AccentColorNotifier());

class AccentColorNotifier extends StateNotifier<Color>{
  AccentColorNotifier(): super(AppColors.mainColor){
    _loadAccentColor();
  }

  Future<void> _loadAccentColor()async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final val = preferences.getString('saveColor');
    if(val!=null){
      state = Color(int.parse(val,radix: 16));
    }
  }

  Future<void> saveAccentColor(Color value)async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString('saveColor', value.value.toRadixString(16).padLeft(8,'0'));
    state = value;
  }
}