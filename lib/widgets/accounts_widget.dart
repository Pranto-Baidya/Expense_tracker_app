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
          ] : [
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 45.w,
                    width: 45.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.9),
                          theme.colorScheme.primary.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  SizedBox(width: 20.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.h,),
                      Text(
                        title,
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  Spacer(),
                  PopupMenuButton(
                    popUpAnimationStyle:
                    const AnimationStyle(curve: Curves.easeInOut),
                    color: theme.cardColor,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem(
                          onTap: onEdit,
                          child: Row(
                            children: [
                              Icon(Icons.mode_edit_outline_outlined, size: 18),
                              SizedBox(width: 12),
                              Text(
                                "Edit",
                                style: theme.textTheme.titleSmall
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          onTap: onDelete,
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              SizedBox(width: 12),
                              Text(
                                "Delete",
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
              SizedBox(height: 15.h,),
              Row(
                children: [
                  Text(
                    'Balance: ',
                    style: theme.textTheme.titleSmall,
                  ),
                  SizedBox(width: 5.w,),
                  Text(formattedBalance,
                    style: theme.textTheme.titleSmall,
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
