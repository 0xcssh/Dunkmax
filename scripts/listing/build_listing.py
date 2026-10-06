"""Source of truth for the App Store product page, all locales.

    py -3.12 scripts/listing/build_listing.py   # validates + writes 1.0.json

Checks every field against Apple's limits and the indexing rule that title,
subtitle and keyword field must not repeat a word (Apple indexes the three
together, so a duplicate is a wasted slot). Writes scripts/listing/1.0.json,
which scripts/asc_listing.py pushes through the App Store Connect API.

Copy rules (CLAUDE.md): no ratings, no user counts, no "top N %", nothing the
app does not do today. "Vertical" is always *estimated*. The privacy URL is
a placeholder until a real page is published; asc_listing.py refuses to push
while it is.
"""
import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).parent
VERSION = "1.0"
FIRST_RELEASE = True  # set False from the second version on
PRIVACY = "https://0xcssh.github.io/dunkit-legal/privacy.html"
TERMS = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
SUPPORT = "https://0xcssh.github.io/dunkit-legal/"

LIMITS = {"name": 30, "subtitle": 30, "keywords": 100, "promotionalText": 170,
          "description": 4000, "whatsNew": 4000}

# ---------------------------------------------------------------- English
DESC_EN = """Film one jump. Get your real vertical — and how far you are from dunking.

Dunk It measures your vertical jump with your phone's camera, then builds the training plan that closes the gap to the rim.

HOW IT WORKS

1. Film a jump. Straight on, full body in frame — record in the app or pick a clip from your library.
2. Get your vertical. On-device body tracking finds the exact frames where your feet leave the floor and land. Hang time gives height through physics — no wearables, no markers, no calibration.
3. See your dunk gap. Your height and reach set a dunk target, so every jump shows what is still to go.
4. Train the gap. Follow a plan matched to your level, your schedule and where you train.

WHAT YOU GET

— Estimated vertical from flight time, every jump logged
— Four form scores from the same clip: Bounce (ground contact), Power (dip and drive), Control (balance and lean), Form (arm swing and timing)
— One-foot or two-foot takeoff, detected automatically
— A written breakdown: your strongest and weakest measured aspect, with two drills aimed at the weakness
— Your dunk target for a one-hand or a two-hand finish
— 3 programs from beginner to advanced, 8 to 10 weeks, 2 to 5 sessions a week, with rest days, progressive overload and deload weeks
— Train at home or in the gym: no equipment, and every drill that needs kit is swapped for a bodyweight version
— Guided sessions: warm-up, sets, reps and loads, with a how-to and the common mistakes for every drill
— Progress: vertical trend, day streak, workouts completed, jump history with replay
— Inches or centimetres, following your region

HONEST BY DESIGN

If a clip can't be measured — athlete out of frame, flight cut off — Dunk It tells you why and how to film it again. It never makes up a number. Your clips never leave your phone.

DUNK IT PRO

Your first jump analysis is free. Dunk It Pro unlocks the full training plan, unlimited jump analysis and progress tracking. Weekly and yearly plans, with a free trial where offered. Payment is charged to your Apple ID at confirmation of purchase. The subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel it in your App Store account settings.

Privacy Policy: {PRIVACY}
Terms of Use: {TERMS}"""

WHATS_NEW_EN = "First release. Film a jump to get your estimated vertical, four form scores and your gap to the rim — then follow a plan built to close it."
PROMO_EN = "Film one jump, get your vertical and your gap to the rim — then follow the plan that closes it."

# ---------------------------------------------------------------- French
DESC_FR = """Filme un saut. Découvre ta vraie détente — et ce qu'il te manque pour dunker.

Dunk It mesure ta détente verticale avec la caméra de ton téléphone, puis construit le plan d'entraînement qui comble l'écart avec l'arceau.

COMMENT ÇA MARCHE

1. Filme un saut. De face, le corps entier dans le cadre — enregistre dans l'app ou choisis une vidéo de ta galerie.
2. Obtiens ta détente. Le suivi du corps, directement sur ton téléphone, repère l'image exacte où tes pieds quittent le sol et celle où ils le retrouvent. Ton temps de suspension donne ta hauteur par la physique — sans capteur, sans repère, sans calibrage.
3. Vois ce qu'il te manque. Ta taille et ton allonge fixent une cible de dunk : chaque saut te montre ce qu'il reste à gagner.
4. Comble l'écart. Suis un plan adapté à ton niveau, à ton planning et à l'endroit où tu t'entraînes.

CE QUE TU OBTIENS

— Détente estimée par le temps de vol, chaque saut enregistré
— Quatre scores techniques tirés de la même vidéo : Rebond (contact au sol), Puissance (flexion et poussée), Contrôle (équilibre et inclinaison), Technique (balancier des bras et timing)
— Impulsion à un pied ou à deux pieds, détectée automatiquement
— Une analyse écrite : ton point fort et ton point faible mesurés, avec deux exercices qui ciblent le point faible
— Ta cible de dunk à une main ou à deux mains
— 3 programmes du débutant au confirmé, 8 à 10 semaines, 2 à 5 séances par semaine, avec jours de repos, surcharge progressive et semaines de décharge
— À la maison ou en salle : sans matériel, chaque exercice qui en demande est remplacé par une version au poids du corps
— Séances guidées : échauffement, séries, répétitions et charges, avec les consignes et les erreurs fréquentes de chaque exercice
— Progression : courbe de détente, jours d'affilée, séances terminées, historique des sauts avec replay
— Centimètres ou pouces, selon ta région

HONNÊTE PAR CONCEPTION

Si une vidéo ne peut pas être mesurée — athlète hors cadre, vol coupé — Dunk It te dit pourquoi et comment la refilmer. Il n'invente jamais de chiffre. Tes vidéos ne quittent jamais ton téléphone.

DUNK IT PRO

Ta première analyse de saut est gratuite. Dunk It Pro débloque le plan d'entraînement complet, l'analyse de saut illimitée et le suivi de progression. Formules hebdomadaire et annuelle, avec essai gratuit lorsqu'il est proposé. Le paiement est débité sur ton identifiant Apple à la confirmation de l'achat. L'abonnement se renouvelle automatiquement sauf annulation au moins 24 heures avant la fin de la période en cours. Gère-le ou annule-le dans les réglages de ton compte App Store.

Politique de confidentialité : {PRIVACY}
Conditions d'utilisation : {TERMS}"""

WHATS_NEW_FR = "Première version. Filme un saut pour obtenir ta détente estimée, quatre scores techniques et ton écart avec l'arceau — puis suis le plan qui le comble."
PROMO_FR = "Filme un saut, découvre ta détente et ce qu'il te manque pour dunker — puis suis le plan qui comble l'écart."

# ---------------------------------------------------------------- Spanish
def desc_es(ball, dunk_noun, dunk_verb_inf):
    return f"""Graba un salto. Descubre tu salto vertical real — y cuánto te falta para {dunk_verb_inf}.

Dunk It mide tu salto vertical con la cámara de tu teléfono y crea el plan de entrenamiento que cierra la distancia hasta el aro.

CÓMO FUNCIONA

1. Graba un salto. De frente, con el cuerpo entero en el encuadre — grábalo en la app o elige un vídeo de tu galería.
2. Obtén tu salto vertical. El seguimiento corporal, en tu propio teléfono, encuentra el fotograma exacto en que tus pies dejan el suelo y en el que vuelven a tocarlo. El tiempo de vuelo da la altura por pura física — sin sensores, sin marcas, sin calibración.
3. Mira cuánto te falta. Tu estatura y tu alcance fijan un objetivo de {dunk_noun}: cada salto te muestra lo que queda por ganar.
4. Entrena la diferencia. Sigue un plan según tu nivel, tus días y dónde entrenas.

LO QUE OBTIENES

— Salto vertical estimado por el tiempo de vuelo, cada salto registrado
— Cuatro puntuaciones técnicas del mismo vídeo: Rebote (contacto con el suelo), Potencia (flexión e impulso), Control (equilibrio e inclinación), Técnica (balanceo de brazos y sincronización)
— Despegue a una o a dos piernas, detectado automáticamente
— Un análisis escrito: tu punto fuerte y tu punto débil medidos, con dos ejercicios para el punto débil
— Tu objetivo de {dunk_noun} a una o a dos manos
— 3 programas de principiante a avanzado, de 8 a 10 semanas, de 2 a 5 sesiones por semana, con días de descanso, sobrecarga progresiva y semanas de descarga
— En casa o en el gimnasio: sin material, cada ejercicio que lo necesita se cambia por una versión con el peso corporal
— Sesiones guiadas: calentamiento, series, repeticiones y cargas, con instrucciones y errores comunes de cada ejercicio
— Progreso: evolución del salto, racha de días, sesiones completadas, historial de saltos con repetición
— Centímetros o pulgadas, según tu región

HONESTO POR DISEÑO

Si un vídeo no se puede medir — atleta fuera del encuadre, vuelo cortado — Dunk It te dice por qué y cómo volver a grabarlo. Nunca se inventa un número. Tus vídeos nunca salen de tu teléfono.

DUNK IT PRO

Tu primer análisis de salto es gratis. Dunk It Pro desbloquea el plan de entrenamiento completo, el análisis de saltos ilimitado y el seguimiento del progreso. Planes semanal y anual, con prueba gratuita cuando se ofrece. El pago se carga a tu ID de Apple al confirmar la compra. La suscripción se renueva automáticamente salvo que se cancele al menos 24 horas antes del final del periodo actual. Gestiónala o cancélala en los ajustes de tu cuenta del App Store.

Política de privacidad: {PRIVACY}
Condiciones de uso: {TERMS}"""

WHATS_NEW_ES = "Primera versión. Graba un salto para obtener tu salto vertical estimado, cuatro puntuaciones técnicas y lo que te falta hasta el aro — y sigue el plan para conseguirlo."
PROMO_ES = "Graba un salto, descubre tu salto vertical y cuánto te falta hasta el aro — y sigue el plan que cierra la distancia."

# ---------------------------------------------------------------- Portuguese (BR)
DESC_PT = """Grave um salto. Descubra sua impulsão real — e quanto falta para enterrar.

O Dunk It mede seu salto vertical com a câmera do celular e monta o plano de treino que fecha a distância até o aro.

COMO FUNCIONA

1. Grave um salto. De frente, com o corpo inteiro no quadro — grave no app ou escolha um vídeo da galeria.
2. Receba sua impulsão. O rastreamento corporal, no próprio celular, encontra o quadro exato em que seus pés saem do chão e o quadro em que voltam. O tempo de voo dá a altura pela física — sem sensores, sem marcações, sem calibração.
3. Veja quanto falta. Sua altura e seu alcance definem uma meta de enterrada: cada salto mostra o que ainda falta.
4. Treine a diferença. Siga um plano de acordo com seu nível, sua agenda e onde você treina.

O QUE VOCÊ RECEBE

— Impulsão estimada pelo tempo de voo, cada salto registrado
— Quatro notas técnicas do mesmo vídeo: Reatividade (contato com o chão), Potência (flexão e impulso), Controle (equilíbrio e inclinação), Técnica (balanço dos braços e tempo)
— Saída com um ou com dois pés, detectada automaticamente
— Uma análise escrita: seu ponto forte e seu ponto fraco medidos, com dois exercícios para o ponto fraco
— Sua meta de enterrada com uma ou com duas mãos
— 3 programas do iniciante ao avançado, de 8 a 10 semanas, de 2 a 5 treinos por semana, com dias de descanso, sobrecarga progressiva e semanas de recuperação
— Em casa ou na academia: sem equipamento, cada exercício que precisa dele é trocado por uma versão com o peso do corpo
— Treinos guiados: aquecimento, séries, repetições e cargas, com instruções e erros comuns de cada exercício
— Progresso: evolução da impulsão, sequência de dias, treinos concluídos, histórico de saltos com replay
— Centímetros ou polegadas, de acordo com sua região

HONESTO POR PRINCÍPIO

Se um vídeo não puder ser medido — atleta fora do quadro, voo cortado — o Dunk It diz por quê e como gravar de novo. Ele nunca inventa um número. Seus vídeos nunca saem do seu celular.

DUNK IT PRO

Sua primeira análise de salto é grátis. O Dunk It Pro libera o plano de treino completo, análises de salto ilimitadas e o acompanhamento do progresso. Planos semanal e anual, com teste grátis quando oferecido. O pagamento é cobrado no seu ID Apple na confirmação da compra. A assinatura é renovada automaticamente, a menos que seja cancelada pelo menos 24 horas antes do fim do período atual. Gerencie ou cancele nos ajustes da sua conta da App Store.

Política de Privacidade: {PRIVACY}
Termos de Uso: {TERMS}"""

WHATS_NEW_PT = "Primeira versão. Grave um salto para receber sua impulsão estimada, quatro notas técnicas e quanto falta até o aro — e siga o plano para chegar lá."
PROMO_PT = "Grave um salto, descubra sua impulsão e quanto falta para enterrar — e siga o plano que fecha a distância."

# ---------------------------------------------------------------- German
DESC_DE = """Filme einen Sprung. Erfahre deine echte Sprungkraft — und wie weit du vom Dunk entfernt bist.

Dunk It misst deinen Vertikalsprung mit der Kamera deines Handys und baut den Trainingsplan, der die Lücke zum Korb schließt.

SO FUNKTIONIERT ES

1. Filme einen Sprung. Von vorn, ganzer Körper im Bild — direkt in der App oder als Video aus deiner Mediathek.
2. Erhalte deine Sprunghöhe. Körpertracking direkt auf dem Gerät findet genau das Bild, in dem deine Füße den Boden verlassen, und das, in dem sie landen. Aus der Flugzeit ergibt sich die Höhe — reine Physik, ohne Sensoren, ohne Markierungen, ohne Kalibrierung.
3. Sieh deine Lücke zum Dunk. Größe und Reichhöhe ergeben ein Dunk-Ziel: Jeder Sprung zeigt, was noch fehlt.
4. Trainiere die Lücke weg. Folge einem Plan nach deinem Level, deinem Zeitplan und deinem Trainingsort.

DAS BEKOMMST DU

— Sprunghöhe aus der Flugzeit geschätzt, jeder Sprung gespeichert
— Vier Technik-Scores aus demselben Video: Reaktivität (Bodenkontakt), Kraft (Ausholbewegung und Absprung), Kontrolle (Balance und Neigung), Technik (Armschwung und Timing)
— Einbeiniger oder beidbeiniger Absprung, automatisch erkannt
— Eine schriftliche Auswertung: deine stärkste und schwächste gemessene Komponente, mit zwei Übungen für die Schwäche
— Dein Dunk-Ziel für einhändig oder beidhändig
— 3 Programme vom Einsteiger bis zum Fortgeschrittenen, 8 bis 10 Wochen, 2 bis 5 Einheiten pro Woche, mit Ruhetagen, progressiver Steigerung und Deload-Wochen
— Zu Hause oder im Gym: ohne Ausrüstung wird jede Übung, die Equipment braucht, durch eine Version mit Körpergewicht ersetzt
— Geführte Einheiten: Aufwärmen, Sätze, Wiederholungen und Gewichte, mit Anleitung und typischen Fehlern zu jeder Übung
— Fortschritt: Verlauf der Sprunghöhe, Serie, absolvierte Einheiten, Sprungverlauf mit Wiedergabe
— Zentimeter oder Zoll, je nach Region

EHRLICH VON GRUND AUF

Lässt sich ein Video nicht messen — Athlet außerhalb des Bilds, Flug abgeschnitten — sagt dir Dunk It, warum, und wie du es neu filmst. Es erfindet nie eine Zahl. Deine Videos verlassen nie dein Handy.

DUNK IT PRO

Deine erste Sprunganalyse ist kostenlos. Dunk It Pro schaltet den kompletten Trainingsplan, unbegrenzte Sprunganalysen und das Fortschritts-Tracking frei. Wochen- und Jahresabo, mit Gratis-Testphase, wo angeboten. Die Zahlung wird bei Kaufbestätigung über deine Apple-ID abgerechnet. Das Abo verlängert sich automatisch, sofern es nicht mindestens 24 Stunden vor Ende des laufenden Zeitraums gekündigt wird. Verwalten oder kündigen kannst du es in den Einstellungen deines App Store-Accounts.

Datenschutzerklärung: {PRIVACY}
Nutzungsbedingungen: {TERMS}"""

WHATS_NEW_DE = "Erste Version. Filme einen Sprung für deine geschätzte Sprunghöhe, vier Technik-Scores und deine Lücke zum Korb — und folge dem Plan, der sie schließt."
PROMO_DE = "Filme einen Sprung, erfahre deine Sprungkraft und wie weit du vom Dunk entfernt bist — und folge dem Plan, der die Lücke schließt."

# ---------------------------------------------------------------- Italian
DESC_IT = """Filma un salto. Scopri il tuo vero salto verticale — e quanto ti manca per schiacciare.

Dunk It misura il tuo salto verticale con la fotocamera del telefono e costruisce il piano di allenamento che colma la distanza dal ferro.

COME FUNZIONA

1. Filma un salto. Di fronte, con tutto il corpo nell'inquadratura — registra nell'app o scegli un video dalla libreria.
2. Ottieni il tuo salto. Il tracciamento del corpo, direttamente sul telefono, trova il fotogramma esatto in cui i piedi lasciano il suolo e quello in cui atterrano. Il tempo di volo dà l'altezza con la fisica — niente sensori, niente segni, niente calibrazione.
3. Guarda quanto ti manca. Statura e allungo fissano un obiettivo di schiacciata: ogni salto ti mostra quanto resta.
4. Allena la differenza. Segui un piano su misura per il tuo livello, i tuoi giorni e il luogo in cui ti alleni.

COSA OTTIENI

— Salto verticale stimato dal tempo di volo, ogni salto registrato
— Quattro punteggi tecnici dallo stesso video: Reattività (contatto con il suolo), Potenza (piegamento e spinta), Controllo (equilibrio e inclinazione), Tecnica (slancio delle braccia e tempismo)
— Stacco a un piede o a due piedi, rilevato automaticamente
— Un'analisi scritta: il tuo punto forte e il tuo punto debole misurati, con due esercizi per il punto debole
— Il tuo obiettivo di schiacciata a una o a due mani
— 3 programmi dal principiante all'avanzato, da 8 a 10 settimane, da 2 a 5 sedute a settimana, con giorni di riposo, sovraccarico progressivo e settimane di scarico
— A casa o in palestra: senza attrezzi, ogni esercizio che li richiede viene sostituito da una versione a corpo libero
— Sedute guidate: riscaldamento, serie, ripetizioni e carichi, con istruzioni ed errori comuni di ogni esercizio
— Progressi: andamento del salto, serie di giorni, sedute completate, storico dei salti con replay
— Centimetri o pollici, in base alla tua regione

ONESTA PER PRINCIPIO

Se un video non si può misurare — atleta fuori dall'inquadratura, volo tagliato — Dunk It ti dice perché e come rifilmarlo. Non inventa mai un numero. I tuoi video non lasciano mai il telefono.

DUNK IT PRO

La prima analisi del salto è gratuita. Dunk It Pro sblocca il piano di allenamento completo, analisi illimitate del salto e il monitoraggio dei progressi. Piani settimanale e annuale, con prova gratuita dove prevista. Il pagamento viene addebitato sull'ID Apple alla conferma dell'acquisto. L'abbonamento si rinnova automaticamente se non viene disdetto almeno 24 ore prima della fine del periodo in corso. Gestiscilo o disdicilo nelle impostazioni del tuo account App Store.

Informativa sulla privacy: {PRIVACY}
Termini di utilizzo: {TERMS}"""

WHATS_NEW_IT = "Prima versione. Filma un salto per ottenere il salto verticale stimato, quattro punteggi tecnici e quanto ti manca dal ferro — poi segui il piano per arrivarci."
PROMO_IT = "Filma un salto, scopri il tuo salto verticale e quanto ti manca per schiacciare — poi segui il piano che colma la distanza."


def fill(text):
    return text.replace("{PRIVACY}", PRIVACY).replace("{TERMS}", TERMS)


# locale -> (name, subtitle, keywords, description, whatsNew, promo)
EN_KW = "higher,measure,height,workout,training,plyometrics,tracker,hops,explosive,leap,volleyball,coach"
LOCALES = {
    "en-US": ("Dunk It: Vertical Jump Trainer", "AI Vert Test & Basketball Plan", EN_KW, DESC_EN, WHATS_NEW_EN, PROMO_EN),
    "en-GB": ("Dunk It: Vertical Jump Trainer", "AI Vert Test & Basketball Plan", EN_KW, DESC_EN, WHATS_NEW_EN, PROMO_EN),
    "en-CA": ("Dunk It: Vertical Jump Trainer", "AI Vert Test & Basketball Plan", EN_KW, DESC_EN, WHATS_NEW_EN, PROMO_EN),
    "en-AU": ("Dunk It: Vertical Jump Trainer", "AI Vert Test & Basketball Plan", EN_KW, DESC_EN, WHATS_NEW_EN, PROMO_EN),
    "fr-FR": ("Dunk It : Détente Verticale", "Test de saut et plan basket",
              "sauter,haut,entrainement,pliometrie,explosivite,jambes,volley,mesurer,vertical,jump,coach,muscu,ia",
              DESC_FR, WHATS_NEW_FR, PROMO_FR),
    "fr-CA": ("Dunk It : Détente Verticale", "Test de saut et plan basket",
              "sauter,haut,entrainement,pliometrie,explosivite,jambes,volley,mesurer,vertical,jump,coach,muscu,ia",
              DESC_FR, WHATS_NEW_FR, PROMO_FR),
    "es-MX": ("Dunk It: Salto Vertical", "Brinca más alto y llega al aro",
              "medir,basquetbol,baloncesto,entrenamiento,pliometria,clavada,impulso,piernas,voleibol,altura,ia,jump",
              desc_es("básquetbol", "clavada", "clavarla"), WHATS_NEW_ES, PROMO_ES),
    "es-ES": ("Dunk It: Salto Vertical", "Salta más alto y llega al aro",
              "baloncesto,entrenamiento,pliometria,mate,machacar,potencia,piernas,voleibol,test,bosco,altura,ia",
              desc_es("baloncesto", "mate", "hacer un mate"), WHATS_NEW_ES, PROMO_ES),
    "pt-BR": ("Dunk It: Treino de Impulsão", "Meça seu salto vertical com IA",
              "pular,alto,basquete,enterrada,pliometria,volei,pernas,explosao,teste,altura,treinador,jump",
              DESC_PT, WHATS_NEW_PT, PROMO_PT),
    "de-DE": ("Dunk It: Sprungkraft Training", "Sprunghöhe messen mit KI",
              "basketball,vertikal,sprungtest,schnellkraft,plyometrie,beintraining,volleyball,springen,höher",
              DESC_DE, WHATS_NEW_DE, PROMO_DE),
    "it": ("Dunk It: Salto Verticale", "Misura e migliora l'elevazione",
           "ia,allenamento,basket,schiacciata,pliometria,esplosivita,gambe,pallavolo,test,altezza,coach",
           DESC_IT, WHATS_NEW_IT, PROMO_IT),
}


def words(s):
    return {w for w in re.split(r"[^\wÀ-ÿ]+", s.lower()) if w}


def main():
    errors, out = [], {"version": VERSION, "localizations": {}, "appInfo": {}}
    for loc, (name, sub, kw, desc, new, promo) in LOCALES.items():
        desc = fill(desc)
        fields = {"name": name, "subtitle": sub, "keywords": kw, "description": desc,
                  "whatsNew": new, "promotionalText": promo}
        for k, v in fields.items():
            if len(v) > LIMITS[k]:
                errors.append(f"{loc}.{k}: {len(v)} > {LIMITS[k]}")
        if " " in kw or ", " in kw:
            errors.append(f"{loc}.keywords: spaces waste characters")
        dup = (words(name) | words(sub)) & set(kw.split(","))
        dup |= words(name) & words(sub) - {"it", "dunk", "de", "e", "y", "et", "&", "mit", "di", "il", "tu", "ta"}
        if dup:
            errors.append(f"{loc}: repeated words {sorted(dup)}")
        print(f"{loc:6} name {len(name):2}/30  sub {len(sub):2}/30  kw {len(kw):3}/100  "
              f"desc {len(desc):4}/4000  promo {len(promo):3}/170")
        out["localizations"][loc] = {"description": desc, "keywords": kw,
                                     "promotionalText": promo, "supportUrl": SUPPORT}
        # App Store Connect rejects "What's New" on an app's first version
        # (409 "cannot be edited at this time"); it ships from the next one.
        if not FIRST_RELEASE:
            out["localizations"][loc]["whatsNew"] = new
        out["appInfo"][loc] = {"name": name, "subtitle": sub}
    if errors:
        sys.exit("\n".join(errors))
    (HERE / f"{VERSION}.json").write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n",
                                         encoding="utf-8")
    print(f"wrote {VERSION}.json")


if __name__ == "__main__":
    main()
