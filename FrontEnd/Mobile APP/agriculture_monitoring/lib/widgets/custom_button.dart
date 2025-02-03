import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: isPrimary
          ? const EdgeInsets.symmetric(horizontal: 18, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
      child: InkWell(
        onTap: onPressed,
        child: Container(
          alignment: Alignment.center,
          height: 43,
          padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 5),
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFFD9D9D9) : Colors.black26,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isPrimary ? Colors.black : const Color(0xFFD9D9D9),
              fontSize: isPrimary ? 20 : 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
