import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Placeholder avatar that renders the person's initials on a colour
/// derived from their name, so the same person always gets the same colour.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.radius = 22});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hue = (name.hashCode % 360).toDouble();
    final background = HSLColor.fromAHSL(1, hue, 0.45, 0.45).toColor();
    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      child: Text(
        Formatters.initials(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}