// File: lib/ui/widgets/placeholder_view.dart
import 'package:flutter/material.dart';

/// A simple placeholder that just centers a title on the screen.
class PlaceholderView extends StatelessWidget {
  final String title;

  const PlaceholderView({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}