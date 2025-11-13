
import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:expense_tracker_app/widgets/balace_dashboard.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

final analysisDateProvider = StateProvider<DateTime>((ref)=>DateTime.now());

final isIncomeProvider = StateProvider<bool>((ref)=>false);

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

    final nonZeroInExpense = recordList.filteredRecord.where((exp) => exp.amount != 0 && (exp.moneyType == MoneyType.expense)).map((i)=>i.category).toSet().toList();

    final nonZeroInIncome = recordList.filteredRecord.where((exp) => exp.amount != 0 && (exp.moneyType == MoneyType.income)).map((i)=>i.category).toSet().toList();

    final selectedColor = selected.contains('Expense') ? Colors.red : Colors.green;

    final isIncome = ref.watch(isIncomeProvider);

    final isIncomeNotifier = ref.read(isIncomeProvider.notifier);

    final analysisDateState = ref.watch(analysisDateProvider);

    final analysisDateNotifier = ref.read(analysisDateProvider.notifier);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h,),
              BalanceDashboard(
                  theme: theme,
                  dateNotifier: analysisDateNotifier,
                  dateState: analysisDateState,
                  selectedCurrency: ref.read(currencyProvider)
              ),
              if(ref.watch(expenseProvider).filteredRecord.isEmpty)
                Center(
                  child: Column(
                    children: [
                      SizedBox(height: 80.h,),
                      Icon(Icons.query_stats,size: 100,color: theme.colorScheme.primary,),
                      SizedBox(height: 10.h,),
                      Text('No analysis for this month',style: theme.textTheme.titleMedium,)
                    ],
                  ),
                ),
              if(ref.watch(expenseProvider).filteredRecord.isNotEmpty)...[
              SizedBox(height: 20.h),
              Text('Analysis of records', style: theme.textTheme.titleLarge),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return selectedColor;
                      }
                      return theme.cardColor;
                    }),
                    side: WidgetStateProperty.all(
                        BorderSide.none
                    ),
                  ),
                  segments: [
                    ButtonSegment(
                      value: 'Expense',
                      icon: Icon(Icons.remove,
                          color: selected.contains('Expense')
                              ? Colors.white
                              : Colors.redAccent),
                      label: Text(
                        'Expense',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: selected.contains('Expense')
                              ? Colors.white
                              : Colors.redAccent,
                        ),
                      ),
                    ),
                    ButtonSegment(
                      value: 'Income',
                      icon: Icon(Icons.add,
                          color: selected.contains('Income')
                              ? Colors.white
                              : Colors.green),
                      label: Text(
                        'Income',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: selected.contains('Income')
                              ? Colors.white
                              : Colors.green,
                        ),
                      ),
                    ),
                  ],
                  selected: selected,
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() => selected = newSelection);
                    if(newSelection.contains('Income')){
                      isIncomeNotifier.state = true;
                    }
                    else{
                      isIncomeNotifier.state = false;
                    }
                  },
                ),
              ),
              SizedBox(height: 20.h),
              Center(child: isIncome?Text('Income overview',style: theme.textTheme.titleLarge,):Text('Expense overview',style: theme.textTheme.titleLarge,)),
              SizedBox(height: 5.h,),
              Divider(indent: 50,endIndent: 50,thickness: 3),
              SizedBox(height: 30.h),
              Center(
                child: SizedBox(
                  height: 220.h,
                  width: 220.w,
                  child: const PieChartScreen(),
                ),
              ),
              SizedBox(height: 20.h),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 16,
                  runSpacing: 12,
                  children: !isIncome?
                  nonZeroInExpense.map((item) {
                    late Color color;
                    switch (item) {
                      case "Personal":
                        color = Colors.green;
                        break;
                      case "Family":
                        color = Colors.blue;
                        break;
                      case "Food":
                        color = Colors.orange;
                        break;
                      case "Shopping":
                        color = Colors.indigo;
                        break;
                      case "Transport":
                        color = Colors.purple;
                        break;
                      case "Phone":
                        color = Colors.cyan;
                        break;
                      case "Bills":
                        color = Colors.teal;
                        break;
                      case "Rent":
                        color = Colors.lime;
                        break;
                      default:
                        color = Colors.pink;
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          color: color,
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          item,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    );
                  }).toList()
                      :nonZeroInIncome.map((item) {
                    late Color incomeLegendColor;
                    switch (item) {
                      case "Personal":
                        incomeLegendColor = Colors.green;
                        break;
                      case "Family":
                        incomeLegendColor = Colors.blue;
                        break;
                      case "Food":
                        incomeLegendColor = Colors.orange;
                        break;
                      case "Shopping":
                        incomeLegendColor = Colors.indigo;
                        break;
                      case "Transport":
                        incomeLegendColor = Colors.purple;
                        break;
                      case "Phone":
                        incomeLegendColor = Colors.cyan;
                        break;
                      case "Bills":
                        incomeLegendColor = Colors.teal;
                        break;
                      case "Rent":
                        incomeLegendColor = Colors.lime;
                        break;
                      default:
                        incomeLegendColor = Colors.pink;
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          color: incomeLegendColor,
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          item,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    );
                  }).toList()
                ) ,
              ),

             SizedBox(height: 20.h,),
              ref.read(expenseProvider).filteredRecord.isNotEmpty?Center(
                child: !isIncome?Text(
                  "(Expense distribution by category)",
                  style: theme.textTheme.titleMedium,
                ):Text(
                  "(Income distribution by category)",
                  style: theme.textTheme.titleMedium,
                ),
              ):SizedBox.shrink(),
              SizedBox(height: 40.h,),
              Center(child: isIncome? Text('Income flow',style: theme.textTheme.titleLarge,):Text('Expense flow',style: theme.textTheme.titleLarge,)),
              SizedBox(height: 5.h,),
              Divider(indent: 50,endIndent: 50,thickness: 3,),
              SizedBox(height: 30.h,),
              SizedBox(
                height: 400.h,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: LineChartScreen(),
                ),
              ),
              SizedBox(height: 40.h,),
              Center(child: Text('Analysis of accounts',style: theme.textTheme.titleLarge,)),
              SizedBox(height: 5.h,),
              Divider(indent: 50,endIndent: 50,thickness: 3,),
              SizedBox(height: 20.h,),
              Visibility(
                visible: ref.read(expenseProvider).filteredRecord.isNotEmpty,
                replacement: SizedBox.shrink(),
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 5.h),
                        Text(
                          'Expense',
                          style: theme.textTheme.bodySmall,
                        ),
                        SizedBox(width: 10.w,),
                        Container(
                          width: 20,
                          height: 20,
                          color: Colors.green.shade700,
                        ),
                        SizedBox(width: 5.h),
                        Text(
                          'Income',
                          style: theme.textTheme.bodySmall,
                        ),
                      ]
                  ),
                ),
              ),
              SizedBox(height: 20.h,),
              SizedBox(height: 30.h,),
              SizedBox(
                  height: 400.h,
                  child: BarChartScreen()
              ),
              SizedBox(height: 20.h,),
              ]
            ],
          ),
        ),
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
                final formatted = NumberFormat.currency(
                  symbol: ref.read(currencyProvider),
                  decimalDigits: 2
                ).format(val);
                return Text(formatted.toString(),style: theme.textTheme.labelSmall,);
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





