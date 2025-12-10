import 'package:expense_tracker_app/models/budget_model.dart';
import 'package:expense_tracker_app/models/category_model.dart';
import 'package:expense_tracker_app/riverpod/budget_riverpod/budget_riverpod.dart';
import 'package:expense_tracker_app/riverpod/category_riverpod/category_riverpod.dart';
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
final budgetTrackProvider = StateProvider<int>((ref)=>0);
final selectedIdsForBulkDeleteProvider = StateProvider<Set<int>>((ref)=>{});
final isSelectedBudgetForBulkDeleteProvider = StateProvider<bool>((ref)=>false);


class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<BudgetScreen> with SingleTickerProviderStateMixin{
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

  late AnimationController _bulkDeleteFABController;

  late Animation<double> _bulkDeleteFABAnimation;

  @override
  void initState() {

    _bulkDeleteFABController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400)
    );

    _bulkDeleteFABAnimation = Tween<double>(begin: 0,end: 1).animate(CurvedAnimation(parent: _bulkDeleteFABController, curve: Curves.fastOutSlowIn));

    WidgetsBinding.instance.addPostFrameCallback((_)async{
      await ref.read(budgetProvider.notifier).getAllBudgetsList();
      ref.read(budgetProvider.notifier).filterBudgetsByMonth(ref.read(selectedDateProviderForBudgets));
      ref.read(categoryProvider.notifier).getAllCategories();
    });
    _budgetController.addListener(()=>checkForBudgetTyping(ref));
    super.initState();
  }

  @override
  void dispose() {
    _budgetController.removeListener(()=>checkForBudgetTyping(ref));
    _editBudgetController.removeListener(()=>checkForBudgetTyping(ref));
    _budgetController.dispose();
    _editBudgetController.dispose();
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


  void addBudgetDialogue(CategoryModel category) {
    _budgetController.clear();
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
                      Container(
                        height: 45.w,
                        width: 45.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.r),
                          gradient: LinearGradient(
                            colors: [
                              category.color.withOpacity(0.9),
                              category.color.withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: category.color.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Icon(category.icon, color: Colors.white, size: 22),
                      ),
                      SizedBox(width: 15.w),
                      Text(
                        category.categoryName,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
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
                           categoryName: category.categoryName,
                           budget: double.parse(_budgetController.text),
                           date: DateTime.now()
                       );
                       ref.read(budgetProvider.notifier).addBudget(newBudget);
                       ref.read(budgetTrackProvider.notifier).state++;
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

  void editBudgetDialogue(BudgetModel budget, CategoryModel model){
    ref.read(checkBudgetTyping.notifier).state = false;
    ref.read(budgetEditingProvider.notifier).state = true;

    _editBudgetController.text = budget.budget.toString();
    String category = budget.categoryName;

    IconData icon = model.icon;
    Color bgColor = model.color;

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
                          Container(
                            height: 45.w,
                            width: 45.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14.r),
                              gradient: LinearGradient(
                                colors: [
                                  bgColor.withOpacity(0.9),
                                  bgColor.withOpacity(0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: bgColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Icon(icon, color: Colors.white, size: 22),
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
                            ref.read(budgetTrackProvider.notifier).state++;
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

  void bulkDeleteAlert(){
    showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text('Delete selected records?',style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),),
            content: Text('This can not be undone.',style: Theme.of(context).textTheme.titleSmall,),
            actions: [
              TextButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: Text('Cancel',style: Theme.of(context).textTheme.titleMedium,)
              ),
              TextButton(
                  onPressed: (){
                    ref.read(budgetProvider.notifier).bulkDeleteBudgets(ref.read(selectedIdsForBulkDeleteProvider).toList());
                    ref.read(selectedIdsForBulkDeleteProvider).clear();
                    ref.read(isSelectedBudgetForBulkDeleteProvider.notifier).state = false;
                    Navigator.pop(context);
                  },
                  child: Text('Delete',style: Theme.of(context).textTheme.titleMedium,)
              ),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    final budgetState = ref.watch(budgetProvider);

    final budgetNotifier = ref.read(budgetProvider.notifier);

    final budgetedCategories = budgetState.filteredBudgets.map((i)=>i.categoryName).toSet();

    final expenseCategories = ref.watch(categoryProvider);
    
    final unbudgetedCategories = expenseCategories.allExpenseCategories.where((i){
      return !budgetedCategories.contains(i.categoryName);
    }).toList();

    final groupedBudgets = _groupByDate(budgetState.filteredBudgets);

    final sortedDates = groupedBudgets.keys.toList()..sort((a,b)=>b.compareTo(a));

    final totalBudget = budgetState.filteredBudgets.fold(0,(a,b){
      return (a+b.budget).toInt();
    });

    final totalSpent = budgetState.filteredBudgets.fold(0,(a,b)=>(a+b.spent).toInt());

    final selectedDate = ref.watch(selectedDateProviderForBudgets);

    final now = DateTime.now();

    final isPastMonth = selectedDate.year < now.year || (selectedDate.year==now.year && selectedDate.month<now.month);

    final isSelectedForBulkDelete = ref.watch(isSelectedBudgetForBulkDeleteProvider);

    final isSelectedForBulkDeleteNotifier = ref.read(isSelectedBudgetForBulkDeleteProvider.notifier);

    final selectedIdsState = ref.watch(selectedIdsForBulkDeleteProvider);

    final selectedIdsNotifier = ref.read(selectedIdsForBulkDeleteProvider.notifier);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Column(
        children: [
          SizedBox(height: 10.h),
          BudgetDashboard(
            dateNotifier: ref.read(selectedDateProviderForBudgets.notifier),
            dateState: ref.watch(selectedDateProviderForBudgets),
            totalBudget: totalBudget,
            totalSpent: totalSpent,
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if(budgetState.isLoading && budgetState.filteredBudgets.isEmpty)...[
                              Center(child: CircularProgressIndicator(color: theme.colorScheme.primary,),)
                            ],
                            if(!budgetState.isLoading)...[
                              if (isPastMonth && budgetedCategories.isEmpty)
                                SizedBox(
                                  width: double.infinity.w,
                                  child: Column(
                                    children: [
                                      SizedBox(height: 80.h),
                                      Icon(Icons.event_busy, color: theme.colorScheme.primary, size: 100),
                                      SizedBox(height: 24.h),
                                      Text('Month expired', style: theme.textTheme.titleLarge),
                                      SizedBox(height: 8.h),
                                      Text('View past budget limits for comparison', style: theme.textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                              if (budgetedCategories.isEmpty && !isPastMonth)
                                Column(
                                  children: [
                                    unbudgetedCategories.isEmpty?SizedBox(height: 80.h,):SizedBox(height: 20.h),
                                    Icon(Icons.note_add_outlined, color: theme.colorScheme.primary, size: 100),
                                    SizedBox(height: 24.h),
                                    Text('No budgets this month', style: theme.textTheme.titleLarge),
                                    SizedBox(height: 8.h),
                                    Text('Set a budget from the list below', style: theme.textTheme.bodyMedium),
                                  ],
                                ),
                              SizedBox(height: 10.h),
                              if (budgetedCategories.isNotEmpty)
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: sortedDates.length,
                                  itemBuilder: (context, index) {
                                    final date = sortedDates[index];
                                    final budgetsForDates = groupedBudgets[date]!;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 10.h),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: theme.colorScheme.primary.withOpacity(0.4),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 10.w),
                                            Text(
                                              'Budgeted categories: ',
                                              style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(width: 5.w),
                                            Text(
                                              DateFormat('MMM, yyyy').format(date),
                                              style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        isPastMonth?SizedBox(height: 10.w):SizedBox.shrink(),
                                        ...budgetsForDates.map((budget) {
                                          final matchedCategory = expenseCategories.allExpenseCategories.firstWhere(
                                                (i) => i.categoryName == budget.categoryName,
                                            orElse: () => CategoryModel(
                                              categoryName: budget.categoryName,
                                              icon: Icons.category,
                                              color: Colors.grey,
                                            ),
                                          );
                                          return GestureDetector(
                                            onLongPress: (){
                                              isSelectedForBulkDeleteNotifier.state = true;
                                              selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..add(budget.id!);
                                              if(selectedIdsNotifier.state.length==1){
                                                _bulkDeleteFABController.forward(from: 0);
                                              }
                                            },
                                            onTap: (){
                                              if(selectedIdsNotifier.state.contains(budget.id)){
                                                selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..remove(budget.id!);
                                                if(selectedIdsNotifier.state.isEmpty){
                                                  isSelectedForBulkDeleteNotifier.state = false;
                                                  _bulkDeleteFABController.reverse();
                                                }
                                              }
                                              else{
                                                selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..add(budget.id!);
                                              }
                                            },
                                            child: Column(
                                              children: [
                                                if(isSelectedForBulkDelete)...[
                                                  Row(
                                                    children: [
                                                      Icon(
                                                          selectedIdsState.contains(budget.id)?Icons.check_box:Icons.check_box_outline_blank,
                                                          color: selectedIdsState.contains(budget.id)?theme.colorScheme.primary:Colors.grey,
                                                      ),
                                                      SizedBox(width: 15.w,),
                                                      Expanded(
                                                        child: BudgetWidget(
                                                          bgColor: matchedCategory.color,
                                                          icon: matchedCategory.icon,
                                                          budget: budget,
                                                          onEdit: () => editBudgetDialogue(budget,matchedCategory),
                                                          onDelete: () => budgetNotifier.deleteBudget(budget.id!),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                ],
                                                if(!isSelectedForBulkDelete)...[
                                                  BudgetWidget(
                                                    bgColor: matchedCategory.color,
                                                    icon: matchedCategory.icon,
                                                    budget: budget,
                                                    onEdit: () => editBudgetDialogue(budget,matchedCategory),
                                                    onDelete: () => budgetNotifier.deleteBudget(budget.id!),
                                                  ),
                                                ]
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    );
                                  },
                                ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isPastMonth)
                                    ...[
                                      SizedBox(height: 20.h),
                                      Visibility(
                                        visible: unbudgetedCategories.isNotEmpty,
                                        replacement: SizedBox.shrink(),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: theme.colorScheme.primary.withOpacity(0.4),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 10.w),
                                            Text(
                                              'Not budgeted this month',
                                              style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 10.h),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: unbudgetedCategories.length,
                                        itemBuilder: (context, index) {
                                          final data = unbudgetedCategories[index];
                                          return Padding(
                                            padding: EdgeInsets.symmetric(vertical: 8.0),
                                            child: Container(
                                              padding: EdgeInsets.all(15),
                                              decoration: BoxDecoration(
                                                color: theme.cardColor.withOpacity(0.92),
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
                                                ] : [
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
                                              child: Row(
                                                children: [
                                                  Container(
                                                    height: 45.w,
                                                    width: 45.w,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(14.r),
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          data.color.withOpacity(0.9),
                                                          data.color.withOpacity(0.6),
                                                        ],
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: data.color.withOpacity(0.3),
                                                          blurRadius: 12,
                                                          spreadRadius: 1,
                                                          offset: const Offset(0, 4),
                                                        )
                                                      ],
                                                    ),
                                                    child: Icon(data.icon, color: Colors.white, size: 22),
                                                  ),
                                                  SizedBox(width: 20.w),
                                                  Text(data.categoryName, style: theme.textTheme.titleMedium),
                                                  Spacer(),
                                                  ElevatedButton(
                                                    onPressed: ()=> addBudgetDialogue(data),
                                                    style: ElevatedButton.styleFrom(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(15.r),
                                                        side: BorderSide(color: theme.colorScheme.primary),
                                                      ),
                                                      backgroundColor: theme.cardColor,
                                                      minimumSize: Size(100, 50),
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
                                        },
                                      ),
                                    ]
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isSelectedForBulkDelete?
      ScaleTransition(
        scale: _bulkDeleteFABController,
        child: Container(
          height: 64.h,
          width: 64.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withOpacity(0.9),
                Colors.red.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: bulkDeleteAlert,
              borderRadius: BorderRadius.circular(18),
              child: Center(
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      )
      :SizedBox.shrink(),
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
