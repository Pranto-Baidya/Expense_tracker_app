import 'package:expense_tracker_app/models/card_model.dart';
import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:expense_tracker_app/widgets/accounts_widget.dart';
import 'package:expense_tracker_app/widgets/app_colors.dart';
import 'package:expense_tracker_app/widgets/custom_app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final selectedIconProvider = StateProvider<IconData>((ref)=>Icons.credit_card);
final typingProvider = StateProvider<bool>((ref)=>false);
final accountEditingProvider = StateProvider<bool>((ref)=>false);


class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<AccountsScreen> {

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editAmountController = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      ref.read(cardsProvider.notifier).getCards();
    });
    super.initState();
    _nameController.addListener(()=>checkTyping(ref));
    _amountController.addListener(()=>checkTyping(ref));
  }

  @override
  void dispose() {
    _nameController.removeListener(()=>checkTyping(ref));
    _amountController.removeListener(()=>checkTyping(ref));
    super.dispose();
  }

  void checkTyping(WidgetRef ref,{CardModel? card}){

    final isTyping = ref.read(typingProvider);
    final isEditing = ref.read(accountEditingProvider);

    if(!isEditing) {
      bool hasValue = _nameController.text.isNotEmpty &&
          _amountController.text.isNotEmpty;
      if (hasValue != isTyping) {
        ref.read(typingProvider.notifier).state = hasValue;
      }
    }
   else {
      bool hasChanged = _editNameController.text != card?.cardName
          || _editAmountController.text != card?.amount.toString()
          || ref.read(selectedIconProvider.notifier).state != card?.icon;

      if (hasChanged != isTyping) {
        ref.read(typingProvider.notifier).state = hasChanged;
      }
    }

  }

  void addCardDialogue(){

    ref.read(typingProvider.notifier).state = false;

    showDialog(
        context: context,
        builder: (BuildContext context){

          var theme = Theme.of(context);

          List<IconData> icons = [
            Icons.credit_card,
            Icons.savings_outlined,
            Icons.money,
            Icons.wallet_outlined,
            Icons.phone_iphone_sharp
          ];
          return Consumer(
              builder: (context,ref,_){
                final isTyping = ref.watch(typingProvider);
                return AlertDialog(
                  backgroundColor: Theme.of(context).cardColor,
                  title: Row(
                    children: [
                      Text('Add a new account',style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        autofocus: true,
                        controller: _nameController,
                        decoration: InputDecoration(
                            hintText: 'Name of your account',
                            hintStyle: theme.textTheme.titleSmall?.copyWith(color: AppColors.hintTextColor)
                        ),
                      ),
                      SizedBox(height: 15.h,),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            hintText: 'Initial amount',
                            hintStyle: theme.textTheme.titleSmall?.copyWith(color: AppColors.hintTextColor)
                        ),
                      ),
                      SizedBox(height: 20.h,),
                      Text('Choose icon',style: theme.textTheme.titleMedium),
                      SizedBox(height: 10.h,),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ...icons.map((icon){

                              final selectedIcon = ref.watch(selectedIconProvider);
                              final selectedNotifier = ref.read(selectedIconProvider.notifier);
                              final isSelected = selectedIcon==icon;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: ChoiceChip(
                                  checkmarkColor: Colors.white,
                                  selectedColor: theme.colorScheme.primary,
                                  label: isSelected?Icon(icon,color: Colors.white,):Icon(icon,color: theme.iconTheme.color,),
                                  selected: isSelected,
                                  onSelected: (selected){
                                    selectedNotifier.state = icon;
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h,),
                      !isTyping?ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          elevation: 0,
                          minimumSize: Size(double.infinity.w, 50.h),
                        ),
                        child: Text(
                          'Add account',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                      )
                      :CustomAppButton(
                          onPressed: (){
                            final selectedIcon = ref.read(selectedIconProvider);
                            final card = CardModel(
                                cardName: _nameController.text,
                                amount: double.parse(_amountController.text),
                                icon: selectedIcon,
                            );
                            ref.read(cardsProvider.notifier).addCard(card);
                            Navigator.pop(context);
                          },
                          title: 'Add account'
                      )
                    ],
                  ),
                );
              }
          );
        }
    ).then((_){
      _nameController.clear();
      _amountController.clear();
      ref.read(selectedIconProvider.notifier).state=Icons.credit_card;
    });
  }
  
  void editCardDialogue(CardModel card){

    ref.read(typingProvider.notifier).state = false;
    ref.read(accountEditingProvider.notifier).state = true;
    
    _editNameController.text = card.cardName;
    _editAmountController.text = card.amount.toString();
    ref.read(selectedIconProvider.notifier).state = card.icon;
    
    showDialog(
        context: context, 
        builder: (context){
          var theme = Theme.of(context);

          List<IconData> icons = [
            Icons.credit_card,
            Icons.savings_outlined,
            Icons.money,
            Icons.wallet_outlined,
            Icons.phone_iphone_sharp
          ];

          return Consumer(
              builder: (context,ref,_){
                final isTyping = ref.watch(typingProvider);
                return AlertDialog(
                  backgroundColor: Theme.of(context).cardColor,
                  title: Row(
                    children: [
                      Text('Edit account',style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        autofocus: true,
                        controller: _editNameController,
                        decoration: InputDecoration(
                            hintText: 'Name of your account',
                            hintStyle: theme.textTheme.titleSmall?.copyWith(color: AppColors.hintTextColor)
                        ),
                        onChanged: (_)=>checkTyping(ref,card: card),
                      ),
                      SizedBox(height: 15.h,),
                      TextField(
                        controller: _editAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            hintText: 'Initial amount',
                            hintStyle: theme.textTheme.titleSmall?.copyWith(color: AppColors.hintTextColor)
                        ),
                        onChanged: (_)=>checkTyping(ref,card: card),
                      ),
                      SizedBox(height: 20.h,),
                      Text('Choose icon',style: theme.textTheme.titleMedium),
                      SizedBox(height: 10.h,),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...icons.map((icon){
                              final selectedIconState = ref.watch(selectedIconProvider);
                              final selectedIconNotifier = ref.read(selectedIconProvider.notifier);
                              final isSelected = selectedIconState==icon;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: ChoiceChip(
                                  label: Icon(icon,color: isSelected?Colors.white:theme.iconTheme.color,),
                                  selected: isSelected,
                                  checkmarkColor: Colors.white,
                                  selectedColor: theme.colorScheme.primary,
                                  onSelected: (selected){
                                    selectedIconNotifier.state = icon;
                                    checkTyping(ref);
                                  },
                                ),
                              );
                            })
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h,),
                      !isTyping?ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          elevation: 0,
                          minimumSize: Size(double.infinity.w, 50.h),
                        ),
                        child: Text(
                          'Edit account',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                      ):CustomAppButton(
                          onPressed: (){
                            final newData = CardModel(
                                id: card.id,
                                cardName: _editNameController.text,
                                amount: double.parse(_editAmountController.text),
                                icon: ref.read(selectedIconProvider.notifier).state
                            );
                            ref.read(cardsProvider.notifier).updateCard(newData);
                            Navigator.pop(context);
                          },
                          title: 'Edit account'
                      )

                    ],
                  ),
                );
              }
          );
        }
    ).then((_){
      ref.read(accountEditingProvider.notifier).state = false;
      ref.read(typingProvider.notifier).state = false;
    });
    
  }


  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    final cardState = ref.watch(cardsProvider);
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w,vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h,),
            Text('All Accounts',style: theme.textTheme.titleLarge,),
            SizedBox(height: 15.h,),
            Expanded(
                child: Builder(
                    builder: (context){
                      if(cardState.isLoading){
                        return Center(child: CircularProgressIndicator(),);
                      }
                      if(cardState.cards.isEmpty){
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.credit_card_off_outlined,color: theme.colorScheme.primary,size: 100,),
                              SizedBox(height: 10.h,),
                              Text('No accounts are added yet',style: theme.textTheme.titleMedium,),
                              Text('Tap the + button to add a new account',style: theme.textTheme.titleMedium,),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                          shrinkWrap: true,
                          itemCount: cardState.cards.length,
                          itemBuilder: (context,index){

                            final data = cardState.cards[index];
                            double amount = 0;

                            if(data.amount<=0 && ref.read(moneyTypeProvider.notifier).state==MoneyType.expense){
                              amount = 0;
                            }
                            else{
                              amount = data.amount;
                            }

                            return AccountsWidget(
                                title: data.cardName,
                                amount: amount,
                                icon: data.icon,
                                value: data.progress,
                                onEdit: (){
                                  editCardDialogue(data);
                                },
                                onDelete: (){
                                  ref.read(cardsProvider.notifier).deleteCard(data.id!);
                                }
                            );
                          }
                      );
                    }
                )
            )
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        height: 60.h,
        width: 60.h,
        child: FloatingActionButton(
            onPressed: addCardDialogue,
            backgroundColor: theme.colorScheme.primary,
            elevation: 0,
            child: Icon(Icons.add_card,color: Colors.white,size: 30,),
            ),
      ),
    );
  }
}
