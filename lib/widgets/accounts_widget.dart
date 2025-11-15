import 'package:expense_tracker_app/riverpod/currency_riverpod/currency_pref.dart';
import 'package:expense_tracker_app/screens/records_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class AccountsWidget extends ConsumerWidget {
  final String title;
  final double amount;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final double? value;

  const AccountsWidget({
    required this.title,
    required this.amount,
    required this.icon,
    required this.onEdit,
    required this.onDelete,
    this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final formattedBalance = NumberFormat.currency(
      symbol: ref.read(newCurrencyProvider).currency,
      decimalDigits: 2
    ).format(amount);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: theme.dividerColor.withOpacity(0.3))
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    child: Icon(icon, color: Colors.white),
                  ),
                  SizedBox(width: 16.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Text(
                            'Balance: ',
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(formattedBalance,
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Spacer(),
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
                          child: Text('Edit', style: theme.textTheme.titleMedium),
                        ),
                        PopupMenuItem(
                          onTap: onDelete,
                          child: Text('Delete', style: theme.textTheme.titleMedium),
                        ),
                      ];
                    },
                  ),
                ],
              ),
              SizedBox(height: 10.h,),
              Row(
                children: [
                  Text('Usage:',style: theme.textTheme.titleSmall,),
                  SizedBox(width: 15.w,),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: value,
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: Colors.grey.shade200,
                      color: value==1?Colors.redAccent:(value!>=0.8&&value!<1)?Colors.amber:theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 15.w,),
                  Padding(
                    padding: const EdgeInsets.only(right: 7.0),
                    child: Text('${((value ?? 0) * 100).toStringAsFixed(0)}%',style: theme.textTheme.titleSmall,),
                  )

                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
