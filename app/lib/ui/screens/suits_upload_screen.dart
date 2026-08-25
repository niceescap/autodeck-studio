import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "package:provider/provider.dart";

import "../../config.dart";
import "../../models/deck_models.dart";
import "../../state/deck_provider.dart";
import "../widgets/ref_slot_tile.dart";

/// ÉTAPE 1 — upload des références par enseigne (♠ ♥ ♦ ♣).
///
/// Chaque slot est optionnel : sans image, le backend utilisera le
/// symbole standard. "Continuer" déclenche l'upload des nouvelles
/// images puis navigue vers l'étape 2.
class SuitsUploadScreen extends StatefulWidget {
  const SuitsUploadScreen({super.key});

  @override
  State<SuitsUploadScreen> createState() => _SuitsUploadScreenState();
}

class _SuitsUploadScreenState extends State<SuitsUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _choose(DeckProvider deck, RefSlot slot) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text("Choisir dans la galerie"),
              onTap: () => Navigator.pop(ctx, "gallery"),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text("Prendre une photo"),
              onTap: () => Navigator.pop(ctx, "camera"),
            ),
            if (slot.hasLocal)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text("Retirer (symbole standard)"),
                onTap: () => Navigator.pop(ctx, "remove"),
              ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    if (action == "remove") {
      deck.clearImage(slot.id);
      return;
    }

    final picked = await _picker.pickImage(
      source:
          action == "camera" ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 88,
    );
    if (picked != null) deck.setImage(slot.id, picked.path);
  }

  Future<void> _continue() async {
    final deck = context.read<DeckProvider>();
    final ok = await deck.pushStep1Refs();
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamed(context, "/figures");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deck.error ?? "Envoi impossible"),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Étape 1 · Les 4 enseignes")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              "Choisissez une image par enseigne. "
              "Sans image, nous utiliserons le symbole classique.",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
          ),
          if (AppConfig.useStub)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x38FF8F00),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.science_outlined,
                        size: 18, color: Colors.amberAccent),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Mode démo — aucune donnée ne quitte l'app.",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(20),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              crossAxisCount: 2,
              childAspectRatio: 0.82,
              children: [
                for (final slot in deck.suitSlots)
                  RefSlotTile(
                    slot: slot,
                    enabled: !deck.busy,
                    onTap: () => _choose(deck, slot),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (deck.busy) const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: deck.busy ? null : _continue,
                icon: const Icon(Icons.arrow_forward),
                label: Text(
                  "Continuer (${deck.filledSuitCount}/4 personnalisées)",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
