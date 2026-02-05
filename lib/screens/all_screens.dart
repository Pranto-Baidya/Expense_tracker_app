

import 'dart:io';
import 'dart:math';

import 'package:expense_tracker_app/database/db_connection.dart';
import 'package:expense_tracker_app/export_csv/export_service.dart';
import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:expense_tracker_app/riverpod/accent_riverpod/accent_riverpod.dart';
import 'package:expense_tracker_app/riverpod/budget_riverpod/budget_riverpod.dart';
import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:expense_tracker_app/riverpod/category_riverpod/category_riverpod.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/riverpod/prefs_riverpod/prefs_riverpod.dart';
import 'package:expense_tracker_app/riverpod/save_record_filter/save_record_filter.dart';
import 'package:expense_tracker_app/riverpod/theme_riverpod/theme_riverpod.dart';
import 'package:expense_tracker_app/screens/about_app.dart';
import 'package:expense_tracker_app/screens/accounts_screen.dart';
import 'package:expense_tracker_app/screens/analysis_screen/stats_screen.dart';
import 'package:expense_tracker_app/screens/budgets_screen.dart';
import 'package:expense_tracker_app/screens/category_screen.dart';
import 'package:expense_tracker_app/screens/history_screen/transaction_history.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:expense_tracker_app/screens/search_records_screen.dart';
import 'package:expense_tracker_app/screens/settings_screen.dart';
import 'package:expense_tracker_app/widgets/animated_nav_icon.dart';
import 'package:expense_tracker_app/widgets/custom_app_button.dart';
import 'package:expense_tracker_app/widgets/custom_appbar.dart';
import 'package:expense_tracker_app/widgets/listAnimation_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';



final indexProvider = StateProvider<int>((ref)=>0);
final obSecureProvider = StateProvider<bool>((ref)=>true);


class AllScreens extends ConsumerStatefulWidget {
  const AllScreens({super.key});

  @override
  _AllScreensState createState() => _AllScreensState();
}


class _AllScreensState extends ConsumerState<AllScreens> with SingleTickerProviderStateMixin{

  final GlobalKey<RecordsScreenState> _recordsKey = GlobalKey<RecordsScreenState>();

  final DatabaseConnection _databaseConnection = DatabaseConnection();

  bool _isBottomNavVisible = true;
  double lastScrollPosition = 0;

  late AnimationController _animationController;
  late Animation<double> _hideBottomNavAnimation;

  bool _handleBottomNav(ScrollNotification scroll) {
    if (scroll is ScrollUpdateNotification) {
      final currentScroll = scroll.metrics.pixels;
      final scrollDelta = currentScroll - lastScrollPosition;

      if (scrollDelta > 2 && _isBottomNavVisible) {
          _animationController.forward();
          _isBottomNavVisible = false;
      }
      else if (scrollDelta < -2 && !_isBottomNavVisible) {
          _animationController.reverse();
          _isBottomNavVisible = true;
      }
      lastScrollPosition = currentScroll;
    }
    return false;
  }

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        showDragHandle: true,
        isScrollControlled: true,
        enableDrag: true,
        context: context,
        builder: (BuildContext context){
          var theme = Theme.of(context);
          return Container(
            height: 700.h,
            width: double.infinity.w,
            decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.file_download_outlined,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Export Records',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Save your data as CSV',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 28.h),

                  Container(
                    padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.05),
                          theme.colorScheme.primary.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ref.watch(accentColorProvider).withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ref.watch(accentColorProvider).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Image.asset(
                            'assets/transparent.png',
                            width: 36,
                            height: 36,
                          ),
                        ),
                        Column(
                          children: [
                            Icon(Icons.arrow_forward_rounded,
                                size: 24,
                                color: theme.colorScheme.primary.withOpacity(0.6)
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              height: 2,
                              width: 40.w,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withOpacity(0.3),
                                    theme.colorScheme.primary.withOpacity(0.1),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Guidelines Section
                  Text(
                    'Important Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  _buildGuidelineItem(
                    theme,
                    icon: Icons.table_chart_outlined,
                    text: 'All records will be exported as a CSV worksheet file',
                  ),
                  SizedBox(height: 12.h),

                  _buildGuidelineItem(
                    theme,
                    icon: Icons.info_outline,
                    text: "CSV files are for viewing only and cannot be used to restore data",
                  ),
                  SizedBox(height: 12.h),

                  _buildGuidelineItem(
                    theme,
                    icon: Icons.folder_outlined,
                    text: "Files are saved to: /Android/data/.../MoneyMate/",
                    isPath: true,
                  ),
                  SizedBox(height: 12.h),

                  _buildGuidelineItem(
                    theme,
                    icon: Icons.touch_app_outlined,
                    text: "Tap 'Export Now' to begin the export process",
                  ),

                  SizedBox(height: 28.h),

                  // Action Button
                  CustomAppButton(
                    onPressed: (){
                      showProgress();
                    },
                    title: 'Export Now',
                    width: double.infinity.w,
                  ),
                  SizedBox(height: 16.h),
                ],
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        showDragHandle: true,
        isScrollControlled: true,
        enableDrag: true,
        context: context,
        builder: (BuildContext context){
          var theme = Theme.of(context);
          return Container(
            height: 700.h,
            width: double.infinity.w,
            decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.backup_outlined,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Backup & Restore',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Secure your data safely',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 28.h),

                  Container(
                    padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.05),
                          theme.colorScheme.primary.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ref.watch(accentColorProvider).withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ref.watch(accentColorProvider).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Image.asset(
                            'assets/transparent.png',
                            width: 36,
                            height: 36,
                          ),
                        ),
                        Column(
                          children: [
                            Icon(Icons.sync_alt_rounded,
                                size: 32,
                                color: theme.colorScheme.primary.withOpacity(0.6)
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              height: 2,
                              width: 40.w,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withOpacity(0.3),
                                    theme.colorScheme.primary.withOpacity(0.1),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.cloud_done_outlined,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Guidelines Section
                  Text(
                    'Important Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  _buildGuidelineItem(
                    theme,
                    icon: Icons.security_outlined,
                    text: 'Create secure backup files to protect your financial data',
                  ),
                  SizedBox(height: 12.h),

                  _buildGuidelineItem(
                    theme,
                    icon: Icons.restore_outlined,
                    text: "Restore your complete data from backup files anytime",
                  ),
                  SizedBox(height: 12.h),

                  _buildGuidelineItem(
                    theme,
                    icon: Icons.folder_outlined,
                    text: "Backup files saved to: /Download/MoneyMate/",
                    isPath: true,
                  ),
                  SizedBox(height: 12.h),

                  _buildGuidelineItem(
                    theme,
                    icon: Icons.warning_amber_rounded,
                    text: "Keep backup files safe - they contain all your financial records",
                  ),

                  SizedBox(height: 28.h),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomAppButton(
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
                          title: 'Backup Now',
                          height: 55,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: CustomAppButton(
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
                          title: 'Restore Now',
                          height: 55,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          );
        }
    );
  }


  void deleteEverything() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        var theme = Theme.of(context);
        return Consumer(
          builder: (context, ref, _) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: theme.cardColor,
              elevation: 24,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.cardColor,
                      theme.cardColor.withOpacity(0.95),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Header
                      Center(
                        child: Container(
                          height: 72,
                          width: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.red.withOpacity(0.15),
                                Colors.red.withOpacity(0.08),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_forever_rounded,
                            color: Colors.red,
                            size: 36,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Title
                      Center(
                        child: Text(
                          'Delete Everything?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      Center(
                        child: Text(
                          'This action cannot be undone',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Warning Box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 20,
                                  color: Colors.red.withOpacity(0.8),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'What will be deleted:',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDeleteItem(theme, 'All Records'),
                            _buildDeleteItem(theme, 'Statistics'),
                            _buildDeleteItem(theme, 'Budgets'),
                            _buildDeleteItem(theme, 'Accounts'),
                            _buildDeleteItem(theme, 'Categories'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(
                                  color: theme.dividerColor.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _databaseConnection.deleteAllTables();

                                ref.invalidate(expenseProvider);
                                ref.invalidate(categoryProvider);
                                ref.invalidate(cardsProvider);
                                ref.invalidate(budgetProvider);

                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                shadowColor: Colors.red.withOpacity(0.3),
                              ),
                              child: Text(
                                'Delete All',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDeleteItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.close_rounded,
            size: 16,
            color: Colors.red.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
  
  void exitFromTheApp(){
    showDialog(
        context: context, 
        builder: (context){
          var theme = Theme.of(context);
          return AlertDialog(
            backgroundColor: theme.cardColor,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.exit_to_app,color: theme.colorScheme.primary,),
                ),
                SizedBox(width: 10.w,),
                Text('Exit app',style: theme.textTheme.titleLarge,)
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Are you sure you want to exit from the app?',style: theme.textTheme.titleSmall,),
                SizedBox(height: 10.h,),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                          onPressed: ()=>Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Cancel',style: theme.textTheme.titleSmall,)
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: ElevatedButton(
                            onPressed: ()=>SystemNavigator.pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Yes',style: theme.textTheme.titleSmall?.copyWith(color: Colors.white),)
                        )
                    )

                  ],
                )
              ],
            ),
          );
        }
    );
  }
  
  void sendFeedBack()async{
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'prantobaidya5@gmail.com',
      queryParameters: {
        'subject' : 'MoneyMate feedback',
        'body' : 'Write your feedback...'
      }

    );
    if(await canLaunchUrl(emailUri)){
      await launchUrl(emailUri,mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300)
    );

    _hideBottomNavAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final index = ref.watch(indexProvider);
    var theme = Theme.of(context);
    final isCollapseModeActivated = ref.watch(collapseDashboardPrefProvider);
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
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchRecordsScreen()),
                    );

                    if (result != null && result is Map<String, dynamic>) {

                      final action = result['action'] as String;
                      final expense = result['expense'] as ExpenseModel;

                      ref.read(indexProvider.notifier).state = 0;

                      await Future.delayed(Duration(milliseconds: 300));

                      if (_recordsKey.currentState != null) {
                        if (action == 'edit') {
                          _recordsKey.currentState!.editExpenseDialogue(expense);
                        } else if (action == 'delete') {
                          _recordsKey.currentState!.deleteAlert(expense);
                        }
                      }
                    }
                  },
                  icon: Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: Icon(Icons.search,color: Colors.white,size: 30,),
                  )
              ),
            )
          ],
      ),
     body: NotificationListener<ScrollNotification>(
       onNotification: _handleBottomNav,
         child: [
           RecordsScreen(key: _recordsKey,),
           StatsScreen(),
           BudgetScreen(),
           AccountsScreen(),
           CategoryScreen()
         ][index],
     ),

      bottomNavigationBar: isCollapseModeActivated? AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 3 * (1 - _hideBottomNavAnimation.value)),
            child: SizedBox(
              height: 60 * _hideBottomNavAnimation.value,
              child: Opacity(
                opacity: _hideBottomNavAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: ref.watch(themeModeProvider) == ThemeMode.dark ? Colors.grey.shade500 : Colors.grey.shade500,
                            width: 0.5
                        )
                    ),
                  ),
                  child: NavigationBar(
                      backgroundColor: theme.navigationBarTheme.backgroundColor,
                      indicatorColor: Colors.transparent,
                      selectedIndex: index,
                      height: 60,
                      maintainBottomViewPadding: true,
                      labelPadding: EdgeInsets.zero,
                      onDestinationSelected: (ind) {
                        ref.read(indexProvider.notifier).state = ind;
                        ref.read(isIncomeProvider.notifier).state = false;
                      },
                      destinations: [
                        NavigationDestination(
                            selectedIcon: AnimatedNavIcon(icon: Icons.feed, isNavSelected: index==0, color: theme.colorScheme.primary),
                            icon: AnimatedNavIcon(icon: Icons.feed_outlined, isNavSelected: index==0, color: theme.iconTheme.color!),
                            label: 'Records'
                        ),
                        NavigationDestination(
                            selectedIcon: AnimatedNavIcon(icon: Icons.analytics, isNavSelected: index==1, color: theme.colorScheme.primary),
                            icon: AnimatedNavIcon(icon: Icons.analytics_outlined, isNavSelected: index==1, color: theme.iconTheme.color!),
                            label: 'Analysis'
                        ),
                        NavigationDestination(
                            selectedIcon: AnimatedNavIcon(icon: Icons.request_quote, isNavSelected: index==2, color: theme.colorScheme.primary),
                            icon: AnimatedNavIcon(icon: Icons.request_quote_outlined, isNavSelected: index==2, color: theme.iconTheme.color!),
                            label: 'Budget'
                        ),
                        NavigationDestination(
                            selectedIcon: AnimatedNavIcon(icon: Icons.account_balance_wallet, isNavSelected: index==3, color: theme.colorScheme.primary),
                            icon: AnimatedNavIcon(icon: Icons.account_balance_wallet_outlined, isNavSelected: index==3, color: theme.iconTheme.color!),
                            label: 'Accounts'
                        ),
                        NavigationDestination(
                            selectedIcon: AnimatedNavIcon(icon: Icons.category, isNavSelected: index==4, color: theme.colorScheme.primary),
                            icon: AnimatedNavIcon(icon: Icons.category_outlined, isNavSelected: index==4, color: theme.iconTheme.color!),
                            label: 'Category'
                        ),
                      ]
                  ),
                ),
              ),
            ),
          );
        },
      )
          :Container(
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: ref.watch(themeModeProvider) == ThemeMode.dark ? Colors.grey.shade500 : Colors.grey.shade500,
                  width: 0.5
              )
          ),
        ),
        child: NavigationBar(
            backgroundColor: theme.navigationBarTheme.backgroundColor,
            indicatorColor: Colors.transparent,
            selectedIndex: index,
            height: 60,
            maintainBottomViewPadding: true,
            labelPadding: EdgeInsets.zero,
            onDestinationSelected: (ind) {
              ref.read(indexProvider.notifier).state = ind;
              ref.read(isIncomeProvider.notifier).state = false;
            },
            destinations: [
              NavigationDestination(
                  selectedIcon: AnimatedNavIcon(icon: Icons.feed, isNavSelected: index==0, color: theme.colorScheme.primary),
                  icon: AnimatedNavIcon(icon: Icons.feed_outlined, isNavSelected: index==0, color: theme.iconTheme.color!),
                  label: 'Records'
              ),
              NavigationDestination(
                  selectedIcon: AnimatedNavIcon(icon: Icons.analytics, isNavSelected: index==1, color: theme.colorScheme.primary),
                  icon: AnimatedNavIcon(icon: Icons.analytics_outlined, isNavSelected: index==1, color: theme.iconTheme.color!),
                  label: 'Analysis'
              ),
              NavigationDestination(
                  selectedIcon: AnimatedNavIcon(icon: Icons.request_quote, isNavSelected: index==2, color: theme.colorScheme.primary),
                  icon: AnimatedNavIcon(icon: Icons.request_quote_outlined, isNavSelected: index==2, color: theme.iconTheme.color!),
                  label: 'Budget'
              ),
              NavigationDestination(
                  selectedIcon: AnimatedNavIcon(icon: Icons.account_balance_wallet, isNavSelected: index==3, color: theme.colorScheme.primary),
                  icon: AnimatedNavIcon(icon: Icons.account_balance_wallet_outlined, isNavSelected: index==3, color: theme.iconTheme.color!),
                  label: 'Accounts'
              ),
              NavigationDestination(
                  selectedIcon: AnimatedNavIcon(icon: Icons.category, isNavSelected: index==4, color: theme.colorScheme.primary),
                  icon: AnimatedNavIcon(icon: Icons.category_outlined, isNavSelected: index==4, color: theme.iconTheme.color!),
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
                  Text('Version : 1.0.0 (Free)',style: theme.textTheme.titleSmall,)
                ],
              ),
            ),
            ListTile(
              tileColor: Colors.transparent,
              title: Text('Preferences',style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary,fontSize: 18),),
            ),
            ListAnimationWidget(
              index: 1,
              offset: Offset(-0.3, 0),
              child: ListTile(
                  onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (context)=>SettingsScreen())),
                  tileColor: Colors.transparent,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.settings,color: Colors.white,size: 16,),
                  ),
                  title: Text('Settings'),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
              ),
            ),
            Divider(indent: 0,endIndent: 0,thickness: 0.8,color: theme.colorScheme.primary,),
            ListTile(
              tileColor: Colors.transparent,
              title: Text('Management',style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary,fontSize: 18),),
            ),
            ListAnimationWidget(
              index: 2,
              offset: Offset(-0.3, 0),
              child: ListTile(
                  onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (context)=>TransactionHistory())),
                  tileColor: Colors.transparent,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.history,color: Colors.white,size: 16,),
                  ),
                  title: Text('Transaction history'),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
              ),
            ),
            ListAnimationWidget(
              index: 3,
              offset: Offset(-0.3, 0),
              child: ListTile(
                  onTap: ()=> exportRecordsSheet(),
                  tileColor: Colors.transparent,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.upload_file,color: Colors.white,size: 16,),
                  ),
                  title: Text('Export records'),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
              ),
            ),
            ListAnimationWidget(
              index: 4,
              offset: Offset(-0.3, 0),
              child: ListTile(
                  onTap: backupRestoreSheet,
                  tileColor: Colors.transparent,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.save_outlined,color: Colors.white,size: 16,),
                  ),
                  title: Text('Backup & Restore'),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
              ),
            ),
            ListAnimationWidget(
              index: 5,
              offset: Offset(-0.3, 0),
              child: ListTile(
                  onTap: deleteEverything,
                  tileColor: Colors.transparent,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.delete_outline,color: Colors.white,size: 16,),
                  ),
                  title: Text('Erase all data'),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
              ),
            ),
            Divider(indent: 0,endIndent: 0,thickness: 0.8,color: theme.colorScheme.primary,),
            ListTile(
              tileColor: Colors.transparent,
              title: Text('Application',style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary,fontSize: 18),),
            ),
            ListAnimationWidget(
              index: 6,
              offset: Offset(-0.3, 0),
              child: ListTile(
                  onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (context)=>AboutScreen())),
                  tileColor: Colors.transparent,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.info_outline,color: Colors.white,size: 16,),
                  ),
                  title: Text('About app'),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
              ),
            ),
            ListAnimationWidget(
              index: 7,
              offset: Offset(-0.3, 0),
              child: ListTile(
                  onTap: ()=>sendFeedBack(),
                  tileColor: Colors.transparent,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.mail_outline,color: Colors.white,size: 16,),
                  ),
                  title: Text('Feedback'),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
              ),
            ),
            ListAnimationWidget(
              index: 8,
              offset: Offset(-0.3, 0),
              child: ListTile(
                  onTap: exitFromTheApp,
                  tileColor: Colors.transparent,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.exit_to_app,color: Colors.white,size: 16,),
                  ),
                  title: Text('Exit from the app'),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,size: 18,)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(ThemeData theme, {
    required IconData icon,
    required String text,
    bool isPath = false,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                fontSize: isPath ? 12.5 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
