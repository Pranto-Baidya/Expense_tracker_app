import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final isIncomeProvider = StateProvider<bool>((ref)=>false);

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {

  Set<String> selected = {'Expense'};

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    final recordList = ref.watch(expenseProvider);

    final nonZeroInExpense = recordList.expenses.where((exp) => exp.amount != 0 && (exp.moneyType == MoneyType.expense)).toList();

    final nonZeroInIncome = recordList.expenses.where((exp) => exp.amount != 0 && (exp.moneyType == MoneyType.income)).toList();

    final selectedColor = selected.contains('Expense') ? Colors.red : Colors.green;

    final isIncome = ref.watch(isIncomeProvider);

    final isIncomeNotifier = ref.read(isIncomeProvider.notifier);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      icon: Icon(Icons.warning_amber,
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
              Center(child: Text('Pie chart of records',style: theme.textTheme.titleLarge,)),
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
                    switch (item.category) {
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
                          item.category,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    );
                  }).toList()
                      :nonZeroInIncome.map((item) {
                    late Color incomeLegendColor;
                    switch (item.category) {
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
                          item.category,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    );
                  }).toList()
                ) ,
              ),

             SizedBox(height: 20.h,),
              Center(
                child: !isIncome?Text(
                  "(Expense distribution by category)",
                  style: theme.textTheme.titleMedium,
                ):Text(
                  "(Income distribution by category)",
                  style: theme.textTheme.titleMedium,
                ),
              ),
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

    for (var i in recordList.expenses) {
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

    final total = personal +
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
