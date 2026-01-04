import 'package:expense_tracker_app/models/card_model.dart';
import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:expense_tracker_app/riverpod/currency_riverpod/currency_pref.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/riverpod/prefs_riverpod/prefs_riverpod.dart';
import 'package:expense_tracker_app/riverpod/premade_accounts/premade_accounts.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:expense_tracker_app/widgets/account_dashboard.dart';
import 'package:expense_tracker_app/widgets/accounts_widget.dart';
import 'package:expense_tracker_app/widgets/app_colors.dart';
import 'package:expense_tracker_app/widgets/custom_app_button.dart';
import 'package:expense_tracker_app/widgets/listAnimation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

final selectedIconProvider = StateProvider<IconData>((ref)=>Icons.credit_card);
final typingProvider = StateProvider<bool>((ref)=>false);
final accountEditingProvider = StateProvider<bool>((ref)=>false);
final isIdSelectedForBulkDeleteProvider = StateProvider<bool>((ref)=>false);
final selectedIdsProvider = StateProvider<Set<int>>((ref)=>{});
final accountDashboardCollapseProvider = StateProvider<bool>((ref)=>false);


class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<AccountsScreen> with TickerProviderStateMixin{

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  final TextEditingController _editNameController = TextEditingController();
  final TextEditingController _editAmountController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  late AnimationController _animationController;

  late Animation<Offset> _fabAnimation;

  late AnimationController _bulkDeleteFABController;

  late Animation<double> _bulkDeleteFABAnimation;

  double _lastScrollPosition = 0;
  bool _isFABVisible = true;

  double expandedHeight = 244.0.h;
  double collapsedHeight = 60.0.h;

  @override
  void initState() {

    _scrollController.addListener(_onScroll);

    _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300)
    );

    _fabAnimation = Tween<Offset>(begin: Offset.zero,end: Offset(0, 1.5)).animate(CurvedAnimation(parent: _animationController, curve: Curves.fastOutSlowIn));

    _bulkDeleteFABController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500)
    );

    _bulkDeleteFABAnimation = Tween<double>(begin: 0,end: 1).animate(CurvedAnimation(parent: _bulkDeleteFABController, curve: Curves.fastOutSlowIn));

    WidgetsBinding.instance.addPostFrameCallback((_){
      ref.read(premadeAccountsProvider.notifier).initializePreMadeAccounts(ref);
    });
    super.initState();
    _nameController.addListener(()=>checkTyping(ref));
    _amountController.addListener(()=>checkTyping(ref));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bulkDeleteFABController.dispose();
    _nameController.removeListener(()=>checkTyping(ref));
    _amountController.removeListener(()=>checkTyping(ref));
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll(){
    final scrollState = ref.read(accountDashboardCollapseProvider);
    final scrollNotifier = ref.read(accountDashboardCollapseProvider.notifier);

    final bool isCollapsed = _scrollController.offset > 50;

    if(isCollapsed!=scrollState){
      scrollNotifier.state = isCollapsed;
    }
  }

  bool _handleFabButton(ScrollNotification scrollInfo){
    if(scrollInfo is ScrollUpdateNotification){

      final currentScrollPosition = scrollInfo.metrics.pixels;
      final scrollDelta = currentScrollPosition - _lastScrollPosition;

      if(scrollDelta>2 && _isFABVisible){
        _animationController.forward();
        _isFABVisible = false;
      }
      else if(scrollDelta<-2 && !_isFABVisible){
        _animationController.reverse();
        _isFABVisible = true;
      }

      _lastScrollPosition = currentScrollPosition;
    }
    return false;
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
            Icons.phone_iphone_sharp,
            Icons.payment,
            Icons.account_balance_wallet,
            Icons.card_membership,
            Icons.card_giftcard,
            Icons.card_travel,
            Icons.attach_money,
            Icons.monetization_on,
            Icons.point_of_sale,
            Icons.receipt_long,
            Icons.account_balance,
            Icons.savings,
            Icons.account_tree,
            Icons.account_box,
            Icons.trending_up,
            Icons.trending_down,
            Icons.currency_exchange,
            Icons.price_check,
            Icons.request_page,
            Icons.fact_check,
            Icons.money_off_csred_rounded,
            Icons.local_atm,
            Icons.wallet,
            Icons.currency_bitcoin,
            Icons.phone_android,
            Icons.smartphone,
            Icons.phonelink_setup,
            Icons.devices,
            Icons.contact_phone,
            Icons.mobile_friendly,
            Icons.qr_code,
            Icons.qr_code_scanner,
            Icons.nfc,
            Icons.receipt,
            Icons.shopping_bag,
            Icons.shopping_cart,
            Icons.store,
            Icons.storefront,
            Icons.shopping_basket,
            Icons.add_shopping_cart,
            Icons.sell,
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
            Icons.phone_iphone_sharp,
            Icons.payment,
            Icons.account_balance_wallet,
            Icons.card_membership,
            Icons.card_giftcard,
            Icons.card_travel,
            Icons.attach_money,
            Icons.monetization_on,
            Icons.point_of_sale,
            Icons.receipt_long,
            Icons.account_balance,
            Icons.savings,
            Icons.account_tree,
            Icons.account_box,
            Icons.trending_up,
            Icons.trending_down,
            Icons.currency_exchange,
            Icons.price_check,
            Icons.request_page,
            Icons.fact_check,
            Icons.money_off_csred_rounded,
            Icons.local_atm,
            Icons.wallet,
            Icons.currency_bitcoin,
            Icons.phone_android,
            Icons.smartphone,
            Icons.phonelink_setup,
            Icons.devices,
            Icons.contact_phone,
            Icons.mobile_friendly,
            Icons.qr_code,
            Icons.qr_code_scanner,
            Icons.nfc,
            Icons.receipt,
            Icons.shopping_bag,
            Icons.shopping_cart,
            Icons.store,
            Icons.storefront,
            Icons.shopping_basket,
            Icons.add_shopping_cart,
            Icons.sell,
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
                            hintText: 'Current balance',
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
                                    checkTyping(ref, card: card);
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
                                initialAmount: card.initialAmount,
                                icon: ref.read(selectedIconProvider.notifier).state,
                                moneyType: card.moneyType,
                                progress: card.progress
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

  void deleteAlert(CardModel card){
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
                        'Delete account',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Are you sure you want to delete this account?\nThis action cannot be undone.',
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
                            ref.read(cardsProvider.notifier).deleteCard(card.id!);
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
          final selectedIds = ref.read(selectedIdsProvider);
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
                          'Delete ${selectedIds.length} account?',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: 17,fontWeight: FontWeight.bold),
                        ):Text(
                          'Delete ${selectedIds.length} accounts?',
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
                            ref.read(cardsProvider.notifier).bulkDeleteCards(selectedIds.toList());
                            selectedIds.clear();
                            ref.read(isIdSelectedForBulkDeleteProvider.notifier).state = false;
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
    var theme = Theme.of(context);
    final cardState = ref.watch(cardsProvider);

    final totalAccountBalance = cardState.cards.fold(0.0, (sum,value)=>sum+value.amount);

    final avg = ref.watch(cardsProvider).cards.isEmpty ? 0.0 : ref.watch(cardsProvider).cards.fold(0.0, (sum, card) => sum + card.progress) / ref.watch(cardsProvider).cards.length;

    final isCollapseModeActivated = ref.watch(collapseDashboardPrefProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: isCollapseModeActivated?NotificationListener<ScrollNotification>(
        onNotification: _handleFabButton,
        child: CustomScrollView(
          controller: _scrollController,
          physics: cardState.cards.isEmpty?const NeverScrollableScrollPhysics(): const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Collapsible Account Dashboard
            SliverAppBar(
              expandedHeight: expandedHeight,
              collapsedHeight: collapsedHeight,
              backgroundColor: theme.colorScheme.primary,
              elevation: 0,
              pinned: true,
              automaticallyImplyLeading: false,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final double maxHeight = expandedHeight;
                  final double minHeight = collapsedHeight;
                  final double currentHeight = constraints.maxHeight;
                  final double collapseThreshold = minHeight + ((maxHeight - minHeight) * 0.3);
                  final bool isCurrentlyCollapsed = currentHeight <= collapseThreshold;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final currentState = ref.read(accountDashboardCollapseProvider);
                    if (isCurrentlyCollapsed != currentState) {
                      ref.read(accountDashboardCollapseProvider.notifier).state = isCurrentlyCollapsed;
                    }
                  });

                  return AnimatedAccountDashboard(isCollapsed: isCurrentlyCollapsed);
                },
              ),
            ),

            // Loading State
            if (cardState.isLoading)
              SliverFillRemaining(
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
           else if (cardState.cards.isEmpty)...[
              SliverToBoxAdapter(
                child: SizedBox(height: 12.h),
              ),
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
                  child: Column(
                    children: [
                      SizedBox(height: 80.h,),
                      Icon(
                        Icons.credit_card_off_outlined,
                        color: theme.colorScheme.primary,
                        size: 100,
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'No accounts yet',
                        style: theme.textTheme.titleLarge,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Tap the + button to add a new account',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
              ]
            else
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
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.h),
                          if (cardState.cards.isNotEmpty)
                            Text(
                              'All accounts',
                              style: theme.textTheme.titleLarge,
                            ),

                          SizedBox(height: 10.h),

                          // Accounts List
                          Column(
                            children: [
                              ...cardState.cards.map((data) {
                                final index = cardState.cards.indexOf(data);
                                double amount = 0;

                                if (data.amount <= 0 && ref.read(moneyTypeProvider.notifier).state == MoneyType.expense) {
                                  amount = 0;
                                } else {
                                  amount = data.amount;
                                }

                                return GestureDetector(
                                  onLongPress: () {
                                    ref.read(isIdSelectedForBulkDeleteProvider.notifier).state = true;
                                    final val = ref.read(selectedIdsProvider);
                                    ref.read(selectedIdsProvider.notifier).state = Set<int>.from(val)..add(data.id!);
                                    if (ref.read(selectedIdsProvider.notifier).state.length == 1) {
                                      _bulkDeleteFABController.forward(from: 0);
                                    }
                                  },
                                  onTap: () {
                                    if (ref.read(isIdSelectedForBulkDeleteProvider)) {
                                      final val = ref.read(selectedIdsProvider);
                                      if (val.contains(data.id)) {
                                        final newSet = Set<int>.from(val)..remove(data.id);
                                        ref.read(selectedIdsProvider.notifier).state = newSet;
                                        if (ref.read(selectedIdsProvider.notifier).state.isEmpty) {
                                          ref.read(isIdSelectedForBulkDeleteProvider.notifier).state = false;
                                          _bulkDeleteFABController.reverse();
                                        }
                                      } else {
                                        ref.read(selectedIdsProvider.notifier).state = Set<int>.from(val)..add(data.id!);
                                      }
                                    }
                                  },
                                  child: Column(
                                    children: [
                                      if (ref.watch(isIdSelectedForBulkDeleteProvider)) ...[
                                        Row(
                                          children: [
                                            Icon(
                                              ref.watch(selectedIdsProvider).contains(data.id!)
                                                  ? Icons.check_box
                                                  : Icons.check_box_outline_blank,
                                              color: ref.watch(selectedIdsProvider).contains(data.id)
                                                  ? theme.colorScheme.primary
                                                  : Colors.grey,
                                            ),
                                            SizedBox(width: 15.w),
                                            Expanded(
                                              child: AccountsWidget(
                                                title: data.cardName,
                                                amount: amount,
                                                icon: data.icon,
                                                value: data.progress,
                                                onEdit: () {
                                                  editCardDialogue(data);
                                                },
                                                onDelete: () {
                                                  ref.read(cardsProvider.notifier).deleteCard(data.id!);
                                                },
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                      if (!ref.watch(isIdSelectedForBulkDeleteProvider)) ...[
                                        ListAnimationWidget(
                                          index: index,
                                          offset: const Offset(0, 0.3),
                                          child: AccountsWidget(
                                            title: data.cardName,
                                            amount: amount,
                                            icon: data.icon,
                                            value: data.progress,
                                            onEdit: () {
                                              editCardDialogue(data);
                                            },
                                            onDelete: () => deleteAlert(data),
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                );
                              }),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              )
          ],
        ),
      )
      :Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccountDashboard(
              avgUsage: avg,
              totalBalance: totalAccountBalance,
              theme: theme,
              selectedCurrency: ref.watch(newCurrencyProvider).currency
          ),
          SizedBox(height: 10.h,),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: cardState.isLoading?
              Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
                  :Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 15.h),
                    cardState.cards.isEmpty ? SizedBox.shrink() : Text('All accounts', style: theme.textTheme.titleLarge),
                    SizedBox(height: 10.h),
                    Expanded(
                      child: cardState.cards.isEmpty
                          ? Center(
                        child: Column(
                          children: [
                            SizedBox(height: 50.h),
                            Icon(Icons.credit_card_off_outlined, color: theme.colorScheme.primary, size: 100),
                            SizedBox(height: 24.h),
                            Text('No accounts yet', style: theme.textTheme.titleLarge),
                            SizedBox(height: 8.h),
                            Text('Tap the + button to add a new account', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      )
                          : NotificationListener(
                        onNotification: _handleFabButton,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: cardState.cards.length,
                          itemBuilder: (context, index) {
                            final data = cardState.cards[index];
                            double amount = 0;

                            if (data.amount <= 0 && ref.read(moneyTypeProvider.notifier).state == MoneyType.expense) {
                              amount = 0;
                            } else {
                              amount = data.amount;
                            }

                            return GestureDetector(
                              onLongPress: () {
                                ref.read(isIdSelectedForBulkDeleteProvider.notifier).state = true;
                                final val = ref.read(selectedIdsProvider);
                                ref.read(selectedIdsProvider.notifier).state = Set<int>.from(val)..add(data.id!);
                                if (ref.read(selectedIdsProvider.notifier).state.length == 1) {
                                  _bulkDeleteFABController.forward(from: 0);
                                }
                              },
                              onTap: () {
                                final val = ref.read(selectedIdsProvider);
                                if (val.contains(data.id)) {
                                  final newSet = Set<int>.from(val)..remove(data.id);
                                  ref.read(selectedIdsProvider.notifier).state = newSet;
                                  if (ref.read(selectedIdsProvider.notifier).state.isEmpty) {
                                    ref.read(isIdSelectedForBulkDeleteProvider.notifier).state = false;
                                    _bulkDeleteFABController.reverse();
                                  }
                                } else {
                                  final val = ref.read(selectedIdsProvider);
                                  ref.read(selectedIdsProvider.notifier).state = Set<int>.from(val)..add(data.id!);
                                }
                              },
                              child: Column(
                                children: [
                                  if (ref.watch(isIdSelectedForBulkDeleteProvider)) ...[
                                    Row(
                                      children: [
                                        Center(
                                          child: Icon(
                                            ref.watch(selectedIdsProvider).contains(data.id!) ? Icons.check_box : Icons.check_box_outline_blank,
                                            color: ref.watch(selectedIdsProvider).contains(data.id) ? theme.colorScheme.primary : Colors.grey,
                                          ),
                                        ),
                                        SizedBox(width: 15.w),
                                        Expanded(
                                          child: AccountsWidget(
                                            title: data.cardName,
                                            amount: amount,
                                            icon: data.icon,
                                            value: data.progress,
                                            onEdit: () {
                                              editCardDialogue(data);
                                            },
                                            onDelete: () {
                                              ref.read(cardsProvider.notifier).deleteCard(data.id!);
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                  if (!ref.watch(isIdSelectedForBulkDeleteProvider)) ...[
                                    ListAnimationWidget(
                                      index: index,
                                      offset: Offset(0, 0.3),
                                      child: AccountsWidget(
                                        title: data.cardName,
                                        amount: amount,
                                        icon: data.icon,
                                        value: data.progress,
                                        onEdit: () {
                                          editCardDialogue(data);
                                        },
                                        onDelete: () => deleteAlert(data),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: ref.read(isIdSelectedForBulkDeleteProvider)?
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
      :SlideTransition(
        position: _fabAnimation,
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
              onTap: addCardDialogue,
              borderRadius: BorderRadius.circular(18),
              child: Center(
                child: Icon(
                  Icons.add_card,
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
}


class AnimatedAccountDashboard extends ConsumerWidget {
  final bool isCollapsed;
  const AnimatedAccountDashboard({super.key, required this.isCollapsed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    var theme = Theme.of(context);
    final currency = ref.watch(newCurrencyProvider).currency;
    final total = ref.watch(cardsProvider).cards.fold(0.0, (a, b) => a + b.amount);

    final avg = ref.watch(cardsProvider).cards.isEmpty ? 0.0 : ref.watch(cardsProvider).cards.fold(0.0, (sum, card) => sum + card.progress) / ref.watch(cardsProvider).cards.length;

    return Container(
      color: theme.colorScheme.primary,
      child: ClipRect(
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: isCollapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: AccountDashboard(
              avgUsage: avg,
              totalBalance: total,
              theme: theme,
              selectedCurrency: currency,
            ),
          ),
          secondChild: _buildMinimizedHeader(
            ref: ref,
            context: context,
            currency: currency,
          ),
        ),
      ),
    );
  }

  Widget _buildMinimizedHeader({
    required WidgetRef ref,
    required BuildContext context,
    required String currency,
  }) {
    var theme = Theme.of(context);

    final formattedSpending = NumberFormat.compactCurrency(
      decimalDigits: 0,
      symbol: currency,
    ).format(ref.watch(totalExpenseInAccountProvider));

    final formattedEarning = NumberFormat.compactCurrency(
      decimalDigits: 0,
      symbol: currency,
    ).format(ref.watch(totalIncomeInAccountProvider));

    final avg = ref.watch(cardsProvider).cards.isEmpty ? 0.0 : ref.watch(cardsProvider).cards.fold(0.0, (sum, card) => sum + card.progress) / ref.watch(cardsProvider).cards.length;

    return Container(
      height: 60.h,
      color: theme.colorScheme.primary,
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
                  Icon(Icons.arrow_downward, color: Colors.red.shade300, size: 16.sp),
                  SizedBox(height: 2.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formattedSpending,
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
              margin: EdgeInsets.symmetric(horizontal: 4.w),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_upward, color: Colors.green.shade300, size: 16.sp),
                  SizedBox(height: 2.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formattedEarning,
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
              margin: EdgeInsets.symmetric(horizontal: 4.w),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.show_chart, color: Colors.yellow, size: 16.sp),
                  SizedBox(height: 2.h),
                  Text(
                    '${(avg*100).toStringAsFixed(0)}%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
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

