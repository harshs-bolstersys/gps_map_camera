import 'package:flutter/material.dart';
import 'package:gps_map_camera/core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final double? width;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isEnabled = true,
    this.width,
    this.height = 52,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? AppColors.primary : AppColors.divider,
          foregroundColor: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
          disabledBackgroundColor: AppColors.divider,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: isEnabled ? 2 : 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
