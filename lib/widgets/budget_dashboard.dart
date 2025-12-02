import 'package:expense_tracker_app/riverpod/budget_riverpod/budget_riverpod.dart';
import 'package:expense_tracker_app/riverpod/currency_riverpod/currency_pref.dart';
import 'package:expense_tracker_app/screens/budgets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class BudgetDashboard extends ConsumerStatefulWidget {
  final int totalBudget;
  final int totalSpent;
  final StateController<DateTime> dateNotifier;
  final DateTime dateState;
  const BudgetDashboard({required this.totalBudget, required this.totalSpent, required this.dateNotifier, required this.dateState, super.key});

  @override
  ConsumerState<BudgetDashboard> createState() => _BudgetDashboardState();
}

class _BudgetDashboardState extends ConsumerState<BudgetDashboard> with TickerProviderStateMixin {

  late AnimationController _budgetController;
  late AnimationController _spentController;

  late Animation<double> _budgetScaleAnimation;
  late Animation<double> _spentScaleAnimation;

  @override
  void initState() {
    _budgetController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1000)
    );

    _spentController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1000)
    );

    _budgetScaleAnimation = Tween<double>(begin: 1,end: 1).animate(CurvedAnimation(parent: _budgetController, curve: Interval(0, 0,curve: Curves.bounceInOut)));

    _spentScaleAnimation = Tween<double>(begin: 1,end: 1).animate(
        CurvedAnimation(
            parent: _spentController,
            curve: Interval(0, 0,curve: Curves.bounceInOut)
        )
    );

    _budgetController.forward(from: 0);
    _spentController.forward(from: 0);

    super.initState();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _spentController.dispose();
    super.dispose();
  }

  void _showBudgetAnimation(){
    _budgetScaleAnimation = Tween<double>(begin: 0,end: 1).animate(
        CurvedAnimation(
            parent: _budgetController,
            curve: Interval(0, 1,curve: Curves.easeOutCubic)
        )
    );
    _budgetController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    ref.listen(budgetTrackProvider, (prev,next){
      if(prev != next) {
        _showBudgetAnimation();
      }
    });

    final formattedTotalBudget = NumberFormat.currency(
      symbol: ref.read(newCurrencyProvider).currency,
      decimalDigits: 2,
    ).format(widget.totalBudget);

    final formattedTotalSpent = NumberFormat.currency(
      symbol: ref.read(newCurrencyProvider).currency,
      decimalDigits: 2,
    ).format(widget.totalSpent);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
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
                _buildNavigationButton(icon: Icons.chevron_left_outlined, onPressed: () {
                  widget.dateNotifier.state = DateTime(
                    widget.dateNotifier.state.year,
                    widget.dateNotifier.state.month - 1,
                  );
                  ref.read(budgetProvider.notifier).filterBudgetsByMonth(
                    widget.dateNotifier.state,
                  );
                }),
                Text(
                  DateFormat('MMMM, yyyy').format(widget.dateState),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                _buildNavigationButton(icon: Icons.chevron_right_outlined, onPressed: () {
                  widget.dateNotifier.state = DateTime(
                    widget.dateNotifier.state.year,
                    widget.dateNotifier.state.month + 1,
                  );
                  ref.read(budgetProvider.notifier).filterBudgetsByMonth(
                    widget.dateNotifier.state,
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 15.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildBudgetCard(
                  title: 'Total Budget',
                  amount: formattedTotalBudget.toString(),
                  color: Colors.green,
                  theme: theme,
                  icon: Icons.paid,
                  gradientColors: [
                    Color(0xFF51CF66),
                    Color(0xFF69DB7C),
                  ],
                  animation: _budgetScaleAnimation
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildBudgetCard(
                  title: 'Total Spent',
                  amount: formattedTotalSpent.toString(),
                  color: Colors.redAccent,
                  theme: theme,
                  icon: Icons.receipt_long,
                  gradientColors: [
                    Color(0xFFFF6B6B),
                    Color(0xFFFF8E8E),
                  ],
                  animation: _spentScaleAnimation
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildBudgetCard({
    required String title,
    required String amount,
    required Color color,
    required ThemeData theme,
    required IconData icon,
    required List<Color> gradientColors,
    required Animation<double> animation
  }) {
    return Container(
      height: 130.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
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
              ScaleTransition(
                scale: animation,
                child: Container(
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
                  child: ScaleTransition(
                    scale: animation,
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
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
              )
            ],
          ),
        ),
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


