import 'package:flutter/cupertino.dart';

class AnimatedNavIcon extends StatelessWidget {
  final IconData icon;
  final bool isNavSelected;
  final Color color;
  final double size;
  const AnimatedNavIcon({super.key, required this.icon, required this.isNavSelected, required this.color, this.size=25});

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: isNavSelected? 0.500 : 0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedScale(
          scale: isNavSelected? 1.15 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Icon(icon,color: color,size: size,),
      ),
    );
  }
}
