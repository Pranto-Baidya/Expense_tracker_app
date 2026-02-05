import 'package:expense_tracker_app/models/history_model.dart';
import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:expense_tracker_app/riverpod/category_riverpod/category_riverpod.dart';
import 'package:expense_tracker_app/riverpod/currency_riverpod/currency_pref.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/riverpod/history_riverpod/history_riverpod.dart';
import 'package:expense_tracker_app/riverpod/theme_riverpod/theme_riverpod.dart';
import 'package:expense_tracker_app/riverpod/trash_provider/trash_provider.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:expense_tracker_app/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../models/trash_model.dart';
import '../../riverpod/budget_riverpod/budget_riverpod.dart';
import '../../widgets/listAnimation_widget.dart';

final selectedFilterProvider = StateProvider<Set<String>>((ref) => {'all'});
final searchClickProvider = StateProvider<bool>((ref) => false);

class TransactionHistory extends ConsumerStatefulWidget {
  const TransactionHistory({super.key});

  @override
  _TransactionHistoryState createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends ConsumerState<TransactionHistory>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _scaleAnim;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnim = Tween<double>(begin: -20.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(historyProvider.notifier).getAllHistoryList();
      await ref.read(trashProvider.notifier).getAllTrashData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void restoreFromTrash(TrashModel trashItem) async {
    final historyItem = trashItem.toHistoryModel();
    final record = trashItem.toExpenseModel();
    await ref.read(expenseProvider.notifier).insertExpense(record);
    await ref.read(historyProvider.notifier).addHistory(historyItem);

    ref.read(enteredAmountProvider.notifier).state = record.amount;
    ref.read(selectedAccountProvider.notifier).state = record.accountId;
    ref.read(moneyTypeProvider.notifier).state = record.moneyType;
    ref.read(categoryPickerProvider.notifier).state = record.category;
    ref.read(cardsProvider.notifier).calculateTotalAmountInAccount();

    if (record.moneyType == MoneyType.expense) {
      ref.read(budgetProvider.notifier).calculateAmount(record.date);
    }
    await ref.read(trashProvider.notifier).permanentlyDelete(trashItem.id!);
  }

  void permanentlyDeleteFromTrash(TrashModel trashItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanent Delete',style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 20),),
        content: Text(
          'This will permanently delete this item. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(trashProvider.notifier).permanentlyDelete(trashItem.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red,elevation: 0),
            child: Text('Delete Forever',style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    bool isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    final selectedState = ref.watch(selectedFilterProvider);
    final selectedNotifier = ref.read(selectedFilterProvider.notifier);

    final isSearchClicked = ref.watch(searchClickProvider);
    final searchClickNotifier = ref.read(searchClickProvider.notifier);

    final historyState = ref.watch(historyProvider);
    final trashState = ref.watch(trashProvider);

    final filtered = () {
      if (selectedState.first == 'trash') {
        final trashItems = trashState.allTrash;
        return trashItems.map((i) => i.toHistoryModel()).toList();
      }
      else {
        return historyState.histories.where((hist) {
          if (selectedState.first == 'income') {
            return hist.moneyType.name == selectedState.first;
          }
          else if (selectedState.first == 'expense') {
            return hist.moneyType.name == selectedState.first;
          }
          else if (selectedState.first == 'all') {
            return true;
          }
          return false;
        }).toList();
      }
    }();

    final groupedData = _groupedMonthlyData(filtered);

    final sortedMonths = groupedData.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('History', style: theme.textTheme.titleLarge),
        iconTheme: theme.iconTheme,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withOpacity(0.25),
                width: 1,
              ),
            ),
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          systemNavigationBarColor: theme.navigationBarTheme.backgroundColor,
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        actions: [
          Visibility(
            visible: selectedState.first!='trash' && !isSearchClicked,
            child: IconButton(
                onPressed: (){
                  showGeneralDialog(
                      context: context,
                      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
                      barrierColor: Colors.black45,
                      transitionDuration: const Duration(milliseconds: 500),
                      transitionBuilder: (context,anim,_,child){
                        return ScaleTransition(
                          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                          child: child,
                        );
                      },
                      pageBuilder: (context,_,_){
                        return Dialog(
                          backgroundColor: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                                        color: Colors.redAccent.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Empty history?',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'All histories will be cleared, click on clear to confirm.',
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
                                    SizedBox(width: 12.w,),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: (){
                                          ref.read(historyProvider.notifier).clearAllHistory();
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
                                          'Clear',
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
                },
                icon: Icon(Icons.delete_outline,color: theme.iconTheme.color,size: 26,)
            ),
          ),
          Visibility(
            visible: selectedState.first=='trash' && !isSearchClicked,
            child: IconButton(
                onPressed: (){
                  showGeneralDialog(
                      context: context,
                      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
                      barrierColor: Colors.black45,
                      transitionDuration: const Duration(milliseconds: 500),
                      transitionBuilder: (context,anim,_,child){
                        return ScaleTransition(
                          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                          child: child,
                        );
                      },
                      pageBuilder: (context,_,_){
                        return Dialog(
                          backgroundColor: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                                        color: Colors.redAccent.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Empty trash?',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'All trashes will be cleared, click on clear to confirm.',
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
                                    SizedBox(width: 12.w,),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: (){
                                          ref.read(trashProvider.notifier).emptyTrash();
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
                                          'Clear',
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
                },
                icon: Icon(Icons.delete_outline,color: theme.iconTheme.color,size: 26,)
            ),
          ),
          Visibility(
            visible: selectedState.first=='trash' && !isSearchClicked,
            child: IconButton(
                onPressed: (){
                  showGeneralDialog(
                      context: context,
                      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
                      barrierColor: Colors.black45,
                      transitionDuration: const Duration(milliseconds: 500),
                      transitionBuilder: (context,anim,_,child){
                        return ScaleTransition(
                            scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                            child: child,
                        );
                      },
                      pageBuilder: (context,_,_){
                        return Dialog(
                          backgroundColor: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.info_outline,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Trash info',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Trashes older than 30 days will automatically be cleared.',
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
                                          'Got it',
                                          style: Theme.of(context).textTheme.titleMedium,
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
                },
                icon: Icon(Icons.info_outline,color: theme.iconTheme.color,size: 26,)
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: AnimatedRotation(
              turns: isSearchClicked ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: IconButton(
                onPressed: () {
                  if (!isSearchClicked) {
                    searchClickNotifier.state = true;
                    _animationController.forward();
                  } else {
                    _searchController.clear();
                    searchClickNotifier.state = false;
                    _animationController.reverse();
                  }
                },
                icon: Icon(
                  isSearchClicked ? Icons.close : Icons.search,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedSize(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: !isSearchClicked ? SizedBox(height: 15.h) : SizedBox.shrink(),
          ),
          Visibility(
            visible: !isSearchClicked,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(30.r),
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
                      _buildTabButton('All', 'all', theme, selectedState, selectedNotifier),
                      _buildTabButton('Income', 'income', theme, selectedState, selectedNotifier),
                      _buildTabButton('Expense', 'expense', theme, selectedState, selectedNotifier),
                      _buildTabButton('Trash', 'trash', theme, selectedState, selectedNotifier),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isSearchClicked ? SizedBox(height: 15.h) : SizedBox.shrink(),
          ),
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Visibility(
                visible: isSearchClicked || _animationController.isAnimating,
                child: Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.r),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.1 * _fadeAnim.value),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: theme.cardColor,
                              hintText: 'Search transactions...',
                              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: theme.colorScheme.primary,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: Icon(
                                  Icons.clear,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.r),
                                borderSide: BorderSide(
                                  color: theme.dividerColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.r),
                                borderSide: BorderSide(
                                  color: theme.dividerColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.r),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 16.h,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (!isSearchClicked) ...[
            if (historyState.isLoading || trashState.isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                ),
              )
            else if (filtered.isEmpty)
              Center(
                child: Column(
                  children: [
                    SizedBox(height: 200.h),
                    selectedState.first=='trash'?
                    Icon(
                      Icons.cleaning_services_outlined,
                      size: 100,
                      color: theme.colorScheme.primary,
                    )
                    :Icon(
                      Icons.history_toggle_off,
                      size: 100,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(height: 10.h),
                    selectedState.first=='trash'?
                    Text(
                      'Trash is empty',
                      style: theme.textTheme.titleMedium,
                    ):
                    Text(
                      'No history to show',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: sortedMonths.length,
                  itemBuilder: (context, index) {

                    final date = sortedMonths[index];
                    final histMonth = groupedData[date]!;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                      child: Column(
                        children: [
                          SizedBox(height: 15.h),
                          Row(
                            children: [
                              Text(
                                DateFormat('MMMM, yyyy').format(date),
                                style: theme.textTheme.titleLarge,
                              ),
                            ],
                          ),
                          SizedBox(height: 15.h),
                          ...histMonth.map((data) {
                            final selectedAcc = ref.read(cardsProvider).cards.firstWhere((i) => i.id == data.accountId,);
                            final selectedCategory = ref.read(categoryProvider).allCategories.firstWhere((i) => i.categoryName == data.category,);

                            final formattedAmount = NumberFormat.currency(
                              symbol: ref.read(newCurrencyProvider).currency,
                              decimalDigits: 2,
                            ).format(data.amount);

                            TrashModel? correspondingTrash;
                            if (selectedState.first == 'trash') {
                              try {
                                correspondingTrash = trashState.allTrash.firstWhere(
                                      (trash) =>
                                  trash.title == data.title &&
                                      trash.date.year == data.date.year &&
                                      trash.date.month == data.date.month &&
                                      trash.date.day == data.date.day &&
                                      trash.amount == data.amount &&
                                      trash.category == data.category,
                                );
                              } catch (e) {
                                //
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: ListAnimationWidget(
                                index: histMonth.indexOf(data),
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
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 8.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selectedCategory.color.withOpacity(0.08),
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16.r),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 14.sp,
                                              color: selectedCategory.color,
                                            ),
                                            SizedBox(width: 6.w),
                                            Text(
                                              DateFormat('MMMM dd, yyyy').format(data.date),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: selectedCategory.color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Spacer(),
                                            Icon(
                                              Icons.access_time,
                                              size: 14.sp,
                                              color: selectedCategory.color,
                                            ),
                                            SizedBox(width: 6.w),
                                            Text(
                                              DateFormat('hh:mm a').format(data.date),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: selectedCategory.color,
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
                                                color: selectedCategory.color.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(12.r),
                                              ),
                                              child: Icon(
                                                selectedCategory.icon,
                                                color: selectedCategory.color,
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
                                                        selectedAcc.icon,
                                                        size: 16.sp,
                                                        color: theme.iconTheme.color?.withOpacity(0.6),
                                                      ),
                                                      SizedBox(width: 6.w),
                                                      Text(
                                                        selectedAcc.cardName,
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
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12.w,
                                                vertical: 8.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: data.moneyType == MoneyType.income
                                                    ? Colors.green.withOpacity(0.08)
                                                    : Colors.red.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(10.r),
                                                border: Border.all(
                                                  color: data.moneyType == MoneyType.income
                                                      ? Colors.green.withOpacity(0.2)
                                                      : Colors.red.withOpacity(0.2),
                                                ),
                                              ),
                                              child: data.moneyType == MoneyType.income
                                                  ? Text(
                                                '+$formattedAmount',
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                                  : Text(
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
                                      if (selectedState.first == 'trash' && correspondingTrash != null) ...[
                                        Divider(
                                          color: theme.dividerColor.withOpacity(0.15),
                                          thickness: 0.5,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8.0,
                                            right: 8.0,
                                            bottom: 12.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () {
                                                    restoreFromTrash(correspondingTrash!);
                                                  },
                                                  icon: Icon(Icons.restore, size: 18),
                                                  label: Text('Restore'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.green,
                                                    side: BorderSide(color: Colors.green),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () {
                                                    permanentlyDeleteFromTrash(correspondingTrash!);
                                                  },
                                                  icon: Icon(
                                                    Icons.delete_forever_outlined,
                                                    size: 18,
                                                  ),
                                                  label: Text('Delete'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                    side: BorderSide(color: Colors.red),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      Visibility(
                                        visible: selectedState.first!='trash',
                                        child: Divider(
                                          color: theme.dividerColor.withOpacity(0.15),
                                          thickness: 0.5,
                                        ),
                                      ),
                                      Visibility(
                                        visible: selectedState.first!='trash',
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8.0,
                                            right: 8.0,
                                            bottom: 12.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () {
                                                    ref.read(historyProvider.notifier).deleteHist(data.id!);
                                                  },
                                                  icon: Icon(
                                                    Icons.delete_forever_outlined,
                                                    size: 18,
                                                  ),
                                                  label: Text('Delete history'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                    side: BorderSide(color: Colors.red),
                                                  ),
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
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabButton(
      String label,
      String value,
      ThemeData theme,
      Set<String> selectedState,
      StateController<Set<String>> selectedNotifier,
      ) {
    final isSelected = selectedState.contains(value);

    return GestureDetector(
      onTap: () {
        selectedNotifier.state = {value};
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 23.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? switch (value) {
            'income' => Colors.green,
            'expense' => Colors.redAccent,
            'trash' => Colors.orange,
            _ => theme.colorScheme.primary,
          }
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: switch (value) {
                'income' => Colors.green.withOpacity(0.3),
                'expense' => Colors.redAccent.withOpacity(0.3),
                'trash' => Colors.orange.withOpacity(0.3),
                _ => theme.colorScheme.primary.withOpacity(0.3),
              },
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14.sp,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Map<DateTime, List<HistoryModel>> _groupedMonthlyData(List<HistoryModel> hist) {
    Map<DateTime, List<HistoryModel>> map = {};

    for (var t in hist) {
      final month = DateTime(t.date.year, t.date.month);
      map.putIfAbsent(month, () => []).add(t);
    }
    return map;
  }
}