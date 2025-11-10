

import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:expense_tracker_app/screens/accounts_screen.dart';
import 'package:expense_tracker_app/screens/analysis_screen/stats_screen.dart';
import 'package:expense_tracker_app/screens/budgets_screen.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:expense_tracker_app/screens/search_records_screen.dart';
import 'package:expense_tracker_app/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
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

  final GlobalKey<RecordsScreenState> _recordKey = GlobalKey<RecordsScreenState>();

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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchRecordsScreen()),
                    ).then((result) {
                      if (result != null && result is Map<String, dynamic>) {
                        final expense = result['expense'] as ExpenseModel;
                        final action = result['action'] as String;

                        if (action == 'edit') {
                          _recordKey.currentState?.editExpenseDialogue(expense);
                        } else if (action == 'delete') {
                          _recordKey.currentState?.deleteAlert(expense);
                        }
                      }
                    });

                  },
                  icon: Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: Icon(Icons.search,color: theme.iconTheme.color,size: 30,),
                  )
              ),
            )
          ],
      ),
     body: [
         RecordsScreen(key: _recordKey,),
         AccountsScreen(),
         CategoryScreen(),
         StatsScreen()
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
         ref.read(isIncomeProvider.notifier).state = false;
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
               selectedIcon: Icon(Icons.analytics,color: theme.colorScheme.primary,size: 25,),
               icon: Icon(Icons.analytics_outlined,color: theme.iconTheme.color,size: 25,),
               label: 'Analysis'
           ),
         ]
       ),
      drawer: Drawer(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}
