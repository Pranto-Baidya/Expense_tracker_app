import 'dart:math';
import 'dart:ui';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:expense_tracker_app/models/card_model.dart';
import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:expense_tracker_app/riverpod/category_riverpod/category_riverpod.dart';
import 'package:expense_tracker_app/riverpod/currency_riverpod/currency_pref.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/widgets/app_colors.dart';
import 'package:expense_tracker_app/widgets/custom_app_button.dart';
import 'package:expense_tracker_app/widgets/expense_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:overlay_support/overlay_support.dart';

import '../models/category_model.dart';
import '../riverpod/budget_riverpod/budget_riverpod.dart';
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

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  RecordsScreenState createState() => RecordsScreenState();
}

class RecordsScreenState extends ConsumerState<RecordsScreen> with SingleTickerProviderStateMixin{

  late AnimationController _animationController;

  late Animation<Offset> _disappearFABAnimation;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editAmountController = TextEditingController();

  double _lastScrollPosition = 0.0;
  bool _isFabVisible = true;


  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300)
    );

    _disappearFABAnimation = Tween<Offset>(begin: Offset.zero,end: Offset(0,1.5)).animate(CurvedAnimation(parent: _animationController, curve: Curves.fastOutSlowIn));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(expenseProvider.notifier).getExpenses();
      await ref.read(cardsProvider.notifier).getCards();
      await ref.read(categoryProvider.notifier).getAllCategories();

      final selectedDate = ref.read(selectedDateProvider);
      final selectedTime = ref.read(selectedTimeProvider);
      ref.read(expenseProvider.notifier).filterRecordsByMonth(selectedDate,selectedTime);
    });

    _titleController.addListener(()=>checkTyping(ref));
    _amountController.addListener(()=>checkTyping(ref));

  }


  @override
  void dispose() {
    _titleController.removeListener(()=>checkTyping(ref,));
    _amountController.removeListener(()=>checkTyping(ref));
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification scrollInfo){
    if(scrollInfo is ScrollUpdateNotification){

      final currentScroll = scrollInfo.metrics.pixels;
      final scrollDelta = currentScroll-_lastScrollPosition;

      if(scrollDelta>10 && _isFabVisible){
        _animationController.forward();
        _isFabVisible = false;
      }
      else if(scrollDelta<-10 && !_isFabVisible){
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
    ref.read(selectedDateProvider.notifier).state = DateTime.now();
    ref.read(selectedTimeProvider.notifier).state = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        var theme = Theme.of(context);

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
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
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Text(
                      "Add a new record",
                      style:
                      theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                    ),
                    SizedBox(height: 15.h),
                    TextFormField(
                      autofocus: true,
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Name of your expense or income',
                        hintStyle: theme.textTheme.labelLarge
                            ?.copyWith(color: AppColors.hintTextColor),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    TextFormField(
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      controller: _amountController,
                      decoration: InputDecoration(
                        hintText: 'Amount spent or received today',
                        hintStyle: theme.textTheme.labelLarge
                            ?.copyWith(color: AppColors.hintTextColor),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Row(
                      children: [
                        Icon(Icons.date_range, color: theme.iconTheme.color),
                        TextButton(
                          onPressed: pickDate,
                          child: Text(
                            DateFormat('MMMM dd, yyyy')
                                .format(ref.watch(selectedDateProvider)),
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.more_time_outlined,
                            color: theme.iconTheme.color),
                        TextButton(
                          onPressed: pickTime,
                          child: Text(
                            ref.watch(selectedTimeProvider).format(context),
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15.h),
                    Text('Select money type:',
                        style: theme.textTheme.titleMedium),
                    Row(
                      children: MoneyType.values.map((type) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<MoneyType>(
                              fillColor: WidgetStatePropertyAll(
                                  theme.colorScheme.primary),
                              value: type,
                              groupValue: moneyTypeState,
                              onChanged: (value) {
                                moneyTypeNotifier.state = value!;
                                ref.read(categoryPickerProvider.notifier).state =
                                value == MoneyType.expense
                                    ? expenseCategories.first.categoryName
                                    : incomeCategories.first.categoryName;
                                ref.read(categorySelectionProvider.notifier).state = false;
                              },
                            ),
                            Text(
                              type == MoneyType.expense
                                  ? 'Expense'
                                  : 'Income',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(width: 10),
                          ],
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 15.h),
                    Text('Select category',style: theme.textTheme.titleMedium,),
                    SizedBox(height: 10.h,),
                    DropdownButtonFormField2(
                      isExpanded: true,
                      value: (moneyTypeState == MoneyType.expense ? expenseCategories : incomeCategories)
                          .any((cat) => cat.categoryName == category) ? category : null,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant,
                        contentPadding: EdgeInsets.zero,
                      ),
                      hint: Text(
                        'Select category',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: AppColors.hintTextColor),
                      ),
                      items: moneyTypeNotifier.state==MoneyType.expense?
                      expenseCategories.map((item) {
                        return DropdownMenuItem<String>(
                          value: item.categoryName,
                          child: Text(
                            item.categoryName,
                            style: theme.textTheme.titleSmall,
                          ),
                        );
                      }).toList() : incomeCategories.map((item) {
                        return DropdownMenuItem<String>(
                          value: item.categoryName,
                          child: Text(
                            item.categoryName,
                            style: theme.textTheme.titleSmall,
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
                      iconStyleData: const IconStyleData(
                        icon: Icon(Icons.arrow_drop_down_rounded),
                        iconSize: 28,
                      ),
                      buttonStyleData: ButtonStyleData(
                        height: 55.h,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          color: theme.dropdownMenuTheme.menuStyle
                              ?.backgroundColor
                              ?.resolve({}) ??
                              theme.colorScheme.surface,
                        ),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 48,
                        padding: EdgeInsets.symmetric(horizontal: 15),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Text('Choose account',style: theme.textTheme.titleMedium,),
                    SizedBox(height: 10.h,),
                    DropdownButtonFormField2(
                      isExpanded: true,
                      value: selectedAccountState,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant,
                      ),
                      hint: Text(
                        'Choose account',
                        style: theme.textTheme.labelLarge?.copyWith(color: AppColors.hintTextColor,),
                      ),
                      items: ref.watch(cardsProvider).cards.map((card) {
                        return DropdownMenuItem<int>(
                          value: card.id,
                          child: Row(
                            children: [
                              Icon(card.icon, size: 20, color: theme.iconTheme.color),
                              const SizedBox(width: 10),
                              Text(
                                card.cardName,
                                style: theme.textTheme.titleSmall,
                              ),
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
                      iconStyleData: const IconStyleData(
                        icon: Icon(Icons.arrow_drop_down_rounded),
                        iconSize: 28,
                      ),
                      buttonStyleData: ButtonStyleData(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        height: 55.h,
                      ),
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.surface,
                        ),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 50,
                        padding: EdgeInsets.symmetric(horizontal: 15),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    SizedBox(
                      width: double.infinity,
                      child: !isTyping
                          ? ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          elevation: 0,
                          minimumSize: Size(double.infinity.w, 55.h),
                        ),
                        child: Text(
                          'Add record',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                      )
                          : CustomAppButton(
                          onPressed: () {

                          ref.read(enteredAmountProvider.notifier).state = double.parse(_amountController.text);
                          final selectedCard = ref.watch(cardsProvider).cards.firstWhere((card)=>card.id==selectedAccountNotifier.state);

                          if((ref.read(enteredAmountProvider.notifier).state>selectedCard.amount || selectedCard.amount<=0) && ref.read(moneyTypeProvider.notifier).state==MoneyType.expense){
                            toast('Not sufficient balance, please choose a different account or update the balance');
                            return;
                          }

                          ref.read(expenseProvider.notifier).insertExpense(
                            ExpenseModel(
                              title: _titleController.text,
                              amount: double.parse(_amountController.text),
                              category: category,
                              date: ref.read(selectedDateProvider.notifier).state,
                              time: ref.read(selectedTimeProvider.notifier).state,
                              moneyType: ref.read(moneyTypeProvider.notifier).state,
                              accountId: ref.read(selectedAccountProvider)!
                            ),
                          );
                          ref.read(cardsProvider.notifier).calculateTotalAmountInAccount();
                          ref.read(budgetProvider.notifier).calculateAmount();
                          ref.read(recordAddedTriggerProvider.notifier).state++;

                          Navigator.pop(context);
                        },
                        title: 'Add record',
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      _titleController.clear();
      _amountController.clear();
      ref.read(categoryPickerProvider.notifier).state = 'Personal';
      ref.read(selectedDateProvider.notifier).state = DateTime.now();
      ref.read(selectedTimeProvider.notifier).state = TimeOfDay.now();
    });
  }

  void editExpenseDialogue(ExpenseModel expense) {

    int? id = expense.id;
    _editTitleController.text = expense.title;
    _editAmountController.text = expense.amount.toString();
    ref.read(categoryPickerProvider.notifier).state = expense.category;
    ref.read(selectedDateProvider.notifier).state = expense.date;
    ref.read(selectedTimeProvider.notifier).state = expense.time;
    ref.read(moneyTypeProvider.notifier).state = expense.moneyType;

    ref.read(editingProvider.notifier).state = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        var theme = Theme.of(context);

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
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
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Text(
                      'Edit existing record',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                    ),
                    SizedBox(height: 15.h),
                    TextFormField(
                      autofocus: true,
                      controller: _editTitleController,
                      onChanged: (_) => checkTyping(ref, expense: expense),
                      decoration: InputDecoration(
                        hintText: 'Name of your expense or income',
                        hintStyle: theme.textTheme.labelLarge
                            ?.copyWith(color: AppColors.hintTextColor),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    TextFormField(
                      autofocus: true,
                      controller: _editAmountController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => checkTyping(ref, expense: expense),
                      decoration: InputDecoration(
                        hintText: 'Amount spent or received today',
                        hintStyle: theme.textTheme.labelLarge
                            ?.copyWith(color: AppColors.hintTextColor),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    Row(
                      children: [
                        Icon(Icons.date_range, color: theme.iconTheme.color),
                        TextButton(
                          onPressed: pickDate,
                          child: Text(
                            DateFormat('MMMM dd, yyyy')
                                .format(ref.watch(selectedDateProvider)),
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.more_time_outlined, color: theme.iconTheme.color),
                        TextButton(
                          onPressed: pickTime,
                          child: Text(
                            ref.watch(selectedTimeProvider).format(context),
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15.h),
                    Text('Select money type:',
                        style: theme.textTheme.titleMedium),
                    Row(
                      children: MoneyType.values.map((type) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<MoneyType>(
                              fillColor: WidgetStatePropertyAll(
                                  theme.colorScheme.primary),
                              value: type,
                              groupValue: moneyTypeState,
                              onChanged: (value) {
                                moneyTypeNotifier.state = value!;
                                checkTyping(ref);
                                ref.read(categoryPickerProvider.notifier).state = value==MoneyType.expense? expenseCategories.first.categoryName
                                    :incomeCategories.first.categoryName;
                              },
                            ),
                            Text(
                              type == MoneyType.expense
                                  ? 'Expense'
                                  : 'Income',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(width: 10),
                          ],
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 15.h),
                    Text('Select category',style: theme.textTheme.titleMedium,),
                    SizedBox(height: 10.h),
                    DropdownButtonFormField(
                      value: category,
                      items: moneyTypeNotifier.state==MoneyType.expense?expenseCategories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.categoryName,
                          child: Text(cat.categoryName),
                        );
                      }).toList()
                          :incomeCategories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.categoryName,
                          child: Text(cat.categoryName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        ref.read(categoryPickerProvider.notifier).state = value!;
                        ref.read(categorySelectionProvider.notifier).state = true;
                        checkTyping(ref, expense: expense);
                      },
                    ),
                    SizedBox(height: 10.h),
                    Text('Choose account',style: theme.textTheme.titleMedium,),
                    SizedBox(height: 10.h,),
                    DropdownButtonFormField2(
                      isExpanded: true,
                      value: selectedAccountState,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant,
                      ),
                      hint: Text(
                        'Choose account',
                        style: theme.textTheme.labelLarge?.copyWith(color: AppColors.hintTextColor,),
                      ),
                      items: ref.watch(cardsProvider).cards.map((card) {
                        return DropdownMenuItem<int>(
                          value: card.id,
                          child: Row(
                            children: [
                              Icon(card.icon, size: 20, color: theme.iconTheme.color),
                              const SizedBox(width: 10),
                              Text(
                                card.cardName,
                                style: theme.textTheme.titleSmall,
                              ),
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
                      iconStyleData: const IconStyleData(
                        icon: Icon(Icons.arrow_drop_down_rounded),
                        iconSize: 28,
                      ),
                      buttonStyleData: ButtonStyleData(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        height: 55.h,
                      ),
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.surface,
                        ),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 50,
                        padding: EdgeInsets.symmetric(horizontal: 15),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    SizedBox(
                      width: double.infinity,
                      child: !isTyping
                          ? ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.r)),
                          elevation: 0,
                          minimumSize: Size(double.infinity, 55.h),
                        ),
                        child: Text(
                          'Edit record',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                      )
                          : CustomAppButton(
                        onPressed: () {

                          if(ref.read(editingProvider.notifier).state==true) {
                            ref.read(enteredAmountProvider.notifier).state = double.parse(_editAmountController.text);
                          }

                          final selectedCard = ref.watch(cardsProvider).cards.firstWhere((card)=>card.id==selectedAccountNotifier.state);

                          if((ref.read(enteredAmountProvider.notifier).state>selectedCard.amount || selectedCard.amount<=0) && ref.read(moneyTypeProvider.notifier).state==MoneyType.expense){
                            toast('Not sufficient balance, please choose a different account or update the balance');
                            return;
                          }

                          ref.read(expenseProvider.notifier).updateExpense(
                            ExpenseModel(
                              id: id,
                              title: _editTitleController.text,
                              amount: double.parse(_editAmountController.text),
                              category: category,
                              date: ref.read(selectedDateProvider.notifier).state,
                              time: ref.read(selectedTimeProvider.notifier).state,
                              moneyType: ref.read(moneyTypeProvider.notifier).state,
                              accountId: ref.read(selectedAccountProvider)!
                            ),
                          );

                          ref.read(cardsProvider.notifier).calculateTotalAmountInAccount();

                          ref.read(editingProvider.notifier).state = false;
                          ref.read(checkTypingProvider.notifier).state = false;
                          ref.read(recordAddedTriggerProvider.notifier).state++;

                          Navigator.pop(context);
                        },
                        title: 'Edit record',
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      ref.read(editingProvider.notifier).state = false;
      ref.read(checkTypingProvider.notifier).state = false;
    });
  }

  void deleteAlert(ExpenseModel expense){
    showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text('Wait!',style: Theme.of(context).textTheme.titleLarge,),
            content: Text('Are you sure you want to delete this entry?',style: Theme.of(context).textTheme.titleSmall,),
            actions: [
              TextButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: Text('Cancel',style: Theme.of(context).textTheme.titleMedium,)
              ),
              TextButton(
                  onPressed: (){
                    ref.read(expenseProvider.notifier).deleteExpense(expense.id!);
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
    final expenseState = ref.watch(expenseProvider);
    final expenseNotifier = ref.read(expenseProvider.notifier);
    var theme = Theme.of(context);

    final selectedCurrency = ref.watch(newCurrencyProvider).currency;

    final dateState = ref.watch(selectedDateProvider);
    final dateNotifier = ref.read(selectedDateProvider.notifier);

    final timeState = ref.watch(selectedTimeProvider);
    final timeNotifier = ref.read(selectedTimeProvider.notifier);

    final expenseList = expenseState.filteredRecord;

    final groupedExpenses = _groupByDate(expenseList);

    final sortedDates = groupedExpenses.keys.toList()..sort((a,b)=>b.compareTo(a));


    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
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
                              child: _buildRecordsList(context, ref, theme, sortedDates, groupedExpenses, selectedCurrency, expenseNotifier, expenseState)
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
      floatingActionButton: SlideTransition(
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 50.h),
        Icon(Icons.error_outline_outlined, color: theme.colorScheme.primary, size: 100),
        SizedBox(height: 24.h),
        Text('No records this month', style: theme.textTheme.titleLarge),
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
    return ListView.builder(
      shrinkWrap: true,
      physics: BouncingScrollPhysics(),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final expensesForDate = groupedExpenses[date]!;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                
                return ExpenseTile(
                  bgColor: selectedCategory.color,
                  icon: selectedCategory.icon,
                  expenseModel: expense,
                  currency: selectedCurrency,
                  cardModel: selectedCard,
                  onEdit: () => editExpenseDialogue(expense),
                  onDelete: () => deleteAlert(expense),
                );
              }),
            ],
          ),
        );
      },
    );
  }

}


