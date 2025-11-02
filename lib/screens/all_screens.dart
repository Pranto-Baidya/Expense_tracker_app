

import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:expense_tracker_app/screens/accounts_screen.dart';
import 'package:expense_tracker_app/screens/budgets_screen.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:expense_tracker_app/screens/stats_screen.dart';
import 'package:expense_tracker_app/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final indexProvider = StateProvider<int>((ref)=>0);

class AllScreens extends ConsumerStatefulWidget {
  const AllScreens({super.key});

  @override
  _AllScreensState createState() => _AllScreensState();
}

class _AllScreensState extends ConsumerState<AllScreens> {
  @override
  Widget build(BuildContext context) {
    final index = ref.watch(indexProvider);
    var theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppbar(
          title: 'MoneyMate',
          action: [
            Padding(
              padding: EdgeInsets.only(right: 5.w),
              child: IconButton(
                  onPressed: (){

                  },
                  icon: Icon(Icons.search,color: theme.iconTheme.color,size: 25,)
              ),
            )
          ],
      ),
     body: [
         RecordsScreen(),
         AccountsScreen(),
         CategoryScreen(),
         StatsScreen(),
       ][index],

     bottomNavigationBar: NavigationBar(
         backgroundColor: theme.navigationBarTheme.backgroundColor,
         indicatorColor: Colors.transparent,
         selectedIndex: index,
         height: 60,
         maintainBottomViewPadding: true,
         labelPadding: EdgeInsets.zero,
         onDestinationSelected: (ind){
         ref.read(indexProvider.notifier).state = ind;
       },
         destinations: [
           NavigationDestination(
               selectedIcon: Icon(Icons.feed,color: theme.colorScheme.primary,size: 25,),
               icon: Icon(Icons.feed_outlined,color: theme.iconTheme.color,size: 25,),
               label: 'Records'
           ),
           NavigationDestination(
               selectedIcon: Icon(Icons.account_balance_wallet,color: theme.colorScheme.primary,size: 25,),
               icon: Icon(Icons.account_balance_wallet_outlined,color: theme.iconTheme.color,size: 25,),
               label: 'Accounts'
           ),
           NavigationDestination(
               selectedIcon: Icon(Icons.paid,color: theme.colorScheme.primary,size: 25,),
               icon: Icon(Icons.paid_outlined,color: theme.iconTheme.color,size: 25,),
               label: 'Budget'
           ),
           NavigationDestination(
               selectedIcon: Icon(Icons.pie_chart,color: theme.colorScheme.primary,size: 25,),
               icon: Icon(Icons.pie_chart_outline,color: theme.iconTheme.color,size: 25,),
               label: 'Analysis'
           ),
         ]
       ),
      drawer: Drawer(),
    );
  }
}
