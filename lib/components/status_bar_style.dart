import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatusBarStyle extends StatelessWidget {
  final Widget child;
  const StatusBarStyle({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: iconBrightness,
      ),
      child: child,
    );
  }
}
