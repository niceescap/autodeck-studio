/// Modèles de domaine AutoDeck Studio.
///
/// Conventions pipeline (identiques côté backend) :
///   - codes cartes = {RANK}{SUIT} : AS.png = As de Pique, TH.png = 10♥…
///   - rangs : A, 2-9, T (=10), J, Q, K ; enseignes : S, H, D, C.
library;

// ============================================================
// ENSEIGNES
// ============================================================

enum CardSuit { spades, hearts, diamonds, clubs }

extension CardSuitX on CardSuit {
  String get code => switch (this) {
        CardSuit.spades => "S",
        CardSuit.hearts => "H",
        CardSuit.diamonds => "D",
        CardSuit.clubs => "C",
      };

  String get frLabel => switch (this) {
        CardSuit.spades => "Pique",
        CardSuit.hearts => "Cœur",
        CardSuit.diamonds => "Carreau",
        CardSuit.clubs => "Trèfle",
      };

  String get symbol => switch (this) {
        CardSuit.spades => "♠",
        CardSuit.hearts => "♥",
        CardSuit.diamonds => "♦",
        CardSuit.clubs => "♣",
      };
}

// ============================================================
// FIGURES + AS
// ============================================================

enum FaceKind { ace, jack, queen, king }

extension FaceKindX on FaceKind {
  String get code => switch (this) {
        FaceKind.ace => "A",
        FaceKind.jack => "J",
        FaceKind.queen => "Q",
        FaceKind.king => "K",
      };

  String get frLabel => switch (this) {
        FaceKind.ace => "As",
        FaceKind.jack => "Valet",
        FaceKind.queen => "Dame",
        FaceKind.king => "Roi",
      };
}

// ============================================================
// EMPLACEMENT DE RÉFÉRENCE UTILISATEUR
// ============================================================

/// Un slot d'image : soit une enseigne (étape 1), soit une figure/as (étape 2).
class RefSlot {
  RefSlot({
    required this.id,
    required this.title,
    required this.hint,
    this.symbol,
  });

  /// Identifiant stable partagé avec l'API : `suit_S`, `face_K`, `back`…
  final String id;
  final String title;
  final String hint;

  /// Glyphe décoratif affiché quand le slot est vide (♠, ♥… ou ★).
  final String? symbol;

  /// Chemin local du fichier choisi par l'utilisateur (avant upload).
  String? localPath;

  /// Marqueur "image bien reçue par le serveur".
  String? remoteName;

  bool get hasLocal => localPath != null;
  bool get isUploaded => remoteName != null;

  /// true si la carte utilisera le symbole/représentation standard.
  bool get usesFallback => !hasLocal && !isUploaded;
}

// ============================================================
// STATUT DE JOB
// ============================================================

enum JobState { queued, running, done, failed }

JobState jobStateFrom(String? s) => switch (s) {
      "queued" => JobState.queued,
      "running" => JobState.running,
      "done" => JobState.done,
      "failed" => JobState.failed,
      _ => JobState.queued,
    };

class JobStatus {
  const JobStatus({
    required this.state,
    required this.completed,
    required this.total,
    this.currentItem,
    this.error,
  });

  final JobState state;
  final int completed;
  final int total;
  final String? currentItem;
  final String? error;

  double? get progress =>
      total == 0 ? null : (completed / total).clamp(0.0, 1.0);

  factory JobStatus.fromJson(Map<String, dynamic> j) => JobStatus(
        state: jobStateFrom(j["state"] as String?),
        completed: (j["completed"] as num?)?.toInt() ?? 0,
        total: (j["total"] as num?)?.toInt() ?? 0,
        currentItem: j["current_item"] as String?,
        error: j["error"] as String?,
      );
}
