"""
AutoDeck Studio — API backend (STUB de développement, jalon M0)
===============================================================

Reproduit le contrat HTTP définitif (docs/ARCHITECTURE.md §4) mais SIMULE
les jobs de génération. Le vrai pipeline OpenRouter + Pillow sera branché
au jalon M1.

Lancer en local :
    cd server
    python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
    .venv/bin/uvicorn main:app --host 127.0.0.1 --port 3253

Sur noe (production M1+) : systemd autodeck.service + Nginx /autodeck/
(voir docs/ARCHITECTURE.md §7).
"""
from __future__ import annotations

import asyncio
import shutil
import time
import uuid
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

DATA_DIR = Path.home() / "autodeck-studio" / "data"
(DATA_DIR).mkdir(parents=True, exist_ok=True)

# Conventions pipeline : {RANK}{SUIT}.png, back.png ; T = 10.
SAMPLE_CARDS = ["AH", "KC", "QD", "JS", "TH", "7C", "4D", "3S"]
_FULL_RANKS = ["A", "K", "Q", "J", "T", "9", "8", "7", "6", "5", "4", "3", "2"]
_FULL_SUITS = ["S", "H", "D", "C"]
FULL_CARDS = [r + s for r in _FULL_RANKS for s in _FULL_SUITS] + ["back"]

SECONDS_PER_CARD = {"sample": 1.2, "full": 1.5}  # simulé (démo accélérée)

ALLOWED_IMAGE_EXT = {".png", ".jpg", ".jpeg", ".webp"}

app = FastAPI(title="AutoDeck Studio API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

DECKS: dict[str, dict] = {}
JOBS: dict[str, dict] = {}


def _deck(deck_id: str) -> dict:
    if deck_id not in DECKS:
        raise HTTPException(404, "deck inconnu ou expiré")
    return DECKS[deck_id]


# ============================================================
# CONFIGURATION PUBLIQUE
# ============================================================

@app.get("/api/v1/config")
def config():
    """Prix/quotas provisoires — calés définitivement au jalon M5."""
    return {
        "currency": "EUR",
        "price": None,
        "included_sample_jobs": 1,
        "included_full_jobs": 1,
        "model": "black-forest-labs/flux.2-klein-4b",
        "retention": {"refs_after_completion_h": 0, "archive_h": 48},
    }


# ============================================================
# CYCLE DE VIE D'UN DECK
# ============================================================

@app.post("/api/v1/decks")
async def create_deck():
    deck_id = uuid.uuid4().hex[:12]
    (DATA_DIR / deck_id / "refs").mkdir(parents=True, exist_ok=True)
    DECKS[deck_id] = {
        "created_at": time.time(),
        "updated_at": time.time(),
        "refs": {},
        "style": {},
    }
    return {"deck_id": deck_id}


@app.delete("/api/v1/decks/{deck_id}")
def delete_deck(deck_id: str):
    DECKS.pop(deck_id, None)
    for suffix in ("-sample", "-full"):
        JOBS.pop(f"{deck_id}{suffix}", None)
    shutil.rmtree(DATA_DIR / deck_id, ignore_errors=True)
    return {"deleted": True}


# ============================================================
# RÉFÉRENCES UTILISATEUR
# ============================================================

@app.post("/api/v1/decks/{deck_id}/refs/{ref_id}")
async def upload_ref(deck_id: str, ref_id: str, image: UploadFile = File(...)):
    d = _deck(deck_id)
    if not ref_id.startswith(("suit_", "face_", "back")):
        raise HTTPException(422, f"ref_id invalide : {ref_id!r}")

    suffix = Path(image.filename or "").suffix.lower()
    if suffix not in ALLOWED_IMAGE_EXT:
        raise HTTPException(415, "format non supporté (png/jpg/webp)")

    dest = DATA_DIR / deck_id / "refs" / f"{ref_id}{suffix}"
    dest.write_bytes(await image.read())
    d["refs"][ref_id] = dest.name
    d["updated_at"] = time.time()
    return {"ok": True, "ref_id": ref_id}


class StyleIn(BaseModel):
    style_id: Optional[str] = None
    free_prompt: Optional[str] = None
    back_prompt: Optional[str] = None


@app.post("/api/v1/decks/{deck_id}/style")
def set_style(deck_id: str, body: StyleIn):
    _deck(deck_id)["style"] = body.model_dump(exclude_none=True)
    return {"ok": True}


# ============================================================
# JOBS — échantillon (8 cartes) / génération complète (53 cartes)
# ============================================================

def _start_job(deck_id: str, kind: str) -> dict:
    _deck(deck_id)
    cards = SAMPLE_CARDS if kind == "sample" else FULL_CARDS
    job_id = f"{deck_id}-{kind}"
    JOBS[job_id] = {
        "kind": kind,
        "state": "running",
        "completed": 0,
        "total": len(cards),
        "cards": cards,
        "per": SECONDS_PER_CARD[kind],
        "started": time.time(),
    }
    asyncio.get_running_loop().create_task(_simulate(job_id))
    return {"job_id": job_id}


async def _simulate(job_id: str) -> None:
    j = JOBS[job_id]
    while j["completed"] < j["total"]:
        await asyncio.sleep(j["per"])
        j["completed"] += 1
    j["state"] = "done"


@app.post("/api/v1/decks/{deck_id}/sample-job")
def start_sample(deck_id: str):
    return _start_job(deck_id, "sample")


@app.post("/api/v1/decks/{deck_id}/full-jobs")
def start_full(deck_id: str):
    return _start_job(deck_id, "full")


@app.get("/api/v1/jobs/{job_id}")
def job_status(job_id: str):
    j = JOBS.get(job_id)
    if j is None:
        raise HTTPException(404, "job inconnu")
    idx = min(j["completed"], len(j["cards"]) - 1)
    return {
        "state": j["state"],
        "completed": j["completed"],
        "total": j["total"],
        "current_item": j["cards"][idx],
        "error": None,
    }


# ============================================================
# LIVRAISON
# ============================================================

@app.get("/api/v1/decks/{deck_id}/archive")
def archive(deck_id: str):
    _deck(deck_id)
    # Jalon M3 : renverra le ZIP des 53 PNG compressés (pipeline réel).
    raise HTTPException(501, "archive disponible au jalon M3 (pipeline réel)")
