import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "config.dart";
import "services/api_client.dart";
import "state/deck_provider.dart";
import "ui/screens/home_screen.dart";
import "ui/screens/step_placeholder_screen.dart";
import "ui/screens/suits_upload_screen.dart";
import "ui/theme.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final DeckApi api =
      AppConfig.useStub ? StubDeckApi() : HttpDeckApi(AppConfig.apiBaseUrl);

  runApp(
    ChangeNotifierProvider(
      create: (_) => DeckProvider(api: api),
      child: const AutoDeckApp(),
    ),
  );
}

class AutoDeckApp extends StatelessWidget {
  const AutoDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "AutoDeck Studio",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: "/",
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case "/":
            return MaterialPageRoute<void>(
              builder: (_) => const HomeScreen(),
            );
          case "/suits":
            return MaterialPageRoute<void>(
              builder: (_) => const SuitsUploadScreen(),
            );
          case "/figures":
            return MaterialPageRoute<void>(
              builder: (_) =>
                  const StepPlaceholderScreen(step: 2, title: "Figures & As"),
            );
          case "/style":
            return MaterialPageRoute<void>(
              builder: (_) => const StepPlaceholderScreen(step: 3, title: "Style"),
            );
          case "/sample":
            return MaterialPageRoute<void>(
              builder: (_) =>
                  const StepPlaceholderScreen(step: 4, title: "Échantillon"),
            );
          case "/back":
            return MaterialPageRoute<void>(
              builder: (_) =>
                  const StepPlaceholderScreen(step: 5, title: "Dos de carte"),
            );
          case "/generate":
            return MaterialPageRoute<void>(
              builder: (_) =>
                  const StepPlaceholderScreen(step: 6, title: "Génération"),
            );
          case "/delivery":
            return MaterialPageRoute<void>(
              builder: (_) =>
                  const StepPlaceholderScreen(step: 7, title: "Livraison"),
            );
          default:
            return MaterialPageRoute<void>(
              builder: (_) => const HomeScreen(),
            );
        }
      },
    );
  }
}
