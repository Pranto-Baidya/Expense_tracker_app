import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/widgets/app_colors.dart';
import 'package:expense_tracker_app/widgets/custom_app_button.dart';
import 'package:expense_tracker_app/widgets/custom_appbar.dart';
import 'package:expense_tracker_app/widgets/expense_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final categoryProvider = StateProvider<String>((ref)=>'Personal');
final categorySelectionProvider = StateProvider<bool>((ref)=>false);
final checkTypingProvider = StateProvider<bool>((ref)=>false);
final currencyProvider = StateProvider<String>((ref)=>'\$');
final editingProvider = StateProvider<bool>((ref)=>false);

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final TextEditingController _editTitleController = TextEditingController();
  final TextEditingController _editAmountController = TextEditingController();


  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      ref.read(expenseProvider.notifier).getExpenses();
    });
    _titleController.addListener(()=>checkTyping(ref));
    _amountController.addListener(()=>checkTyping(ref));

    super.initState();
  }

  @override
  void dispose() {
    _titleController.removeListener(()=>checkTyping(ref,));
    _amountController.removeListener(()=>checkTyping(ref));
    super.dispose();
  }

  void checkTyping(WidgetRef ref,{ExpenseModel? expense}){
    final isEditing = ref.read(editingProvider);

    if(!isEditing) {
      bool hasContents = _titleController.text.isNotEmpty && _amountController.text.isNotEmpty && ref.read(categorySelectionProvider);
      if (hasContents != ref.read(checkTypingProvider.notifier).state) {
        ref.read(checkTypingProvider.notifier).state = hasContents;
      }
    }
    else{
      bool hasChanged = _editTitleController.text!=expense?.title || _editAmountController.text!=expense?.amount.toString() || ref.read(categoryProvider)!=expense?.category;
      if(hasChanged!=ref.read(checkTypingProvider.notifier).state){
        ref.read(checkTypingProvider.notifier).state = hasChanged;
      }
    }
  }

  void addExpenseDialogue(){

    showDialog(
        context: context,
        builder: (context){
          var theme = Theme.of(context);
          List<String> categories = ['Personal','Family','Food','Shopping','Transport','Phone','Bills','Rent','Other'];

          return Consumer(
              builder: (context,ref,_){
                final category = ref.watch(categoryProvider);
                final isTyping = ref.watch(checkTypingProvider);

                return AlertDialog(
                  backgroundColor: theme.dialogTheme.backgroundColor,
                  title: Text("Add a new expense",style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                            hintText: 'Name of your expense',
                            hintStyle: theme.textTheme.labelLarge?.copyWith(color: AppColors.hintTextColor)
                        ),
                      ),
                      SizedBox(height: 15.h,),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        controller: _amountController,
                        decoration: InputDecoration(
                            hintText: 'Amount spent today',
                            hintStyle: theme.textTheme.labelLarge?.copyWith(color: AppColors.hintTextColor)
                        ),
                      ),
                      SizedBox(height: 15.h,),
                      DropdownButtonFormField(
                        dropdownColor: theme.dropdownMenuTheme.menuStyle?.backgroundColor?.resolve(({})),
                        borderRadius: BorderRadius.circular(10.r),
                        hint: Text('Select category',style: theme.textTheme.labelLarge?.copyWith(color: AppColors.hintTextColor),),
                        initialValue: category,
                        items: [
                          ...categories.map((item){
                            return DropdownMenuItem(
                                value: item,
                                child: Text(item,style: theme.textTheme.titleSmall,)
                            );
                          })
                        ],
                        onChanged: (value){
                          ref.read(categoryProvider.notifier).state = value!;
                          ref.read(categorySelectionProvider.notifier).state = true;
                          checkTyping(ref);
                        },
                      ),
                      SizedBox(height: 15.h,),
                      !isTyping? ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                              elevation: 0,
                              minimumSize: Size(double.infinity.w, 55.h)
                          ),
                          child: Text('Add expense',style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),)
                      ) : CustomAppButton(
                          onPressed: (){
                            ref.read(expenseProvider.notifier).insertExpense(
                                ExpenseModel(
                                    title: _titleController.text,
                                    amount: double.parse(_amountController.text),
                                    category: category,
                                    date: DateTime.now().toIso8601String()
                                )
                            );
                            Navigator.pop(context);
                          },
                          title: 'Add Expense'
                      )

                    ],
                  ),
                );
              }
          );
        }
    ).then((_){
      _titleController.clear();
      _amountController.clear();
      ref.read(categoryProvider.notifier).state ='Personal';
    });
  }

  void editExpenseDialogue(ExpenseModel expense) {
    int? id = expense.id;
    _editTitleController.text = expense.title;
    _editAmountController.text = expense.amount.toString();
    ref.read(categoryProvider.notifier).state = expense.category;
    ref.read(editingProvider.notifier).state = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        var theme = Theme.of(context);
        List<String> categories = [
          'Personal', 'Family', 'Food', 'Shopping', 'Transport',
          'Phone', 'Bills', 'Rent', 'Other'
        ];

        return Consumer(
          builder: (context, ref, _) {
            final category = ref.watch(categoryProvider);
            final isTyping = ref.watch(checkTypingProvider);

            return AlertDialog(
              title: Text(
                'Edit expense',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _editTitleController,
                    onChanged: (_) => checkTyping(ref, expense: expense),
                    decoration: InputDecoration(
                      hintText: 'Name of your expense',
                      hintStyle: theme.textTheme.labelLarge
                          ?.copyWith(color: AppColors.hintTextColor),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  TextFormField(
                    controller: _editAmountController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => checkTyping(ref, expense: expense),
                    decoration: InputDecoration(
                      hintText: 'Amount spent today',
                      hintStyle: theme.textTheme.labelLarge
                          ?.copyWith(color: AppColors.hintTextColor),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  DropdownButtonFormField(
                    initialValue: category,
                    items: categories
                        .map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    ))
                        .toList(),
                    onChanged: (value) {
                      ref.read(categoryProvider.notifier).state = value!;
                      ref.read(categorySelectionProvider.notifier).state = true;
                      checkTyping(ref, expense: expense);
                    },
                  ),
                  SizedBox(height: 10.h),
                  !isTyping
                      ? ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.r)),
                      elevation: 0,
                      minimumSize: Size(double.infinity, 55.h),
                    ),
                    child: Text(
                      'Edit expense',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                  )
                      : CustomAppButton(
                    onPressed: () {
                      ref.read(expenseProvider.notifier).updateExpense(
                        ExpenseModel(
                          id: id,
                          title: _editTitleController.text,
                          amount: double.parse(
                              _editAmountController.text),
                          category: category,
                          date: DateTime.now().toIso8601String(),
                        ),
                      );

                      ref.read(editingProvider.notifier).state = false;
                      ref.read(checkTypingProvider.notifier).state = false;
                      Navigator.pop(context);
                    },
                    title: 'Edit expense',
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_){
      ref.read(editingProvider.notifier).state = false;
      ref.read(checkTypingProvider.notifier).state = false;
    });
  }

  void deleteAlert(int id){
    showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
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
                    ref.read(expenseProvider.notifier).deleteExpense(id);
                    Navigator.pop(context);
                  },
                  child: Text('Delete',style: Theme.of(context).textTheme.titleMedium,)
              ),
            ],
          );
        }
    );
  }


  List<String> currencies = ["\$","€","₹","৳"];

  IconData icons(String category){
    switch(category){
      case 'Personal':
        return Icons.person;
      case 'Family':
        return Icons.groups;
      case 'Food':
        return Icons.fastfood;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Transport':
        return Icons.directions_car;
      case 'Phone':
        return Icons.phone_android;
      case 'Bills':
        return Icons.receipt_long;
      case 'Rent':
        return Icons.home;
      case 'Other':
        return Icons.control_point_duplicate;
      default: return Icons.control_point_duplicate;

    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final expenseNotifier = ref.read(expenseProvider.notifier);
    var theme = Theme.of(context);

    final selectedCurrency = ref.watch(currencyProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppbar(
          title: 'ExpenseMate',
          action: [
            Padding(
              padding: const EdgeInsets.only(right: 30),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Change currency:  ",
                      style: theme.textTheme.titleSmall,
                    ),
                    DropdownButton<String>(
                      dropdownColor: theme.dropdownMenuTheme.menuStyle?.backgroundColor?.resolve(({})),
                      value: selectedCurrency,
                      underline: const SizedBox(),
                      items: currencies.map((cr) {
                        return DropdownMenuItem(
                          value: cr,
                          child: Center(
                            child: Text(
                              cr, style: theme.textTheme.titleMedium,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        ref.read(currencyProvider.notifier).state = value!;
                      },
                    ),
                  ],
                ),
              ),
            )

          ],
      ),
      body: RefreshIndicator(
        onRefresh: ()=> expenseNotifier.refreshExpenseRecord(),
        child: NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo){
              if(scrollInfo.metrics.pixels>=scrollInfo.metrics.maxScrollExtent-100 && !expenseState.isLoading && expenseState.hasMore){
                expenseNotifier.getExpenses();
              }
              return false;
            },
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: expenseState.expenses.length + (expenseState.hasMore? 1 : 0),
                itemBuilder: (context,index){
                  if(index<expenseState.expenses.length){
                    final data = expenseState.expenses[index];
                     return ExpenseTile(
                         icon: icons(data.category),
                         expenseModel: data,
                         currency: selectedCurrency,
                         onEdit: (){
                           editExpenseDialogue(data);
                         },
                         onDelete: (){
                           deleteAlert(data.id!);
                         },
                     );
                  }
                  else{
                    return expenseState.hasMore? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator(),),
                    ):SizedBox.shrink();
                  }
                }
            )
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: addExpenseDialogue,
          backgroundColor: theme.colorScheme.primary,
          child: Icon(Icons.add,color: Colors.white),
      ),
    );
  }
}
