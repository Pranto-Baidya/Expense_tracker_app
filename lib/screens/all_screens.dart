

import 'dart:io';
import 'dart:math';

import 'package:expense_tracker_app/database/db_connection.dart';
import 'package:expense_tracker_app/export_csv/export_service.dart';
import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:expense_tracker_app/notification/notification_service.dart';
import 'package:expense_tracker_app/riverpod/accent_riverpod/accent_riverpod.dart';
import 'package:expense_tracker_app/riverpod/auth_riverpod/auth_riverpod.dart';
import 'package:expense_tracker_app/riverpod/budget_riverpod/budget_riverpod.dart';
import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:expense_tracker_app/riverpod/category_riverpod/category_riverpod.dart';
import 'package:expense_tracker_app/riverpod/currency_riverpod/currency_pref.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/riverpod/prefs_riverpod/prefs_riverpod.dart';
import 'package:expense_tracker_app/riverpod/save_record_filter/save_record_filter.dart';
import 'package:expense_tracker_app/riverpod/theme_riverpod/theme_riverpod.dart';
import 'package:expense_tracker_app/screens/accounts_screen.dart';
import 'package:expense_tracker_app/screens/analysis_screen/stats_screen.dart';
import 'package:expense_tracker_app/screens/budgets_screen.dart';
import 'package:expense_tracker_app/screens/category_screen.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:expense_tracker_app/screens/search_records_screen.dart';
import 'package:expense_tracker_app/screens/settings_screen.dart';
import 'package:expense_tracker_app/widgets/custom_app_button.dart';
import 'package:expense_tracker_app/widgets/custom_appbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';



final indexProvider = StateProvider<int>((ref)=>0);
final obSecureProvider = StateProvider<bool>((ref)=>true);



class AllScreens extends ConsumerStatefulWidget {
  const AllScreens({super.key});

  @override
  _AllScreensState createState() => _AllScreensState();
}


class _AllScreensState extends ConsumerState<AllScreens> {

  final GlobalKey<RecordsScreenState> _recordKey = GlobalKey<RecordsScreenState>();

  final DatabaseConnection _databaseConnection = DatabaseConnection();

  void showFilterDialogue(){
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context){
          var theme = Theme.of(context);
          return Consumer(
              builder: (context,ref,_){
                final filterOptionsState = ref.watch(saveRecordFilterProvider);
                final filterOptionsNotifier = ref.read(saveRecordFilterProvider.notifier);

                final filteredRecord = ref.read(expenseProvider.notifier);
                final saveFilterNotifier = ref.read(saveRecordFilterProvider.notifier);

                return AlertDialog(
                  backgroundColor: theme.cardColor,
                  title: Text('Display options',style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...FilterRecordOptions.values.map((val){
                        return RadioListTile(
                            tileColor: Colors.transparent,

                            title: val==FilterRecordOptions.daily?Text('Daily',style: theme.textTheme.titleMedium,)
                                  :val==FilterRecordOptions.weekly?Text('Weekly',style: theme.textTheme.titleMedium,)
                                  :val==FilterRecordOptions.monthly?Text('Monthly',style: theme.textTheme.titleMedium,)
                                  :Text('Yearly',style: theme.textTheme.titleMedium,),

                            fillColor: WidgetStatePropertyAll(theme.colorScheme.primary,),
                            value: val,
                            groupValue: filterOptionsState,
                            onChanged: (option){
                              if(option!=null) {
                                filterOptionsNotifier.saveFilter(option);
                                ref.read(expenseProvider.notifier).setActiveFilter(option.name);
                              }
                            },
                        );
                      })
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: (){
                          switch(filterOptionsState){
                            case FilterRecordOptions.daily:
                              filteredRecord.filterRecordsByDay(ref.read(selectedDateProvider));
                              saveFilterNotifier.saveFilter(filterOptionsState);
                              break;
                            case FilterRecordOptions.weekly:
                              filteredRecord.filterRecordsByWeek(ref.read(selectedDateProvider));
                              saveFilterNotifier.saveFilter(filterOptionsState);
                              break;
                            case FilterRecordOptions.monthly:
                              filteredRecord.filterRecordsByMonth(ref.read(selectedDateProvider), ref.read(selectedTimeProvider));
                              saveFilterNotifier.saveFilter(filterOptionsState);
                              break;
                            case FilterRecordOptions.yearly:
                              filteredRecord.filterRecordsByYear(ref.read(selectedDateProvider));
                              saveFilterNotifier.saveFilter(filterOptionsState);
                              break;
                          }
                          Navigator.pop(context);
                        },
                        child: Text('Done',style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),)
                    )
                  ],
                );
              }
          );
        }
    );
  }

  void showProgress(){
    final random = Random();
    final delayed = 2 + random.nextInt(3);

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context){
          Future.delayed(Duration(seconds: delayed),()async{
             final path = await ExportsService.exportToCSV(ref.read(expenseProvider).filteredRecord);

             print(path);

             Navigator.of(context,rootNavigator: true).pop();

             Navigator.of(context,rootNavigator: true).pop();

             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 margin: EdgeInsets.all(10),
                 behavior: SnackBarBehavior.floating,
                 padding: EdgeInsets.all(8),
                 duration: Duration(seconds: 5),
                 backgroundColor: Colors.green,
                   content: Row(
                     children: [
                       Text('Exported successfully',style: TextStyle(color: Colors.white),),
                       Spacer(),
                       TextButton(
                           onPressed: ()async{
                             await OpenFile.open(path);
                           },
                           child: Text('Open file',style: TextStyle(color: Colors.white),)
                       )
                     ],
                   )
               ),
             );

          });
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text('Exporting to CSV',style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Please wait...',style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 15),),
                Spacer(),
                CircularProgressIndicator(color: Theme.of(context).colorScheme.primary,)
              ],
            ),
          );
        }
    );
  }

  void exportRecordsSheet(){
    showModalBottomSheet(
        backgroundColor: Theme.of(context).cardColor,
        showDragHandle: true,
        isScrollControlled: true,
        enableDrag: true,
        context: context,
        builder: (BuildContext context){
          var theme = Theme.of(context);
          return Container(
            height: 540.h,
            width: double.infinity.w,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(15.r)
            ),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Export records to CSV',style: theme.textTheme.titleLarge,),
                    SizedBox(height: 20.h,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage('assets/transparent.png'),
                          backgroundColor: ref.watch(accentColorProvider),
                        ),
                        Icon(Icons.arrow_right_alt,size: 60,),
                        Icon(Icons.upload_file,size: 90,color: theme.colorScheme.primary,),
                      ],
                    ),
                    SizedBox(height: 10.h,),
                    Text('Guidelines',style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),),
                    SizedBox(height: 10.h,),
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: theme.cardColor,
                          border: Border.all(color: theme.colorScheme.primary,width: 1.5),
                          borderRadius: BorderRadius.circular(15.r)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('1. All records can be exported as a worksheet (Currently in CSV format)',style: theme.textTheme.titleSmall,),
                          SizedBox(height: 10.h,),
                          Text("2. Note that, exported files (.csv) are not backup files and you can't restore data from these files",style: theme.textTheme.titleSmall,),
                          SizedBox(height: 10.h,),
                          Text("3. MoneyMate will create a folder and the (.csv) file will be saved to '/storage/emulated/0/Android/data/com.example.expense_tracker_app/files/MoneyMate'",style: theme.textTheme.titleSmall,),
                          SizedBox(height: 10.h,),
                          Text("4. Tap the 'Export now' button to get started ",style: theme.textTheme.titleSmall,)
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h,),
                    CustomAppButton(
                        onPressed: (){
                          showProgress();
                        },
                        title: 'Export now',
                        width: 150.w,
                    ),
                    SizedBox(height: 20.h,),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

  Future<void> requestStoragePermission()async{
    if(Platform.isAndroid) {
      var status = await Permission.storage.request();
      if(!status.isGranted){
        throw Exception('Storage permission denied');
      }
    }
  }

  void backupRestoreSheet(){
    showModalBottomSheet(
        backgroundColor: Theme.of(context).cardColor,
        showDragHandle: true,
        isScrollControlled: true,
        enableDrag: true,
        context: context,
        builder: (BuildContext context){
          var theme = Theme.of(context);

          return Container(
            height: 500.h,
            width: double.infinity.w,
            decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(15.r)
            ),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Backup & Restore records',style: theme.textTheme.titleLarge,),
                    SizedBox(height: 20.h,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage('assets/transparent.png'),
                          backgroundColor: ref.watch(accentColorProvider),
                        ),
                        Icon(Icons.compare_arrows_outlined,size: 70,),
                        Icon(Icons.save_outlined,size: 90,color: theme.colorScheme.primary,),
                      ],
                    ),
                    SizedBox(height: 10.h,),
                    Text('Guidelines',style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),),
                    SizedBox(height: 10.h,),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: theme.cardColor,
                          border: Border.all(color: theme.colorScheme.primary,width: 1.5),
                          borderRadius: BorderRadius.circular(15.r)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('1. All records can be exported as a worksheet (Currently in CSV format)',style: theme.textTheme.titleSmall,),
                          SizedBox(height: 10.h,),
                          Text("2. Note that, exported files (.csv) are not backup files and you can't restore data from these files",style: theme.textTheme.titleSmall,),
                          SizedBox(height: 10.h,),
                          Text("3. MoneyMate will create a folder and the (.csv) file will be saved to '/storage/emulated/0/Download/MoneyMate'",style: theme.textTheme.titleSmall,),
                          SizedBox(height: 10.h,),
                          Text("4. Tap the 'Export now' button to get started ",style: theme.textTheme.titleSmall,)
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomAppButton(
                          onPressed: ()async{
                            try {
                              await requestStoragePermission();

                              final file = await _databaseConnection.createBackupFile();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    margin: EdgeInsets.all(10),
                                    behavior: SnackBarBehavior.floating,
                                    padding: EdgeInsets.all(8),
                                    duration: Duration(seconds: 5),
                                    backgroundColor: Colors.green,
                                    content: Text('Backup successful: ${file.path}', style: TextStyle(color: Colors.white),)
                                ),
                              );
                              Navigator.pop(context);
                            }catch(e){
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Backup failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          title: 'Backup now',
                          width: 150.w,
                          height: 55,
                        ),
                        CustomAppButton(
                          onPressed: ()async{
                            
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['json'],
                                withData: true
                            );

                            if(result!=null){
                              final file = File(result.files.single.path!);
                              await _databaseConnection.restoreDataFromBackup(file);

                              ref.invalidate(expenseProvider);
                              ref.invalidate(cardsProvider);
                              ref.invalidate(budgetProvider);
                              ref.invalidate(categoryProvider);

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      margin: EdgeInsets.all(10),
                                      behavior: SnackBarBehavior.floating,
                                      padding: EdgeInsets.all(8),
                                      duration: Duration(seconds: 5),
                                      backgroundColor: Colors.green,
                                      content: Text('Success! Backup restored successfully',style: TextStyle(color: Colors.white),)
                                  )
                              );
                            }
                          },
                          title: 'Restore now',
                          width: 150.w,
                          height: 55,
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h,),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

  void deleteEverything(){
    showDialog(
        context: context,
        builder: (BuildContext context){
          var theme = Theme.of(context);
          return Consumer(
              builder: (context,ref,_){
                return AlertDialog(
                  backgroundColor: theme.cardColor,
                  title: Row(
                    children: [
                      Text('Please wait!',style: theme.textTheme.titleMedium?.copyWith(fontSize: 20,color: Colors.red),),
                      Spacer(),
                      IconButton(onPressed: ()=>Navigator.pop(context), icon: Icon(Icons.close,color: theme.iconTheme.color,size: 30,))
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Are you sure you want to delete everything?',style: theme.textTheme.titleMedium,),
                      SizedBox(height: 10.h,),
                      Text('This action will erase everything including: ',style: theme.textTheme.titleMedium,),
                      SizedBox(height: 10.h,),
                      Text('Records,Statistics,Budgets,Accounts and Categories.',style: theme.textTheme.titleMedium,)
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: ()async{
                          await _databaseConnection.deleteAllTables();

                          ref.invalidate(expenseProvider);
                          ref.invalidate(categoryProvider);
                          ref.invalidate(cardsProvider);
                          ref.invalidate(budgetProvider);

                          Navigator.pop(context);
                        },
                        child: Text('Delete all',style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),)
                    )
                  ],
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
            Visibility(
              visible: index<2,
              replacement: SizedBox.shrink(),
              child: Padding(
                padding: EdgeInsets.only(right: 5.w),
                child: IconButton(
                    onPressed: showFilterDialogue,
                    icon: Icon(Icons.filter_list,color: Colors.white,size: 30,)
                ),
              ),
            ),
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
                    backgroundImage: AssetImage('assets/transparent.png'),
                    backgroundColor: ref.watch(accentColorProvider),
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
                onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (context)=>SettingsScreen())),
                tileColor: Colors.transparent,
                leading: Icon(Icons.settings,color: theme.iconTheme.color,),
                title: Text('Settings'),
                trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
            ),
            Divider(indent: 0,endIndent: 0,thickness: 0.8,color: theme.colorScheme.primary,),
            ListTile(
              tileColor: Colors.transparent,
              title: Text('Management',style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary,fontSize: 18),),
            ),
            ListTile(
                onTap: ()=> exportRecordsSheet(),
                tileColor: Colors.transparent,
                leading: Icon(Icons.upload_file,color: theme.iconTheme.color,),
                title: Text('Export records'),
                trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
            ),
            ListTile(
                onTap: backupRestoreSheet,
                tileColor: Colors.transparent,
                leading: Icon(Icons.save_outlined,color: theme.iconTheme.color,),
                title: Text('Backup & Restore'),
                trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
            ),
            ListTile(
                onTap: deleteEverything,
                tileColor: Colors.transparent,
                leading: Icon(Icons.delete_outline,color: theme.iconTheme.color,),
                title: Text('Delete & Reset'),
                trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
            ),
            Divider(indent: 0,endIndent: 0,thickness: 0.8,color: theme.colorScheme.primary,),
            ListTile(
              tileColor: Colors.transparent,
              title: Text('Application',style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary,fontSize: 18),),
            ),
            ListTile(
                onTap: (){},
                tileColor: Colors.transparent,
                leading: Icon(Icons.info_outlined,color: theme.iconTheme.color,),
                title: Text('About app'),
                trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
            ),
            ListTile(
                onTap: (){},
                tileColor: Colors.transparent,
                leading: Icon(Icons.share_outlined,color: theme.iconTheme.color,),
                title: Text('Share app'),
                trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
            ),
            ListTile(
                onTap: (){},
                tileColor: Colors.transparent,
                leading: Icon(Icons.power_settings_new_outlined,color: theme.iconTheme.color,),
                title: Text('Exit from the app'),
                trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
            ),
          ],
        ),
      ),
    );
  }
}
