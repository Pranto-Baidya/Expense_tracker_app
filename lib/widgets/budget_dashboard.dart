import 'package:expense_tracker_app/models/budget_model.dart';
import 'package:expense_tracker_app/riverpod/budget_riverpod/budget_riverpod.dart';
import 'package:expense_tracker_app/riverpod/currency_riverpod/currency_pref.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class BudgetDashboard extends ConsumerWidget {
  final int totalBudget;
  final int totalSpent;
  final StateController<DateTime> dateNotifier;
  final DateTime dateState;
  const BudgetDashboard({required this.totalBudget,required this.totalSpent,required this.dateNotifier, required this.dateState,super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    var theme = Theme.of(context);
    final formattedTotalBudget = NumberFormat.currency(
      symbol: ref.read(newCurrencyProvider).currency,
      decimalDigits: 2
    ).format(totalBudget);

    final formattedTotalSpent = NumberFormat.currency(
      symbol: ref.read(newCurrencyProvider).currency,
      decimalDigits: 2
    ).format(totalSpent);

    return Container(
      height: 190.h,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: theme.dividerColor.withOpacity(0.3))
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 10.w),
                child: IconButton(
                    onPressed: (){
                     dateNotifier.state = DateTime(
                         dateNotifier.state.year,
                         dateNotifier.state.month-1
                     );
                     ref.read(budgetProvider.notifier).filterBudgetsByMonth(dateNotifier.state);
                    },
                    icon: Icon(Icons.keyboard_double_arrow_left,color: theme.iconTheme.color,size: 30,)
                ),
              ),
              Text(DateFormat('MMMM, yyyy').format(dateState),style: theme.textTheme.titleLarge,),
              Padding(
                padding: EdgeInsets.only(right: 10.w),
                child: IconButton(
                    onPressed: (){
                      dateNotifier.state = DateTime(
                          dateNotifier.state.year,
                          dateNotifier.state.month+1
                      );
                      ref.read(budgetProvider.notifier).filterBudgetsByMonth(dateNotifier.state);
                    },
                    icon: Icon(Icons.keyboard_double_arrow_right,color: theme.iconTheme.color,size: 30,)
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBudgetCard(
                  title: 'Total Budget',
                  amount: formattedTotalBudget.toString(),
                  color: Colors.green,
                  theme: theme,
                  icon: Icons.paid
              ),
              _buildBudgetCard(
                  title: 'Total Spent',
                  amount: formattedTotalSpent.toString(),
                  color: Colors.redAccent,
                  theme: theme,
                  icon: Icons.receipt_long
              ),
            ],
          )

        ],
      ),
    );
  }

  Widget _buildBudgetCard({
    required String title,
    required String amount,
    required Color color,
    required ThemeData theme,
    required IconData icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      width: 150.w,
      height: 100.h,
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
