import 'package:expense_tracker_app/riverpod/accent_riverpod/accent_riverpod.dart';
import 'package:expense_tracker_app/riverpod/theme_riverpod/theme_riverpod.dart';
import 'package:expense_tracker_app/screens/checkAuth.dart';
import 'package:expense_tracker_app/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {

  late AnimationController _animationController;

  late Animation<Offset> _slideAnimation;

  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 900)
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, -0.35),end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: Curves.fastOutSlowIn));

    _fadeAnimation = Tween<double>(begin: 0,end: 1).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _animationController.forward(from: 0);

    WidgetsBinding.instance.addPostFrameCallback((_)async{
      await Future.delayed(Duration(seconds: 1)).then((_){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>CheckAuth()));
      });
    });

    super.initState();
  }

  List<BoxShadow> customShadow(bool isDark,WidgetRef ref) {
    final accentColor = ref.read(accentColorProvider);
    return isDark
        ? [
      BoxShadow(
        color: accentColor.withOpacity(0.6),
        blurRadius: 20,
        spreadRadius: -2,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.05),
        blurRadius: 10,
        spreadRadius: -4,
        offset: const Offset(0, -4),
      ),
    ]
        : [
      BoxShadow(
        offset: const Offset(0, 12),
        blurRadius: 32,
        spreadRadius: -4,
        color: accentColor.withOpacity(0.12),
      ),
      BoxShadow(
        offset: const Offset(0, -4),
        blurRadius: 16,
        spreadRadius: -2,
        color: Colors.white.withOpacity(0.5),
      ),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final accentColor = ref.watch(accentColorProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppbar(
         title: '',
         toolbarHeight: 0,
     ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150.w,
              height: 150.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
                boxShadow: customShadow(isDark,ref)
              ),
              child: SlideTransition(
                  position: _slideAnimation,
                  child: Image.asset('assets/transparent.png')
              ),
            ),
            SizedBox(height: 30.h,),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('MoneyMate',style: theme.textTheme.headlineMedium?.copyWith(color: accentColor),),
                  SizedBox(height: 10.h,),
                  Text('Budget, Save And Spend—Smartly.',style: theme.textTheme.titleMedium,),
                ],
              ),
            )
          ],
        ),
      ),

    );
  }
}
