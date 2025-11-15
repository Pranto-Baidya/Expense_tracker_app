

import 'package:expense_tracker_app/riverpod/theme_riverpod/theme_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomAppbar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? action;
  final double? toolbarHeight;
  const CustomAppbar({required this.title,this.action, this.toolbarHeight=kToolbarHeight,super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    var theme = Theme.of(context);
    return AppBar(
      title: Text(title,style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary),),
      centerTitle: false,
      titleSpacing: 0,
      toolbarHeight: toolbarHeight ?? 55,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: theme.appBarTheme.backgroundColor,
      iconTheme: theme.iconTheme,
      actions: action,
      systemOverlayStyle: SystemUiOverlayStyle(
        systemNavigationBarColor: theme.navigationBarTheme.backgroundColor,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark? Brightness.light:Brightness.dark
      ),
    );
  }

  @override
  Size get preferredSize {
    if(toolbarHeight!=null) {
      return Size.fromHeight(toolbarHeight!);
    }
    return Size.fromHeight(kToolbarHeight);
    }
}
