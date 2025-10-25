import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class BalanceDashboard extends ConsumerWidget {
  const BalanceDashboard({
    super.key,
    required this.theme,
    required this.dateNotifier,
    required this.dateState,
    required this.selectedCurrency,
  });

  final ThemeData theme;
  final StateController<DateTime> dateNotifier;
  final DateTime dateState;
  final String selectedCurrency;

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: Container(
        height: 150.h,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(
              color: theme.dividerColor.withOpacity(0.2),
              offset: Offset(0, 1),
              blurRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Column(
              children: [
                SizedBox(height: 10.h,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                        onPressed: (){
                          dateNotifier.state = DateTime(dateNotifier.state.year,dateNotifier.state.month-1);
                          ref.read(expenseProvider.notifier).filterRecordsByMonth(dateNotifier.state);
                        },
                        icon: Icon(Icons.keyboard_double_arrow_left,color: theme.iconTheme.color,size: 30,)
                    ),
                    Text(DateFormat('MMMM, yyyy').format(dateState),style: theme.textTheme.titleMedium,),
                    IconButton(
                        onPressed: (){
                          dateNotifier.state = DateTime(dateNotifier.state.year,dateNotifier.state.month+1);
                          ref.read(expenseProvider.notifier).filterRecordsByMonth(dateNotifier.state);
                        },
                        icon: Icon(Icons.keyboard_double_arrow_right,color: theme.iconTheme.color,size: 30,)
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  SizedBox(height: 10.h,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Expense',
                            style: theme.textTheme.titleMedium,
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            '- $selectedCurrency ${45}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Income',
                            style: theme.textTheme.titleMedium,
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            '+ $selectedCurrency ${45}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Total',
                            style: theme.textTheme.titleMedium,
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            '= $selectedCurrency ${45}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}