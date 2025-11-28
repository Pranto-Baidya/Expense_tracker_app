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
    required this.cardModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final formattedAmount = NumberFormat.currency(
      symbol: currency,
      decimalDigits: 2,
    ).format(expenseModel.amount);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Slidable(
        key: ValueKey(expenseModel.id),
        startActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.23,
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              icon: Icons.edit_rounded,
              label: "Edit",
              borderRadius: BorderRadius.circular(14.r),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.23,
          children: [
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: Colors.redAccent.shade200,
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: "Delete",
              borderRadius: BorderRadius.circular(14.r),
            ),
          ],
        ),
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
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(
                      expenseModel.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${expenseModel.moneyType.name == 'income' ? '+' : '-'} $formattedAmount',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: getColor(expenseModel.moneyType),
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 18.h),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text("Category:",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            )),
                        SizedBox(width: 6.w),
                        Text(
                          expenseModel.category,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Text("Account:",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            )),
                        SizedBox(width: 6.w),
                        Icon(
                          cardModel.icon,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          cardModel.cardName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getColor(MoneyType moneyType) {
    switch (moneyType) {
      case MoneyType.expense:
        return Colors.redAccent;
      case MoneyType.income:
        return Colors.green.shade600;
    }
  }
}

