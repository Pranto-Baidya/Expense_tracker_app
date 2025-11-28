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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavigationButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: () {
                    dateNotifier.state = DateTime(
                      dateNotifier.state.year,
                      dateNotifier.state.month - 1,
                    );
                    ref.read(expenseProvider.notifier).filterRecordsByMonth(
                      dateNotifier.state,
                      timeNotifier?.state ?? TimeOfDay.now(),
                    );
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(dateState),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                _buildNavigationButton(
                  icon: Icons.chevron_right_rounded,
                  onPressed: () {
                    dateNotifier.state = DateTime(
                      dateNotifier.state.year,
                      dateNotifier.state.month + 1,
                    );
                    ref.read(expenseProvider.notifier).filterRecordsByMonth(
                      dateNotifier.state,
                      timeNotifier?.state ?? TimeOfDay.now(),
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _buildBalanceCard(
                  title: 'Expense',
                  amount: formattedTotalExpense,
                  icon: Icons.arrow_downward_rounded,
                  gradientColors: [
                    Color(0xFFFF6B6B),
                    Color(0xFFFF8E8E),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildBalanceCard(
                  title: 'Income',
                  amount: formattedTotalIncome,
                  icon: Icons.arrow_upward_rounded,
                  gradientColors: [
                    Color(0xFF51CF66),
                    Color(0xFF69DB7C),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildBalanceCard(
                  title: 'Balance',
                  amount: formattedTotalAmount,
                  icon: Icons.account_balance_wallet_rounded,
                  gradientColors: [
                    Color(0xFF748FFC),
                    Color(0xFF91A7FF),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required String amount,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      height: 130.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      amount,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
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
  }
}