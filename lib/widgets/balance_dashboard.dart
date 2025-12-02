import 'dart:ui';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class BalanceDashboard extends ConsumerStatefulWidget {
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
  ConsumerState<BalanceDashboard> createState() => _BalanceDashboardState();
}

class _BalanceDashboardState extends ConsumerState<BalanceDashboard> with TickerProviderStateMixin {

  late AnimationController _expenseController;
  late AnimationController _incomeController;
  late AnimationController _balanceController;

  late Animation<Offset> _expenseAnimation;
  late Animation<Offset> _incomeAnimation;
  late Animation<Offset> _balanceAnimation;

  @override
  void initState() {
    super.initState();

    _expenseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _incomeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _balanceController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _expenseAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _expenseController, curve: Curves.easeOut));

    _incomeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _incomeController, curve: Curves.easeOut));

    _balanceAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _balanceController, curve: Curves.easeOut));
  }

  void triggerExpenseAnimation() {
    _expenseAnimation = Tween<Offset>(
      begin: Offset(0, -1.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _expenseController, curve: Curves.fastOutSlowIn),
    );
    _expenseController.forward(from: 0);
  }

  void triggerIncomeAnimation() {
    _incomeAnimation = Tween<Offset>(
      begin: Offset(0, 1.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _incomeController, curve: Curves.fastOutSlowIn),
    );
    _incomeController.forward(from: 0);
  }

  void triggerBalanceAnimation() {
    _balanceAnimation = Tween<Offset>(
      begin: Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _balanceController, curve: Curves.fastOutSlowIn),
    );
    _balanceController.forward(from: 0);
  }

  @override
  void dispose() {
    _expenseController.dispose();
    _incomeController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalExpenseState = ref.watch(totalExpenseProvider);
    final totalIncomeState = ref.watch(totalIncomeProvider);
    final totalMoneyState = ref.watch(totalMoneyProvider);

    ref.listen(recordAddedTriggerProvider, (prev, next) {
      final moneyType = ref.read(moneyTypeProvider);
      if (moneyType == MoneyType.expense) {
        triggerExpenseAnimation();
      }
      else if (moneyType == MoneyType.income) {
        triggerIncomeAnimation();
      }
      triggerBalanceAnimation();
    });

    final String formattedTotalAmount = NumberFormat.currency(
      symbol: widget.selectedCurrency,
      decimalDigits: 2,
    ).format(totalMoneyState);

    final String formattedTotalExpense = NumberFormat.currency(
      symbol: widget.selectedCurrency,
      decimalDigits: 2,
    ).format(totalExpenseState);

    final String formattedTotalIncome = NumberFormat.currency(
      symbol: widget.selectedCurrency,
      decimalDigits: 2,
    ).format(totalIncomeState);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Column(
        children: [
          _buildMonthNavigation(),
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
                  animation: _expenseAnimation,
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
                  animation: _incomeAnimation,
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
                  animation: _balanceAnimation,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Container(
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
              widget.dateNotifier.state = DateTime(
                widget.dateNotifier.state.year,
                widget.dateNotifier.state.month - 1,
              );
              ref.read(expenseProvider.notifier).filterRecordsByMonth(
                widget.dateNotifier.state,
                widget.timeNotifier?.state ?? TimeOfDay.now(),
              );
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(widget.dateNotifier.state),
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          _buildNavigationButton(
            icon: Icons.chevron_right_rounded,
            onPressed: () {
              widget.dateNotifier.state = DateTime(
                widget.dateNotifier.state.year,
                widget.dateNotifier.state.month + 1,
              );
              ref.read(expenseProvider.notifier).filterRecordsByMonth(
                widget.dateNotifier.state,
                widget.timeNotifier?.state ?? TimeOfDay.now(),
              );
            },
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
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildBalanceCard({
    required String title,
    required String amount,
    required IconData icon,
    required List<Color> gradientColors,
    required Animation<Offset> animation,
  }) {
    return Container(
      height: 130.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
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
              child: SlideTransition(
                position: animation,
                child: Icon(icon, color: Colors.white, size: 22),
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
                  ),
                ),
                SizedBox(height: 4.h),
                FittedBox(
                  child: Text(
                    amount,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}