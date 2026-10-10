#!/usr/bin/env python3
"""Download a sample realistic humanoid for development (Bake3D, CC BY 4.0).

Attribution mandatory. Asset is intentionally fetched at build time instead of
bundled in the project ZIP. This sample depicts an OLD MAN, and is not the
final young protagonist for Cidade Lexus RP.
"""
from pathlib import Path
from urllib.request import Request, urlopen
import os, struct, time

URL = os.environ.get("LEXUS_REAL_HUMAN_URL", "https://bake3d.ai/samples/free/bake3d-person-animated.glb")
DEST = Path("assets/models/hero_realistic.glb")
DEST.parent.mkdir(parents=True, exist_ok=True)

for attempt in range(3):
    try:
        req = Request(URL, headers={"User-Agent":"CidadeLexusRP-CharacterImporter/1.0"})
        with urlopen(req, timeout=70) as resp, DEST.open("wb") as fh:
            while True:
                block = resp.read(1024*1024)
                if not block:
                    break
                fh.write(block)
        data_size=DEST.stat().st_size
        with DEST.open("rb") as f:
            header=f.read(12)
        if len(header)<12 or header[:4]!=b"glTF" or struct.unpack_from("<I",header,8)[0]!=data_size:
            raise ValueError("Arquivo baixado nao e um GLB valido")
        if data_size<100_000 or data_size>80_000_000:
            raise ValueError("Tamanho do modelo fora do limite: %d"%data_size)
        print("Human GLB valido:", DEST, data_size, "bytes")
        break
    except Exception as exc:
        DEST.unlink(missing_ok=True)
        if attempt==2:
            raise SystemExit(f"Falha ao obter humano 3D apos 3 tentativas: {exc}")
        print("Tentando novamente",attempt+1,str(exc))
        time.sleep(3+attempt*2)
