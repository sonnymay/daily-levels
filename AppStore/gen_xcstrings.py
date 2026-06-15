#!/usr/bin/env python3
# Generates DailyLevels/Localizable.xcstrings from a translation table.
# Languages: es, pt-BR, de, fr, ja. All non-English flagged needs_review.
import json, collections

LANGS = ["es", "pt-BR", "de", "fr", "ja"]

# key -> [es, pt-BR, de, fr, ja]   (key == English source string, byte-identical to code)
T = collections.OrderedDict()
def add(key, es, pt, de, fr, ja): T[key] = [es, pt, de, fr, ja]

# --- Class names ---
add("Novice","Novato","Novato","Neuling","Novice","ノービス")
add("Squire","Escudero","Escudeiro","Knappe","Écuyer","スクワイア")
add("Swordsman","Espadachín","Espadachim","Schwertkämpfer","Bretteur","ソードマン")
add("Knight","Caballero","Cavaleiro","Ritter","Chevalier","ナイト")
add("Crusader","Cruzado","Cruzado","Kreuzritter","Croisé","クルセイダー")
add("Champion","Campeón","Campeão","Champion","Champion","チャンピオン")
add("Paladin","Paladín","Paladino","Paladin","Paladin","パラディン")
add("Hero","Héroe","Herói","Held","Héros","ヒーロー")
add("Legend","Leyenda","Lenda","Legende","Légende","レジェンド")
add("Mythic","Mítico","Mítico","Mythisch","Mythique","ミシック")

# --- Header / progress ---
add("Today","Hoy","Hoje","Heute","Aujourd’hui","今日")
add("Level %lld","Nivel %lld","Nível %lld","Level %lld","Niveau %lld","レベル%lld")
add("%lld min focused today","%lld min de foco hoy","%lld min de foco hoje","%lld Min. fokussiert heute","%lld min de focus aujourd’hui","今日%lld分集中")
add("5 min = 1 level","5 min = 1 nivel","5 min = 1 nível","5 Min. = 1 Level","5 min = 1 niveau","5分 = 1レベル")
add("Daily class %@","Clase diaria %@","Classe diária %@","Tagesklasse %@","Classe du jour %@","今日のクラス %@")
add("Level progress","Progreso de nivel","Progresso do nível","Level-Fortschritt","Progression du niveau","レベルの進捗")
add("%lld percent","%lld por ciento","%lld por cento","%lld Prozent","%lld pour cent","%lldパーセント")
add("Current session","Sesión actual","Sessão atual","Aktuelle Sitzung","Session en cours","現在のセッション")
add("Paused","En pausa","Pausado","Pausiert","En pause","一時停止中")
add("Ready to focus","Listo para concentrarte","Pronto para focar","Bereit zum Fokussieren","Prêt à se concentrer","集中の準備OK")
add("Max level — Mythic!","Nivel máximo: ¡Mítico!","Nível máximo — Mítico!","Maximales Level — Mythisch!","Niveau max — Mythique !","最大レベル — ミシック！")
add("Level up!","¡Subiste de nivel!","Subiu de nível!","Level-up!","Niveau supérieur !","レベルアップ！")
add("Next level in %lld min","Próximo nivel en %lld min","Próximo nível em %lld min","Nächstes Level in %lld Min.","Niveau suivant dans %lld min","次のレベルまで%lld分")

# --- Celebration ---
add("%@ reached","%@ alcanzado","%@ alcançado","%@ erreicht","%@ atteint","%@に到達")
add("Level %lld!","¡Nivel %lld!","Nível %lld!","Level %lld!","Niveau %lld !","レベル%lld！")
add("Class changed to %@","Clase cambiada a %@","Classe alterada para %@","Klasse geändert zu %@","Classe changée en %@","クラスが%@に変化")
add("Level %lld reached","Nivel %lld alcanzado","Nível %lld alcançado","Level %lld erreicht","Niveau %lld atteint","レベル%lldに到達")

# --- Bottom button ---
add("Pause","Pausar","Pausar","Pause","Pause","一時停止")
add("Resume","Reanudar","Retomar","Fortsetzen","Reprendre","再開")
add("Start","Empezar","Começar","Start","Démarrer","開始")
add("Pause focus timer","Pausar el temporizador de concentración","Pausar o cronômetro de foco","Fokus-Timer pausieren","Mettre en pause le minuteur de focus","集中タイマーを一時停止")
add("Resume focus timer","Reanudar el temporizador de concentración","Retomar o cronômetro de foco","Fokus-Timer fortsetzen","Reprendre le minuteur de focus","集中タイマーを再開")
add("Start focus timer","Iniciar el temporizador de concentración","Iniciar o cronômetro de foco","Fokus-Timer starten","Démarrer le minuteur de focus","集中タイマーを開始")
add("Lock your phone — focus keeps counting","Bloquea el teléfono: el foco sigue contando","Bloqueie o telefone — o foco continua contando","Sperre dein Telefon — der Fokus zählt weiter","Verrouille ton téléphone — le focus continue de compter","スマホをロックしても集中はカウント継続")

# --- Unlock Pro row ---
add("Evolve your hero all the way to Mythic","Haz evolucionar a tu héroe hasta Mítico","Evolua seu herói até Mítico","Entwickle deinen Helden bis Mythisch","Fais évoluer ton héros jusqu’à Mythique","ヒーローをミシックまで進化させよう")
add("Opens the Pro unlock","Abre el desbloqueo Pro","Abre o desbloqueio Pro","Öffnet die Pro-Freischaltung","Ouvre le déblocage Pro","Pro解除を開く")

# --- Intro sheet ---
add("Welcome to Daily Levels","Te damos la bienvenida a Daily Levels","Boas-vindas ao Daily Levels","Willkommen bei Daily Levels","Bienvenue dans Daily Levels","Daily Levelsへようこそ")
add("Focus to level up — every 5 minutes is one level.","Concéntrate para subir de nivel: cada 5 minutos es un nivel.","Foque para subir de nível — cada 5 minutos é um nível.","Fokussiere, um aufzusteigen — alle 5 Minuten ein Level.","Concentre-toi pour monter de niveau — 5 minutes = un niveau.","集中してレベルアップ — 5分ごとに1レベル。")
add("Lock your phone — your focus keeps counting.","Bloquea el teléfono: tu foco sigue contando.","Bloqueie o telefone — seu foco continua contando.","Sperre dein Telefon — dein Fokus zählt weiter.","Verrouille ton téléphone — ton focus continue de compter.","スマホをロックしても集中はカウント継続。")
add("Switch apps and your hero rests until you return.","Cambia de app y tu héroe descansa hasta que vuelvas.","Troque de app e seu herói descansa até você voltar.","Wechsle die App und dein Held ruht, bis du zurückkommst.","Change d’appli et ton héros se repose jusqu’à ton retour.","アプリを切り替えると、戻るまでヒーローは休憩します。")
add("Start focusing","Empezar a concentrarte","Começar a focar","Fokussieren beginnen","Commencer à se concentrer","集中を始める")

# --- Paywall ---
add("One-time unlock. Yours forever.","Desbloqueo único. Tuyo para siempre.","Desbloqueio único. Seu para sempre.","Einmalige Freischaltung. Für immer deins.","Déblocage unique. À toi pour toujours.","一度の解除で、ずっとあなたのもの。")
add("Evolve to Mythic","Evoluciona hasta Mítico","Evolua até Mítico","Bis Mythisch entwickeln","Évolue jusqu’à Mythique","ミシックまで進化")
add("Unlock your hero's full journey — Knight, Crusader, all the way to Mythic.","Desbloquea el viaje completo de tu héroe: Caballero, Cruzado y hasta Mítico.","Desbloqueie a jornada completa do seu herói — Cavaleiro, Cruzado, até Mítico.","Schalte die ganze Reise deines Helden frei — Ritter, Kreuzritter, bis Mythisch.","Débloque tout le parcours de ton héros — Chevalier, Croisé, jusqu’à Mythique.","ヒーローの全行程を解除 — ナイト、クルセイダー、ミシックまで。")
add("All 10 classes","Las 10 clases","Todas as 10 classes","Alle 10 Klassen","Les 10 classes","全10クラス")
add("See every class your focus earns, not just the first three.","Ve todas las clases que gana tu concentración, no solo las tres primeras.","Veja todas as classes que seu foco conquista, não só as três primeiras.","Sieh jede Klasse, die dein Fokus verdient — nicht nur die ersten drei.","Vois toutes les classes que ton focus débloque, pas seulement les trois premières.","最初の3つだけでなく、集中で得られる全クラスを表示。")
add("No ads, no tracking","Sin anuncios ni rastreo","Sem anúncios, sem rastreamento","Keine Werbung, kein Tracking","Sans pub, sans suivi","広告なし、トラッキングなし")
add("No accounts, no analytics, no ads — ever. Your focus stays on your phone.","Sin cuentas, sin analíticas, sin anuncios, nunca. Tu concentración se queda en tu teléfono.","Sem contas, sem análises, sem anúncios — nunca. Seu foco fica no seu telefone.","Keine Konten, keine Analyse, keine Werbung — niemals. Dein Fokus bleibt auf deinem Telefon.","Pas de comptes, pas d’analyses, pas de pub — jamais. Ton focus reste sur ton téléphone.","アカウントも分析も広告も一切なし。集中はあなたのスマホの中だけ。")
add("Support an indie dev","Apoya a un dev independiente","Apoie um dev indie","Unterstütze einen Indie-Entwickler","Soutiens un dév indé","個人開発者を応援")
add("A one-time purchase keeps Daily Levels calm and ad-free.","Una compra única mantiene Daily Levels tranquilo y sin anuncios.","Uma compra única mantém o Daily Levels calmo e sem anúncios.","Ein einmaliger Kauf hält Daily Levels ruhig und werbefrei.","Un achat unique garde Daily Levels calme et sans pub.","一度の購入でDaily Levelsを静かで広告なしに保てます。")
add("Unlock Pro · %@","Desbloquear Pro · %@","Desbloquear Pro · %@","Pro freischalten · %@","Débloquer Pro · %@","Proを解除 · %@")
add("Restore Purchases","Restaurar compras","Restaurar compras","Käufe wiederherstellen","Restaurer les achats","購入を復元")
add("Privacy Policy","Política de privacidad","Política de Privacidade","Datenschutzrichtlinie","Politique de confidentialité","プライバシーポリシー")
add("Terms","Términos","Termos","Nutzungsbedingungen","Conditions","利用規約")

# --- Hero panel ---
add("Unlock Pro to evolve","Desbloquea Pro para evolucionar","Desbloqueie o Pro para evoluir","Pro freischalten zum Aufsteigen","Débloquer Pro pour évoluer","Proで進化を解除")
add("Hero locked. Unlock Pro to evolve past %@.","Héroe bloqueado. Desbloquea Pro para evolucionar más allá de %@.","Herói bloqueado. Desbloqueie o Pro para evoluir além de %@.","Held gesperrt. Schalte Pro frei, um über %@ hinaus aufzusteigen.","Héros verrouillé. Débloque Pro pour évoluer au-delà de %@.","ヒーローはロック中。Proで%@より先へ進化。")
add("%@ hero, grinding","Héroe %@, entrenando","Herói %@, treinando","%@-Held, am Grinden","Héros %@, en pleine action","%@のヒーロー、修行中")
add("%@ hero, resting","Héroe %@, descansando","Herói %@, descansando","%@-Held, ruht","Héros %@, au repos","%@のヒーロー、休憩中")
add("Grinding…","Entrenando…","Treinando…","Am Grinden…","En pleine action…","修行中…")
add("Resting by the campfire","Descansando junto a la fogata","Descansando perto da fogueira","Rast am Lagerfeuer","Repos près du feu de camp","焚き火のそばで休憩中")

# --- History card ---
add("Focus History","Historial de concentración","Histórico de foco","Fokus-Verlauf","Historique de focus","集中の履歴")
add("History","Historial","Histórico","Verlauf","Historique","履歴")
add("Levels earned each day · resets at midnight","Niveles ganados cada día · se reinicia a medianoche","Níveis ganhos por dia · reinicia à meia-noite","Täglich erreichte Level · Reset um Mitternacht","Niveaux gagnés chaque jour · réinitialisé à minuit","毎日獲得したレベル · 深夜にリセット")
add("%lld min focus time","%lld min de foco","%lld min de foco","%lld Min. Fokuszeit","%lld min de focus","集中時間%lld分")
add("%lld-day focus streak","Racha de %lld días","Sequência de %lld dias","%lld-Tage-Serie","Série de %lld jours","%lld日連続")
add("%lld day focus streak","Racha de concentración de %lld días","Sequência de foco de %lld dias","%lld Tage Fokus-Serie","Série de concentration de %lld jours","%lld日間の集中連続記録")

# --- Notifications ---
add("New class unlocked — keep grinding!","¡Nueva clase desbloqueada! Sigue entrenando.","Nova classe desbloqueada — continue treinando!","Neue Klasse freigeschaltet — weiter grinden!","Nouvelle classe débloquée — continue !","新しいクラスを解除 — その調子で修行を！")
add("You're at level %lld. Keep going.","Estás en el nivel %lld. ¡Sigue así!","Você está no nível %lld. Continue!","Du bist auf Level %lld. Weiter so!","Tu es au niveau %lld. Continue !","レベル%lldです。その調子！")

# --- Growth: milestone share, free-ceiling nudge, onboarding ---
add("You reached %@!","¡Alcanzaste %@!","Você alcançou %@!","%@ erreicht!","%@ atteint !","%@に到達！")
add("Show a friend how far your focus has climbed.","Muestra a un amigo hasta dónde llegó tu concentración.","Mostre a um amigo até onde seu foco chegou.","Zeig einem Freund, wie weit dein Fokus geklettert ist.","Montre à un ami jusqu’où ta concentration t’a mené.","あなたの集中がどこまで登ったか友だちに見せよう。")
add("Share your climb","Comparte tu ascenso","Compartilhe sua escalada","Deinen Aufstieg teilen","Partager ton ascension","登りを共有")
add("Maybe later","Quizás más tarde","Talvez depois","Vielleicht später","Plus tard","あとで")
add("You've reached the free climb","Llegaste al límite gratuito","Você chegou ao limite gratuito","Du hast den kostenlosen Aufstieg erreicht","Tu as atteint le palier gratuit","無料の範囲に到達しました")
add("Unlock Knight → Mythic — yours forever","Desbloquea de Caballero a Mítico, para siempre","Desbloqueie de Cavaleiro a Mítico, para sempre","Ritter bis Mythisch freischalten — für immer deins","Débloque Chevalier → Mythique, à toi pour toujours","ナイト→ミシックを解除 — ずっとあなたのもの")
add("Come back tomorrow — your streak keeps growing.","Vuelve mañana: tu racha sigue creciendo.","Volte amanhã — sua sequência continua crescendo.","Komm morgen wieder — deine Serie wächst weiter.","Reviens demain — ta série continue de grandir.","明日も戻ってきて — 連続記録は伸び続けます。")
add("Share your climb to inspire a friend.","Comparte tu ascenso para inspirar a un amigo.","Compartilhe sua escalada para inspirar um amigo.","Teile deinen Aufstieg und inspiriere einen Freund.","Partage ton ascension pour inspirer un ami.","登りを共有して友だちを励まそう。")

strings = {}
for key, vals in T.items():
    locs = {}
    for lang, val in zip(LANGS, vals):
        locs[lang] = {"stringUnit": {"state": "needs_review", "value": val}}
    strings[key] = {"extractionState": "manual", "localizations": locs}

catalog = {"sourceLanguage": "en", "strings": strings, "version": "1.0"}
out = "/Users/santipapmay/Documents/Daily Levels/DailyLevels/Localizable.xcstrings"
with open(out, "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")
print(f"wrote {out} with {len(strings)} keys × {len(LANGS)} languages")
