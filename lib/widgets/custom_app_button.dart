
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomAppButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;
  final double? width;
  final double? height;
  const CustomAppButton({super.key,required this.onPressed, required this.title,this.width,this.height});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(width?.w ?? double.infinity.w, height?.h ?? 50.h),
          backgroundColor: theme.colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
          elevation: 0
        ),
        child: Text(title,style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),)
    );
  }
}
