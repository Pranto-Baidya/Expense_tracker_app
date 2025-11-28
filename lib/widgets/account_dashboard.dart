import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class AccountDashboard extends ConsumerStatefulWidget {
  final ThemeData theme;
  final String selectedCurrency;
  const AccountDashboard({
    required this.theme,
    required this.selectedCurrency, super.key
  });

  @override
  _AccountDashboardState createState() => _AccountDashboardState();
}

class _AccountDashboardState extends ConsumerState<AccountDashboard> {
  @override
  Widget build(BuildContext context) {

    final formattedTotal = NumberFormat.currency(
      symbol: widget.selectedCurrency,
      decimalDigits: 2
    ).format(ref.watch(totalMoneyProvider));
    final formattedIncome = NumberFormat.currency(
        symbol: widget.selectedCurrency,
        decimalDigits: 2
    ).format(ref.watch(totalIncomeProvider));
    final formattedExpense = NumberFormat.currency(
        symbol: widget.selectedCurrency,
        decimalDigits: 2
    ).format(ref.watch(totalExpenseProvider));

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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('All accounts: ',style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                 ),
                ),
                SizedBox(width: 5.w,),
                Text(formattedTotal,style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                 ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                  child: _buildBalanceCard(
                      title: 'Expense so far',
                      amount: formattedExpense,
                      icon: Icons.arrow_downward,
                      gradientColors: [
                        Color(0xFFFF6B6B),
                        Color(0xFFFF8E8E),
                      ],
                  ),
              ),
              SizedBox(width: 12.w,),
              Expanded(
                child: _buildBalanceCard(
                  title: 'Income so far',
                  amount: formattedIncome,
                  icon: Icons.arrow_upward,
                  gradientColors: [
                    Color(0xFF51CF66),
                    Color(0xFF69DB7C),
                  ],
                ),
              ),
            ],
          )
        ],
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
      height: 135.h,
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
