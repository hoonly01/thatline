import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? iconColor;
  final double? iconSize;
  final double? labelSize;

  const ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
    this.iconColor,
    this.iconSize = 24,
    this.labelSize = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? const Color(0xFF7A5DC7),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: (color ?? const Color(0xFF7A5DC7)).withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: iconColor ?? color ?? const Color(0xFF7A5DC7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
              color: color ?? const Color(0xFF7A5DC7),
            ),
          ),
        ],
      ),
    );
  }
}
