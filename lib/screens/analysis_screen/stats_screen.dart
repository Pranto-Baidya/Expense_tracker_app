import 'package:expense_tracker_app/models/category_model.dart';
import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:expense_tracker_app/riverpod/category_riverpod/category_riverpod.dart';
import 'package:expense_tracker_app/riverpod/currency_riverpod/currency_pref.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/riverpod/prefs_riverpod/prefs_riverpod.dart';
import 'package:expense_tracker_app/riverpod/save_record_filter/save_record_filter.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:expense_tracker_app/widgets/balance_dashboard.dart';
import 'package:expense_tracker_app/widgets/listAnimation_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

final isIncomeProvider = StateProvider<bool>((ref) => false);
final dashboardCollapseProvider = StateProvider<bool>((ref)=>false);

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {

  final ScrollController _scrollController = ScrollController();

  double fullDashboardHeight = 244.0.h;

  double minimizedDashboardHeight = 60.0.h;


  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(expenseProvider.notifier).getExpenses();
      await ref.read(cardsProvider.notifier).getCards();

      final currentFilter = ref.read(saveRecordFilterProvider);
      final selectedDate = ref.read(selectedDateProvider);
      final selectedTime = ref.read(selectedTimeProvider);

      switch(currentFilter) {
        case FilterRecordOptions.daily:
          ref.read(expenseProvider.notifier).filterRecordsByDay(selectedDate);
          break;
        case FilterRecordOptions.weekly:
          ref.read(expenseProvider.notifier).filterRecordsByWeek(selectedDate);
          break;
        case FilterRecordOptions.yearly:
          ref.read(expenseProvider.notifier).filterRecordsByYear(selectedDate);
          break;
        case FilterRecordOptions.monthly:
          ref.read(expenseProvider.notifier).filterRecordsByMonth(selectedDate, selectedTime);
          break;
      }
    });
  }

  Set<String> selected = {'Expense'};

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll(){

    final scrollState = ref.read(dashboardCollapseProvider);
    final scrollNotifier = ref.read(dashboardCollapseProvider.notifier);

    final isCollapsed = _scrollController.offset > 50;

    if(isCollapsed!=scrollState){
      scrollNotifier.state = isCollapsed;
    }
  }

  @override
  Widget build(BuildContext context) {

    var theme = Theme.of(context);
    final recordList = ref.watch(expenseProvider);

    final nonZeroInExpense = recordList.filteredRecord
        .where((exp) => exp.amount != 0 && (exp.moneyType == MoneyType.expense))
        .map((i) => i.category)
        .toSet()
        .toList();

    final nonZeroInIncome = recordList.filteredRecord
        .where((exp) => exp.amount != 0 && (exp.moneyType == MoneyType.income))
        .map((i) => i.category)
        .toSet()
        .toList();

    final selectedColor = selected.contains('Expense') ? Colors.redAccent : Colors.greenAccent.shade700;

    final isIncome = ref.watch(isIncomeProvider);
    final isIncomeNotifier = ref.read(isIncomeProvider.notifier);

    final isCollapseModeActivated = ref.watch(collapseDashboardPrefProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: isCollapseModeActivated? CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: fullDashboardHeight,
            collapsedHeight: minimizedDashboardHeight,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {

                final double maxHeight = fullDashboardHeight;
                final double minHeight = minimizedDashboardHeight;
                final double currentHeight = constraints.maxHeight;

                final double collapseThreshold = minHeight + ((maxHeight - minHeight) * 0.3);
                final bool isCurrentlyCollapsed = currentHeight <= collapseThreshold;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final currentState = ref.read(dashboardCollapseProvider);
                  if (isCurrentlyCollapsed != currentState) {
                    ref.read(dashboardCollapseProvider.notifier).state = isCurrentlyCollapsed;
                  }
                });

                return AnimatedBalanceDashboard(
                  isCollapsed: isCurrentlyCollapsed,
                );
              },
            ),
          ),

          if (recordList.filteredRecord.isEmpty)...[
            SliverToBoxAdapter(
              child: SizedBox(height: 12.h),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r),
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(height: 80.h,),
                      Icon(
                        Icons.query_stats,
                        size: 100,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'No Data Available',
                        style: theme.textTheme.titleLarge,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'No transactions for this period',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          if (recordList.filteredRecord.isNotEmpty)
            SliverList(
              delegate: SliverChildListDelegate([
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity.w,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w,vertical: 8.h),
                    child: Column(
                      children: [
                        SizedBox(height: 15.h,),
                        ListAnimationWidget(
                          index: 1,
                          offset: Offset(0, 0.3),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(
                                color: theme.dividerColor.withOpacity(0.15),
                                width: 1,
                              ),
                              boxShadow: Theme.of(context).brightness == Brightness.dark
                                  ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, -1),
                                ),
                              ]
                                  : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(-2, -2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(8.w),
                            child: SegmentedButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return selectedColor;
                                  }
                                  return theme.colorScheme.surfaceVariant.withOpacity(0.5);
                                }),
                                foregroundColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.white;
                                  }
                                  return theme.colorScheme.onSurface;
                                }),
                                side: WidgetStateProperty.all(BorderSide.none),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                padding: WidgetStateProperty.all(
                                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                ),
                              ),
                              segments: [
                                ButtonSegment(
                                  value: 'Expense',
                                  icon: Icon(
                                    Icons.arrow_downward_rounded,
                                    color: selected.contains('Expense')
                                        ? Colors.white
                                        : Colors.redAccent,
                                    size: 18.sp,
                                  ),
                                  label: Text(
                                    'Expense',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: selected.contains('Expense')
                                          ? Colors.white
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                ButtonSegment(
                                  value: 'Income',
                                  icon: Icon(
                                    Icons.arrow_upward_rounded,
                                    color: selected.contains('Income')
                                        ? Colors.white
                                        : Colors.greenAccent.shade700,
                                    size: 18.sp,
                                  ),
                                  label: Text(
                                    'Income',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: selected.contains('Income')
                                          ? Colors.white
                                          : Colors.greenAccent.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              selected: selected,
                              showSelectedIcon: false,
                              onSelectionChanged: (Set<String> newSelection) {
                                setState(() => selected = newSelection);
                                isIncomeNotifier.state = newSelection.contains('Income');
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: 25.h),

                        // Pie Chart Container
                        ListAnimationWidget(
                          index: 2,
                          offset: Offset(0, 0.1),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(
                                color: theme.dividerColor.withOpacity(0.15),
                                width: 1,
                              ),
                              boxShadow: Theme.of(context).brightness == Brightness.dark
                                  ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, -1),
                                ),
                              ]
                                  : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(-2, -2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(24.w),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: selectedColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10.r),
                                      ),
                                      child: Icon(
                                        isIncome ? Icons.trending_up : Icons.trending_down,
                                        color: selectedColor,
                                        size: 20.sp,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      isIncome ? 'Income Distribution' : 'Expense Distribution',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 28.h),
                                Container(
                                  height: 200.h,
                                  width: 200.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        theme.colorScheme.primary.withOpacity(0.05),
                                        theme.colorScheme.surface.withOpacity(0.02),
                                      ],
                                    ),
                                  ),
                                  child: const PieChartScreen(),
                                ),
                                SizedBox(height: 24.h),
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 16.w,
                                    runSpacing: 12.h,
                                    children: !(isIncome ? nonZeroInIncome : nonZeroInExpense).isNotEmpty
                                        ? []
                                        : (isIncome ? nonZeroInIncome : nonZeroInExpense).map((item) {
                                      final cat = ref.read(categoryProvider).allCategories.firstWhere(
                                            (i) => i.categoryName == item,
                                        orElse: () => CategoryModel(
                                          categoryName: 'Unknown',
                                          icon: Icons.category,
                                          color: Colors.grey,
                                        ),
                                      );
                                      return Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                          vertical: 8.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.cardColor,
                                          borderRadius: BorderRadius.circular(8.r),
                                          border: Border.all(
                                            color: cat.color.withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              height: 12.h,
                                              width: 12.w,
                                              decoration: BoxDecoration(
                                                color: cat.color,
                                                borderRadius: BorderRadius.circular(3.r),
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              item,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 28.h),

                        // Line Chart
                        ListAnimationWidget(
                          index: 3,
                          offset: Offset(0, 0.1),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(
                                color: theme.dividerColor.withOpacity(0.15),
                                width: 1,
                              ),
                              boxShadow: Theme.of(context).brightness == Brightness.dark
                                  ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, -1),
                                ),
                              ]
                                  : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(-2, -2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(24.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: selectedColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10.r),
                                      ),
                                      child: Icon(
                                        Icons.show_chart_rounded,
                                        color: selectedColor,
                                        size: 20.sp,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      isIncome ? "Income Trend" : "Expense Trend",
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                Container(
                                  height: 320.h,
                                  child: LineChartScreen(),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 28.h),

                        // Bar Chart
                        ListAnimationWidget(
                          index: 4,
                          offset: Offset(0, 0.1),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(
                                color: theme.dividerColor.withOpacity(0.15),
                                width: 1,
                              ),
                              boxShadow: Theme.of(context).brightness == Brightness.dark
                                  ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, -1),
                                ),
                              ]
                                  : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(-2, -2),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(24.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10.r),
                                      ),
                                      child: Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: theme.colorScheme.primary,
                                        size: 20.sp,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      "Account Overview",
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 12.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        height: 14.h,
                                        width: 14.w,
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius: BorderRadius.circular(3.r),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Expense',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 20.w),
                                      Container(
                                        height: 14.h,
                                        width: 14.w,
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade700,
                                          borderRadius: BorderRadius.circular(3.r),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Income',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                Container(
                                  height: 320.h,
                                  child: BarChartScreen(),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                )
              ]),
            ),
        ],
      )
          :Column(
        children: [
          BalanceDashboard(
            theme: theme,
            dateNotifier: ref.read(selectedDateProvider.notifier),
            timeNotifier: ref.read(selectedTimeProvider.notifier),
            dateState: ref.watch(selectedDateProvider),
            timeState: ref.watch(selectedTimeProvider),
            selectedCurrency: ref.watch(newCurrencyProvider).currency,
          ),
          SizedBox(height: 10.h,),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r)
                ),
              ),
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  children: [
                    if (recordList.filteredRecord.isEmpty)
                      Column(
                        children: [
                          SizedBox(height: 80.h,),
                          Icon(
                            Icons.query_stats,
                            size: 100,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            'No Data Available',
                            style: theme.textTheme.titleLarge,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                              'No transactions for this period',
                              style: theme.textTheme.bodyMedium
                          ),
                        ],
                      ),

                    if (recordList.filteredRecord.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 12.h),

                            ListAnimationWidget(
                              index: 1,
                              offset: Offset(0, 0.3),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(color: theme.dividerColor.withOpacity(0.3))
                                ),
                                padding: EdgeInsets.all(8.w),
                                child: SegmentedButton(
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return selectedColor;
                                      }
                                      return theme.colorScheme.surfaceVariant.withOpacity(0.5);
                                    }),
                                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return Colors.white;
                                      }
                                      return theme.colorScheme.onSurface;
                                    }),
                                    side: WidgetStateProperty.all(BorderSide.none),
                                    shape: WidgetStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                    ),
                                    padding: WidgetStateProperty.all(
                                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                    ),
                                  ),
                                  segments: [
                                    ButtonSegment(
                                      value: 'Expense',
                                      icon: Icon(
                                        Icons.arrow_downward_rounded,
                                        color: selected.contains('Expense')
                                            ? Colors.white
                                            : theme.colorScheme.error,
                                        size: 18.sp,
                                      ),
                                      label: Text(
                                        'Expense',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          color: selected.contains('Expense')
                                              ? Colors.white
                                              : theme.colorScheme.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    ButtonSegment(
                                      value: 'Income',
                                      icon: Icon(
                                        Icons.arrow_upward_rounded,
                                        color: selected.contains('Income')
                                            ? Colors.white
                                            : Colors.greenAccent.shade700,
                                        size: 18.sp,
                                      ),
                                      label: Text(
                                        'Income',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          color: selected.contains('Income')
                                              ? Colors.white
                                              : Colors.greenAccent.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  selected: selected,
                                  showSelectedIcon: false,
                                  onSelectionChanged: (Set<String> newSelection) {
                                    setState(() => selected = newSelection);
                                    isIncomeNotifier.state = newSelection.contains('Income');
                                  },
                                ),
                              ),
                            ),

                            SizedBox(height: 32.h),

                            ListAnimationWidget(
                              index: 2,
                              offset: Offset(0, 0.1),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(color: theme.dividerColor.withOpacity(0.3))
                                ),
                                padding: EdgeInsets.all(24.w),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8.w),
                                          decoration: BoxDecoration(
                                            color: selectedColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10.r),
                                          ),
                                          child: Icon(
                                            isIncome ? Icons.trending_up : Icons.trending_down,
                                            color: selectedColor,
                                            size: 20.sp,
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Text(
                                          isIncome ? 'Income Distribution' : 'Expense Distribution',
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 28.h),
                                    Container(
                                      height: 200.h,
                                      width: 200.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            theme.colorScheme.primary.withOpacity(0.05),
                                            theme.colorScheme.surface.withOpacity(0.02),
                                          ],
                                        ),
                                      ),
                                      child: const PieChartScreen(),
                                    ),
                                    SizedBox(height: 24.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 16.w,
                                        runSpacing: 12.h,
                                        children: !(isIncome ? nonZeroInIncome : nonZeroInExpense)
                                            .isNotEmpty ? []
                                            : (isIncome ? nonZeroInIncome : nonZeroInExpense)
                                            .map((item) {
                                          Color c;
                                          switch (item) {
                                            case "Personal":
                                              c = Colors.green;
                                              break;
                                            case "Family":
                                              c = Colors.blue;
                                              break;
                                            case "Food":
                                              c = Colors.orange;
                                              break;
                                            case "Shopping":
                                              c = Colors.indigo;
                                              break;
                                            case "Transport":
                                              c = Colors.purple;
                                              break;
                                            case "Phone":
                                              c = Colors.cyan;
                                              break;
                                            case "Bills":
                                              c = Colors.teal;
                                              break;
                                            case "Rent":
                                              c = Colors.lime;
                                              break;
                                            default:
                                              c = Colors.pink;
                                          }
                                          return Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12.w,
                                              vertical: 8.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.cardColor,
                                              borderRadius: BorderRadius.circular(8.r),
                                              border: Border.all(
                                                color: c.withOpacity(0.3),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  height: 12.h,
                                                  width: 12.w,
                                                  decoration: BoxDecoration(
                                                    color: c,
                                                    borderRadius: BorderRadius.circular(3.r),
                                                  ),
                                                ),
                                                SizedBox(width: 8.w),
                                                Text(
                                                  item,
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 28.h),

                            ListAnimationWidget(
                              index: 3,
                              offset: Offset(0, 0.1),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(color: theme.dividerColor.withOpacity(0.3))
                                ),
                                padding: EdgeInsets.all(24.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8.w),
                                          decoration: BoxDecoration(
                                            color: selectedColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10.r),
                                          ),
                                          child: Icon(
                                            Icons.show_chart_rounded,
                                            color: selectedColor,
                                            size: 20.sp,
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Text(
                                          isIncome ? "Income Trend" : "Expense Trend",
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20.h),
                                    Container(
                                      height: 320.h,
                                      child: LineChartScreen(),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 28.h),

                            ListAnimationWidget(
                              index: 4,
                              offset: Offset(0, 0.1),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(color: theme.dividerColor.withOpacity(0.3))
                                ),
                                padding: EdgeInsets.all(24.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8.w),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10.r),
                                          ),
                                          child: Icon(
                                            Icons.account_balance_wallet_rounded,
                                            color: theme.colorScheme.primary,
                                            size: 20.sp,
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Text(
                                          "Account Overview",
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 12.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 14.h,
                                            width: 14.w,
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent,
                                              borderRadius: BorderRadius.circular(3.r),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'Expense',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 20.w),
                                          Container(
                                            height: 14.h,
                                            width: 14.w,
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade700,
                                              borderRadius: BorderRadius.circular(3.r),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'Income',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                    Container(
                                      height: 320.h,
                                      child: BarChartScreen(),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 32.h),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class AnimatedBalanceDashboard extends ConsumerWidget {
  final bool isCollapsed;
  const AnimatedBalanceDashboard({super.key, required this.isCollapsed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = Theme.of(context);
    final currency = ref.watch(newCurrencyProvider).currency;

    final selectedDate = ref.watch(selectedDateProvider);
    final selectedTime = ref.watch(selectedTimeProvider);

    return Container(
      color: theme.colorScheme.primary,
      child: ClipRect(
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: isCollapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: BalanceDashboard(
              theme: theme,
              dateNotifier: ref.read(selectedDateProvider.notifier),
              timeNotifier: ref.read(selectedTimeProvider.notifier),
              dateState: selectedDate,
              timeState: selectedTime,
              selectedCurrency: currency,
            ),
          ),
          secondChild: _buildMinimizedHeader(
            ref: ref,
            currency: currency,
            context: context,
          ),
        ),
      ),
    );
  }

  Widget _buildMinimizedHeader({
    required WidgetRef ref,
    required String currency,
    required BuildContext context,
  }) {
    var theme = Theme.of(context);

    final totalExpense = ref.watch(totalExpenseProvider);
    final formattedExpense = NumberFormat.compactCurrency(
      symbol: currency,
      decimalDigits: 0,
    ).format(totalExpense);

    final totalIncome = ref.watch(totalIncomeProvider);
    final formattedIncome = NumberFormat.compactCurrency(
      symbol: currency,
      decimalDigits: 0,
    ).format(totalIncome);

    final totalMoney = ref.watch(totalMoneyProvider);
    final formattedTotal = NumberFormat.compactCurrency(
      symbol: currency,
      decimalDigits: 0,
    ).format(totalMoney);

    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.arrow_downward,
                value: formattedExpense,
                theme: theme,
                color: Colors.red.shade300,
              ),
            ),
            Container(
              width: 1,
              height: 24.h,
              color: Colors.white.withOpacity(0.3),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.arrow_upward,
                value: formattedIncome,
                theme: theme,
                color: Colors.green.shade300,
              ),
            ),
            Container(
              width: 1,
              height: 24.h,
              color: Colors.white.withOpacity(0.3),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.account_balance_wallet,
                value: formattedTotal,
                theme: theme,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required ThemeData theme,
    required Color color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 14.sp,
        ),
        SizedBox(height: 2.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}




class PieChartScreen extends ConsumerWidget {
  const PieChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = Theme.of(context);

    final recordList = ref.watch(expenseProvider);
    final isIncome = ref.watch(isIncomeProvider);
    final allCategories = ref.watch(categoryProvider).allCategories;

    Map<String, double> categoryAmounts = {};

    for (var record in recordList.filteredRecord) {
      if (isIncome ? record.moneyType == MoneyType.income : record.moneyType == MoneyType.expense) {
        categoryAmounts[record.category] = (categoryAmounts[record.category] ?? 0) + record.amount;
      }
    }

    final total = categoryAmounts.values.fold(0.0, (sum, amount) => sum + amount);

    if (total == 0 || categoryAmounts.isEmpty) {
      return const Center(child: Text("No data to display"));
    }

    List<PieChartSectionData> sections = [];

    categoryAmounts.forEach((categoryName, amount) {
      if (amount > 0) {
        final categoryModel = allCategories.firstWhere(
              (cat) => cat.categoryName == categoryName,
          orElse: () => CategoryModel(
            categoryName: categoryName,
            icon: Icons.category,
            color: Colors.grey,
          ),
        );

        sections.add(
          PieChartSectionData(
            value: amount,
            color: categoryModel.color,
            title: '${(amount / total * 100).toStringAsFixed(1)}%',
            titleStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        );
      }
    });

    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        sections: sections,
      ),
    );
  }
}

class LineChartScreen extends ConsumerWidget {
  const LineChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recordList = ref.watch(expenseProvider).filteredRecord;
    final isIncome = ref.watch(isIncomeProvider);

    Map<String, double> dayMap = {};

    for (var i in recordList) {
      final date = DateTime(i.date.year, i.date.month, i.date.day);
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      if (isIncome ? i.moneyType == MoneyType.income : i.moneyType == MoneyType.expense) {
        dayMap[formattedDate] = (dayMap[formattedDate] ?? 0) + i.amount;
      }
    }

    final sortedDates = dayMap.keys.toList()..sort((a, b) => a.compareTo(b));

    if (sortedDates.isEmpty) {
      return const Center(child: Text("No data to display"));
    }

    List<FlSpot> spots = [];

    for (var i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), dayMap[sortedDates[i]] ?? 0));
    }


    final maxY = dayMap.values.isNotEmpty ? dayMap.values.reduce((a, b) => a > b ? a : b) : 10;

    final interval = (sortedDates.length / 6).ceilToDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        minY: 0,
        maxY: maxY * 1.2,
        gridData: FlGridData(
          drawHorizontalLine: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: false,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: maxY / 5,
              getTitlesWidget: (val, _) => Text(
                val.toInt().toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: interval,
              getTitlesWidget: (val, _) {
                final index = val.toInt();
                if (index >= 0 && index < sortedDates.length) {
                  final date = sortedDates[index];
                  return Text(
                    DateFormat('MMM,dd').format(DateTime.parse(date)),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(

              sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: isIncome ? Colors.greenAccent : Colors.redAccent,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isIncome
                    ? [Colors.greenAccent.withOpacity(0.3), Colors.transparent]
                    : [Colors.redAccent.withOpacity(0.3), Colors.transparent],
              ),
            ),
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

class BarChartScreen extends ConsumerWidget {
  const BarChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allAccounts = ref.watch(cardsProvider);
    final recordList = ref.watch(expenseProvider).filteredRecord;

    if (recordList.isEmpty) {
      return const Center(child: Text("No account data available"));
    }

    final accountStats = allAccounts.cards.map((card) {
      final totalExpenses = recordList
          .where((rec) => rec.accountId == card.id && rec.moneyType == MoneyType.expense)
          .fold(0.0, (sum, rec) => sum + rec.amount);

      final totalIncome = recordList
          .where((rec) => rec.accountId == card.id && rec.moneyType == MoneyType.income)
          .fold(0.0, (sum, rec) => sum + rec.amount);

      return {
        'name': card.cardName,
        'income': totalIncome,
        'expense': totalExpenses,
      };
    }).where((stat) {
      return (stat['income'] as double) > 0 || (stat['expense'] as double) > 0;
    }).toList();

    if (accountStats.isEmpty) {
      return const Center(child: Text("No account data available"));
    }

    final maxY = accountStats.map((stat) {
      final income = stat['income'] as double;
      final expense = stat['expense'] as double;
      return income > expense ? income : expense;
    }).reduce((a, b) => a > b ? a : b) * 1.2;

    final yInterval = maxY > 0 ? maxY / 5 : 1.0;

    final barWidth = 30.w;
    final groupWidth = (barWidth * 2) + 10; // 2 bars + spacing
    final accountSpacing = 40.w; // Space between account groups
    final minChartWidth = MediaQuery.of(context).size.width - 100.w;
    final calculatedWidth = (accountStats.length * (groupWidth + accountSpacing));
    final chartWidth = calculatedWidth > minChartWidth ? calculatedWidth : minChartWidth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: chartWidth,
        height: 320.h,
        padding: EdgeInsets.only(right: 20.w),
        child: BarChart(
          BarChartData(
            maxY: maxY > 0 ? maxY : 10,
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBorder: BorderSide(
                  color: theme.dividerColor.withOpacity(0.3),
                  width: 1,
                ),
                tooltipPadding: EdgeInsets.all(8.w),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final accountName = accountStats[group.x.toInt()]['name'] as String;
                  final isExpense = rodIndex == 0;
                  final label = isExpense ? 'Expense' : 'Income';
                  final amount = rod.toY;

                  return BarTooltipItem(
                    '$accountName\n$label: ${amount.toStringAsFixed(2)}',
                    theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ) ?? const TextStyle(),
                  );
                },
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              drawHorizontalLine: true,
              horizontalInterval: yInterval,
              getDrawingHorizontalLine: (value) => FlLine(
                color: theme.dividerColor.withOpacity(0.3),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  reservedSize: 50,
                  showTitles: true,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max) return const SizedBox.shrink();

                    return Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: Text(
                        value.toInt().toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= accountStats.length) {
                      return const SizedBox.shrink();
                    }

                    final accountName = accountStats[index]['name'] as String;

                    return Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: SizedBox(
                        width: groupWidth + accountSpacing,
                        child: Text(
                          accountName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            barGroups: List.generate(accountStats.length, (index) {
              final income = accountStats[index]['income'] as double;
              final expense = accountStats[index]['expense'] as double;

              return BarChartGroupData(
                x: index,
                barsSpace: 4,
                barRods: [
                  BarChartRodData(
                    toY: expense,
                    color: Colors.red,
                    width: barWidth,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4.r),
                    ),
                  ),
                  BarChartRodData(
                    toY: income,
                    color: Colors.green,
                    width: barWidth,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4.r),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}