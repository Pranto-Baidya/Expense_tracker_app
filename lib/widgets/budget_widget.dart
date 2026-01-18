import 'package:expense_tracker_app/models/budget_model.dart';
import 'package:expense_tracker_app/screens/budgets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../riverpod/currency_riverpod/currency_pref.dart';


class BudgetWidget extends ConsumerStatefulWidget {
  final Color bgColor;
  final IconData icon;
  final BudgetModel budget;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDetailsTap;
  const BudgetWidget({required this.bgColor, required this.icon,required this.budget, required this.onEdit, required this.onDelete,required this.onDetailsTap,super.key});

  @override
  _BudgetWidgetState createState() => _BudgetWidgetState();
}

class _BudgetWidgetState extends ConsumerState<BudgetWidget>{

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    double progress = (widget.budget.spent / widget.budget.budget).clamp(0, 1);
    double remaining = widget.budget.remaining;

    final now = DateTime.now();
    final selectedDate = ref.watch(selectedDateProviderForBudgets);

    final isPastBudget = selectedDate.year < now.year || (selectedDate.year==now.year && selectedDate.month<now.month);

    if(remaining<1){
      remaining = 0;
    }

    if(widget.budget.spent==0){
      remaining = widget.budget.budget;
    }

    final formattedTotal = NumberFormat.currency(
      symbol: ref.read(newCurrencyProvider).currency,
      decimalDigits: 2,
    ).format(widget.budget.budget);

    final formattedSpent = NumberFormat.currency(
      symbol: ref.read(newCurrencyProvider).currency,
      decimalDigits: 2,
    ).format(widget.budget.spent);

    final formattedRemaining = NumberFormat.currency(
      symbol: ref.read(newCurrencyProvider).currency,
      decimalDigits: 2,
    ).format(remaining);

    return Visibility(
      visible: isPastBudget,
      replacement: Container(
        margin: EdgeInsets.symmetric(vertical: 10.h),
        padding: EdgeInsets.all(16.w),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 45.w,
                  width: 45.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    gradient: LinearGradient(
                      colors: [
                        widget.bgColor.withOpacity(0.9),
                        widget.bgColor.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.bgColor.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 22),
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: Text(
                    widget.budget.categoryName,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 20),
                  ),
                ),
                Visibility(
                  visible: !ref.watch(isSelectedBudgetForBulkDeleteProvider),
                  replacement: SizedBox.shrink(),
                  child: PopupMenuButton(
                    popUpAnimationStyle:
                    const AnimationStyle(curve: Curves.easeInOut),
                    color: theme.cardColor,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
                    menuPadding: EdgeInsets.all(5),
                    itemBuilder: (context) {
                      return [
                        if(!isPastBudget)...[
                          PopupMenuItem(
                            onTap: widget.onDetailsTap,
                            child: Row(
                              children: [
                                Icon(Icons.info_outlined, size: 18,color: widget.bgColor,),
                                SizedBox(width: 12),
                                Text("Details", style: theme.textTheme.titleSmall?.copyWith(color: widget.bgColor)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            onTap: widget.onEdit,
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 12),
                                Text("Edit", style: theme.textTheme.titleSmall),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            onTap: widget.onDelete,
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
                        ]
                        else...[
                          PopupMenuItem(
                            onTap: widget.onDetailsTap,
                            child: Row(
                              children: [
                                Icon(Icons.info_outlined, size: 18,color: widget.bgColor,),
                                SizedBox(width: 12),
                                Text("Details", style: theme.textTheme.titleSmall?.copyWith(color: widget.bgColor)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            onTap: widget.onDelete,
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
                         ]
                      ];
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
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
            if (remaining == 0 && widget.budget.spent >= widget.budget.budget)
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
      ),
      child: Badge(
        padding: EdgeInsets.only(left: 10,right: 10,top: 3,bottom: 3),
        label: const Text('Budget expired'),
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        offset: const Offset(0, 2),
        alignment: Alignment.topLeft,
        child: Column(
          children: [
            SizedBox(height: 5.h,),
            Container(
              margin: EdgeInsets.symmetric(vertical: 10.h),
              padding: EdgeInsets.all(16.w),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 45.w,
                        width: 45.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.r),
                          gradient: LinearGradient(
                            colors: [
                              widget.bgColor.withOpacity(0.9),
                              widget.bgColor.withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.bgColor.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 22),
                      ),
                      SizedBox(width: 15.w),
                      Expanded(
                        child: Text(
                          widget.budget.categoryName,
                          style: theme.textTheme.titleMedium?.copyWith(fontSize: 20),
                        ),
                      ),
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
                                onTap: widget.onDetailsTap,
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outlined, size: 18, color: widget.bgColor),
                                    SizedBox(width: 12),
                                    Text("Details", style: theme.textTheme.titleSmall?.copyWith(color: widget.bgColor)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                onTap: widget.onDelete,
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    SizedBox(width: 12),
                                    Text(
                                      "Delete",
                                      style: theme.textTheme.titleSmall?.copyWith(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ];
                          }

                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
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
                      color: progress >= 0.6 && progress < 1
                          ? Colors.amber
                          : progress == 1
                          ? Colors.redAccent
                          : theme.colorScheme.primary,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  if (remaining == 0 && widget.budget.spent >= widget.budget.budget)
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
            ),
          ],
        ),
      ),
    );

  }
}



