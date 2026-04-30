import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:thisjowi/core/appColors.dart';

class PrivacyOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PrivacyOverlay({
    super.key, 
    required this.child, 
    this.enabled = true
  });

  @override
  State<PrivacyOverlay> createState() => _PrivacyOverlayState();
}

class _PrivacyOverlayState extends State<PrivacyOverlay> with WidgetsBindingObserver {
  bool _shouldBlur = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enabled) return;

    // Blur when app goes to background or is inactive
    final shouldBlur = state == AppLifecycleState.inactive || 
                       state == AppLifecycleState.paused || 
                       state == AppLifecycleState.hidden;

    if (_shouldBlur != shouldBlur) {
      setState(() {
        _shouldBlur = shouldBlur;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_shouldBlur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: AppColors.background.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 64, color: AppColors.text.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        "ThisJowi Secured",
                        style: TextStyle(
                          color: AppColors.text.withOpacity(0.7),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
