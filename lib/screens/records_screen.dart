import 'dart:math';
import 'dart:ui';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:expense_tracker_app/models/card_model.dart';
import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:expense_tracker_app/riverpod/category_riverpod/category_riverpod.dart';
import 'package:expense_tracker_app/riverpod/currency_riverpod/currency_pref.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/riverpod/prefs_riverpod/prefs_riverpod.dart';
import 'package:expense_tracker_app/screens/analysis_screen/stats_screen.dart';
import 'package:expense_tracker_app/widgets/app_colors.dart';
import 'package:expense_tracker_app/widgets/custom_app_button.dart';
import 'package:expense_tracker_app/widgets/expense_tile.dart';
import 'package:expense_tracker_app/widgets/listAnimation_widget.dart';
import 'package:expense_tracker_app/widgets/search_callback_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:overlay_support/overlay_support.dart';

import '../models/category_model.dart';
import '../riverpod/budget_riverpod/budget_riverpod.dart';
import '../riverpod/save_record_filter/save_record_filter.dart';
import '../widgets/balance_dashboard.dart';

enum MoneyType {expense, income}

final categoryPickerProvider = StateProvider<String>((ref)=>'Personal');
final categorySelectionProvider = StateProvider<bool>((ref)=>false);
final checkTypingProvider = StateProvider<bool>((ref)=>false);
final editingProvider = StateProvider<bool>((ref)=>false);
final selectedDateProvider = StateProvider<DateTime>((ref)=>DateTime.now());
final selectedTimeProvider = StateProvider<TimeOfDay>((ref)=>TimeOfDay.now());
final moneyTypeProvider = StateProvider<MoneyType>((ref)=>MoneyType.expense);
final selectedAccountProvider = StateProvider<int?>((ref)=>null);
final enteredAmountProvider = StateProvider<double>((ref)=>0);
final recordAddedTriggerProvider = StateProvider<int>((ref) => 0);
final recordsDashboardCollapseProvider = StateProvider<bool>((ref)=>false);
final oldAmountTrackerProvider = StateProvider<double>((ref)=>0);


class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  RecordsScreenState createState() => RecordsScreenState();
}

class RecordsScreenState extends ConsumerState<RecordsScreen> with TickerProviderStateMixin{

  late AnimationController _animationController;

  late Animation<Offset> _disappearFABAnimation;

  late AnimationController _bulkDeleteAnimationController;

  late Animation<double> _bulkDeleteFabAnimation;

  late AnimationController _tipController;

  late Animation<double> _tipAnimationBounce;

  late Animation<Offset> _slideAnimTip;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editAmountController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  double _lastScrollPosition = 0.0;
  bool _isFabVisible = true;

  bool isSelectedForBulkDelete = false;
  Set<int> selectedIds = {};

  final double _expandedHeight = 244.0.h;
  final double _collapsedHeight = 60.0.h;

  bool _hasPlayedTipAnimation = false;


  @override
  void initState() {

    _scrollController.addListener(_onScroll);
    super.initState();

    _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300)
    );

    _tipController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800)
    );

    _slideAnimTip = Tween<Offset>(begin:Offset(0,-0.9),end: Offset.zero ).animate(CurvedAnimation(parent: _tipController, curve: Curves.fastOutSlowIn));
    _tipAnimationBounce = Tween<double>(begin: 0.5, end: 1).animate(CurvedAnimation(parent: _tipController, curve: Curves.easeInOut));

    _disappearFABAnimation = Tween<Offset>(begin: Offset.zero, end: Offset(0, 2.5))
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.fastOutSlowIn));

    _bulkDeleteAnimationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500)
    );

    _bulkDeleteFabAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _bulkDeleteAnimationController, curve: Curves.fastOutSlowIn));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(expenseProvider.notifier).getExpenses();
      await ref.read(cardsProvider.notifier).getCards();
      await ref.read(categoryProvider.notifier).getAllCategories();
      await ref.read(tipPrefProvider.notifier).loadTip();


      final savedFilter = ref.read(saveRecordFilterProvider);
      final selectedDate = ref.read(selectedDateProvider);
      final selectedTime = ref.read(selectedTimeProvider);
      final expenseNotifier = ref.read(expenseProvider.notifier);

      switch (savedFilter) {
        case FilterRecordOptions.daily:
          expenseNotifier.setActiveFilter('daily');
          expenseNotifier.filterRecordsByDay(selectedDate);
          break;
        case FilterRecordOptions.weekly:
          expenseNotifier.setActiveFilter('weekly');
          expenseNotifier.filterRecordsByWeek(selectedDate);
          break;
        case FilterRecordOptions.yearly:
          expenseNotifier.setActiveFilter('yearly');
          expenseNotifier.filterRecordsByYear(selectedDate);
          break;
        default:
          expenseNotifier.setActiveFilter('monthly');
          expenseNotifier.filterRecordsByMonth(selectedDate, selectedTime);
          break;
      }

    });

    _titleController.addListener(() => checkTyping(ref));
    _amountController.addListener(() => checkTyping(ref));
  }


  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _titleController.removeListener(()=>checkTyping(ref,));
    _amountController.removeListener(()=>checkTyping(ref));
    _bulkDeleteAnimationController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  void _onScroll(){
    final collapseState = ref.read(recordsDashboardCollapseProvider);
    final collapseNotifier = ref.read(recordsDashboardCollapseProvider.notifier);

    final isCollapsed = _scrollController.offset > 50;

    if(isCollapsed!=collapseState){
      collapseNotifier.state = isCollapsed;
    }
  }

  bool _handleScrollNotification(ScrollNotification scrollInfo){
    if(scrollInfo is ScrollUpdateNotification){

      final currentScroll = scrollInfo.metrics.pixels;
      final scrollDelta = currentScroll-_lastScrollPosition;

      if(scrollDelta>2 && _isFabVisible){
        _animationController.forward();
        _isFabVisible = false;
      }
      else if(scrollDelta<-2 && !_isFabVisible){
        _animationController.reverse();
        _isFabVisible = true;
      }
      _lastScrollPosition = currentScroll;
    }
    return false;
  }


  void checkTyping(WidgetRef ref,{ExpenseModel? expense,CardModel? card}){
    final isEditing = ref.read(editingProvider);
    final moneyTypeState = ref.read(moneyTypeProvider);
    final account = ref.read(selectedAccountProvider);

    if(!isEditing) {
      bool hasContents = _titleController.text.isNotEmpty && _amountController.text.isNotEmpty && ref.read(categorySelectionProvider) && ref.read(selectedAccountProvider.notifier).state!=null;
      if (hasContents != ref.read(checkTypingProvider.notifier).state) {
        ref.read(checkTypingProvider.notifier).state = hasContents;
      }
    }
    else{
      bool hasChanged = _editTitleController.text!=expense?.title || _editAmountController.text!=expense?.amount.toString() || ref.read(categoryPickerProvider)!=expense?.category
          || ref.read(selectedDateProvider)!=expense?.date || ref.read(selectedTimeProvider)!=expense?.time || moneyTypeState!=expense?.moneyType || account!=card?.id;

      if(hasChanged!=ref.read(checkTypingProvider.notifier).state){
        ref.read(checkTypingProvider.notifier).state = hasChanged;
        checkTyping(ref);
      }
    }
  }

  Future<void> pickDate()async{
    final currentDate = ref.read(selectedDateProvider);
    final pickedDate = await showDatePicker(
        context: context,
        firstDate: DateTime(2010),
        lastDate: DateTime(2090),
        initialDate: DateTime.now()
    );
    if(pickedDate!=null && pickedDate!=currentDate){
      ref.read(selectedDateProvider.notifier).state = pickedDate;
      checkTyping(ref);
    }
  }

  Future<void> pickTime()async{
    final currentTime = ref.read(selectedTimeProvider);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if(pickedTime!=null && pickedTime!=currentTime){
      ref.read(selectedTimeProvider.notifier).state = pickedTime;
      checkTyping(ref);
    }
  }

  void addExpenseDialogue(){
    final currentNavigationDate = ref.read(selectedDateProvider);

    ref.read(selectedDateProvider.notifier).state = DateTime.now();
    ref.read(selectedTimeProvider.notifier).state = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 12,
            ),
            child: Consumer(
              builder: (context, ref, _) {
                final category = ref.watch(categoryPickerProvider);
                final isTyping = ref.watch(checkTypingProvider);
                final moneyTypeState = ref.watch(moneyTypeProvider);
                final moneyTypeNotifier = ref.read(moneyTypeProvider.notifier);
                final selectedAccountState = ref.watch(selectedAccountProvider);
                final selectedAccountNotifier = ref.read(selectedAccountProvider.notifier);
                final incomeCategories = ref.watch(categoryProvider).allIncomeCategories;
                final expenseCategories = ref.watch(categoryProvider).allExpenseCategories;
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        "Add new record",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      TextFormField(
                        autofocus: true,
                        controller: _titleController,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          hintText: 'Name of your expense or income',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.hintTextColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      TextFormField(
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        controller: _amountController,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: '0.00',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.hintTextColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: pickDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: theme.dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 20,
                                      color: theme.iconTheme.color?.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        DateFormat('MMM dd, yyyy')
                                            .format(ref.watch(selectedDateProvider)),
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: pickTime,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: theme.dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 20,
                                      color: theme.iconTheme.color?.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        ref.watch(selectedTimeProvider).format(context),
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        children: MoneyType.values.map((type) {
                          final isSelected = moneyTypeState == type;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: type == MoneyType.expense ? 8 : 0,
                                left: type == MoneyType.income ? 8 : 0,
                              ),
                              child: InkWell(
                                onTap: () {
                                  moneyTypeNotifier.state = type;
                                  ref.read(categoryPickerProvider.notifier).state =
                                  type == MoneyType.expense
                                      ? expenseCategories.first.categoryName
                                      : incomeCategories.first.categoryName;
                                  ref.read(categorySelectionProvider.notifier).state = false;
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? type==MoneyType.expense? Colors.redAccent : Colors.green : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? type==MoneyType.expense? Colors.redAccent : Colors.green
                                          : theme.dividerColor,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      isSelected?type == MoneyType.expense? Icon(Icons.arrow_downward_outlined,color: Colors.white,):Icon(Icons.arrow_upward_outlined,color: Colors.white,):SizedBox.shrink(),
                                      SizedBox(width: 5.w,),
                                      Text(
                                        type == MoneyType.expense ? 'Expense' : 'Income',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : theme.textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 20.h),
                      DropdownButtonFormField2(
                        isExpanded: true,
                        value: (moneyTypeState == MoneyType.expense ? expenseCategories : incomeCategories)
                            .any((cat) => cat.categoryName == category) ? category : null,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        hint: Text(
                          'Select category',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.hintTextColor,
                          ),
                        ),
                        items: moneyTypeNotifier.state==MoneyType.expense?
                        expenseCategories.map((item) {
                          return DropdownMenuItem<String>(
                            value: item.categoryName,
                            child: Row(
                              children: [
                                Icon(item.icon,size: 20,),
                                SizedBox(width: 10.w,),
                                Text(
                                  item.categoryName,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          );
                        }).toList() : incomeCategories.map((item) {
                          return DropdownMenuItem<String>(
                            value: item.categoryName,
                            child: Row(
                              children: [
                                Icon(item.icon,size: 20,),
                                SizedBox(width: 10.w,),
                                Text(
                                  item.categoryName,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(categoryPickerProvider.notifier).state = value;
                            ref.read(categorySelectionProvider.notifier).state = true;
                            checkTyping(ref);
                          }
                        },
                        iconStyleData: IconStyleData(
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: theme.iconTheme.color?.withOpacity(0.7),
                          ),
                          iconSize: 24,
                        ),
                        buttonStyleData: ButtonStyleData(
                          height: 56.h,
                          padding: EdgeInsets.zero,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: theme.cardColor,
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 48,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      DropdownButtonFormField2(
                        isExpanded: true,
                        value: selectedAccountState,
                        decoration: InputDecoration(
                          labelText: 'Account',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        hint: Text(
                          'Choose account',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.hintTextColor,
                          ),
                        ),
                        items: ref.watch(cardsProvider).cards.map((card) {
                          return DropdownMenuItem<int>(
                            value: card.id,
                            child: Row(
                              children: [
                                Icon(
                                  card.icon,
                                  size: 20,
                                  color: theme.iconTheme.color,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  card.cardName,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Spacer(),
                                Text('${ref.read(newCurrencyProvider).currency}${card.amount.toStringAsFixed(2)} ',style: theme.textTheme.bodyMedium,)
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            selectedAccountNotifier.state = value;
                            checkTyping(ref);
                          }
                        },
                        iconStyleData: IconStyleData(
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: theme.iconTheme.color?.withOpacity(0.7),
                          ),
                          iconSize: 24,
                        ),
                        buttonStyleData: ButtonStyleData(
                          height: 56.h,
                          padding: EdgeInsets.zero,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: theme.cardColor,
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 48,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: !isTyping
                            ? ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Add Record',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withOpacity(0.38),
                            ),
                          ),
                        )
                            : ElevatedButton(
                          onPressed: () {
                            ref.read(enteredAmountProvider.notifier).state = double.parse(_amountController.text);
                            final selectedCard = ref.watch(cardsProvider).cards.firstWhere((card)=>card.id==selectedAccountNotifier.state);
                            if((ref.read(enteredAmountProvider.notifier).state>selectedCard.amount || selectedCard.amount<=0) && ref.read(moneyTypeProvider.notifier).state==MoneyType.expense){
                              toast('Not sufficient balance, please choose a different account or update the balance');
                              return;
                            }
                            final expenseDate = ref.read(selectedDateProvider.notifier).state;
                            ref.read(expenseProvider.notifier).insertExpense(
                              ExpenseModel(
                                  title: _titleController.text,
                                  amount: double.parse(_amountController.text),
                                  category: category,
                                  date: expenseDate,
                                  time: ref.read(selectedTimeProvider.notifier).state,
                                  moneyType: ref.read(moneyTypeProvider.notifier).state,
                                  accountId: ref.read(selectedAccountProvider)!
                              ),
                            );
                            ref.read(cardsProvider.notifier).calculateTotalAmountInAccount();
                            ref.read(budgetProvider.notifier).calculateAmount(expenseDate);
                            ref.read(recordAddedTriggerProvider.notifier).state++;
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            backgroundColor: theme.colorScheme.primary,
                          ),
                          child: Text(
                            'Add Record',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    ).then((_) {
      _titleController.clear();
      _amountController.clear();
      ref.read(categoryPickerProvider.notifier).state = 'Personal';
      ref.read(selectedAccountProvider.notifier).state = null;
      ref.read(selectedDateProvider.notifier).state = currentNavigationDate;
      ref.read(selectedTimeProvider.notifier).state = TimeOfDay.now();
    });
  }

  void editExpenseDialogue(ExpenseModel expense) {

    final currentDate = ref.read(selectedDateProvider);

    int? id = expense.id;
    _editTitleController.text = expense.title;
    _editAmountController.text = expense.amount.toString();
    ref.read(categoryPickerProvider.notifier).state = expense.category;
    ref.read(selectedDateProvider.notifier).state = expense.date;
    ref.read(selectedTimeProvider.notifier).state = expense.time;
    ref.read(moneyTypeProvider.notifier).state = expense.moneyType;
    ref.read(selectedAccountProvider.notifier).state = expense.accountId;

    ref.read(editingProvider.notifier).state = true;

    ref.read(oldAmountTrackerProvider.notifier).state = expense.amount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 12,
            ),
            child: Consumer(
              builder: (context, ref, _) {
                final category = ref.watch(categoryPickerProvider);
                final isTyping = ref.watch(checkTypingProvider);
                final moneyTypeState = ref.watch(moneyTypeProvider);
                final moneyTypeNotifier = ref.read(moneyTypeProvider.notifier);
                final selectedAccountState = ref.watch(selectedAccountProvider);
                final selectedAccountNotifier = ref.read(selectedAccountProvider.notifier);
                final incomeCategories = ref.watch(categoryProvider).allIncomeCategories;
                final expenseCategories = ref.watch(categoryProvider).allExpenseCategories;
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        "Edit record",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      TextFormField(
                        autofocus: true,
                        controller: _editTitleController,
                        onChanged: (_) => checkTyping(ref, expense: expense),
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          hintText: 'Name of your expense or income',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.hintTextColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      TextFormField(
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        controller: _editAmountController,
                        onChanged: (_) => checkTyping(ref, expense: expense),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: '0.00',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.hintTextColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: pickDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: theme.dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 20,
                                      color: theme.iconTheme.color?.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        DateFormat('MMM dd, yyyy')
                                            .format(ref.watch(selectedDateProvider)),
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: pickTime,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: theme.dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 20,
                                      color: theme.iconTheme.color?.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        ref.watch(selectedTimeProvider).format(context),
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        children: MoneyType.values.map((type) {
                          final isSelected = moneyTypeState == type;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: type == MoneyType.expense ? 8 : 0,
                                left: type == MoneyType.income ? 8 : 0,
                              ),
                              child: InkWell(
                                onTap: () {
                                  moneyTypeNotifier.state = type;
                                  ref.read(categoryPickerProvider.notifier).state =
                                  type == MoneyType.expense
                                      ? expenseCategories.first.categoryName
                                      : incomeCategories.first.categoryName;
                                  checkTyping(ref, expense: expense);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? type==MoneyType.expense? Colors.redAccent : Colors.green : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? type==MoneyType.expense? Colors.redAccent : Colors.green
                                          : theme.dividerColor,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      isSelected?type == MoneyType.expense? Icon(Icons.arrow_downward_outlined,color: Colors.white,):Icon(Icons.arrow_upward_outlined,color: Colors.white,):SizedBox.shrink(),
                                      SizedBox(width: 5.w,),
                                      Text(
                                        type == MoneyType.expense ? 'Expense' : 'Income',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : theme.textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 20.h),
                      DropdownButtonFormField2(
                        isExpanded: true,
                        value: (moneyTypeState == MoneyType.expense ? expenseCategories : incomeCategories)
                            .any((cat) => cat.categoryName == category) ? category : null,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        hint: Text(
                          'Select category',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.hintTextColor,
                          ),
                        ),
                        items: moneyTypeNotifier.state==MoneyType.expense?
                        expenseCategories.map((item) {
                          return DropdownMenuItem<String>(
                            value: item.categoryName,
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 20,
                                  color: theme.iconTheme.color,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  item.categoryName,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          );
                        }).toList() : incomeCategories.map((item) {
                          return DropdownMenuItem<String>(
                            value: item.categoryName,
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 20,
                                  color: theme.iconTheme.color,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  item.categoryName,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(categoryPickerProvider.notifier).state = value;
                            ref.read(categorySelectionProvider.notifier).state = true;
                            checkTyping(ref, expense: expense);
                          }
                        },
                        iconStyleData: IconStyleData(
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: theme.iconTheme.color?.withOpacity(0.7),
                          ),
                          iconSize: 24,
                        ),
                        buttonStyleData: ButtonStyleData(
                          height: 56.h,
                          padding: EdgeInsets.zero,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: theme.cardColor,
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 48,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      DropdownButtonFormField2(
                        isExpanded: true,
                        value: selectedAccountState,
                        decoration: InputDecoration(
                          labelText: 'Account',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        hint: Text(
                          'Choose account',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.hintTextColor,
                          ),
                        ),
                        items: ref.watch(cardsProvider).cards.map((card) {
                          return DropdownMenuItem<int>(
                            value: card.id,
                            child: Row(
                              children: [
                                Icon(
                                  card.icon,
                                  size: 20,
                                  color: theme.iconTheme.color,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  card.cardName,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Spacer(),
                                Text('${ref.read(newCurrencyProvider).currency}${card.amount.toStringAsFixed(2)}',style: theme.textTheme.bodyMedium,)
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            selectedAccountNotifier.state = value;
                            checkTyping(ref, expense: expense);
                          }
                        },
                        iconStyleData: IconStyleData(
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: theme.iconTheme.color?.withOpacity(0.7),
                          ),
                          iconSize: 24,
                        ),
                        buttonStyleData: ButtonStyleData(
                          height: 56.h,
                          padding: EdgeInsets.zero,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: theme.cardColor,
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 48,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: !isTyping
                            ? ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Edit Record',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withOpacity(0.38),
                            ),
                          ),
                        )
                            : ElevatedButton(
                onPressed: () {
                if(ref.read(editingProvider.notifier).state==true) {
                ref.read(enteredAmountProvider.notifier).state = double.parse(_editAmountController.text);
                }

                final selectedCard = ref.watch(cardsProvider).cards.firstWhere((card)=>card.id==selectedAccountNotifier.state);

                if((ref.read(enteredAmountProvider.notifier).state>selectedCard.amount || selectedCard.amount<=0) && ref.read(moneyTypeProvider.notifier).state==MoneyType.expense){
                toast('Not sufficient balance, please choose a different account or update the balance');
                return;
                }

                final updatedExpense = ExpenseModel(
                id: id,
                title: _editTitleController.text,
                amount: double.parse(_editAmountController.text),
                category: category,
                date: ref.read(selectedDateProvider.notifier).state,
                time: ref.read(selectedTimeProvider.notifier).state,
                moneyType: ref.read(moneyTypeProvider.notifier).state,
                accountId: ref.read(selectedAccountProvider)!
                );

                ref.read(expenseProvider.notifier).updateExpense(
                updatedExpense,
                expense
                );


                ref.read(cardsProvider.notifier).calculateTotalAmountInAccount();
                ref.read(editingProvider.notifier).state = false;
                ref.read(checkTypingProvider.notifier).state = false;
                ref.read(recordAddedTriggerProvider.notifier).state++;

                Navigator.pop(context);
                },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            backgroundColor: theme.colorScheme.primary,
                          ),
                          child: Text(
                            'Edit Record',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    ).then((_) {
      ref.read(editingProvider.notifier).state = false;
      ref.read(checkTypingProvider.notifier).state = false;
      ref.read(selectedDateProvider.notifier).state= currentDate;
    });
  }

  void deleteAlert(ExpenseModel expense){
    showDialog(
        context: context,
        builder: (BuildContext context){
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
                        'Delete entry',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Are you sure you want to delete this entry?\nThis action cannot be undone.',
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
                            ref.read(expenseProvider.notifier).deleteExpense(expense.id!);
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
    showDialog(
        context: context,
        builder: (BuildContext context){
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
                          'Delete ${selectedIds.length} record?',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: 17,fontWeight: FontWeight.bold),
                        ):Text(
                          'Delete ${selectedIds.length} records?',
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
                            ref.read(expenseProvider.notifier)
                                .bulkDeleteSelectedRecords(selectedIds.toList());
                            setState(() {
                              isSelectedForBulkDelete = false;
                              selectedIds.clear();
                            });
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


  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final expenseNotifier = ref.read(expenseProvider.notifier);
    var theme = Theme.of(context);

    final selectedCurrency = ref.watch(newCurrencyProvider).currency;

    final dateState = ref.watch(selectedDateProvider);
    final dateNotifier = ref.read(selectedDateProvider.notifier);

    final timeState = ref.watch(selectedTimeProvider);
    final timeNotifier = ref.read(selectedTimeProvider.notifier);

    final expenseList = expenseState.filteredRecord;

    final isCollapseModeActivated = ref.watch(collapseDashboardPrefProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: isCollapseModeActivated? NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: _expandedHeight,
                collapsedHeight: _collapsedHeight,
                pinned: true,
                elevation: 0,
                backgroundColor: theme.colorScheme.primary,
                automaticallyImplyLeading: false,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final double collapseThreshold =
                        _collapsedHeight + ((_expandedHeight - _collapsedHeight) * 0.3);

                    final bool isCollapsed = constraints.maxHeight <= collapseThreshold;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final prev = ref.read(recordsDashboardCollapseProvider);
                      if (prev != isCollapsed) {
                        ref.read(recordsDashboardCollapseProvider.notifier).state = isCollapsed;
                      }
                    });

                    return AnimatedBalanceDashboard(
                      isCollapsed: isCollapsed,
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: 12.h),
              ),

              if(expenseState.isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    width: double.infinity,
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
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                )
              else if(expenseList.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                      ),
                    ),
                    child: _buildEmptyState(theme),
                  ),
                )

              else ...[
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.r),
                          topRight: Radius.circular(20.r),
                        ),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 10.h),
                          _buildRecordsList(
                            context,
                            ref,
                            theme,
                            (() {
                              final expenseList = ref.watch(expenseProvider).filteredRecord;
                              final groupedExpenses = _groupByDate(expenseList);
                              return groupedExpenses.keys.toList()..sort((a, b) => b.compareTo(a));
                            })(),
                            _groupByDate(ref.watch(expenseProvider).filteredRecord),
                            selectedCurrency,
                            expenseNotifier,
                            expenseState,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Container(color: theme.cardColor),
                  ),
                ],
            ],
          )
      )
          : Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BalanceDashboard(
                theme: theme,
                dateNotifier: dateNotifier,
                timeNotifier: timeNotifier,
                dateState: dateState,
                timeState: timeState,
                selectedCurrency: selectedCurrency
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 10.h,),
                      if(expenseState.isLoading)...[
                        Center(child: CircularProgressIndicator(color: theme.colorScheme.primary,backgroundColor: Colors.transparent,),)
                      ],
                      if(!expenseState.isLoading)...[
                        SizedBox(height: 10.h,),
                        if(expenseList.isEmpty)
                          _buildEmptyState(theme),
                        Expanded(
                            child: NotificationListener(
                                onNotification: _handleScrollNotification,
                                child: Builder(
                                    builder: (context) {

                                      final expenseList = ref.watch(expenseProvider).filteredRecord;
                                      final groupedExpenses = _groupByDate(expenseList);
                                      final sortedDates = groupedExpenses.keys.toList()..sort((a,b)=>b.compareTo(a));

                                      return _buildRecordsList(
                                          context,
                                          ref,
                                          theme,
                                          sortedDates,
                                          groupedExpenses,
                                          selectedCurrency,
                                          expenseNotifier,
                                          expenseState
                                      );
                                    }
                                )
                            )
                        )
                      ]
                    ],
                  ),
                )
            )
          ],
        ),
      ),
      floatingActionButton: isSelectedForBulkDelete
          ? ScaleTransition(
        scale: _bulkDeleteFabAnimation,
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
          : SlideTransition(
        position: _disappearFABAnimation,
        child: Container(
          height: 64.h,
          width: 64.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.9),
                theme.colorScheme.primary.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: addExpenseDialogue,
              borderRadius: BorderRadius.circular(18),
              child: Center(
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Map<DateTime,List<ExpenseModel>> _groupByDate(List<ExpenseModel> expense){
    Map<DateTime,List<ExpenseModel>> map = {};

    for(var exp in expense){
      final date = DateTime(exp.date.year,exp.date.month,exp.date.day);

      if(!map.containsKey(date)){
        map[date] = [];
      }
      map[date]!.add(exp);
    }
    return map;
  }


  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      children: [
        SizedBox(height: 80.h,),
        Icon(Icons.error_outline_outlined, color: theme.colorScheme.primary, size: 100),
        SizedBox(height: 24.h),
        Text('No records in this period', style: theme.textTheme.titleLarge),
        SizedBox(height: 8.h),
        Text('Tap the + button to add a new record', style: theme.textTheme.bodyMedium),
        SizedBox(height: 100.h),
      ],
    );
  }

  Widget _buildRecordsList(
      BuildContext context,
      WidgetRef ref,
      ThemeData theme,
      List<DateTime> sortedDates,
      Map<DateTime, List<ExpenseModel>> groupedExpenses,
      String selectedCurrency,
      dynamic expenseNotifier,
      dynamic expenseState,
      ) {
    final isCollapseModeActivated = ref.watch(collapseDashboardPrefProvider);

    return ListView.builder(
      shrinkWrap: true,
      physics: isCollapseModeActivated ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final expensesForDate = groupedExpenses[date]!;

        final tipNotifier = ref.watch(tipPrefProvider.notifier);
        final showBanner = tipNotifier.isLoaded && ref.watch(tipPrefProvider);

        if (showBanner && !_hasPlayedTipAnimation) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_hasPlayedTipAnimation) {
              _tipController.forward().then((_) {
                _hasPlayedTipAnimation = true;
              });
            }
          });
        }

        return Column(
          children: [
            if(expensesForDate.isNotEmpty && showBanner)...[
              FadeTransition(
                opacity: _tipAnimationBounce,
                child: SlideTransition(
                  position: _slideAnimTip,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Container(
                      width: double.infinity.w,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15.r)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 5.h,),
                          Padding(
                            padding: const EdgeInsets.only(right: 0),
                            child: Row(
                              children: [
                                Icon(Icons.lightbulb_outline,color: theme.colorScheme.primary,size: 30,),
                                Spacer(),
                                IconButton(
                                    onPressed: (){
                                      ref.read(tipPrefProvider.notifier).save(false);
                                    },
                                    icon: Icon(Icons.close,color: theme.colorScheme.primary,size: 30,)
                                )
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: Text('Quick Tip: ',style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),),
                          ),
                          SizedBox(height: 10.h,),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              children: [
                                Text('Long press on a record to perform bulk delete.',style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),)
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            showBanner? SizedBox(height: 10.h,) : SizedBox.shrink(),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 15.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListAnimationWidget(
                    index: index,
                    offset: Offset(0, 0.3),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.4), blurRadius: 4, offset: Offset(0, 2))],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          DateFormat('MMMM dd, yyyy').format(date),
                          style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5.h),
                  ...expensesForDate.map((expense) {
                    final selectedCard = ref.watch(cardsProvider).cards.firstWhere(
                          (card) => card.id == expense.accountId,
                      orElse: () => CardModel(id: -1, cardName: 'Unknown', icon: Icons.help_outline, amount: 0),
                    );

                    final selectedCategory = ref.watch(categoryProvider).allCategories.firstWhere((i)=>i.categoryName==expense.category,
                      orElse: () => CategoryModel(
                        categoryName: expense.category,
                        icon: Icons.category,
                        color: Colors.grey,
                      ),);

                    return GestureDetector(
                      onLongPress: (){
                        setState(() {
                          isSelectedForBulkDelete = true;
                          selectedIds.add(expense.id!);
                          if(selectedIds.length==1) {
                            _bulkDeleteAnimationController.forward(from: 0);
                          }
                        });
                      },
                      onTap: (){
                        setState(() {
                          if(selectedIds.contains(expense.id)){
                            selectedIds.remove(expense.id);
                            if(selectedIds.isEmpty){
                              isSelectedForBulkDelete = false;
                              _bulkDeleteAnimationController.reverse();
                            }
                          }
                          else{
                            selectedIds.add(expense.id!);
                          }
                        });
                      },
                      child: Column(
                        children: [
                          if(isSelectedForBulkDelete)...[
                            Row(
                              children: [
                                Center(
                                  child: Icon(
                                    selectedIds.contains(expense.id!)?
                                    Icons.check_box : Icons.check_box_outline_blank,
                                    color: selectedIds.contains(expense.id!)? theme.colorScheme.primary : Colors.grey,
                                  ),
                                ),
                                SizedBox(width: 15.w,),
                                Expanded(
                                  child: ExpenseTile(
                                    bgColor: selectedCategory.color,
                                    icon: selectedCategory.icon,
                                    expenseModel: expense,
                                    currency: selectedCurrency,
                                    cardModel: selectedCard,
                                    onEdit: () => editExpenseDialogue(expense),
                                    onDelete: () => deleteAlert(expense),
                                  ),
                                )
                              ],
                            )
                          ],
                          if(!isSelectedForBulkDelete)...[

                            ListAnimationWidget(
                              key: ValueKey(expense.id),
                              offset: Offset(0, 0.3),
                              index: expensesForDate.indexOf(expense),
                              child: ExpenseTile(
                                bgColor: selectedCategory.color,
                                icon: selectedCategory.icon,
                                expenseModel: expense,
                                currency: selectedCurrency,
                                cardModel: selectedCard,
                                onEdit: () => editExpenseDialogue(expense),
                                onDelete: () => deleteAlert(expense),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }


}