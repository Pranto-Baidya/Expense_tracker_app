import 'package:expense_tracker_app/models/budget_model.dart';
import 'package:expense_tracker_app/riverpod/budget_riverpod/budget_riverpod.dart';
import 'package:expense_tracker_app/widgets/app_colors.dart';
import 'package:expense_tracker_app/widgets/budget_dashboard.dart';
import 'package:expense_tracker_app/widgets/budget_widget.dart';
import 'package:expense_tracker_app/widgets/custom_app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

final checkBudgetTyping = StateProvider<bool>((ref)=>false);
final budgetEditingProvider = StateProvider<bool>((ref)=>false);
final selectedDateProviderForBudgets = StateProvider<DateTime>((ref)=>DateTime.now());

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<CategoryScreen> {
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _editBudgetController = TextEditingController();

  List<String> categories = [
    'Personal',
    'Family',
    'Food',
    'Shopping',
    'Transport',
    'Phone',
    'Bills',
    'Rent',
    'Other'
  ];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_)async{
      await ref.read(budgetProvider.notifier).getAllBudgetsList();
      ref.read(budgetProvider.notifier).filterBudgetsByMonth(ref.read(selectedDateProviderForBudgets));
    });
    _budgetController.addListener(()=>checkForBudgetTyping(ref));
    super.initState();
  }

  @override
  void dispose() {
    _budgetController.removeListener(()=>checkForBudgetTyping(ref));
    super.dispose();
  }

  void checkForBudgetTyping(WidgetRef ref,{BudgetModel? budget}){
    final isTyping = ref.read(checkBudgetTyping);
    final isEditing = ref.read(budgetEditingProvider);

    if(!isEditing) {
      bool hasBudget = _budgetController.text.isNotEmpty;

      if (hasBudget != isTyping) {
        ref.read(checkBudgetTyping.notifier).state = hasBudget;
      }
    }

    bool hasChanged = _editBudgetController.text!=budget?.budget.toString();

    if(hasChanged!=isTyping){
      ref.read(checkBudgetTyping.notifier).state = hasChanged;
    }
  }


  IconData getIconForCategory(String category) {
    switch (category) {
      case 'Personal':
        return Icons.person;
      case 'Family':
        return Icons.groups;
      case 'Food':
        return Icons.fastfood_rounded;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Transport':
        return Icons.directions_car;
      case 'Phone':
        return Icons.phone_iphone;
      case 'Bills':
        return Icons.receipt_long;
      case 'Rent':
        return Icons.maps_home_work;
      default:
        return Icons.control_point_duplicate;
    }
  }

  void addBudgetDialogue(String category, IconData icon) {
    ref.read(checkBudgetTyping.notifier).state = false;
    var theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer(
          builder: (context, ref, _) {
            final isTyping = ref.watch(checkBudgetTyping);
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Row(
                children: [
                  Text(
                    'Set new budget',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.primary,
                      size: 30,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primary,
                        child: Icon(
                          icon,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 15.w),
                      Text(
                        category,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: 15.h),
                  TextField(
                    autofocus: true,
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter budget amount',
                      hintStyle: theme.textTheme.titleSmall?.copyWith(color: AppColors.hintTextColor),
                    ),
                  ),
                  SizedBox(height: 15.h,),
                  Text('Month: ${DateFormat('MMMM, yyyy').format(DateTime.now())}',style: theme.textTheme.titleSmall?.copyWith(color: AppColors.hintTextColor),),
                  SizedBox(height: 15.h),
                 !isTyping?ElevatedButton(
                    onPressed: null,
                   style: ElevatedButton.styleFrom(
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(15.r),
                     ),
                     elevation: 0,
                     minimumSize: Size(double.infinity.w, 50.h),
                   ),
                    child: Text('Set',style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),),
                  ):
                  CustomAppButton(
                      onPressed: (){
                       final newBudget = BudgetModel(
                           categoryName: category,
                           budget: double.parse(_budgetController.text),
                           date: DateTime.now()
                       );
                       ref.read(budgetProvider.notifier).addBudget(newBudget);

                       Navigator.pop(context);
                      },
                      title: 'Set'
                  )
                ],
              ),
            );
          },
        );
      },
    ).then((_){
      ref.read(checkBudgetTyping.notifier).state = false;
      _budgetController.clear();
    });
  }

  void editBudgetDialogue(BudgetModel budget){
    ref.read(checkBudgetTyping.notifier).state = false;
    ref.read(budgetEditingProvider.notifier).state = true;

    _editBudgetController.text = budget.budget.toString();
    String category = budget.categoryName;

    showDialog(
        context: context,
        builder: (BuildContext context){
          var theme = Theme.of(context);
          return Consumer(
              builder: (context,ref,_){
                final isTyping = ref.watch(checkBudgetTyping);
                return AlertDialog(
                  backgroundColor: Theme.of(context).cardColor,
                  title: Row(
                    children: [
                      Text('Change budget',style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),),
                      Spacer(),
                      IconButton(
                          onPressed: (){
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close,color: theme.colorScheme.primary,size: 30,)
                      )
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.primary,
                            child: Icon(getIconForCategory(category),color: Colors.white,),
                          ),
                          SizedBox(width: 15.w),
                          Text(budget.categoryName,style: theme.textTheme.titleMedium,)
                        ],
                      ),
                      SizedBox(height: 15.h,),
                      TextField(
                        autofocus: true,
                        controller: _editBudgetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter budget amount',
                          hintStyle: theme.textTheme.titleSmall?.copyWith(color: AppColors.hintTextColor)
                        ),
                        onChanged: (_)=> checkForBudgetTyping(ref,budget: budget),
                      ),
                      SizedBox(height: 15.h,),
                      Text('Month: ${DateFormat('MMMM, yyyy').format(budget.date)}',style: theme.textTheme.titleSmall?.copyWith(color: AppColors.hintTextColor)),
                      SizedBox(height: 15.h,),
                      !isTyping?ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          elevation: 0,
                          minimumSize: Size(double.infinity.w, 50.h),
                        ),
                        child: Text('Set',style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),),
                      ):CustomAppButton(
                          onPressed: (){
                            final updatedBudget = BudgetModel(
                                id: budget.id,
                                categoryName: category,
                                budget: double.parse(_editBudgetController.text),
                                date: DateTime.now()
                            );
                            ref.read(budgetProvider.notifier).updateBudget(updatedBudget);
                            Navigator.pop(context);
                          },
                          title: 'Set'
                      )
                    ],
                  ),
                );
              }
          );
        }
    ).then((_){
      ref.read(budgetEditingProvider.notifier).state = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    final budgetState = ref.watch(budgetProvider);

    final budgetNotifier = ref.read(budgetProvider.notifier);

    final budgetedCategories = budgetState.filteredBudgets.map((i)=>i.categoryName).toSet();
    
    final unbudgetedCategories = categories.where((i){
      return !budgetedCategories.contains(i);
    }).toList();

    final groupedBudgets = _groupByDate(budgetState.filteredBudgets);

    final sortedDates = groupedBudgets.keys.toList()..sort((a,b)=>b.compareTo(a));

    final totalBudget = budgetState.filteredBudgets.fold(0,(a,b)=>(a+b.budget).toInt());

    final totalSpent = budgetState.filteredBudgets.fold(0,(a,b)=>(a+b.spent).toInt());

    final selectedDate = ref.watch(selectedDateProviderForBudgets);

    final now = DateTime.now();

    final isPastMonth = selectedDate.year<now.year || (selectedDate.year==now.year && selectedDate.month<now.month);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 10.h,),
              BudgetDashboard(
                dateNotifier: ref.read(selectedDateProviderForBudgets.notifier),
                dateState: ref.watch(selectedDateProviderForBudgets),
                totalBudget: totalBudget,
                totalSpent: totalSpent,
              ),
              if(isPastMonth && budgetedCategories.isEmpty)...[
                Column(
                  children: [
                    SizedBox(height: 50.h),
                    Icon(Icons.event_busy, color: theme.colorScheme.primary, size: 100),
                    SizedBox(height: 10.h),
                    Text('Month expired', style: theme.textTheme.titleMedium),
                    Text('View past budget limits for comparison',style: theme.textTheme.titleMedium)
                  ],
                ),
              ],
              if (budgetedCategories.isEmpty && !isPastMonth)
                Column(
                  children: [
                    SizedBox(height: 20.h),
                    Icon(Icons.note_add_outlined, color: theme.colorScheme.primary, size: 100),
                    SizedBox(height: 10.h),
                    Text('No budget was applied for this month', style: theme.textTheme.titleMedium),
                    Text('Set a budget from the list below',style: theme.textTheme.titleMedium)
                  ],
                ),
              SizedBox(height: 10.h,),
              if(budgetedCategories.isNotEmpty)
                    ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: sortedDates.length,
                        itemBuilder: (context,index){
                          final date = sortedDates[index];
                          final budgetsForDates = groupedBudgets[date]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10.h,),
                              Row(
                                children: [
                                  Text('Budgeted categories: ',style: theme.textTheme.titleMedium,),
                                  SizedBox(width: 5.w,),
                                  Text(
                                    DateFormat('MMM, yyyy').format(date),
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                              SizedBox(height: 5.h),
                              Divider(
                                thickness: 3,
                                indent: 0,
                                endIndent: 1,
                                color: theme.colorScheme.primary,
                              ),
                              ...budgetsForDates.map((budget){
                                return BudgetWidget(
                                    budget: budget,
                                    onEdit: ()=> editBudgetDialogue(budget),
                                    onDelete: ()=> budgetNotifier.deleteBudget(budget.id!)
                                );
                              })
                            ],
                          );
                        }
                    ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  if(!isPastMonth)...[
                    SizedBox(height: 20.h),
                    Text(
                      'Not budgeted this month',
                      style: theme.textTheme.titleMedium,
                    ),
                    SizedBox(height: 5.h),
                    Divider(
                      thickness: 3,
                      indent: 0,
                      endIndent: 1,
                      color: theme.colorScheme.primary,
                    ),
                    ...unbudgetedCategories.map((cat) {
                      final icon = getIconForCategory(cat);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: theme.colorScheme.primary,
                                child: Icon(
                                  icon,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 20.w),
                              Text(
                                cat,
                                style: theme.textTheme.titleMedium,
                              ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () {
                                  addBudgetDialogue(cat, icon);
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.r),
                                    side: BorderSide(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  backgroundColor: theme.cardColor,
                                  minimumSize: const Size(100, 50),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Set budget',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Map<DateTime,List<BudgetModel>> _groupByDate(List<BudgetModel> budget){
    Map<DateTime,List<BudgetModel>> map = {};
    
    for(var b in budget){
      final date = DateTime(b.date.year,b.date.month);
      
      if(!map.containsKey(date)){
        map[date] = [];
      }
      map[date]!.add(b);
    }
    return map;
  }
}
