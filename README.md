# AutoDeck Studio

Générez un jeu de 52 cartes à jouer + 1 dos, entièrement personnalisé par IA,
à partir de **vos propres références visuelles**. Achat unique, sans abonnement.

- 📱 **App** : Flutter / Android (build AAB) — dossier [`app/`](app/)
- 🛠 **Backend** : FastAPI + pipeline IA (OpenRouter) + compositing Pillow — dossier [`server/`](server/)
- 📐 **Architecture & déploiement** : [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)

## Statut du projet

| Jalon | Contenu | État |
|---|---|---|
| M0 | Scaffold Flutter (flow étape 1 fonctionnel) + API stub FastAPI | ✅ en cours |
| M1 | Pipeline réel autodeck branché derrière l'API | ⏳ |
| M2 | Écrans 2→5 (figures, style, échantillon 8 cartes, dos) | ⏳ |
| M3 | Génération complète 53 cartes + ZIP + purge TTL | ⏳ |
| M4 | Google Play Billing + privacy policy | ⏳ |
| M5 | Calibration pricing depuis coûts d'inférence réels | ⏳ |

## Démarrage rapide

### App Flutter

```bash
cd app
flutter create --org com.nicee --project-name autodeck_studio .   # génère android/
# puis appliquer les 2 retouches documentées dans app/README_ANDROID.md
flutter run --dart-define=AUTODECK_API=            # mode démo (stub local)
flutter run --dart-define=AUTODECK_API=https://44i.webredirect.org/autodeck
```

### Backend (stub)

```bash
cd server
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/uvicorn main:app --host 127.0.0.1 --port 3253
```

Le stub simule les jobs de génération (contrat HTTP définitif, aucune dépendance
IA) pour développer le front sans consommer de quota OpenRouter.

## Conventions verrouillées

- Fichiers finaux : `{RANK}{SUIT}.png` (`AS.png` = As de Pique, `TH.png` = 10♥ …) + `back.png`
- Format : 750×1050, coins arrondis alpha lissés, cible 220–280 Ko/carte
- Échantillon de confirmation (8 cartes) : `AH KC QD JS TH 7C 4D 3S`
- Modèle MVP : `black-forest-labs/flux.2-klein-4b` via OpenRouter — clé API **jamais** côté client

## Licence

Tous droits réservés — niceescap.
