import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          minimumSize: Size(double.infinity, 50.h),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          text,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18.sp,
            color: Colors.white,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}