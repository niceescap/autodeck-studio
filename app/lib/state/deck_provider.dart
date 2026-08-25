/// État global du deck en cours de création.
///
/// Un ChangeNotifier unique suffit au MVP : le flow est un assistant
/// linéaire (enseignes → figures → style → échantillon → dos → génération
/// → livraison). Migration Riverpod inutile à ce stade.
library;

import "package:flutter/foundation.dart";

import "../models/deck_models.dart";
import "../services/api_client.dart";

class DeckProvider extends ChangeNotifier {
  DeckProvider({required this.api});

  final DeckApi api;

  String? deckId;
  bool busy = false;
  String? error;

  // ============================================================
  // ÉTAPE 1 — les 4 enseignes (fallback symbole standard si vide)
  // ============================================================

  late final List<RefSlot> suitSlots = [
    for (final s in CardSuit.values)
      RefSlot(
        id: "suit_${s.code}",
        title: "${s.frLabel} ${s.symbol}",
        hint: switch (s) {
          CardSuit.spades => "ex. vélo",
          CardSuit.hearts => "ex. guitare",
          CardSuit.diamonds => "ex. bateau",
          CardSuit.clubs => "ex. ordinateur",
        },
        symbol: s.symbol,
      ),
  ];

  // ============================================================
  // ÉTAPE 2 — figures + as (déclarés dès maintenant, utilisés au M2)
  // ============================================================

  late final List<RefSlot> faceSlots = [
    for (final f in FaceKind.values)
      RefSlot(
        id: "face_${f.code}",
        title: f.frLabel,
        hint: "optionnel",
        symbol: "★",
      ),
  ];

  RefSlot? _byId(String id) =>
      [...suitSlots, ...faceSlots].where((r) => r.id == id).firstOrNull;

  void setImage(String slotId, String path) {
    _byId(slotId)?.localPath = path;
    notifyListeners();
  }

  void clearImage(String slotId) {
    _byId(slotId)?..localPath = null..remoteName = null;
    notifyListeners();
  }

  int get filledSuitCount => suitSlots.where((s) => s.hasLocal).length;

  /// Crée le deck côté serveur si nécessaire.
  Future<bool> ensureDeck() async {
    deckId ??= await api.createDeck();
    return true;
  }

  /// Envoie les nouvelles images de l'étape 1 au backend.
  /// Retourne true si tout est parti (ou s'il n'y avait rien à envoyer).
  Future<bool> pushStep1Refs() async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await ensureDeck();
      for (final slot in suitSlots) {
        if (slot.hasLocal && !slot.isUploaded) {
          await api.uploadRef(deckId!, slot, slot.localPath!);
        }
      }
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
