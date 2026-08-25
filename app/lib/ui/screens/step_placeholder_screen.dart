import "package:flutter/material.dart";

/// Écran générique pour les étapes à construire aux jalons M2/M3.
class StepPlaceholderScreen extends StatelessWidget {
  const StepPlaceholderScreen({
    super.key,
    required this.step,
    required this.title,
  });

  final int step;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Étape $step · $title")),
      body: const Center(
        child: Text(
          "À construire au prochain jalon 🚧",
          style: TextStyle(color: Colors.white38),
        ),
      ),
    );
  }
}
