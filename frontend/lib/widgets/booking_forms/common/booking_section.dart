import 'package:flutter/material.dart';

class BookingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool transparent;
  final double padding;

  const BookingSection({
    super.key,
    required this.title,
    required this.children,
    this.transparent = false,
    this.padding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Card(
        elevation: transparent ? 0 : 2,
        color: transparent
            ? Colors.transparent
            : Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
