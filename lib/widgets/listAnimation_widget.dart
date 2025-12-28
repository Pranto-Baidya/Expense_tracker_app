
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ListAnimationWidget extends ConsumerStatefulWidget {
  final Widget child;
  final int index;
  final Offset offset;
  const ListAnimationWidget({required this.child, required this.index,required this.offset,super.key});

  @override
  _ListAnimationWidgetState createState() => _ListAnimationWidgetState();
}

class _ListAnimationWidgetState extends ConsumerState<ListAnimationWidget> with SingleTickerProviderStateMixin{

  late AnimationController _animationController;

  late Animation<double> _fadeAnimation;

  late Animation<Offset> _slideAnimation;

  bool isDisposed = false;

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300)
    );
    super.initState();

    _fadeAnimation = Tween<double>(begin: 0,end: 1).animate(CurvedAnimation(parent: _animationController, curve: Curves.fastOutSlowIn));

    _slideAnimation = Tween<Offset>(begin: widget.offset,end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: Curves.fastOutSlowIn));

    Future.delayed(Duration(milliseconds: 100*widget.index),(){
      if(!isDisposed && mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
     isDisposed = true;
    _animationController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
        ),
    );
  }
}
