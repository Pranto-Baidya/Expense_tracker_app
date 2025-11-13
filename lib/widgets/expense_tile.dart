import 'package:expense_tracker_app/models/card_model.dart';
import 'package:expense_tracker_app/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../screens/records_screen.dart';

class ExpenseTile extends StatelessWidget {
  final ExpenseModel expenseModel;
  final String currency;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final CardModel cardModel;

  const ExpenseTile({
    super.key,
    required this.expenseModel,
    required this.icon,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
    required this.cardModel
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    final formattedAmount = NumberFormat.currency(
      symbol: currency,
      decimalDigits: 2,
    ).format(expenseModel.amount);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Slidable(
        key: ValueKey(expenseModel.id),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) => onEdit(),
              backgroundColor: AppColors.darkAccent,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
              borderRadius: BorderRadius.only(topLeft: Radius.circular(15.r),bottomLeft: Radius.circular(15.r)),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) => onDelete(),
              backgroundColor: Colors.redAccent.shade200,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: BorderRadius.only(topRight: Radius.circular(15.r),bottomRight: Radius.circular(15.r)),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: theme.dividerColor.withOpacity(0.3))
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 8.0.w, right: 12.w),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        icon,
                        color: Colors.white,
                      ),
                    )
                  ),
                  Text(
                    expenseModel.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacer(),
                  Padding(
                    padding: EdgeInsets.only(right: 8.0.w),
                    child: Text(
                      '${expenseModel.moneyType.name == 'income' ? '+' : '-'} $formattedAmount',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: getColor(expenseModel.moneyType),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h,),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Category:',style: theme.textTheme.bodyMedium,),
                        SizedBox(width: 5.w,),
                        Text(
                          expenseModel.category,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h,),
                    Row(
                      children: [
                        Text('Account:',style: theme.textTheme.bodyMedium,),
                        SizedBox(width: 5.w,),
                        Row(
                          children: [
                            Icon(cardModel.icon,color: theme.colorScheme.primary,size: 22,),
                            SizedBox(width: 5.w,),
                            Text(
                              cardModel.cardName,
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h,),
            ],
          ),
        ),
      ),
    );
  }

  Color getColor(MoneyType moneyType) {
    switch (moneyType) {
      case MoneyType.expense:
        return Colors.red;
      case MoneyType.income:
        return Colors.green;
    }
  }
}
