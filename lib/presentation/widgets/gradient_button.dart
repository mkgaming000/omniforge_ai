// Gradient Button - premium styled button with gradient background
import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient = const LinearGradient(
      colors: [Color(0xFF6750A4), Color(0xFF00E5FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.size = GradientButtonSize.medium,
    this.isLoading = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient gradient;
  final GradientButtonSize size;
  final bool isLoading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final padding = switch (size) {
      GradientButtonSize.small =>
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      GradientButtonSize.medium =>
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      GradientButtonSize.large =>
        const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    };

    final fontSize = switch (size) {
      GradientButtonSize.small => 13.0,
      GradientButtonSize.medium => 15.0,
      GradientButtonSize.large => 17.0,
    };

    final iconSize = switch (size) {
      GradientButtonSize.small => 16.0,
      GradientButtonSize.medium => 18.0,
      GradientButtonSize.large => 22.0,
    };

    final child = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : gradient,
        color: onPressed == null ? Theme.of(context).disabledColor : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: (gradient is LinearGradient
                          ? (gradient as LinearGradient).colors.first
                          : Colors.purple)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          else if (icon != null)
            Icon(icon, size: iconSize, color: Colors.white),
          if ((icon != null || isLoading) && label.isNotEmpty)
            const SizedBox(width: 8),
          if (label.isNotEmpty)
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );

    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(16),
      child: expanded ? SizedBox(width: double.infinity, child: child) : child,
    );
  }
}

enum GradientButtonSize { small, medium, large }
