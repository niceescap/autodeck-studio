/// Client API AutoDeck Studio.
///
/// Deux implémentations de [DeckApi] :
///   - [HttpDeckApi] : le vrai backend FastAPI hébergé sur noe.
///   - [StubDeckApi] : simulation locale (mode démo, zéro réseau).
library;

import "dart:async";
import "dart:convert";
import "dart:math";

import "package:http/http.dart" as http;

import "../config.dart";
import "../models/deck_models.dart";

// ============================================================
// CONVENTIONS CARTES
// ============================================================

/// Échantillon de confirmation (8 cartes) : figures/as + chiffres, 4 enseignes.
const List<String> kSampleCards = [
  "AH", "KC", "QD", "JS", "TH", "7C", "4D", "3S",
];

/// Jeu complet : 52 cartes + dos.
List<String> get kFullCards {
  const ranks = ["A", "K", "Q", "J", "T", "9", "8", "7", "6", "5", "4", "3", "2"];
  const suits = ["S", "H", "D", "C"];
  return [for (final r in ranks) for (final s in suits) "$r$s", "back"];
}

// ============================================================
// CONTRAT
// ============================================================

abstract class DeckApi {
  Future<String> createDeck();
  Future<void> uploadRef(String deckId, RefSlot slot, String filePath);
  Future<void> setStyle(
    String deckId, {
    String? styleId,
    String? freePrompt,
    String? backPrompt,
  });
  Future<String> startSampleJob(String deckId);
  Future<String> startFullJob(String deckId);
  Future<JobStatus> getJob(String jobId);
  Future<String> archiveUrl(String deckId);
  Future<void> deleteDeck(String deckId);
}

// ============================================================
// ERREURS
// ============================================================

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => "Erreur API ($statusCode) : $message";
}

http.Response _ensure(http.Response r) {
  if (r.statusCode >= 400) {
    throw ApiException("HTTP ${r.statusCode}", r.statusCode);
  }
  return r;
}

Future<T> _withTimeout<T>(Future<T> f, Duration d) => f.timeout(d);

// ============================================================
// IMPLÉMENTATION HTTP (backend réel)
// ============================================================

class HttpDeckApi implements DeckApi {
  HttpDeckApi(this.baseUrl);

  final String baseUrl;
  final http.Client _c = http.Client();

  Uri _u(String path) => Uri.parse("$baseUrl$path");

  @override
  Future<String> createDeck() async {
    final r = _ensure(await _withTimeout(
      _c.post(_u("/api/v1/decks")),
      AppConfig.httpTimeout,
    ));
    return (jsonDecode(r.body) as Map<String, dynamic>)["deck_id"] as String;
  }

  @override
  Future<void> uploadRef(String deckId, RefSlot slot, String filePath) async {
    final req = http.MultipartRequest(
      "POST",
      _u("/api/v1/decks/$deckId/refs/${slot.id}"),
    )..files.add(await http.MultipartFile.fromPath("image", filePath));

    final streamed = await req.send().timeout(AppConfig.uploadTimeout);
    _ensure(await http.Response.fromStream(streamed));
    slot.remoteName = "${slot.id}.img";
  }

  @override
  Future<void> setStyle(
    String deckId, {
    String? styleId,
    String? freePrompt,
    String? backPrompt,
  }) async {
    _ensure(await _withTimeout(
      _c.post(
        _u("/api/v1/decks/$deckId/style"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          if (styleId != null) "style_id": styleId,
          if (freePrompt != null) "free_prompt": freePrompt,
          if (backPrompt != null) "back_prompt": backPrompt,
        }),
      ),
      AppConfig.httpTimeout,
    ));
  }

  @override
  Future<String> startSampleJob(String deckId) async {
    final r = _ensure(await _withTimeout(
      _c.post(_u("/api/v1/decks/$deckId/sample-job")),
      AppConfig.httpTimeout,
    ));
    return (jsonDecode(r.body) as Map<String, dynamic>)["job_id"] as String;
  }

  @override
  Future<String> startFullJob(String deckId) async {
    final r = _ensure(await _withTimeout(
      _c.post(_u("/api/v1/decks/$deckId/full-jobs")),
      AppConfig.httpTimeout,
    ));
    return (jsonDecode(r.body) as Map<String, dynamic>)["job_id"] as String;
  }

  @override
  Future<JobStatus> getJob(String jobId) async {
    final r = _ensure(await _withTimeout(
      _c.get(_u("/api/v1/jobs/$jobId")),
      AppConfig.httpTimeout,
    ));
    return JobStatus.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  @override
  Future<String> archiveUrl(String deckId) async =>
      "$baseUrl/api/v1/decks/$deckId/archive";

  @override
  Future<void> deleteDeck(String deckId) async {
    await _withTimeout(
      _c.delete(_u("/api/v1/decks/$deckId")),
      AppConfig.httpTimeout,
    );
  }
}

// ============================================================
// STUB (mode démo — aucune donnée ne quitte l'app)
// ============================================================

class StubDeckApi implements DeckApi {
  final Map<String, DateTime> _started = {};

  @override
  Future<String> createDeck() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return "stub${DateTime.now().millisecondsSinceEpoch}";
  }

  @override
  Future<void> uploadRef(String deckId, RefSlot slot, String filePath) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    slot.remoteName = "${slot.id}.img";
  }

  @override
  Future<void> setStyle(
    String deckId, {
    String? styleId,
    String? freePrompt,
    String? backPrompt,
  }) async {}

  @override
  Future<String> startSampleJob(String deckId) => _start("$deckId-sample");

  @override
  Future<String> startFullJob(String deckId) => _start("$deckId-full");

  Future<String> _start(String jobId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _started[jobId] = DateTime.now();
    return jobId;
  }

  @override
  Future<JobStatus> getJob(String jobId) async {
    final t0 = _started[jobId];
    if (t0 == null) {
      return const JobStatus(state: JobState.queued, completed: 0, total: 0);
    }
    final isFull = jobId.endsWith("-full");
    final cards = isFull ? kFullCards : kSampleCards;
    // Démo accélérée : ~1,4 s / carte en échantillon, ~0,9 s / carte en complet.
    final perCardMs = isFull ? 900 : 1400;
    final elapsedMs = DateTime.now().difference(t0).inMilliseconds;
    final done = min(cards.length, elapsedMs ~/ perCardMs);
    final state =
        done >= cards.length ? JobState.done : JobState.running;

    return JobStatus(
      state: state,
      completed: done,
      total: cards.length,
      currentItem: cards[min(done, cards.length - 1)],
    );
  }

  @override
  Future<String> archiveUrl(String deckId) async => "";

  @override
  Future<void> deleteDeck(String deckId) async {}
}
