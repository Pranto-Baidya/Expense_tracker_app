import 'dart:ui';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class BalanceDashboard extends ConsumerWidget {
  final ThemeData theme;
  final StateController<DateTime> dateNotifier;
  final StateController<TimeOfDay>? timeNotifier;
  final DateTime dateState;
  final TimeOfDay? timeState;
  final String selectedCurrency;

  const BalanceDashboard({
    super.key,
    required this.theme,
    required this.dateNotifier,
    this.timeNotifier,
    required this.dateState,
    this.timeState,
    required this.selectedCurrency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalExpenseState = ref.watch(totalExpenseProvider);
    final totalIncomeState = ref.watch(totalIncomeProvider);
    final totalMoneyState = ref.watch(totalMoneyProvider);

    final formattedTotalAmount = NumberFormat.currency(
      symbol: selectedCurrency,
      decimalDigits: 2
    ).format(totalMoneyState);

    final formattedTotalExpense = NumberFormat.currency(
      symbol: selectedCurrency,
      decimalDigits: 2
    ).format(totalExpenseState);

    final formattedTotalIncome = NumberFormat.currency(
        symbol: selectedCurrency,
        decimalDigits: 2
    ).format(totalIncomeState);


    return Container(
      height: 190.h,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(height: 10.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 10.w),
                  child: IconButton(
                    onPressed: () {
                      dateNotifier.state = DateTime(
                        dateNotifier.state.year,
                        dateNotifier.state.month - 1,
                      );
                      if(timeNotifier!=null)
                      ref.read(expenseProvider.notifier).filterRecordsByMonth(dateNotifier.state, timeNotifier!.state);
                    },
                    icon: Icon(
                      Icons.keyboard_double_arrow_left_rounded,
                      color: theme.iconTheme.color,
                      size: 28,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMMM, yyyy').format(dateState),
                  style: theme.textTheme.titleLarge?.copyWith(
                    letterSpacing: 1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: IconButton(
                    onPressed: () {
                      dateNotifier.state = DateTime(
                        dateNotifier.state.year,
                        dateNotifier.state.month + 1,
                      );
                      if(timeNotifier!=null)
                      ref.read(expenseProvider.notifier).filterRecordsByMonth(dateNotifier.state, timeNotifier!.state);
                    },
                    icon: Icon(
                      Icons.keyboard_double_arrow_right_rounded,
                      color: theme.iconTheme.color,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBalanceCard(
                    title: 'Expense',
                    amount: formattedTotalExpense,
                    color: Colors.redAccent,
                    theme: theme,
                    icon: Icons.trending_down_rounded,
                  ),
                  _buildBalanceCard(
                    title: 'Income',
                    amount: formattedTotalIncome,
                    color: Colors.green,
                    theme: theme,
                    icon: Icons.trending_up_rounded,
                  ),
                  _buildBalanceCard(
                    title: 'Total',
                    amount: formattedTotalAmount,
                    color: theme.colorScheme.primary,
                    theme: theme,
                    icon: Icons.request_page_outlined,
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h,)
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required String amount,
    required Color color,
    required ThemeData theme,
    required IconData icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      width: 100.w,
      height: 90.h,
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15.r),
        border: Border(
          top: BorderSide(color: color),
          right: BorderSide(color: color),
          left: BorderSide(color: color),
          bottom: BorderSide(color: color),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 6.h),
          Text(
            title,
            style: theme.textTheme.labelLarge
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
