import 'package:flutter/material.dart';

class AppButtons extends StatelessWidget {
  final VoidCallback onClicked;
  final String title;
  final IconData icon;

  AppButtons(
      {super.key,
      required this.title,
      required this.icon,
      required this.onClicked});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(56),
          iconColor: Color(0xFFD9D9D9),
          backgroundColor: const Color(0xFF3C3D37),
          textStyle: TextStyle(fontSize: 20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 7),
            Text(title, style: TextStyle(color: Colors.white)),
          ],
        ),
        onPressed: onClicked,
      ),
    );
  }
}
