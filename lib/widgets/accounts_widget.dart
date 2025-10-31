import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              offset: const Offset(0, -2),
              blurRadius: 10,
              spreadRadius: 0,
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
                          Text(
                            '\$$amount',
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
                    icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
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
                      color: value==1?Colors.red:theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 15.w,),
                  Text('${((value ?? 0) * 100).toStringAsFixed(0)}%',style: theme.textTheme.titleSmall,)

                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
