import "package:flutter/material.dart";

/// Écran d'accueil — point d'entrée du wizard de création.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const Text(
                "🂡",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 96, color: Colors.white24),
              ),
              const SizedBox(height: 16),
              Text(
                "AutoDeck Studio",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Votre jeu de 52 cartes, illustré par IA\nà partir de VOS références.",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.white70),
              ),
              const Spacer(flex: 3),
              FilledButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text("Créer mon jeu"),
                onPressed: () => Navigator.pushNamed(context, "/suits"),
              ),
              const SizedBox(height: 12),
              Text(
                "Achat unique · échantillon offert avant génération.\n"
                "Application de divertissement.",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white38),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
