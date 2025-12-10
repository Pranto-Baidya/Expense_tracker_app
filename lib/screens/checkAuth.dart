import 'package:expense_tracker_app/riverpod/auth_riverpod/auth_riverpod.dart';
import 'package:expense_tracker_app/screens/all_screens.dart';
import 'package:expense_tracker_app/screens/auth_screen/auth_screen.dart';
import 'package:expense_tracker_app/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckAuth extends ConsumerWidget {
  const CheckAuth({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {

    final isLoading = ref.watch(authProvider).appLoading;

    if(isLoading){
      return Scaffold(
        appBar: CustomAppbar(title: '',toolbarHeight: 0,),
        body: Center(
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary,backgroundColor: Colors.transparent,),
        ),
      );
    }

    final hasPin = ref.watch(authProvider).isPinSet;

    if(hasPin){
      return AuthScreen();
    }
    else{
      return AllScreens();
    }
  }
}
