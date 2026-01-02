import 'package:expense_tracker_app/riverpod/prefs_riverpod/prefs_riverpod.dart';
import 'package:expense_tracker_app/riverpod/theme_riverpod/theme_riverpod.dart';
import 'package:expense_tracker_app/screens/checkAuth.dart';
import 'package:expense_tracker_app/widgets/custom_appbar.dart';
import 'package:expense_tracker_app/widgets/onboarding_page_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final lastPageProvider = StateProvider<bool>((ref)=>false);
final currentIndexProviderOfOnBoard = StateProvider<int>((ref)=>0);

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {

  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ref.watch(themeModeProvider)==ThemeMode.dark;

    bool isLastPage = ref.watch(lastPageProvider);
    int currentIndex = ref.watch(currentIndexProviderOfOnBoard);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
            systemNavigationBarColor: theme.navigationBarTheme.backgroundColor,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark? Brightness.light:Brightness.dark
        ),
        actions: [
          !isLastPage?Padding(
            padding: const EdgeInsets.only(right: 20),
            child: TextButton(
                onPressed: ()=>_pageController.jumpToPage(4),
                child: Text('Skip',style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary,fontSize: 18),)
            ),
          ):SizedBox.shrink()
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: PageView(
                physics: NeverScrollableScrollPhysics(),
                controller: _pageController,
                children: [
                  BuildPage(
                    title: 'Welcome to ',
                    secondaryTitle: 'MoneyMate',
                    imageSource: 'assets/saving.png',
                    subtitle: 'Track your expenses and take control of your money effortlessly.',
                    pageController: _pageController,
                    pageCount: 5,
                  ),
                  BuildPage(
                    title: 'Insights ',
                    secondaryTitle: 'That matter',
                    imageSource: 'assets/stats.png',
                    subtitle: 'Visual reports help you understand and improve your spending habits.',
                    pageController: _pageController,
                    pageCount: 5,
                  ),
                  BuildPage(
                    title: 'Protect ',
                    secondaryTitle: 'Your data',
                    imageSource: 'assets/lock.png',
                    subtitle: 'Lock your app with a PIN to prevent unauthorized access.',
                    pageController: _pageController,
                    pageCount: 5,
                  ),
                  BuildPage(
                    title: 'Seamless ',
                    secondaryTitle: 'Infinite experience',
                    imageSource: 'assets/collapse.json',
                    isLottie: true,
                    subtitle: 'Navigate endlessly with elegant collapse effects designed for clarity and speed.',
                    pageController: _pageController,
                    pageCount: 5,
                  ),
                  BuildPage(
                    title: 'Select ',
                    secondaryTitle: 'currency',
                    imageSource: 'assets/currency.png',
                    isCurrencyPage: true,
                    subtitle: 'Select the currency you use to manage your finances.',
                    pageController: _pageController,
                    pageCount: 5,
                  ),
                ],
                onPageChanged: (val){
                  ref.read(lastPageProvider.notifier).state = (val==4);
                  ref.read(currentIndexProviderOfOnBoard.notifier).state = val;
                },
              )
          ),

          SizedBox(height: 80.h,),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Visibility(
                  visible: currentIndex>0,
                  child: GestureDetector(
                    onTap: ()=>_pageController.previousPage(duration: Duration(milliseconds: 200), curve: Curves.easeInOut),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back_ios,size: 15,),
                        Text('Previous',style: theme.textTheme.titleMedium,),
                      ],
                    ),
                  ),
                ),
                Spacer(),
                currentIndex==4?
                GestureDetector(
                  onTap: () {
                    ref.read(onBoardProvider.notifier).saveOnBoardingAppearance(true);
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => CheckAuth())
                    );
                  },
                  child: Row(
                    children: [
                      Text("Let's start",style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary,fontSize: 18),),
                      Icon(Icons.arrow_forward_ios,size: 15,color: theme.colorScheme.primary,)
                    ],
                  ),
                ):
                GestureDetector(
                  onTap: ()=>_pageController.nextPage(duration: Duration(milliseconds: 200), curve: Curves.easeInOut),
                  child: Row(
                    children: [
                      Text('Next',style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),),
                      Icon(Icons.arrow_forward_ios,size: 15,)
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h,),
        ],
      ),
    );
  }
}