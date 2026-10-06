"""Composes the App Store screenshots from the raw captures.

    py -3.12 tool/store_screenshots/compose.py [--raw DIR] [--out DIR] [--only SET] [--slides 1,4]

Input: the real app screens written by capture_test.dart
(<raw>/<device>/<ui-variant>/<screen>.png). Output:
<out>/<set>/<device>/NN_<slug>.png, flattened RGB at the store's exact sizes
(iPhone 6.9" 1320x2868, iPad 13" 2064x2752).

Each slide is an HTML page rendered by headless Chrome, so the typography is
a real text engine (Anton for headlines, Inter for body; both OFL, loaded
from Google Fonts). Copy lives in CAPTIONS below, one block per caption set;
SETS maps each set onto the UI capture it sits on.

The storyboard is a mix of the three directions validated on 2026-10-02:
  1 proof   giant measured number over the result screen   (direction A)
  2 film    the Analyze screen, "film one jump"             (B)
  3 scores  the four form scores                            (A)
  4 gap     "how far are you from dunking?" + rim           (C)
  5 plan    the plan reveal                                 (C)
  6 train   per-exercise logging                            (A)
  7 progress the vertical trend                             (B)
  8 closer  the dunker, "jump higher"                       (B)
A dotted measuring line runs down the right edge of every slide so the set
reads as one strip when swiped (direction C).

Honesty rules (Apple 2.3 + this repo's no-fabricated-social-proof rule): no
ratings, no user counts, no percentiles, no prices; the vertical is called
"estimated"; slides 1 and 8 carry the subscription notice (2.3.2). The
athlete in the UI is a demo profile — a picture of the product.
"""
import argparse
import pathlib
import shutil
import subprocess
import sys
import tempfile

from PIL import Image

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent
CHROME_CANDIDATES = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "google-chrome", "chromium",
]

DEVICES = {
    "iphone69": (1320, 2868),
    "ipad13": (2064, 2752),
}

# caption set -> (UI capture variant, big-number text, rim label)
SETS = {
    "en-US": ("en-US", ("27", "″"), "RIM · 10 FT"),
    "en-metric": ("en-metric", ("69", "cm"), "RIM · 3.05 M"),
    "fr": ("fr", ("69", "cm"), "ARCEAU · 3,05 M"),
    "es": ("en-metric", ("69", "cm"), "ARO · 3,05 M"),
    "pt-BR": ("en-metric", ("69", "cm"), "ARO · 3,05 M"),
    "de": ("en-metric", ("69", "cm"), "KORB · 3,05 M"),
    "it": ("en-metric", ("69", "cm"), "CANESTRO · 3,05 M"),
}

# Which caption set each App Store locale uses (read by upload_screenshots.py).
STORE_LOCALES = {
    "en-US": "en-US",
    "en-GB": "en-metric", "en-CA": "en-metric", "en-AU": "en-metric",
    "fr-FR": "fr", "fr-CA": "fr",
    "es-MX": "es", "es-ES": "es",
    "pt-BR": "pt-BR",
    "de-DE": "de",
    "it": "it",
}

# Per slide: (headline line 1, headline line 2 in orange, sub-line or None).
# Headlines are 2-5 words, benefit first; they reuse the listing's search
# terms where it reads naturally (vertical / détente / salto / impulsão /
# Sprungkraft).
CAPTIONS = {
    "en": {
        "proof": ("See your", "true vertical", None),
        "film": ("Film one jump.", "We measure it.",
                 "Body tracking times your flight frame by frame. No wearables, no markers."),
        "scores": ("AI scores", "every jump", "Bounce · Power · Control · Form"),
        "gap": ("How far are you", "from dunking?", None),
        "plan": ("Close the gap", "week by week", "A plan built from your level, schedule and gear"),
        "train": ("Every set", "guided and logged", "Sets, reps and loads, with a how-to for every drill"),
        "progress": ("Watch your vert", "climb", "Every jump and every session, logged"),
        "closer": ("Jump higher.", "Dunk sooner.", "Your plan. Your vert. Your first dunk."),
        "fine1": "Vertical estimated from flight time · Subscription required",
        "fine8": "Subscription required",
    },
    "fr": {
        "proof": ("Découvre ta", "vraie détente", None),
        "film": ("Filme un saut.", "On le mesure.",
                 "Le suivi du corps chronomètre ton temps de vol image par image. Sans capteur, sans repère."),
        "scores": ("L'IA note", "chaque saut", "Rebond · Puissance · Contrôle · Technique"),
        "gap": ("À combien es-tu", "du dunk ?", None),
        "plan": ("Comble l'écart", "semaine après semaine", "Un plan selon ton niveau, ton planning et ton matériel"),
        "train": ("Chaque série", "guidée et notée", "Séries, répétitions et charges, avec les consignes de chaque exercice"),
        "progress": ("Regarde ta détente", "grimper", "Chaque saut et chaque séance, enregistrés"),
        "closer": ("Saute plus haut.", "Vise le dunk.", "Ton plan. Ta détente. Ton premier dunk."),
        "fine1": "Détente estimée par le temps de vol · Abonnement requis",
        "fine8": "Abonnement requis",
    },
    "es": {
        "proof": ("Descubre tu", "salto vertical real", None),
        "film": ("Graba un salto.", "Nosotros lo medimos.",
                 "El seguimiento corporal cronometra tu vuelo fotograma a fotograma. Sin sensores ni marcas."),
        "scores": ("La IA puntúa", "cada salto", "Rebote · Potencia · Control · Técnica"),
        "gap": ("¿Cuánto te falta", "para el mate?", None),
        "plan": ("Cierra la brecha", "semana a semana", "Un plan según tu nivel, tus días y tu material"),
        "train": ("Cada serie", "guiada y registrada", "Series, repeticiones y cargas, con guía para cada ejercicio"),
        "progress": ("Mira cómo sube", "tu salto", "Cada salto y cada sesión, registrados"),
        "closer": ("Salta más alto.", "Llega al mate.", "Tu plan. Tu salto. Tu primer mate."),
        "fine1": "Salto estimado por el tiempo de vuelo · Requiere suscripción",
        "fine8": "Requiere suscripción",
    },
    "pt-BR": {
        "proof": ("Descubra sua", "impulsão real", None),
        "film": ("Grave um salto.", "Nós medimos.",
                 "O rastreamento corporal cronometra seu voo quadro a quadro. Sem sensores, sem marcações."),
        "scores": ("A IA avalia", "cada salto", "Reatividade · Potência · Controle · Técnica"),
        "gap": ("Quanto falta", "para enterrar?", None),
        "plan": ("Feche a distância", "semana a semana", "Um plano pelo seu nível, sua agenda e seu equipamento"),
        "train": ("Cada série", "guiada e registrada", "Séries, repetições e cargas, com guia de cada exercício"),
        "progress": ("Veja sua impulsão", "subir", "Cada salto e cada treino, registrados"),
        "closer": ("Pule mais alto.", "Chegue à enterrada.", "Seu plano. Sua impulsão. Sua primeira enterrada."),
        "fine1": "Impulsão estimada pelo tempo de voo · Requer assinatura",
        "fine8": "Requer assinatura",
    },
    "de": {
        "proof": ("Miss deine", "echte Sprungkraft", None),
        "film": ("Filme einen Sprung.", "Wir messen ihn.",
                 "Körpertracking misst deine Flugzeit Bild für Bild. Ohne Sensoren, ohne Markierungen."),
        "scores": ("KI bewertet", "jeden Sprung", "Reaktivität · Kraft · Kontrolle · Technik"),
        "gap": ("Wie weit bist du", "vom Dunk entfernt?", None),
        "plan": ("Schließ die Lücke", "Woche für Woche", "Ein Plan nach deinem Level, Zeitplan und Equipment"),
        "train": ("Jeder Satz", "geführt und notiert", "Sätze, Wiederholungen und Gewichte, mit Anleitung zu jeder Übung"),
        "progress": ("Sieh deine Sprungkraft", "wachsen", "Jeder Sprung und jede Einheit, gespeichert"),
        "closer": ("Spring höher.", "Dunk früher.", "Dein Plan. Deine Sprungkraft. Dein erster Dunk."),
        "fine1": "Sprunghöhe aus der Flugzeit geschätzt · Abo erforderlich",
        "fine8": "Abo erforderlich",
    },
    "it": {
        "proof": ("Scopri il tuo", "vero salto verticale", None),
        "film": ("Filma un salto.", "Lo misuriamo noi.",
                 "Il tracciamento del corpo cronometra il volo fotogramma per fotogramma. Niente sensori, niente segni."),
        "scores": ("L'IA valuta", "ogni salto", "Reattività · Potenza · Controllo · Tecnica"),
        "gap": ("Quanto ti manca", "alla schiacciata?", None),
        "plan": ("Colma il divario", "settimana dopo settimana", "Un piano su misura per livello, giorni e attrezzatura"),
        "train": ("Ogni serie", "guidata e registrata", "Serie, ripetizioni e carichi, con la guida di ogni esercizio"),
        "progress": ("Guarda il tuo salto", "crescere", "Ogni salto e ogni allenamento, registrati"),
        "closer": ("Salta più in alto.", "Punta alla schiacciata.", "Il tuo piano. Il tuo salto. La tua prima schiacciata."),
        "fine1": "Salto stimato dal tempo di volo · Abbonamento richiesto",
        "fine8": "Abbonamento richiesto",
    },
}
CAPTION_LANG = {"en-US": "en", "en-metric": "en", "fr": "fr", "es": "es",
                "pt-BR": "pt-BR", "de": "de", "it": "it"}

SLIDES = ["proof", "film", "scores", "gap", "plan", "train", "progress", "closer"]

# Which raw capture each slide shows, and how far down it is scrolled (in
# capture pixels at the device's native width).
SCREEN = {
    "proof": ("result", 0),
    "film": ("tab_analyze", 0),
    "scores": ("result", 0.29),   # fraction of the capture height
    "gap": ("gap", 0),
    "plan": ("plan", 0),
    "train": ("log", 0),
    "progress": ("tab_progress", 0),
    "closer": ("result", 0),
}

CSS = """
@import url('https://fonts.googleapis.com/css2?family=Anton&family=Inter:wght@500;700;800&display=block');
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:%(w)dpx;height:%(h)dpx;overflow:hidden;background:#0A0A0B;color:#fff;font-family:Inter,sans-serif}
.s{position:relative;width:100%%;height:100%%;overflow:hidden}
.h{font-family:Anton,sans-serif;text-transform:uppercase;line-height:.95;letter-spacing:1px}
.o{color:#F26A21}
.sub{font-weight:700;color:#A6A6AD;line-height:1.3}
.fine{position:absolute;left:0;right:0;text-align:center;font-weight:500;color:#77777f}
.dev{position:absolute;background:#1c1c1f;box-shadow:0 0 0 %(rim)dpx #3b3b41,0 70px 160px rgba(0,0,0,.75),0 0 140px rgba(242,106,33,.16)}
.dev .scr{position:relative;width:100%%;height:100%%;overflow:hidden;background:#0A0A0B}
.dev .scr img{width:100%%;display:block}
.island{position:absolute;left:50%%;transform:translateX(-50%%);background:#000;z-index:3}
.sb{position:absolute;left:0;right:0;display:flex;justify-content:space-between;font-weight:700;z-index:2}
.ruler{position:absolute;top:0;bottom:0;width:6px;background:repeating-linear-gradient(180deg,#F26A21 0 6px,transparent 6px 64px);opacity:.75}
.glow{position:absolute;border-radius:50%%;filter:blur(40px)}
"""


def device_frame(raw_png, device, x, y, w, rot=0, scroll=0.0):
    """A phone or tablet with the real capture inside; may bleed off-canvas."""
    if device == "iphone69":
        h = w * 2868 / 1320
        radius, pad, rim = w * 0.14, w * 0.024, max(3, w * 0.005)
        island = (f'<div class="island" style="top:{w*0.037}px;width:{w*0.27}px;'
                  f'height:{w*0.078}px;border-radius:{w*0.04}px"></div>')
        sb_top, sb_font, sb_pad = w * 0.048, w * 0.05, w * 0.1
    else:
        h = w * 2752 / 2064
        radius, pad, rim = w * 0.045, w * 0.022, max(3, w * 0.003)
        island = ""
        sb_top, sb_font, sb_pad = w * 0.012, w * 0.019, w * 0.04
    status = (f'<div class="sb" style="top:{sb_top}px;padding:0 {sb_pad}px;font-size:{sb_font}px">'
              f'<span>9:41</span><span style="letter-spacing:{sb_font*0.12}px">'
              f'&#9646;&#9646;&#9646; 100%</span></div>')
    shift = scroll * (w - 2 * pad) * (2868 / 1320 if device == "iphone69" else 2752 / 2064)
    return (f'<div class="dev" style="left:{x}px;top:{y}px;width:{w}px;height:{h}px;'
            f'border-radius:{radius}px;padding:{pad}px;transform:rotate({rot}deg);'
            f'box-shadow:0 0 0 {rim}px #3b3b41,0 70px 160px rgba(0,0,0,.75),0 0 140px rgba(242,106,33,.16)">'
            f'<div class="scr" style="border-radius:{radius - pad}px">{island}'
            f'{"" if scroll else status}'
            f'<img src="{raw_png.as_uri()}" style="margin-top:-{shift}px"></div></div>')


def headline(c, x, y, size, width, align="left", sub=None, sub_size=None, gap=None):
    line1, line2, default_sub = c
    sub = default_sub if sub is None else sub
    sub_html = ""
    if sub:
        sub_html = (f'<div class="sub" style="margin-top:{gap or size*0.32}px;'
                    f'font-size:{sub_size or size*0.30}px">{sub}</div>')
    return (f'<div style="position:absolute;left:{x}px;top:{y}px;width:{width}px;text-align:{align}">'
            f'<div class="h" style="font-size:{size}px">{line1}<br><span class="o">{line2}</span></div>'
            f'{sub_html}</div>')


def slide_html(slide, device, set_name, raw_dir):
    W, H = DEVICES[device]
    ui, (num, unit), rim_label = SETS[set_name]
    cap = CAPTIONS[CAPTION_LANG[set_name]]
    shot_name, scroll = SCREEN[slide]
    shot = raw_dir / device / ui / f"{shot_name}.png"
    ipad = device == "ipad13"
    # Common: the measuring line on the right edge, every slide.
    ruler = f'<div class="ruler" style="right:{W*0.075}px"></div>'
    dunker = (HERE / "assets" / "dunker.png").as_uri()
    M = W * 0.07  # side margin
    hs = W * (0.112 if not ipad else 0.072)  # headline size

    def frame(x, y, w, rot=0, scroll=0.0):
        if ipad:
            # The app has no tablet layout, so a whole iPad screen is mostly
            # air at thumbnail size: show the top of it, large, bleeding off.
            return device_frame(shot, device, W * 0.08, max(y, H * 0.27), W * 0.84,
                                scroll=scroll)
        return device_frame(shot, device, x, y, w, rot=rot, scroll=scroll)

    fine = None
    if slide == "proof":
        bg = "radial-gradient(%dpx %dpx at 50%% 30%%,#3d1b08 0%%,#0A0A0B 70%%)" % (W * 0.9, H * 0.35)
        num_size = H * (0.19 if not ipad else 0.17)
        body = (headline(cap["proof"], 0, H * 0.05, hs, W, "center")
                + f'<div class="h o" style="position:absolute;top:{H*0.155}px;left:0;right:0;text-align:center;'
                  f'font-size:{num_size}px;line-height:1;text-shadow:0 0 {W*0.09}px rgba(242,106,33,.55)">'
                  f'{num}<span style="font-size:{num_size*0.42}px;margin-left:{W*0.01}px;text-transform:none">{unit}</span></div>'
                + frame(W * 0.15, H * 0.40, W * 0.70)
                )
        fine = cap["fine1"]
    elif slide == "film":
        bg = "#0A0A0B"
        body = (f'<img src="{dunker}" style="position:absolute;top:{H*0.33}px;left:{-W*0.55}px;width:{W*1.3}px;opacity:.20;transform:scaleX(-1)">'
                + headline(cap["film"], M, H * 0.05, hs, W - 2 * M, sub_size=W * (0.036 if not ipad else 0.026))
                + frame(W * 0.25, H * 0.30, W * 0.68, rot=5))
    elif slide == "scores":
        bg = "linear-gradient(180deg,#0A0A0B 0%,#1a110b 100%)"
        body = (headline(cap["scores"], M, H * 0.05, hs, W - 2 * M, sub_size=W * (0.036 if not ipad else 0.026))
                + frame(W * 0.13, H * 0.25, W * 0.74, scroll=scroll))
    elif slide == "gap":
        bg = "linear-gradient(180deg,#160b05 0%,#0A0A0B 50%)"
        rim_w = W * 0.30
        body = (f'<div style="position:absolute;top:{H*0.055}px;right:{W*0.075 - rim_w*0.5 + 3}px;width:{rim_w}px;height:{W*0.022}px;'
                f'border-radius:{W*0.011}px;background:#F26A21;box-shadow:0 0 {W*0.05}px rgba(242,106,33,.75)"></div>'
                f'<div style="position:absolute;top:{H*0.075}px;right:{W*0.075 + rim_w*0.55}px;font:800 {W*(0.032 if not ipad else 0.021)}px Inter;color:#F26A21;letter-spacing:2px">{rim_label}</div>'
                + headline(cap["gap"], M, H * 0.13, hs, W * 0.8)
                + frame(W * 0.13, H * 0.36, W * 0.70))
    elif slide == "plan":
        bg = "#0A0A0B"
        body = (headline(cap["plan"], M, H * 0.05, hs, W - 2 * M, sub_size=W * (0.036 if not ipad else 0.026))
                + frame(W * 0.13, H * 0.29, W * 0.70))
    elif slide == "train":
        bg = "linear-gradient(180deg,#0A0A0B 0%,#1d0f07 100%)"
        body = (headline(cap["train"], M, H * 0.05, hs, W - 2 * M, sub_size=W * (0.036 if not ipad else 0.026))
                + frame(W * 0.13, H * 0.29, W * 0.70))
    elif slide == "progress":
        bg = "#0A0A0B"
        body = (f'<img src="{dunker}" style="position:absolute;top:{H*0.40}px;left:{W*0.40}px;width:{W*1.2}px;opacity:.18">'
                + headline(cap["progress"], M, H * 0.05, hs, W - 2 * M, sub_size=W * (0.036 if not ipad else 0.026))
                + frame(W * 0.07, H * 0.29, W * 0.70, rot=-5))
    elif slide == "closer":
        bg = "#0A0A0B"
        body = (f'<img src="{dunker}" style="position:absolute;top:{-H*0.03}px;left:{-W*0.2}px;width:{W*1.4}px;opacity:.95">'
                f'<div style="position:absolute;inset:0;background:linear-gradient(180deg,rgba(10,10,11,0) 35%,#0A0A0B 66%)"></div>'
                + headline(cap["closer"], M, H * 0.56, W * (0.125 if not ipad else 0.085), W - 2 * M,
                           sub_size=W * (0.040 if not ipad else 0.028))
                )
        fine = cap["fine8"]
    else:
        raise ValueError(slide)
    fine = (f'<div class="fine" style="bottom:{H*0.02}px;font-size:{W*(0.025 if not ipad else 0.017)}px">{fine}</div>'
            if fine else "")
    css = CSS % {"w": W, "h": H, "rim": 4}
    return (f'<!doctype html><html lang="{CAPTION_LANG[set_name]}"><meta charset="utf-8"><style>{css}</style>'
            f'<div class="s" style="background:{bg}">{body}'
            f'<div style="position:absolute;left:0;right:0;bottom:0;height:{H*0.09}px;'
            f'background:linear-gradient(180deg,rgba(10,10,11,0),#0A0A0B 70%)"></div>'
            f'{fine}{ruler}</div></html>')


def chrome():
    for c in CHROME_CANDIDATES:
        if pathlib.Path(c).exists() or shutil.which(c):
            return c
    sys.exit("no Chrome/Edge found for rendering")


def render(html, out_png, size, browser):
    W, H = size
    with tempfile.TemporaryDirectory() as tmp:
        page = pathlib.Path(tmp) / "slide.html"
        page.write_text(html, encoding="utf-8")
        shot = pathlib.Path(tmp) / "shot.png"
        subprocess.run([browser, "--headless=new", "--disable-gpu", "--hide-scrollbars",
                        "--force-device-scale-factor=1", f"--window-size={W},{H}",
                        "--virtual-time-budget=10000", "--allow-file-access-from-files",
                        f"--screenshot={shot}", page.as_uri()],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        # The store rejects alpha channels: flatten to RGB at the exact size.
        img = Image.open(shot).convert("RGB")
        if img.size != (W, H):
            sys.exit(f"{out_png}: rendered {img.size}, expected {(W, H)}")
        out_png.parent.mkdir(parents=True, exist_ok=True)
        img.save(out_png, optimize=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default=str(REPO / "build" / "store_screenshots" / "raw"))
    ap.add_argument("--out", default=str(REPO / "build" / "store_screenshots" / "final"))
    ap.add_argument("--only", help="comma-separated caption sets")
    ap.add_argument("--devices", default=",".join(DEVICES))
    ap.add_argument("--slides", help="comma-separated 1-based slide numbers")
    args = ap.parse_args()
    raw, out = pathlib.Path(args.raw), pathlib.Path(args.out)
    sets = args.only.split(",") if args.only else list(SETS)
    slides = [int(s) for s in args.slides.split(",")] if args.slides else range(1, len(SLIDES) + 1)
    browser = chrome()
    for set_name in sets:
        for device in args.devices.split(","):
            for n in slides:
                slide = SLIDES[n - 1]
                target = out / set_name / device / f"{n:02d}_{slide}.png"
                render(slide_html(slide, device, set_name, raw), target, DEVICES[device], browser)
                print(target.relative_to(out))


if __name__ == "__main__":
    main()
