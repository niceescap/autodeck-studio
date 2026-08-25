# Architecture — AutoDeck Studio

## 1. Vision produit

Application mobile Flutter (Android, AAB) : l'utilisateur génère un jeu de
52 cartes + 1 dos entièrement personnalisé par IA à partir de **ses propres
références visuelles**. Modèle économique : **achat unique** (pas d'abonnement).
Prix et quotas inclus : à caler au jalon M5, après mesure des coûts d'inférence
réels sur ce nouveau flow.

Le backend généralise le pipeline éprouvé de [`niceescap/autodeck`](https://github.com/niceescap/autodeck)
(OpenRouter Image API + compositing Pillow + compression pngquant/oxipng) en le
paramétrant par utilisateur au lieu d'un set de références figé dans le code.

## 2. Flow utilisateur (7 étapes)

1. **Réfs par enseigne** — 4 slots (♠ ♥ ♦ ♣), 1 image chacun. Fallback : symbole standard.
2. **Réfs par figure** — As / Valet / Dame / Roi (optionnel). Fallback : silhouette royale classique.
3. **Style** — préréglages (mystique, aquarelle, cyberpunk, minimaliste…) + prompt libre.
4. **Échantillon 8 cartes** AVANT engagement quota complet : `AH KC QD JS TH 7C 4D 3S`
   (couvre les 2 groupes de prompts et les 4 enseignes).
5. **Dos de carte** — prompt dédié, indépendant des faces, cohérent avec le style.
6. **Génération complète** — 53 PNG asynchrones avec polling de statut.
7. **Livraison** — ZIP des 53 PNG (`AS.png`, `KH.png`, …, `back.png`).

## 3. Architecture

```
┌──────────────┐   HTTPS    ┌───────────────────────────────────────────┐
│ Flutter app  │ ─────────► │ noe (VPS Scaleway)                        │
│ (AAB Android)│            │                                           │
│ provider     │            │ Nginx : /autodeck/ → 127.0.0.1:3253       │
│ http         │            │   └─ FastAPI autodeck-api (systemd)       │
│ image_picker │            │        ├─ jobs asyncio séquentiels/deck   │
└──────────────┘            │        ├─ openrouter_client (IA)          │
                            │        ├─ card_factory / number_dispatch  │
   Play Billing ──(M4)──►   │        └─ image_compress (pngquant+oxipng)│
   achat unique             │ Stockage ~/autodeck-studio/data/{deck}/   │
                            │   refs/ samples/ final/ archive.zip       │
                            │ Purge TTL (timer systemd)                 │
                            └───────────────────────────────────────────┘
```

Principes :
- **La clé OpenRouter ne quitte jamais le serveur.**
- Jobs **asynchrones** : POST retourne un `job_id` immédiatement ; polling GET.
- Génération **séquentielle par deck** (pause 3 s entre appels, héritée du pipeline),
  checkpoint `meta.json` par carte → reprise possible après redémarrage.
- Isolation stricte de la prod La Rosace (`44i.service`, port 3252, venv dédié).

## 4. Contrat API v1

| Méthode & chemin | Rôle |
|---|---|
| `POST /api/v1/config` | Prix/quotas/modèle/rétention affichés à l'app |
| `POST /api/v1/decks` | Créer une session deck → `{deck_id}` |
| `DELETE /api/v1/decks/{id}` | Purge immédiate (RGPD) |
| `POST /api/v1/decks/{id}/refs/{ref_id}` | Upload multipart ; `ref_id` ∈ `suit_S/H/D/C`, `face_A/J/Q/K`, `back` |
| `POST /api/v1/decks/{id}/style` | `{style_id?, free_prompt?, back_prompt?}` |
| `POST /api/v1/decks/{id}/sample-job` | Lance les 8 cartes → `{job_id}` |
| `POST /api/v1/decks/{id}/full-jobs` | Lance les 53 cartes → `{job_id}` |
| `GET /api/v1/jobs/{job_id}` | `{state: queued\|running\|done\|failed, completed, total, current_item, error}` |
| `GET /api/v1/decks/{id}/archive` | ZIP final |

## 5. Réutilisation du pipeline autodeck

| Module source | Usage backend | Adaptation |
|---|---|---|
| `openrouter_client.generate_card_image()` | Appel IA (refs data-URL base64, retry ×1, log `usage.cost`) | Injecter clé/modèle/size en paramètres (`config.py` actuel raise à l'import sans `.env`) |
| `card_factory.assemble_card()` | Compositing 750×1050 (rendu 2×→LANCZOS, cadre double #2C1810/#E8D7B8, index coin FR V/D/R/10, coins arrondis alpha) | Aucune + nouveau `compose_back()` |
| `number_dispatch.place_pips()` | Layouts pips normalisés 2→T (inversion bas, scale 0.18) | Aucune |
| `image_compress.compress_png()` | pngquant --quality=60-78 --speed 1 + oxipng -o4 --alpha (cible 220–280 Ko) | Aucune |

Mapping références produit vs pipeline d'origine :

| Cartes | Réfs pipeline (figées) | Réfs AutoDeck Studio |
|---|---|---|
| Chiffres 2–10 | bg_rosace (+ modele_chiffre global) | **réf enseigne utilisateur** de la carte (fallback : rien) |
| As | bg_rosace + modele_as | **réf As utilisateur** (fallback : silhouette standard embarquée serveur) |
| Figures J/Q/K | bg_rosace + modele_J/Q/K | **réf Valet/Dame/Roi utilisateur** (fallback idem) |
| Dos | — (inexistant) | prompt dédié + `compose_back()`, aucune réf |

`bg_rosace.png` = ancre visuelle spécifique La Rosace → **non réutilisée**.

## 6. Décisions tranchées / en attente

- ✅ Hébergement backend : **noe** (zéro coût additionnel, Nginx HTTPS existant,
  toolchain Flutter déjà installée). Mitigations RAM/disque : jobs I/O-bound légers,
  purge agressive, cap 2–3 decks simultanés.
- ✅ Modèle IA : unique et fixe en MVP (`black-forest-labs/flux.2-klein-4b`) — coût prévisible.
- ⏳ Prix public + X échantillons/Y générations inclus → M5 (logs `usage.cost` persistés en JSONL dès M1).
- ⏳ Dépassement quota : MVP = 1 achat = 1 jeu complet (non-consommable), pas de top-up ;
  crédits additionnels éventuels en phase 2.
- ✅ RGPD : réfs supprimées dès la fin du job ; archive purgée ≤ 48 h (timer) ou au
  téléchargement ; bouton suppression immédiate dans l'app ; privacy policy + Data Safety au M4.

## 7. Déploiement sur noe

```ini
# /etc/systemd/system/autodeck.service
[Unit]
Description=AutoDeck Studio API (FastAPI)
After=network.target

[Service]
User=nicee
WorkingDirectory=/home/nicee/autodeck-studio/server
ExecStart=/home/nicee/autodeck-studio/server/.venv/bin/uvicorn main:app --host 127.0.0.1 --port 3253 --workers 1
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```nginx
# dans le server block HTTPS existant de 44i.webredirect.org
location /autodeck/ {
    proxy_pass http://127.0.0.1:3253/;
    proxy_set_header Host $host;
    client_max_body_size 20m;
}
```

Purge TTL (timer systemd quotidien) : suppression des decks dont
`updated_at > 48 h`, et des `refs/` de tout deck terminé.

Règles d'or : ne jamais toucher `~/44i` ni `44i.service` pendant un build
Flutter ou une génération ; surveiller disque (~6,7 Go libres).

## 8. Jalons

| Jalon | Contenu |
|---|---|
| M0 | Scaffold Flutter (étape 1 fonctionnelle, mode démo) + API stub FastAPI ← *ce PR* |
| M1 | Pipeline réel derrière l'API (injection config par deck, prompts V1 produit, JSONL coûts) |
| M2 | Écrans 2→5 : figures, style, revue échantillon (grille), dos |
| M3 | Génération complète + polling + ZIP + purge TTL |
| M4 | Play Billing, quotas, privacy policy, Data Safety, internal testing |
| M5 | Calibration pricing depuis coûts réels → release production |
