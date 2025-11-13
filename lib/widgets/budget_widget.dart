import 'package:expense_tracker_app/models/budget_model.dart';
import 'package:expense_tracker_app/screens/budgets_screen.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:expense_tracker_app/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';


class BudgetWidget extends ConsumerWidget {
  final BudgetModel budget;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const BudgetWidget({required this.budget, required this.onEdit,required this.onDelete, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = Theme.of(context);
    double progress = (budget.spent / budget.budget).clamp(0, 1);
    double remaining = budget.remaining;

    final now = DateTime.now();
    final selectedDate = ref.watch(selectedDateProviderForBudgets);

    final isPastBudget = selectedDate.year < now.year || (selectedDate.year==now.year && selectedDate.month<now.month);

    if(remaining<1){
      remaining = 0;
    }

    if(budget.spent==0){
      remaining = budget.budget;
    }

    final formattedTotal = NumberFormat.currency(
      symbol: ref.read(currencyProvider),
      decimalDigits: 2,
    ).format(budget.budget);

    final formattedSpent = NumberFormat.currency(
      symbol: ref.read(currencyProvider),
      decimalDigits: 2,
    ).format(budget.spent);

    final formattedRemaining = NumberFormat.currency(
      symbol: ref.read(currencyProvider),
      decimalDigits: 2,
    ).format(remaining);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: theme.dividerColor.withOpacity(0.3))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPastBudget)
            Badge(
              label: const Text('Budget expired'),
              backgroundColor: Colors.redAccent,
              textColor: Colors.white,
              offset: const Offset(0, 2),
              child: const SizedBox(),
            ),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary,
                child: Icon(
                  getIcons(budget.categoryName),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  budget.categoryName,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              PopupMenuButton(
                popUpAnimationStyle:
                const AnimationStyle(curve: Curves.easeInOut),
                menuPadding: const EdgeInsets.all(20),
                color: theme.cardColor,
                icon: Icon(Icons.more_horiz, color: theme.iconTheme.color),
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      onTap: onEdit,
                      child: Text('Change budget',
                          style: theme.textTheme.titleMedium),
                    ),
                    PopupMenuItem(
                      onTap: onDelete,
                      child: Text('Remove budget',
                          style: theme.textTheme.titleMedium),
                    ),
                  ];
                },
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: $formattedTotal',
                  style: theme.textTheme.bodyMedium!
                      .copyWith(fontWeight: FontWeight.w500)),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text('Spent: $formattedSpent',
                    style: theme.textTheme.bodyMedium!
                        .copyWith(color: Colors.orange)),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'Remaining: $formattedRemaining',
            style: theme.textTheme.titleSmall!.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(30.r),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: progress,
              color: progress >= 0.8 && progress < 1
                  ? Colors.amber
                  : progress == 1
                  ? Colors.redAccent
                  : theme.colorScheme.primary,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          SizedBox(height: 5.h),
          if (remaining == 0 && budget.spent >= budget.budget)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "*Limit exceeded",
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: Colors.redAccent),
                ),
              ],
            ),
        ],
      ),
    );

  }

  IconData getIcons(String category) {
    switch (category) {
      case 'Personal':
        return Icons.person;
      case 'Family':
        return Icons.groups;
      case 'Food':
        return Icons.fastfood_rounded;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Transport':
        return Icons.directions_car;
      case 'Phone':
        return Icons.phone_iphone;
      case 'Bills':
        return Icons.receipt_long;
      case 'Rent':
        return Icons.maps_home_work;
      default:
        return Icons.control_point_duplicate;
    }
  }
}
