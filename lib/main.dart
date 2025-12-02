import 'package:expense_tracker_app/notification/notification_service.dart';
import 'package:expense_tracker_app/riverpod/accent_riverpod/accent_riverpod.dart';
import 'package:expense_tracker_app/riverpod/theme_riverpod/theme_riverpod.dart';
import 'package:expense_tracker_app/screens/all_screens.dart';
import 'package:expense_tracker_app/screens/auth_screen/auth_screen.dart';
import 'package:expense_tracker_app/screens/checkAuth.dart';
import 'package:expense_tracker_app/screens/splash_screen.dart';
import 'package:expense_tracker_app/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_support/overlay_support.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initNotification();
  await NotificationService.requestPermission();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {

    final themeState = ref.watch(themeModeProvider);
    final accentColor = ref.watch(accentColorProvider);

    return ScreenUtilInit(
      splitScreenMode: true,
      minTextAdapt: true,
      designSize: Size(375, 812),
      builder: (context,_){
        return OverlaySupport.global(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
            themeMode: themeState,
            theme: lightTheme.copyWith(
              colorScheme: lightTheme.colorScheme.copyWith(
                primary: accentColor,
              ),
            ),
            darkTheme: darkTheme.copyWith(
              colorScheme: darkTheme.colorScheme.copyWith(
                primary: accentColor,
              ),
            ),
          ),
        );
      },
    );
  }
}


