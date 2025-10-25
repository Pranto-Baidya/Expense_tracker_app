

import 'package:expense_tracker_app/screens/accounts_screen.dart';
import 'package:expense_tracker_app/screens/categories_screen.dart';
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
          title: 'ExpenseMate',
          action: [
            Padding(
              padding: EdgeInsets.only(right: 5.w),
              child: IconButton(
                  onPressed: (){

                  },
                  icon: Icon(Icons.search,color: theme.iconTheme.color,size: 30,)
              ),
            )
          ],
      ),
     body: IndexedStack(
       index: index,
       children: [
         RecordsScreen(),
         StatsScreen(),
         AccountsScreen(),
         CategoryScreen()
       ],
     ),
     bottomNavigationBar: NavigationBar(
         backgroundColor: theme.navigationBarTheme.backgroundColor,
         selectedIndex: index,
         onDestinationSelected: (ind){
         ref.read(indexProvider.notifier).state = ind;
       },
         destinations: [
           NavigationDestination(
               selectedIcon: Icon(Icons.featured_play_list,color: Colors.black,),
               icon: Icon(Icons.featured_play_list_outlined,color: theme.iconTheme.color,),
               label: 'Records'
           ),
           NavigationDestination(
               selectedIcon: Icon(Icons.insert_chart,color: Colors.black,),
               icon: Icon(Icons.insert_chart_outlined,color: theme.iconTheme.color,),
               label: 'Statistics'
           ),
           NavigationDestination(
               selectedIcon: Icon(Icons.account_balance_wallet,color: Colors.black,),
               icon: Icon(Icons.account_balance_wallet_outlined,color: theme.iconTheme.color,),
               label: 'Accounts'
           ),
           NavigationDestination(
               selectedIcon: Icon(Icons.widgets,color: Colors.black,),
               icon: Icon(Icons.widgets_outlined,color: theme.iconTheme.color,),
               label: 'Categories'
           ),
         ]
       ),
      drawer: Drawer(),
    );
  }
}
