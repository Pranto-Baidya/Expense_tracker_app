

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomAppbar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? action;
  const CustomAppbar({required this.title,this.action, super.key});

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    var theme = Theme.of(context);
    return AppBar(
      title: Text(title,style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary),),
      centerTitle: false,
      toolbarHeight: 55,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: theme.appBarTheme.backgroundColor,
      iconTheme: theme.iconTheme,
      actions: action,
      systemOverlayStyle: SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
