#!/usr/bin/env python3
# Generates DailyLevels/Localizable.xcstrings from a translation table.
# Languages: es, pt-BR, de, fr, ja. All non-English flagged needs_review.
import collections
import json
from pathlib import Path

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
add("Locking counts. Switching apps pauses your hero.","Bloquear el teléfono cuenta. Cambiar de app pausa a tu héroe.","Bloquear o telefone conta. Trocar de app pausa seu herói.","Sperren zählt. Ein App-Wechsel pausiert deinen Helden.","Verrouiller compte. Changer d’app met ton héros en pause.","ロック中もカウント。アプリを切り替えるとヒーローは一時停止します。")
add("Start focusing","Empezar a concentrarte","Começar a focar","Fokussieren beginnen","Commencer à se concentrer","集中を始める")

# --- Paywall ---
add("One-time unlock. Yours forever.","Desbloqueo único. Tuyo para siempre.","Desbloqueio único. Seu para sempre.","Einmalige Freischaltung. Für immer deins.","Déblocage unique. À toi pour toujours.","一度の解除で、ずっとあなたのもの。")
add("7 more hero evolutions","7 evoluciones de héroe más","Mais 7 evoluções de herói","7 weitere Heldenentwicklungen","7 évolutions de héros en plus","さらに7段階のヒーロー進化")
add("Unlock Knight, Crusader, Champion, Paladin, Hero, Legend, and Mythic.","Desbloquea Caballero, Cruzado, Campeón, Paladín, Héroe, Leyenda y Mítico.","Desbloqueie Cavaleiro, Cruzado, Campeão, Paladino, Herói, Lenda e Mítico.","Schalte Ritter, Kreuzritter, Champion, Paladin, Held, Legende und Mythisch frei.","Débloque Chevalier, Croisé, Champion, Paladin, Héros, Légende et Mythique.","ナイト、クルセイダー、チャンピオン、パラディン、ヒーロー、レジェンド、ミシックを解除。")
add("Earn every evolution","Gana cada evolución","Conquiste cada evolução","Verdiene jede Entwicklung","Mérite chaque évolution","すべての進化を獲得")
add("Your focus still does the work. New hero art appears as your journey level grows.","Tu concentración sigue haciendo el trabajo. Aparecen nuevos héroes a medida que crece tu nivel de viaje.","Seu foco ainda faz o trabalho. Novos heróis aparecem conforme seu nível de jornada cresce.","Dein Fokus leistet weiterhin die Arbeit. Mit deinem Reiselevel erscheint neue Heldenkunst.","Ta concentration fait toujours le travail. De nouveaux héros apparaissent à mesure que ton niveau de parcours augmente.","集中した分だけ進みます。旅のレベルが上がると新しいヒーローアートが現れます。")
add("One purchase. Yours forever.","Una compra. Tuyo para siempre.","Uma compra. Seu para sempre.","Ein Kauf. Für immer deins.","Un achat. À toi pour toujours.","一度の購入で、ずっとあなたのもの。")
add("No subscription and no renewal. Restore it on any device using your Apple Account.","Sin suscripción ni renovación. Restáuralo en cualquier dispositivo con tu cuenta de Apple.","Sem assinatura nem renovação. Restaure em qualquer dispositivo com sua Conta Apple.","Kein Abo und keine Verlängerung. Stelle es mit deinem Apple Account auf jedem Gerät wieder her.","Sans abonnement ni renouvellement. Restaure-le sur tout appareil avec ton compte Apple.","サブスクリプションも更新もありません。Apple Accountでどのデバイスでも復元できます。")
add("Private and ad-free for everyone","Privado y sin anuncios para todos","Privado e sem anúncios para todos","Privat und werbefrei für alle","Privé et sans publicité pour tout le monde","すべての人にプライベートで広告なし")
add("Unlock 7 heroes · %@","Desbloquear 7 héroes · %@","Desbloquear 7 heróis · %@","7 Helden freischalten · %@","Débloquer 7 héros · %@","7人のヒーローを解除 · %@")
add("Retry loading price","Reintentar cargar el precio","Tentar carregar o preço novamente","Preis erneut laden","Réessayer de charger le prix","価格を再読み込み")
add("Restore Purchases","Restaurar compras","Restaurar compras","Käufe wiederherstellen","Restaurer les achats","購入を復元")
add("Privacy Policy","Política de privacidad","Política de Privacidade","Datenschutzrichtlinie","Politique de confidentialité","プライバシーポリシー")
add("Terms","Términos","Termos","Nutzungsbedingungen","Conditions","利用規約")
add("Purchase failed","Error en la compra","Falha na compra","Kauf fehlgeschlagen","Échec de l’achat","購入に失敗しました")
add("Couldn’t reach the App Store. Check your connection and try again.","No se pudo conectar con la App Store. Revisa tu conexión e inténtalo de nuevo.","Não foi possível acessar a App Store. Verifique sua conexão e tente novamente.","App Store nicht erreichbar. Prüfe deine Verbindung und versuche es erneut.","Impossible de joindre l’App Store. Vérifie ta connexion et réessaie.","App Storeに接続できませんでした。接続を確認して、もう一度お試しください。")

# --- Hero panel ---
add("Unlock Pro to evolve","Desbloquea Pro para evolucionar","Desbloqueie o Pro para evoluir","Pro freischalten zum Aufsteigen","Débloquer Pro pour évoluer","Proで進化を解除")
add("Hero locked. Unlock Pro to evolve past %@.","Héroe bloqueado. Desbloquea Pro para evolucionar más allá de %@.","Herói bloqueado. Desbloqueie o Pro para evoluir além de %@.","Held gesperrt. Schalte Pro frei, um über %@ hinaus aufzusteigen.","Héros verrouillé. Débloque Pro pour évoluer au-delà de %@.","ヒーローはロック中。Proで%@より先へ進化。")
add("%@ hero, grinding","Héroe %@, entrenando","Herói %@, treinando","%@-Held, am Grinden","Héros %@, en pleine action","%@のヒーロー、修行中")
add("%@ hero, resting","Héroe %@, descansando","Herói %@, descansando","%@-Held, ruht","Héros %@, au repos","%@のヒーロー、休憩中")
add("Grinding…","Entrenando…","Treinando…","Am Grinden…","En pleine action…","修行中…")
add("Resting by the campfire","Descansando junto a la fogata","Descansando perto da fogueira","Rast am Lagerfeuer","Repos près du feu de camp","焚き火のそばで休憩中")

# --- History card ---
add("Focus History","Historial de concentración","Histórico de foco","Fokus-Verlauf","Historique de focus","集中の履歴")
add("Levels earned each day · resets at midnight","Niveles ganados cada día · se reinicia a medianoche","Níveis ganhos por dia · reinicia à meia-noite","Täglich erreichte Level · Reset um Mitternacht","Niveaux gagnés chaque jour · réinitialisé à minuit","毎日獲得したレベル · 深夜にリセット")
add("%lld min focus time","%lld min de foco","%lld min de foco","%lld Min. Fokuszeit","%lld min de focus","集中時間%lld分")

# --- Hero Collection (conversion centerpiece) ---
add("Hero Collection","Colección de héroes","Coleção de heróis","Heldensammlung","Collection de héros","ヒーローコレクション")
add("%lld of 10 heroes reached","%lld de 10 héroes alcanzados","%lld de 10 heróis alcançados","%lld von 10 Helden erreicht","%lld héros sur 10 atteints","10人中%lld人のヒーローに到達")
add("Your journey: lifetime level %lld · %@","Tu viaje: nivel total %lld · %@","Sua jornada: nível vitalício %lld · %@","Deine Reise: Gesamtlevel %lld · %@","Ton parcours : niveau cumulé %lld · %@","あなたの旅: 累計レベル%lld · %@")
add("%lld of 10 reached — keep focusing to climb.","%lld de 10 alcanzados: sigue concentrándote para subir.","%lld de 10 alcançados — continue focando para subir.","%lld von 10 erreicht — bleib fokussiert, um aufzusteigen.","%lld sur 10 atteints — continue à te concentrer pour grimper.","10中%lld到達 — 集中を続けて登ろう。")
add("Unlock 7 more heroes · %@","Desbloquea 7 héroes más · %@","Desbloqueie mais 7 heróis · %@","7 weitere Helden freischalten · %@","Débloque 7 héros de plus · %@","さらに7人のヒーローを解除 · %@")
add("Unlock 7 more heroes","Desbloquea 7 héroes más","Desbloqueie mais 7 heróis","7 weitere Helden freischalten","Débloque 7 héros de plus","さらに7人のヒーローを解除")
add("Reach level %lld","Llega al nivel %lld","Alcance o nível %lld","Erreiche Level %lld","Atteins le niveau %lld","レベル%lldに到達")
add("Tap to unlock","Toca para desbloquear","Toque para desbloquear","Zum Freischalten tippen","Touche pour débloquer","タップで解除")
add("Unlocked","Desbloqueado","Desbloqueado","Freigeschaltet","Débloqué","解除済み")
add("Your collection","Tu colección","Sua coleção","Deine Sammlung","Ta collection","あなたのコレクション")
add("Opens your hero collection","Abre tu colección de héroes","Abre sua coleção de heróis","Öffnet deine Heldensammlung","Ouvre ta collection de héros","ヒーローコレクションを開く")
add("%@, locked. Reach level %lld.","%@, bloqueado. Llega al nivel %lld.","%@, bloqueado. Alcance o nível %lld.","%@, gesperrt. Erreiche Level %lld.","%@, verrouillé. Atteins le niveau %lld.","%@、ロック中。レベル%lldに到達。")
add("%@, earned. Tap to unlock with Pro.","%@, conseguido. Toca para desbloquear con Pro.","%@, conquistado. Toque para desbloquear com Pro.","%@, verdient. Zum Freischalten mit Pro tippen.","%@, mérité. Touche pour débloquer avec Pro.","%@、獲得済み。タップしてProで解除。")
add("%@, unlocked.","%@, desbloqueado.","%@, desbloqueado.","%@, freigeschaltet.","%@, débloqué.","%@、解除済み。")

strings = {}
for key, vals in T.items():
    locs = {}
    for lang, val in zip(LANGS, vals):
        locs[lang] = {"stringUnit": {"state": "needs_review", "value": val}}
    strings[key] = {"extractionState": "manual", "localizations": locs}

catalog = {"sourceLanguage": "en", "strings": strings, "version": "1.0"}
out = Path(__file__).resolve().parents[1] / "DailyLevels" / "Localizable.xcstrings"
with out.open("w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2)
    f.write("\n")
print(f"wrote {out} with {len(strings)} keys × {len(LANGS)} languages")
