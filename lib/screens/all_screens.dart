

import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:expense_tracker_app/notification/notification_service.dart';
import 'package:expense_tracker_app/riverpod/auth_riverpod/auth_riverpod.dart';
import 'package:expense_tracker_app/riverpod/currency_riverpod/currency_pref.dart';
import 'package:expense_tracker_app/riverpod/prefs_riverpod/prefs_riverpod.dart';
import 'package:expense_tracker_app/riverpod/theme_riverpod/theme_riverpod.dart';
import 'package:expense_tracker_app/screens/accounts_screen.dart';
import 'package:expense_tracker_app/screens/analysis_screen/stats_screen.dart';
import 'package:expense_tracker_app/screens/budgets_screen.dart';
import 'package:expense_tracker_app/screens/category_screen.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:expense_tracker_app/screens/search_records_screen.dart';
import 'package:expense_tracker_app/widgets/custom_app_button.dart';
import 'package:expense_tracker_app/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final indexProvider = StateProvider<int>((ref)=>0);
final obSecureProvider = StateProvider<bool>((ref)=>true);


class AllScreens extends ConsumerStatefulWidget {
  const AllScreens({super.key});

  @override
  _AllScreensState createState() => _AllScreensState();
}


class _AllScreensState extends ConsumerState<AllScreens> {

  final GlobalKey<RecordsScreenState> _recordKey = GlobalKey<RecordsScreenState>();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _pinController = TextEditingController();

  void chooseTheme() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        var theme = Theme.of(context);
        return Consumer(
          builder: (context, ref, _) {
            final selected = ref.watch(themeModeProvider);
            final selectedNotifier = ref.read(themeModeProvider.notifier);

            return AlertDialog(
              backgroundColor: theme.cardColor,
              title: Row(
                children: [
                  Text(
                    'Choose theme',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.primary,
                      size: 30,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...ThemeMode.values.map((mode) {
                    return RadioListTile(
                      value: mode,
                      tileColor: Colors.transparent,
                      fillColor: WidgetStatePropertyAll(
                        Theme.of(context).colorScheme.primary,
                      ),
                      title: mode == ThemeMode.system ? Text('System') : mode == ThemeMode.light ? Text('Light') : Text('Dark'),
                      groupValue: selected,
                      onChanged: (val) {
                        if (val != null) {
                          selectedNotifier.saveTheme(val);
                        }
                      },
                    );
                  })
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Close',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void chooseCurrency(){
    showDialog(
        context: context, 
        builder: (BuildContext context){
          var theme = Theme.of(context);
          List<String> currencies = ["\$","€","₹","৳","¥","₽","R"];
          List<String> currencyName = ["USD", "EUR", "INR", "BDT", "JPY/CNY", "RUB", "ZAR"];
          
          Map<String,String> currMap = {};
          
          for(var i=0; i<currencies.length; i++){
            currMap[currencies[i]] = currencyName[i];
          }

          return Consumer(
              builder: (context,ref,_){
                
                final selected = ref.watch(newCurrencyProvider).currency;
                final selectedNotifier = ref.read(newCurrencyProvider.notifier);
                
                return AlertDialog(
                  backgroundColor: theme.cardColor,
                  title: Row(
                    children: [
                      Text('Choose currency',style: theme.textTheme.titleMedium?.copyWith(fontSize: 18,color: theme.colorScheme.primary),),
                      Spacer(),
                      IconButton(
                          onPressed: (){
                            Navigator.pop(context);
                          }, 
                          icon: Icon(Icons.close,color: theme.colorScheme.primary,size: 30,)
                      )
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...currMap.entries.map((curr){
                        return RadioListTile(
                          tileColor: Colors.transparent,
                          value: curr.key,
                          fillColor: WidgetStatePropertyAll(theme.colorScheme.primary),
                          title: Row(
                            children: [
                              Text(curr.key),
                              SizedBox(width: 5,),
                              Text(curr.value)
                            ],
                          ),
                          groupValue: selected,
                          onChanged: (val){
                            if(val!=null){
                              selectedNotifier.saveCurrency(val);
                            }
                          },
                            
                        );
                      })
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Close',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                );
              }
          );
        }
    );
  }

  void setPin(){
    showDialog(
        context: context,
        builder: (BuildContext context){
          var theme = Theme.of(context);
          return Consumer(
              builder: (context,ref,_){
                final obSecureState = ref.watch(obSecureProvider);
                final authNotifier = ref.read(authProvider.notifier);
                return AlertDialog(
                  backgroundColor: theme.cardColor,
                  title:  Row(
                    children: [
                      Text('Set 4 digit PIN',style: theme.textTheme.titleMedium?.copyWith(fontSize: 18,color: theme.colorScheme.primary),),
                      Spacer(),
                      IconButton(
                          onPressed: (){
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close,color: theme.colorScheme.primary,size: 30,)
                      )
                    ],
                  ),
                  content: Form(
                   key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _pinController,
                          obscureText: obSecureState,
                          keyboardType: TextInputType.number,
                          validator: (value){
                            if(value!.isEmpty){
                              return "Please enter 4 digit pin code";
                            }
                            else if(value.length<4 || value.length>4){
                              return "Pin code must be of only 4 digits";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter digits',
                            suffixIcon: IconButton(
                                onPressed: (){
                                 ref.read(obSecureProvider.notifier).state = !ref.read(obSecureProvider.notifier).state;
                                },
                                icon: obSecureState?Icon(Icons.visibility_off_outlined,color: theme.iconTheme.color,):Icon(Icons.visibility_outlined,color: theme.iconTheme.color,)
                            )
                          ),
                        ),
                        SizedBox(height: 15.h,),
                        CustomAppButton(
                            onPressed: (){
                              if(_formKey.currentState!.validate()){
                                authNotifier.savePass(_pinController.text);
                                Navigator.pop(context);
                              }
                            },
                            title: 'Set pin'
                        )
                      ],
                    ),
                  ),
                );
              }
          );
        }
    );
  }


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
                    child: Icon(Icons.search,color: Colors.white,size: 30,),
                  )
              ),
            )
          ],
      ),
     body: [
         RecordsScreen(key: _recordKey,),
         StatsScreen(),
         BudgetScreen(),
         AccountsScreen(),
         CategoryScreen()
       ][index],

     bottomNavigationBar: Container(
       decoration: BoxDecoration(
           border: Border(
               top: BorderSide(color: ref.watch(themeModeProvider)==ThemeMode.dark? Colors.grey.shade500 :Colors.grey.shade500,width: 0.5)
           ),
     ),
       child: NavigationBar(
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
                 selectedIcon: Icon(Icons.analytics,color: theme.colorScheme.primary,size: 25,),
                 icon: Icon(Icons.analytics_outlined,color: theme.iconTheme.color,size: 25,),
                 label: 'Analysis'
             ),
             NavigationDestination(
                 selectedIcon: Icon(Icons.paid,color: theme.colorScheme.primary,size: 25,),
                 icon: Icon(Icons.paid_outlined,color: theme.iconTheme.color,size: 25,),
                 label: 'Budget'
             ),
             NavigationDestination(
                 selectedIcon: Icon(Icons.account_balance_wallet,color: theme.colorScheme.primary,size: 25,),
                 icon: Icon(Icons.account_balance_wallet_outlined,color: theme.iconTheme.color,size: 25,),
                 label: 'Accounts'
             ),
             NavigationDestination(
                 selectedIcon: Icon(Icons.space_dashboard_rounded,color: theme.colorScheme.primary,size: 25,),
                 icon: Icon(Icons.space_dashboard_outlined,color: theme.iconTheme.color,size: 25,),
                 label: 'Category'
             ),
           ]
       ),
     ),
      drawer: Drawer(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),

        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.cardColor,
              ) ,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: AssetImage('assets/icon.png'),
                  ),
                  SizedBox(height: 10.h,),
                  Text('MoneyMate',style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),),
                  SizedBox(height: 5.h,),
                  Text('Version : 2.23 (Free)',style: theme.textTheme.titleSmall,)
                ],
              ),
            ),
            ListTile(
              tileColor: Colors.transparent,
              title: Text('Preferences',style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary,fontSize: 18),),
            ),
            ListTile(
                onTap: (){

                },
                tileColor: Colors.transparent,
                leading: Icon(Icons.color_lens_outlined,color: theme.iconTheme.color,),
                title: Text('Accent color'),
                trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
            ),
            Divider(indent: 10,endIndent: 10,thickness: 1,color: theme.colorScheme.primary,),
            ListTile(
              onTap: chooseTheme,
              tileColor: Colors.transparent,
              leading: Icon(Icons.wb_sunny_outlined,color: theme.iconTheme.color,),
              title: Text('Display mode'),
              trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
            ),
            Divider(indent: 10,endIndent: 10,thickness: 1,color: theme.colorScheme.primary,),
            ListTile(
                onTap: chooseCurrency,
                tileColor: Colors.transparent,
                leading: Icon(Icons.attach_money,color: theme.iconTheme.color,),
                title: Text('Currency sign'),
                trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
            ),
            Divider(indent: 10,endIndent: 10,thickness: 1,color: theme.colorScheme.primary,),
            ListTile(
                tileColor: Colors.transparent,
                leading: Icon(Icons.lock_outline,color: theme.iconTheme.color,),
                title: Text('Protection'),
                trailing:Switch(
                    value: ref.watch(authProvider).isPinSet,
                    onChanged: (val){
                      if(val==true){
                        setPin();
                      }
                      else{
                        ref.read(authProvider.notifier).deletePin();
                      }
                    }
                )
            ),
            Divider(indent: 10,endIndent: 10,thickness: 1,color: theme.colorScheme.primary,),
            ListTile(
                tileColor: Colors.transparent,
                leading: Icon(Icons.notifications_none,color: theme.iconTheme.color,),
                title: Text('Remind everyday'),
                trailing: Switch(
                    value: ref.watch(prefsProvider),
                    onChanged: (val){
                      if(val==true) {
                        ref.read(prefsProvider.notifier).savePref(val);
                        NotificationService.showImmediateNotification();
                      }
                      else{
                        NotificationService.cancelNotification();
                        ref.read(prefsProvider.notifier).savePref(val);
                      }
                    })
            ),
            Divider(indent: 10,endIndent: 10,thickness: 1,color: theme.colorScheme.primary,),
            ListTile(
              tileColor: Colors.transparent,
              title: Text('About app',style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary,fontSize: 18),),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text('MoneyMate',style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),),
                ),
                SizedBox(height: 5.h,),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text('Your smart companion for budgeting, saving, and spending wisely.',style: theme.textTheme.titleSmall,),
                ),
                SizedBox(height: 10.h,),
                Divider(indent: 10,endIndent: 10,thickness: 1,color: theme.colorScheme.primary,),
                SizedBox(height: 20.h,),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text('Developed by Pranto Baidya',style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w100),),
                ),
                SizedBox(height: 5.h,),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text('Contact@Prantobhai.com',style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w100),),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
