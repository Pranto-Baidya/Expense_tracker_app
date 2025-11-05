

import 'package:expense_tracker_app/riverpod/card_riverpod/card_riverpod.dart';
import 'package:expense_tracker_app/riverpod/expense_riverpod/expense_riverpod.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:expense_tracker_app/widgets/app_colors.dart';
import 'package:expense_tracker_app/widgets/expense_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/card_model.dart';

final hasSearchedProvider = StateProvider<bool>((ref)=>false);

class SearchRecordsScreen extends ConsumerStatefulWidget {
  const SearchRecordsScreen({super.key});

  @override
  _SearchRecordsScreenState createState() => _SearchRecordsScreenState();
}

class _SearchRecordsScreenState extends ConsumerState<SearchRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();

  IconData icons(String category){
    switch(category){
      case 'Personal':
        return Icons.person_outline;
      case 'Family':
        return Icons.groups_outlined;
      case 'Food':
        return Icons.fastfood_outlined;
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      case 'Transport':
        return Icons.directions_car_outlined;
      case 'Phone':
        return Icons.phone_android_outlined;
      case 'Bills':
        return Icons.receipt_long_outlined;
      case 'Rent':
        return Icons.maps_home_work_outlined;
      case 'Other':
        return Icons.control_point_duplicate;
      default: return Icons.control_point_duplicate;

    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    var theme = Theme.of(context);
    final searchState = ref.watch(expenseProvider);

    final hasSearched = ref.watch(hasSearchedProvider);
    final hasSearchedNotifier = ref.read(hasSearchedProvider.notifier);

    return PopScope(
      onPopInvokedWithResult: (_,_){
        ref.read(expenseProvider.notifier).searchForRecords('');
        hasSearchedNotifier.state = false;
      },
      canPop: true,
      child: Scaffold(
       backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          toolbarHeight: 80,
          titleSpacing: 0,
          iconTheme: theme.iconTheme,
          title: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: TextField(
              autofocus: true,
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for records',
                hintStyle: theme.textTheme.titleMedium?.copyWith(color: AppColors.hintTextColor)
              ),
              onChanged: (value){
                ref.read(expenseProvider.notifier).searchForRecords(value);
                hasSearchedNotifier.state = true;
              },
            ),
          ),
        ),
        body: Builder(
            builder: (context){
              if(hasSearched && searchState.searchRecords.isEmpty && _searchController.text.isNotEmpty){
                return Center(child: Padding(
                  padding: const EdgeInsets.only(right: 8.0,left: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sentiment_very_dissatisfied,color: theme.colorScheme.primary, size: 100,),
                      SizedBox(height: 10.h,),
                      Text('No match found',style: theme.textTheme.titleMedium,softWrap: true,),
                    ],
                  ),
                ));
              }
              else if(searchState.searchRecords.isEmpty){
                return Center(child: Padding(
                  padding: const EdgeInsets.only(right: 8.0,left: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.manage_search,color: theme.colorScheme.primary, size: 100,),
                      SizedBox(height: 10.h,),
                      Text('Search records by',style: theme.textTheme.titleMedium,softWrap: true,),
                      Text('notes, category name or amount',style: theme.textTheme.titleMedium,softWrap: true,),
                    ],
                  ),
                ));
              }
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
                child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchState.searchRecords.length,
                    itemBuilder: (context,index){
                      final data = searchState.searchRecords[index];
                      return ExpenseTile(
                          expenseModel: data,
                          icon: icons(data.category),
                          currency: ref.read(currencyProvider),
                          onEdit: (){},
                          onDelete: (){},
                          cardModel: ref.watch(cardsProvider).cards.firstWhere((card)=>card.id==data.accountId,
                            orElse: () => CardModel(
                            id: -1,
                            cardName: 'Unknown',
                            icon: Icons.help_outline,
                            amount: 0,
                          ),
                          )
                      );
                    }
                ),
              );
            }
        ),
      ),
    );
  }
}
