

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
  const AccountsWidget({required this.title,required this.amount,required this.icon,required this.onEdit,required this.onDelete,super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
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
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r),),
          leading: CircleAvatar(
            radius: 20,
            child: Icon(icon,color: Colors.white,),
          ),
          title: Text(title,style: theme.textTheme.titleMedium,),
          subtitle: Row(
            children: [
              Text('Balance: ',style: theme.textTheme.titleSmall,),
              Text('\$$amount',style: theme.textTheme.titleSmall,)
            ],
          ),
          trailing: PopupMenuButton(
              popUpAnimationStyle: AnimationStyle(
                curve: Curves.easeInOut
              ),
              menuPadding: EdgeInsets.all(20),
              color: theme.cardColor,
              icon: Icon(Icons.more_horiz,color: theme.iconTheme.color,),
              itemBuilder: (context){
                return[
                  PopupMenuItem(
                      onTap: onEdit,
                      child: Text('Edit',style: theme.textTheme.titleMedium,)
                  ),
                  PopupMenuItem(
                      onTap: onDelete,
                      child: Text('Delete',style: theme.textTheme.titleMedium,)
                  ),
                ];
              },
          )
        ),
      ),
    );
  }
}
