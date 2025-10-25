import 'package:expense_tracker_app/screens/home_screen.dart';
import 'package:expense_tracker_app/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    return ScreenUtilInit(
      splitScreenMode: true,
      minTextAdapt: true,
      designSize: Size(375, 812),
      builder: (context,_){
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Home(),
          theme: lightTheme,
          darkTheme: darkTheme,
        );
      },
    );
  }
}


