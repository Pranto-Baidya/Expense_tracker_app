import 'package:expense_tracker_app/models/budget_model.dart';
import 'package:expense_tracker_app/models/category_model.dart';
import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:expense_tracker_app/riverpod/budget_riverpod/budget_riverpod.dart';
import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:expense_tracker_app/riverpod/category_riverpod/category_riverpod.dart';
import 'package:expense_tracker_app/riverpod/currency_riverpod/currency_pref.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/widgets/app_colors.dart';
import 'package:expense_tracker_app/widgets/budget_dashboard.dart';
import 'package:expense_tracker_app/widgets/budget_widget.dart';
import 'package:expense_tracker_app/widgets/custom_app_button.dart';
import 'package:expense_tracker_app/widgets/listAnimation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../riverpod/prefs_riverpod/prefs_riverpod.dart';

final checkBudgetTyping = StateProvider<bool>((ref)=>false);
final budgetEditingProvider = StateProvider<bool>((ref)=>false);
final selectedDateProviderForBudgets = StateProvider<DateTime>((ref)=>DateTime.now());
final budgetTrackProvider = StateProvider<int>((ref)=>0);
final selectedIdsForBulkDeleteProvider = StateProvider<Set<int>>((ref)=>{});
final isSelectedBudgetForBulkDeleteProvider = StateProvider<bool>((ref)=>false);
final budgetDashboardCollapsedProvider = StateProvider<bool>((ref)=>false);
final isAllBudgetSelectedForBulkDeleteProvider = StateProvider<bool>((ref)=>false);


class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<BudgetScreen> with TickerProviderStateMixin{

  final TextEditingController _budgetController = TextEditingController();

  final TextEditingController _editBudgetController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

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

  final double _expandedHeight = 244.0.h;

  final double _collapsedHeight = 60.0.h;
  
  late AnimationController _detailsAnimation;
  
  late Animation<double> _fadeAnim;
  
  late Animation<Offset> _slideAnim;

  @override
  void initState() {

    _scrollController.addListener(_onScroll);

    _bulkDeleteFABController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500)
    );

    _bulkDeleteFABAnimation = Tween<double>(begin: 0,end: 1).animate(CurvedAnimation(parent: _bulkDeleteFABController, curve: Curves.fastOutSlowIn));
    
    _detailsAnimation = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800)
    );
    
    _fadeAnim = Tween<double>(begin: 0,end: 1).animate(CurvedAnimation(parent: _detailsAnimation, curve: Curves.easeInOut));

    _slideAnim = Tween<Offset>(begin: Offset(-0.7, 0),end: Offset.zero).animate(CurvedAnimation(parent: _detailsAnimation, curve: Curves.fastOutSlowIn));

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
    _scrollController.removeListener(_onScroll);
    _budgetController.removeListener(()=>checkForBudgetTyping(ref));
    _editBudgetController.removeListener(()=>checkForBudgetTyping(ref));
    _budgetController.dispose();
    _editBudgetController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll(){
    final collapseState = ref.read(budgetDashboardCollapsedProvider);
    final collapseNotifier = ref.read(budgetDashboardCollapsedProvider.notifier);

    final isCollapsed = _scrollController.offset > 50;

    if(isCollapsed!=collapseState){
      collapseNotifier.state = isCollapsed;
    }
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

  Color progressColors(double val){
    if(val<0.4){
      return Colors.green;
    }
    else if(val<0.7){
      return Colors.orange;
    }
    return Colors.redAccent;
  }

  void addBudgetDialogue(CategoryModel category) {

    final currentNavigationDate = ref.read(selectedDateProviderForBudgets);

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

                  Text(
                    'Month: ${DateFormat('MMMM, yyyy').format(currentNavigationDate)}',
                    style: theme.textTheme.titleSmall?.copyWith(color: AppColors.hintTextColor),
                  ),
                  SizedBox(height: 15.h),
                  !isTyping ? ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      elevation: 0,
                      minimumSize: Size(double.infinity.w, 50.h),
                    ),
                    child: Text('Set', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),),
                  ) : CustomAppButton(
                      onPressed: () {
                        final newBudget = BudgetModel(
                          categoryName: category.categoryName,
                          budget: double.parse(_budgetController.text),
                          date: currentNavigationDate,
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
    ).then((_) {
      ref.read(checkBudgetTyping.notifier).state = false;
      _budgetController.clear();
    });
  }

  void editBudgetDialogue(BudgetModel budget, CategoryModel model){

    final currentNavigationDate = ref.read(selectedDateProviderForBudgets);

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
                                date: budget.date
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
      ref.read(selectedDateProviderForBudgets.notifier).state = currentNavigationDate;
    });
  }

  void deleteAlert(BudgetModel budget){
    showGeneralDialog(
        context: context,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black45,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 600),
        transitionBuilder: (context,animation,_,child){
          return ScaleTransition(
            scale: CurvedAnimation(
                parent: animation,
                curve: Curves.elasticOut
            ),
            child: child,
          );
        },
        pageBuilder: (BuildContext context,_,_){
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Delete budget',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Are you sure you want to delete this budget?\nThis action cannot be undone.',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (){
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (){
                            ref.read(budgetProvider.notifier).deleteBudget(budget.id!);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Delete',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.white),
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
    );
  }

  void bulkDeleteAlert(){
    showGeneralDialog(
        context: context,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black45,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 600),
        transitionBuilder: (context,animation,_,child){
          return ScaleTransition(
              scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.elasticOut
              ),
            child: child,
          );
        },
        pageBuilder: (BuildContext context,_,_){
          final selectedIds = ref.read(selectedIdsForBulkDeleteProvider);
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: selectedIds.length==1?Text(
                          'Delete ${selectedIds.length} budget?',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: 17,fontWeight: FontWeight.bold),
                        ):Text(
                          'Delete ${selectedIds.length} budgets?',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: 17,fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This action cannot be undone.',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (){
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (){
                            ref.read(budgetProvider.notifier).bulkDeleteBudgets(selectedIds.toList());
                            selectedIds.clear();
                            ref.read(isSelectedBudgetForBulkDeleteProvider.notifier).state = false;
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Delete',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.white),
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
    );
  }

  void budgetDetails(BudgetModel budget) {
    _detailsAnimation.reset();
    _detailsAnimation.forward();

    bool isSortPressed = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var theme = Theme.of(context);

        return Consumer(
          builder: (context, ref, _) {
            final selectedBudget = ref.read(budgetProvider).filteredBudgets.firstWhere((i) => i.id == budget.id);
            final totalExpense = ref.read(totalExpenseProvider);
            final avg = (selectedBudget.spent / totalExpense) * 100;
            final progress = selectedBudget.spent / totalExpense;
            final category = ref.read(categoryProvider).allExpenseCategories.firstWhere((i) => i.categoryName == budget.categoryName);
            final allRecords = ref.read(expenseProvider).expenses;
            final accounts = ref.read(cardsProvider).cards;

            final matchedRecord = allRecords.where((record) {
              return record.category == budget.categoryName &&
                  record.date.year == budget.date.year &&
                  record.date.month == budget.date.month;
            }).toList();

            matchedRecord.sort((a, b) => b.date.compareTo(a.date));

            final formatted = NumberFormat.currency(
              symbol: ref.read(newCurrencyProvider).currency,
              decimalDigits: 2,
            ).format(selectedBudget.spent);

            final formattedBudget = NumberFormat.currency(
              symbol: ref.read(newCurrencyProvider).currency,
              decimalDigits: 2
            ).format(selectedBudget.budget);


            final remainingFormatted = NumberFormat.currency(
              symbol: ref.read(newCurrencyProvider).currency,
              decimalDigits: 2,
            ).format(selectedBudget.remaining);

            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.92,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                        width: 46.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: theme.iconTheme.color,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),

                      SizedBox(height: 5.h),

                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 20.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                category.color,
                                category.color.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24.r),
                            boxShadow: [
                              BoxShadow(
                                color: category.color.withOpacity(0.4),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(24.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(16.w),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.25),
                                            borderRadius: BorderRadius.circular(18.r),
                                          ),
                                          child: Icon(
                                            category.icon,
                                            color: Colors.white,
                                            size: 32.sp,
                                          ),
                                        ),
                                        SizedBox(width: 16.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                category.categoryName,
                                                style: theme.textTheme.headlineSmall?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                DateFormat('MMMM yyyy').format(budget.date),
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 24.h),

                                    Row(
                                      children: [
                                        SlideTransition(
                                          position: _slideAnim,
                                          child: RotationTransition(
                                            turns: _fadeAnim,
                                            child: Container(
                                              width: 90.w,
                                              height: 90.w,
                                              child: Stack(
                                                children: [
                                                  SizedBox(
                                                    width: 90.w,
                                                    height: 90.w,
                                                    child: CircularProgressIndicator(
                                                      value: progress.clamp(0.0, 1.0),
                                                      strokeWidth: 8,
                                                      backgroundColor: Colors.white.withOpacity(0.2),
                                                      valueColor: AlwaysStoppedAnimation(
                                                        progress > 0.9 ? Colors.red : Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Center(
                                                        child: Text(
                                                          '${avg.toStringAsFixed(0)}%',
                                                          style: theme.textTheme.titleLarge?.copyWith(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      Text('of total',style: theme.textTheme.titleSmall?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),)
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 20.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Spent',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: Colors.white70,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              Text(
                                                formatted,
                                                style: theme.textTheme.headlineSmall?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                'of $formattedBudget budget',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 30.h),

                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(16.w),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        child: Icon(
                                          Icons.trending_down,
                                          color: Colors.green,
                                          size: 20.sp,
                                        ),
                                      ),
                                      SizedBox(height: 12.h),
                                      Text(
                                        'Remaining',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        remainingFormatted,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(16.w),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: category.color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        child: Icon(
                                          Icons.receipt_long,
                                          color: category.color,
                                          size: 20.sp,
                                        ),
                                      ),
                                      SizedBox(height: 12.h),
                                      Text(
                                        'Transactions',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        '${matchedRecord.length}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 24.h),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Row(
                          children: [
                            Text(
                              'Transactions',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            if (matchedRecord.length > 1)
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    isSortPressed = !isSortPressed;
                                    if (isSortPressed) {
                                      matchedRecord.sort((a, b) => a.date.compareTo(b.date));
                                    } else {
                                      matchedRecord.sort((a, b) => b.date.compareTo(a.date));
                                    }
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: theme.dividerColor.withOpacity(0.2),
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: Duration(milliseconds: 300),
                                    transitionBuilder: (Widget child, Animation<double> animation) {
                                      return ScaleTransition(scale: animation, child: child);
                                    },
                                    child: Icon(
                                      isSortPressed ? Icons.arrow_upward : Icons.arrow_downward,
                                      key: ValueKey<bool>(isSortPressed),
                                      color: theme.iconTheme.color,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      Expanded(
                        child: matchedRecord.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(24.w),
                                decoration: BoxDecoration(
                                  color: category.color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.inbox_rounded,
                                  size: 48.sp,
                                  color: category.color.withOpacity(0.5),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'No transactions yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Your transactions will appear here',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                            : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                          itemCount: matchedRecord.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final data = matchedRecord[index];

                            final formattedAmount = NumberFormat.currency(
                              symbol: ref.read(newCurrencyProvider).currency,
                              decimalDigits: 2,
                            ).format(data.amount);

                            final acc = accounts.firstWhere((i) => i.id == data.accountId);

                            return FadeTransition(
                              opacity: _fadeAnim,
                              child: ListAnimationWidget(
                                index: index,
                                offset: Offset(0, 0.3),
                                child: Container(
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
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                        decoration: BoxDecoration(
                                          color: category.color.withOpacity(0.08),
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16.r),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 14.sp,
                                              color: category.color,
                                            ),
                                            SizedBox(width: 6.w),
                                            Text(
                                              DateFormat('MMMM dd, yyyy').format(data.date),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: category.color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Spacer(),
                                            Icon(
                                              Icons.access_time,
                                              size: 14.sp,
                                              color: category.color,
                                            ),
                                            SizedBox(width: 6.w),
                                            Text(
                                              DateFormat('hh:mm a').format(data.date),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: category.color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Padding(
                                        padding: EdgeInsets.all(16.w),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(12.w),
                                              decoration: BoxDecoration(
                                                color: category.color.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(12.r),
                                              ),
                                              child: Icon(
                                                category.icon,
                                                color: category.color,
                                                size: 24.sp,
                                              ),
                                            ),
                                            SizedBox(width: 14.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    data.title,
                                                    style: theme.textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  SizedBox(height: 6.h),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        acc.icon,
                                                        size: 16.sp,
                                                        color: theme.iconTheme.color?.withOpacity(0.6),
                                                      ),
                                                      SizedBox(width: 6.w),
                                                      Text(
                                                        acc.cardName,
                                                        style: theme.textTheme.bodySmall?.copyWith(
                                                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(10.r),
                                                border: Border.all(
                                                  color: Colors.red.withOpacity(0.2),
                                                ),
                                              ),
                                              child: Text(
                                                '-$formattedAmount',
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) => _detailsAnimation.reset());
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

    final isCollapseModeActivated = ref.watch(collapseDashboardPrefProvider);

    final allSelectedNotifier = ref.read(isAllBudgetSelectedForBulkDeleteProvider.notifier);

    final allFilteredBudgets = ref.watch(budgetProvider).filteredBudgets;

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,

      body: isCollapseModeActivated? CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: _expandedHeight,
            collapsedHeight: _collapsedHeight,
            backgroundColor: theme.colorScheme.primary,
            elevation: 0,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {

                final double maxHeight = _expandedHeight;
                final double minHeight = _collapsedHeight;
                final double currentHeight = constraints.maxHeight;

                final double collapseThreshold = minHeight + ((maxHeight - minHeight) * 0.3);
                final bool isCurrentlyCollapsed = currentHeight <= collapseThreshold;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final currentState = ref.read(budgetDashboardCollapsedProvider);
                  if (isCurrentlyCollapsed != currentState) {
                    ref.read(budgetDashboardCollapsedProvider.notifier).state = isCurrentlyCollapsed;
                  }
                });

                return AnimatedBudgetDashboard(
                  isCollapsed: isCurrentlyCollapsed,
                );
              },
            ),
          ),

          if (budgetState.isLoading)
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
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            )

          else if (isPastMonth && budgetedCategories.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                width: double.infinity.w,
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
                      SizedBox(height: 80.h),
                      Icon(Icons.event_busy, color: theme.colorScheme.primary, size: 100),
                      SizedBox(height: 24.h),
                      Text('Month expired', style: theme.textTheme.titleLarge),
                      SizedBox(height: 8.h),
                      Text('View past budget limits for comparison', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            )

          else if (budgetedCategories.isEmpty && !isPastMonth)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    SizedBox(height: 12.h,),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.r),
                            topRight: Radius.circular(20.r),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                            child: Column(
                              children: [
                                SizedBox(height: unbudgetedCategories.isEmpty ? 80.h : 20.h),
                                Icon(Icons.note_add_outlined, color: theme.colorScheme.primary, size: 100),
                                SizedBox(height: 24.h),
                                Text('No budgets this month', style: theme.textTheme.titleLarge),
                                SizedBox(height: 8.h),
                                Text('Set a budget from the list below', style: theme.textTheme.bodyMedium),

                                if (unbudgetedCategories.isNotEmpty) ...[
                                  SizedBox(height: 20.h),
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
                                              offset: const Offset(0, 2),
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
                                  SizedBox(height: 10.h),
                                  ...unbudgetedCategories.map((data) {
                                    final index = unbudgetedCategories.indexOf(data);
                                    return ListAnimationWidget(
                                      index: index,
                                      offset: const Offset(0, 0.3),
                                      child: Padding(
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
                                                Expanded(
                                                  child: Text(
                                                    data.categoryName,
                                                    style: theme.textTheme.titleMedium,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                SizedBox(width: 12.w),
                                                ElevatedButton(
                                                  onPressed: () => addBudgetDialogue(data),
                                                  style: ElevatedButton.styleFrom(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12.r),
                                                      side: BorderSide(color: theme.colorScheme.primary),
                                                    ),
                                                    backgroundColor: theme.cardColor,
                                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                                                    elevation: 0,
                                                  ),
                                                  child: FittedBox(
                                                    child: Text(
                                                      'Set budget',
                                                      style: theme.textTheme.titleSmall?.copyWith(
                                                        color: theme.colorScheme.primary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )

           else
            SliverList(
              delegate: SliverChildListDelegate([
                SizedBox(height: 10.h),
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
                    padding: EdgeInsets.symmetric(horizontal: 15.w,vertical: 8.h),
                    child: Column(
                      children: [

                        SizedBox(height: 10.h),

                        // Budgeted Categories List
                        if (budgetedCategories.isNotEmpty)
                          ...sortedDates.expand((date) {
                            final budgetsForDates = groupedBudgets[date]!;
                            return [
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
                                          offset: const Offset(0, 2),
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
                              isSelectedForBulkDelete? SizedBox(height: 5.h,):SizedBox.shrink(),
                              Visibility(
                                  visible: isSelectedForBulkDelete,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                            onPressed: (){
                                              final allIds = allFilteredBudgets.map((i)=>i.id!).toSet();

                                              final areAllSelected = allFilteredBudgets.length==selectedIdsState.length && allFilteredBudgets.every((i)=>selectedIdsState.contains(i.id!));

                                              if(areAllSelected){
                                                selectedIdsNotifier.state = {};
                                                allSelectedNotifier.state = false;
                                              }
                                              else{
                                                selectedIdsNotifier.state = allIds;
                                                allSelectedNotifier.state = true;
                                              }
                                            },
                                            icon: (allFilteredBudgets.length==selectedIdsState.length && allFilteredBudgets.every((i)=>selectedIdsState.contains(i.id!)))?
                                            Icon(Icons.check_box,color: theme.colorScheme.primary,)
                                                :Icon(Icons.check_box_outline_blank,color: theme.colorScheme.primary,)
                                        ),
                                        Text('Select all',style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),)
                                      ],
                                    ),
                                  )
                              ),
                              if (isPastMonth) SizedBox(height: 10.h),
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
                                  onLongPress: () {
                                    isSelectedForBulkDeleteNotifier.state = true;
                                    selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..add(budget.id!);
                                    if (selectedIdsNotifier.state.length == 1) {
                                      _bulkDeleteFABController.forward(from: 0);
                                    }
                                  },
                                  onTap: () {
                                    if (isSelectedForBulkDelete) {
                                      if (selectedIdsNotifier.state.contains(budget.id)) {
                                        selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..remove(budget.id!);
                                        if (selectedIdsNotifier.state.isEmpty) {
                                          isSelectedForBulkDeleteNotifier.state = false;
                                          _bulkDeleteFABController.reverse();
                                        }
                                      } else {
                                        selectedIdsNotifier.state = Set<int>.from(selectedIdsState)..add(budget.id!);
                                      }
                                    }
                                  },
                                  child: Column(
                                    children: [
                                      if (isSelectedForBulkDelete) ...[
                                        Row(
                                          children: [
                                            Icon(
                                              selectedIdsState.contains(budget.id)
                                                  ? Icons.check_box
                                                  : Icons.check_box_outline_blank,
                                              color: selectedIdsState.contains(budget.id)
                                                  ? theme.colorScheme.primary
                                                  : Colors.grey,
                                            ),
                                            SizedBox(width: 15.w),
                                            Expanded(
                                              child: BudgetWidget(
                                                bgColor: matchedCategory.color,
                                                icon: matchedCategory.icon,
                                                budget: budget,
                                                onEdit: () => editBudgetDialogue(budget, matchedCategory),
                                                onDelete: () => deleteAlert(budget),
                                                onDetailsTap: ()=> budgetDetails(budget),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                      if (!isSelectedForBulkDelete) ...[
                                        InkWell(
                                          onTap: ()=>budgetDetails(budget),
                                          child: ListAnimationWidget(
                                            offset: const Offset(0, 0.3),
                                            index: budgetsForDates.indexOf(budget),
                                            child: BudgetWidget(
                                              bgColor: matchedCategory.color,
                                              icon: matchedCategory.icon,
                                              budget: budget,
                                              onEdit: () => editBudgetDialogue(budget, matchedCategory),
                                              onDelete: () =>  deleteAlert(budget),
                                              onDetailsTap: ()=> budgetDetails(budget),
                                            ),
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                );
                              }),
                            ];
                          }),

                        // Not Budgeted Categories Section
                        if (!isPastMonth) ...[
                          SizedBox(height: 20.h),
                          if (unbudgetedCategories.isNotEmpty)
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
                                        offset: const Offset(0, 2),
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
                          SizedBox(height: 10.h),
                          ...unbudgetedCategories.map((data) {
                            final index = unbudgetedCategories.indexOf(data);
                            return ListAnimationWidget(
                              offset: const Offset(0, 0.3),
                              index: index,
                              child: Padding(
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
                                      Expanded(
                                        child: Text(
                                          data.categoryName,
                                          style: theme.textTheme.titleMedium,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      ElevatedButton(
                                        onPressed: () => addBudgetDialogue(data),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12.r),
                                            side: BorderSide(color: theme.colorScheme.primary),
                                          ),
                                          backgroundColor: theme.cardColor,
                                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                                          elevation: 0,
                                        ),
                                        child: FittedBox(
                                          child: Text(
                                            'Set budget',
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ),
                              ),
                            );
                          }),
                        ],

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
          BudgetDashboard(
            dateNotifier: ref.read(selectedDateProviderForBudgets.notifier),
            dateState: ref.watch(selectedDateProviderForBudgets),
            totalBudget: totalBudget,
            totalSpent: totalSpent,
          ),
          SizedBox(height: 10.h),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: budgetState.isLoading?
              Center(child: CircularProgressIndicator(color: theme.colorScheme.primary,),)
              :SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isPastMonth && budgetedCategories.isEmpty)
                              SizedBox(
                                width: double.infinity.w,
                                height: 300.h,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 20.h,),
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
                                      isSelectedForBulkDelete? SizedBox(height: 5.h,):SizedBox.shrink(),
                                      Visibility(
                                          visible: isSelectedForBulkDelete,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 10),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                    onPressed: (){
                                                      final allIds = allFilteredBudgets.map((i)=>i.id!).toSet();

                                                      final areAllSelected = allFilteredBudgets.length==selectedIdsState.length && allFilteredBudgets.every((i)=>selectedIdsState.contains(i.id!));

                                                      if(areAllSelected){
                                                        selectedIdsNotifier.state = {};
                                                        allSelectedNotifier.state = false;
                                                      }
                                                      else{
                                                        selectedIdsNotifier.state = allIds;
                                                        allSelectedNotifier.state = true;
                                                      }
                                                    },
                                                    icon: (allFilteredBudgets.length==selectedIdsState.length && allFilteredBudgets.every((i)=>selectedIdsState.contains(i.id!)))?
                                                    Icon(Icons.check_box,color: theme.colorScheme.primary,)
                                                    :Icon(Icons.check_box_outline_blank,color: theme.colorScheme.primary,)
                                                ),
                                                Text('Select all',style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),)
                                              ],
                                            ),
                                          )
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
                                                        onDetailsTap: ()=>budgetDetails(budget),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              ],
                                              if(!isSelectedForBulkDelete)...[
                                                GestureDetector(
                                                  onTap: ()=>budgetDetails(budget),
                                                  child: ListAnimationWidget(
                                                    offset: Offset(0, 0.3),
                                                    index: budgetsForDates.indexOf(budget),
                                                    child: BudgetWidget(
                                                      bgColor: matchedCategory.color,
                                                      icon: matchedCategory.icon,
                                                      budget: budget,
                                                      onEdit: () => editBudgetDialogue(budget,matchedCategory),
                                                      onDelete: () => deleteAlert(budget),
                                                      onDetailsTap: ()=>budgetDetails(budget),
                                                    ),
                                                  ),
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
                                if (!isPastMonth) ...[
                                  SizedBox(height: 20.h),
                                  if (unbudgetedCategories.isNotEmpty)
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
                                                offset: const Offset(0, 2),
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
                                  SizedBox(height: 10.h),
                                  ...unbudgetedCategories.map((data) {
                                    final index = unbudgetedCategories.indexOf(data);
                                    return ListAnimationWidget(
                                      offset: const Offset(0, 0.3),
                                      index: index,
                                      child: Padding(
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
                                              Expanded(
                                                child: Text(
                                                  data.categoryName,
                                                  style: theme.textTheme.titleMedium,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              ElevatedButton(
                                                onPressed: () => addBudgetDialogue(data),
                                                style: ElevatedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12.r),
                                                    side: BorderSide(color: theme.colorScheme.primary),
                                                  ),
                                                  backgroundColor: theme.cardColor,
                                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                                                  elevation: 0,
                                                ),
                                                child: FittedBox(
                                                  child: Text(
                                                    'Set budget',
                                                    style: theme.textTheme.titleSmall?.copyWith(
                                                      color: theme.colorScheme.primary,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
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
        scale: _bulkDeleteFABAnimation,
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


class AnimatedBudgetDashboard extends ConsumerWidget {
  final bool isCollapsed;

  const AnimatedBudgetDashboard({super.key, required this.isCollapsed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = Theme.of(context);
    final totalBudget = ref.watch(budgetProvider).filteredBudgets.fold(0, (a, b) => a + b.budget.toInt());
    final totalSpent = ref.watch(budgetProvider).filteredBudgets.fold(0, (a, b) => a + b.spent.toInt());

    return Container(
      color: theme.colorScheme.primary,
      child: ClipRect(
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: isCollapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: BudgetDashboard(
              totalBudget: totalBudget,
              totalSpent: totalSpent,
              dateNotifier: ref.read(selectedDateProviderForBudgets.notifier),
              dateState: ref.watch(selectedDateProviderForBudgets),
            ),
          ),
          secondChild: _buildMinimizedHeader(
            context: context,
            currency: ref.watch(newCurrencyProvider).currency,
            ref: ref,
          ),
        ),
      ),
    );
  }

  Widget _buildMinimizedHeader({
    required BuildContext context,
    required String currency,
    required WidgetRef ref,
  }) {
    var theme = Theme.of(context);

    final totalBudget = ref.watch(budgetProvider).filteredBudgets.fold(0, (a, b) => a + b.budget.toInt());
    final formattedBudget = NumberFormat.compactCurrency(
      decimalDigits: 0,
      symbol: currency,
    ).format(totalBudget);

    final totalSpent = ref.watch(budgetProvider).filteredBudgets.fold(0, (a, b) => a + b.spent.toInt());
    final formattedSpent = NumberFormat.compactCurrency(
      decimalDigits: 0,
      symbol: currency,
    ).format(totalSpent);

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.paid_outlined,
                    color: Colors.green.shade300,
                    size: 18.sp,
                  ),
                  SizedBox(height: 4.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formattedBudget,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.sp,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 30.h,
              color: Colors.white.withOpacity(0.3),
              margin: EdgeInsets.symmetric(horizontal: 8.w),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: Colors.red.shade300,
                    size: 18.sp,
                  ),
                  SizedBox(height: 4.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formattedSpent,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.sp,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

