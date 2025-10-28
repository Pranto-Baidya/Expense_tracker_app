import 'package:expense_tracker_app/models/card_model.dart';
import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
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


class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<AccountsScreen> {

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

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

  void checkTyping(WidgetRef ref){
    final isTyping = ref.read(typingProvider);
    bool hasValue = _nameController.text.isNotEmpty && _amountController.text.isNotEmpty;

    if(hasValue!=isTyping){
      ref.read(typingProvider.notifier).state = hasValue;
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
            Icons.paid_outlined,
            Icons.wallet_outlined,
            Icons.phone_iphone_sharp
          ];
          return Consumer(
              builder: (context,ref,_){
                final isTyping = ref.watch(typingProvider);
                return AlertDialog(
                  title: Row(
                    children: [
                      Text('Add a new account',style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),),
                      Spacer(),
                      IconButton(
                          onPressed: (){
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close,color: theme.iconTheme.color,size: 30,)
                      )
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
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
                          minimumSize: Size(double.infinity.w, 55.h),
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
                                icon: selectedIcon
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
                        return Center(child: Text('No cards are added yet',style: theme.textTheme.titleMedium,),);
                      }
                      return ListView.builder(
                          shrinkWrap: true,
                          itemCount: cardState.cards.length,
                          itemBuilder: (context,index){
                            final data = cardState.cards[index];
                            return AccountsWidget(
                                title: data.cardName,
                                amount: data.amount,
                                icon: data.icon,
                                onEdit: (){

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
            elevation: 3,
            child: Icon(Icons.add_card,color: Colors.white,size: 30,),
            ),
      ),
    );
  }
}
