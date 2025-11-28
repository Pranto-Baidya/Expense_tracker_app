import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:expense_tracker_app/riverpod/currency_riverpod/currency_pref.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:expense_tracker_app/widgets/balance_dashboard.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

final analysisDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final isIncomeProvider = StateProvider<bool>((ref) => false);

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(expenseProvider.notifier).getExpenses();
      await ref.read(cardsProvider.notifier).getCards();
    });
  }

  Set<String> selected = {'Expense'};

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

    final selectedColor = selected.contains('Expense')
        ? theme.colorScheme.error
        : Colors.greenAccent.shade700;

    final isIncome = ref.watch(isIncomeProvider);
    final isIncomeNotifier = ref.read(isIncomeProvider.notifier);

    final analysisDateState = ref.watch(analysisDateProvider);
    final analysisDateNotifier = ref.read(analysisDateProvider.notifier);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Column(
        children: [
          BalanceDashboard(
            theme: theme,
            dateNotifier: analysisDateNotifier,
            dateState: analysisDateState,
            selectedCurrency: ref.read(newCurrencyProvider).currency,
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
                  child: Column(
                    children: [
                      if (recordList.filteredRecord.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 80.h),
                          child: Column(
                            children: [
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
                        ),

                      if (recordList.filteredRecord.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: 12.h),

                              Container(
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

                              SizedBox(height: 32.h),

                              Container(
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

                              SizedBox(height: 28.h),

                              Container(
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

                              SizedBox(height: 28.h),

                              Container(
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


class PieChartScreen extends ConsumerWidget {
  const PieChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = Theme.of(context);

    double personal = 0;
    double family = 0;
    double food = 0;
    double shopping = 0;
    double transport = 0;
    double phone = 0;
    double bills = 0;
    double rent = 0;
    double other = 0;

    final recordList = ref.watch(expenseProvider);
    final isIncome = ref.watch(isIncomeProvider);

    for (var i in recordList.filteredRecord) {
      if (isIncome? i.moneyType==MoneyType.income: i.moneyType == MoneyType.expense) {
        switch (i.category) {
          case "Personal":
            personal += i.amount;
            break;
          case "Family":
            family += i.amount;
            break;
          case "Food":
            food += i.amount;
            break;
          case "Shopping":
            shopping += i.amount;
            break;
          case 'Transport':
            transport += i.amount;
            break;
          case 'Phone':
            phone += i.amount;
            break;
          case 'Bills':
            bills += i.amount;
            break;
          case 'Rent':
            rent += i.amount;
            break;
          default:
            other += i.amount;
        }
      }
    }

    final total =
        personal +
        family +
        food +
        shopping +
        transport +
        phone +
        bills +
        rent +
        other;

    if (total == 0) {
      return const Center(child: Text("No data to display"));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        sections: [
          if (personal > 0)
            sectionData(theme, personal, total, Colors.green),
          if (family > 0)
            sectionData(theme, family, total, Colors.blue),
          if (food > 0)
            sectionData(theme, food, total, Colors.orange),
          if (shopping > 0)
            sectionData(theme, shopping, total, Colors.indigo),
          if (transport > 0)
            sectionData(theme, transport, total, Colors.purple),
          if (phone > 0)
            sectionData(theme, phone, total, Colors.cyan),
          if (bills > 0)
            sectionData(theme, bills, total, Colors.teal),
          if (rent > 0)
            sectionData(theme, rent, total, Colors.lime),
          if (other > 0)
            sectionData(theme, other, total, Colors.pink),
        ],
      ),
    );
  }
  PieChartSectionData sectionData(
      ThemeData theme, double value, double total, Color color) {
    return PieChartSectionData(
      value: value,
      color: color,
      title: '${(value / total * 100).toStringAsFixed(1)}%',
      titleStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: Colors.white,
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
          show: true,
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
            isCurved: false,
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

    if(ref.read(expenseProvider).filteredRecord.isEmpty){
      return const Center(child: Text("No account data available"));
    }

    final recordList = ref.watch(expenseProvider).filteredRecord;

    final accountStats = allAccounts.cards.map((card){

      final totalExpenses = recordList.where((acc)=>acc.accountId==card.id && acc.moneyType==MoneyType.expense).fold(0.0, (a,b)=>a+b.amount);

      final totalIncome = recordList.where((acc)=>acc.accountId==card.id && acc.moneyType==MoneyType.income).fold(0.0, (a,b)=>a+b.amount);

      return {
        'name' : card.cardName,
        'income' : totalIncome,
        'expense' : totalExpenses
      };

    }).toList();

    final maxY = accountStats.map((i)=>(i['income'] as double) > (i['expense'] as double) ? i['income'] as double : i['expense'] as double)
                 .reduce((a,b)=>a>b?a:b) * 1.5;

    return BarChart(
      BarChartData(
        maxY: maxY>0?maxY:10,
        alignment: BarChartAlignment.spaceEvenly,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (_)=>FlLine(
            color: Colors.grey.withOpacity(0.3)
          )
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              reservedSize: 50,
              showTitles: true,
              interval: (maxY / 5) > 0 ? (maxY / 5) : 1,
              getTitlesWidget: (val,_){

                return Text(val.toInt().toString(),style: theme.textTheme.labelSmall,);
              }
            )
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val,_){
                final index = val.toInt();
                if(index>=0 && index<accountStats.length){
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(accountStats[index]['name'].toString(),style: theme.textTheme.bodySmall,textAlign: TextAlign.center,),
                  );
                }
                return const Text('');
              }
            )
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false
            )
          ),
          topTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: false
              )
          ),
        ),
        barGroups: List.generate(accountStats.length, (index){
          final income = accountStats[index]['income'] as double;
          final expense = accountStats[index]['expense'] as double;
          return BarChartGroupData(
              x: index,
              barsSpace: 10,
              barRods: [
                BarChartRodData(
                  toY: expense,
                  color: Colors.redAccent,
                  width: 30.w,
                  borderRadius: BorderRadius.circular(0),
                ),
                BarChartRodData(
                  toY: income,
                  color: Colors.green.shade700,
                  width: 30.w,
                  borderRadius: BorderRadius.circular(0),
                )
              ]
          );
        })
      )
    );
  }
}





