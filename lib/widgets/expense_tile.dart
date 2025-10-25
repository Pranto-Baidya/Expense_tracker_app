import 'package:expense_tracker_app/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ExpenseTile extends StatelessWidget {
  final ExpenseModel expenseModel;
  final String currency;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExpenseTile({
    super.key,
    required this.expenseModel,
    required this.icon,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
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
              borderRadius: BorderRadius.circular(15.r),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) => onDelete(),
              backgroundColor: AppColors.lightError,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: BorderRadius.circular(15.r),
            ),
          ],
        ),
        child: Card(
          color: theme.cardColor,
          elevation: 1,
          shadowColor: theme.dividerColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.r),
            ),
            contentPadding: EdgeInsets.all(10),
            leading: Icon(icon, color: theme.iconTheme.color),
            title: Text(
              expenseModel.title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w400),
            ),
            subtitle: Text(
              expenseModel.category,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400),
            ),
            trailing: Text(
              '- $currency ${expenseModel.amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleSmall,
            ),
          ),
        ),
      ),
    );
  }
}
