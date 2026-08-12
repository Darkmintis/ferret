import 'package:flutter/material.dart';

/// Release-mode warning tag shown above the Ferret bubble.
class FerretReleaseTag extends StatelessWidget {
  const FerretReleaseTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFB3261E),
      borderRadius: BorderRadius.circular(6),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          'FERRET ACTIVE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
