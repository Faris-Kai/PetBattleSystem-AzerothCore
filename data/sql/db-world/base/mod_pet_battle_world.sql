-- --------------------------------------------------------
-- PetBattle - Database
-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Versión del servidor:         8.4.10 - MySQL Community Server - GPL
-- SO del servidor:              Win64
-- HeidiSQL Versión:             12.20.0.7320
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- ========================================================
-- TABLA: bp_pet_detach_items
-- ========================================================

CREATE TABLE IF NOT EXISTS `bp_pet_detach_items` (
    `item_entry` INT UNSIGNED NOT NULL,
    `spell_id` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`item_entry`),
    KEY `idx_spell_id` (`spell_id`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;


-- ========================================================
-- TABLA: bp_pet_info
-- ========================================================

CREATE TABLE IF NOT EXISTS `bp_pet_info` (
    `guid_jugador` INT UNSIGNED NOT NULL,
    `spell_id` INT UNSIGNED NOT NULL,
    `item_entry` INT UNSIGNED NOT NULL DEFAULT 0,
    `mascotaID` INT UNSIGNED NOT NULL DEFAULT 0,
    `vida` INT NOT NULL DEFAULT 0,
    `tipo` INT NOT NULL DEFAULT 0,
    `cant_daño_1` INT NOT NULL DEFAULT 0,
    `cant_daño_2` INT NOT NULL DEFAULT 0,
    `cant_daño_3` INT NOT NULL DEFAULT 0,

    PRIMARY KEY (`guid_jugador`, `spell_id`),
    KEY `idx_spell_id` (`spell_id`),
    KEY `idx_item_entry` (`item_entry`),
    KEY `idx_mascotaID` (`mascotaID`)

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;


-- ========================================================
-- TABLA: bp_pet_locale
-- ========================================================

CREATE TABLE IF NOT EXISTS `bp_pet_locale` (
    `id` INT UNSIGNED NOT NULL,
    `enUS` TEXT NOT NULL,
    `esES` TEXT NOT NULL,
    `frFR` TEXT NOT NULL,
    `deDE` TEXT NOT NULL,

    PRIMARY KEY (`id`)

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;


-- ========================================================
-- TABLA: bp_pet_team
-- ========================================================

CREATE TABLE IF NOT EXISTS `bp_pet_team` (
    `guid` INT UNSIGNED NOT NULL,
    `slot1_creature_entry` INT UNSIGNED NOT NULL DEFAULT 0,
    `slot2_creature_entry` INT UNSIGNED NOT NULL DEFAULT 0,
    `slot3_creature_entry` INT UNSIGNED NOT NULL DEFAULT 0,

    PRIMARY KEY (`guid`)

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;


-- ========================================================
-- DATOS: bp_pet_locale
-- ========================================================

INSERT INTO `bp_pet_locale`
(
    `id`,
    `enUS`,
    `esES`,
    `frFR`,
    `deDE`
)
VALUES
    (1,
     'The pet battle system is disabled on this server.',
     'El sistema de combate de mascotas está desactivado en este servidor.',
     'Le système de combat des mascottes est désactivé sur ce serveur.',
     'Das Haustierkampfsystem ist auf diesem Server deaktiviert.'),

    (2,
     'You are already in a pet battle.',
     'Ya estás en un combate de mascotas.',
     'Vous êtes déjà en combat de mascottes.',
     'Du bist bereits in einem Haustierkampf.'),

    (3,
     '{0} is a wild companion! First configure slot 1 of your pet battle team (type /dp with no target selected).',
     '¡{0} es un compañero salvaje! Primero configura la ranura 1 de tu equipo de mascotas (escribe /dp sin objetivo seleccionado).',
     '{0} est un compagnon sauvage ! Configurez d''abord l''emplacement 1 de votre équipe de mascottes (tapez /dp sans cible sélectionnée).',
     '{0} ist ein wilder Begleiter! Konfiguriere zuerst Platz 1 deines Haustierteams (gib /dp ohne ausgewähltes Ziel ein).'),

    (4,
     '{0} is a capturable wild companion ({1})! The battle begins. If you defeat it, you can learn it.',
     '¡{0} es un compañero salvaje capturable ({1})! Comienza el combate. Si lo derrotas, podrás aprenderlo.',
     '{0} est un compagnon sauvage capturable ({1}) ! Le combat commence. Si vous le battez, vous pourrez l''apprendre.',
     '{0} ist ein fangbarer wilder Begleiter ({1})! Der Kampf beginnt. Wenn du ihn besiegst, kannst du ihn erlernen.'),

    (5,
     'Slot {0}: {1}',
     'Ranura {0}: {1}',
     'Emplacement {0} : {1}',
     'Platz {0}: {1}'),

    (6,
     'Empty',
     'Vacía',
     'Vide',
     'Leer'),

    (7,
     'Pet team cleared.',
     'Equipo de mascotas vaciado.',
     'Équipe de mascottes vidée.',
     'Haustierteam geleert.'),

    (8,
     'Pet team saved.',
     'Equipo de mascotas guardado.',
     'Équipe de mascottes enregistrée.',
     'Haustierteam gespeichert.'),

    (9,
     'Pet {0}',
     'Mascota {0}',
     'Mascotte {0}',
     'Haustier {0}'),

    (10,
     'You have no pets available for battle.',
     'No tienes mascotas disponibles para combatir.',
     'Vous n''avez aucune mascotte disponible pour combattre.',
     'Du hast keine Haustiere für den Kampf verfügbar.'),

    (11,
     'Back',
     'Volver',
     'Retour',
     'Zurück'),

    (12,
     'That pet is already in another slot of your team.',
     'Esa mascota ya está en otra ranura de tu equipo.',
     'Cette mascotte est déjà dans un autre emplacement de votre équipe.',
     'Dieses Haustier befindet sich bereits in einem anderen Platz deines Teams.'),

    (13,
     'Pet assigned to slot {0}.',
     'Mascota asignada a la ranura {0}.',
     'Mascotte assignée à l''emplacement {0}.',
     'Haustier Platz {0} zugewiesen.'),

    (14,
     'That companion is not a valid battle pet.',
     'Ese compañero no es una mascota de combate válida.',
     'Ce compagnon n''est pas une mascotte de combat valide.',
     'Dieser Begleiter ist kein gültiges Kampfhaustier.'),

    (15,
     'There is no pet in that slot.',
     'No hay ninguna mascota en esa ranura.',
     'Aucune mascotte ne se trouve dans cet emplacement.',
     'In diesem Platz befindet sich kein Haustier.'),

    (16,
     'Pet ''{0}'' was removed from the team.',
     'La mascota ''{0}'' fue quitada del equipo.',
     'La mascotte « {0} » a été retirée de l''équipe.',
     'Haustier „{0}“ wurde aus dem Team entfernt.'),

    (17,
     'There is no pet in that slot.',
     'No hay ninguna mascota en esa ranura.',
     'Aucune mascotte ne se trouve dans cet emplacement.',
     'In diesem Platz befindet sich kein Haustier.'),

    (18,
     'Pet ''{0}'' was forgotten.',
     'La mascota ''{0}'' fue olvidada.',
     'La mascotte « {0} » a été oubliée.',
     'Haustier „{0}“ wurde vergessen.'),

    (19,
     'This pet has no registered source item.',
     'Esta mascota no tiene registrado su objeto de origen.',
     'Cette mascotte n''a aucun objet source enregistré.',
     'Für dieses Haustier ist kein Ursprungsgegenstand registriert.'),

    (20,
     'Pet ''{0}'' has no registered item that taught it.',
     'La mascota ''{0}'' no tiene registrado el objeto que la enseñó.',
     'La mascotte « {0} » n''a aucun objet enregistré qui l''a enseignée.',
     'Für das Haustier „{0}“ ist kein Gegenstand registriert, durch den es erlernt wurde.'),

    (21,
     'The item configured for this pet does not exist.',
     'El objeto configurado para esta mascota no existe.',
     'L''objet configuré pour cette mascotte n''existe pas.',
     'Der für dieses Haustier konfigurierte Gegenstand existiert nicht.'),

    (22,
     'You do not have enough bag space.',
     'No tienes suficiente espacio en las bolsas.',
     'Vous n''avez pas assez de place dans vos sacs.',
     'Du hast nicht genug Platz in deinen Taschen.'),

    (23,
     'You do not have space to receive the pet item.',
     'No tienes espacio para recibir el objeto de la mascota.',
     'Vous n''avez pas de place pour recevoir l''objet de la mascotte.',
     'Du hast keinen Platz, um den Haustiergegenstand zu erhalten.'),

    (24,
     'The pet item could not be created.',
     'No se pudo crear el objeto de la mascota.',
     'L''objet de la mascotte n''a pas pu être créé.',
     'Der Haustiergegenstand konnte nicht erstellt werden.'),

    (25,
     'Pet ''{0}'' was detached and converted into item {1}.',
     'La mascota ''{0}'' fue desligada y convertida en el objeto {1}.',
     'La mascotte « {0} » a été détachée et convertie en objet {1}.',
     'Haustier „{0}“ wurde gelöst und in Gegenstand {1} umgewandelt.'),

    (26,
     'You are already in a pet battle.',
     'Ya estás en un combate de mascotas.',
     'Vous êtes déjà en combat de mascottes.',
     'Du bist bereits in einem Haustierkampf.'),

    (27,
     'That player is already in a pet battle.',
     'Ese jugador ya está en un combate de mascotas.',
     'Ce joueur est déjà en combat de mascottes.',
     'Dieser Spieler befindet sich bereits in einem Haustierkampf.'),

    (28,
     'You must configure slot 1 of your pet team before challenging.',
     'Debes configurar la ranura 1 de tu equipo de mascotas antes de desafiar.',
     'Vous devez configurer l''emplacement 1 de votre équipe de mascottes avant de lancer un défi (tapez /dp sans cible sélectionnée).',
     'Du musst Platz 1 deines Haustierteams konfigurieren, bevor du herausforderst (gib /dp ohne Ziel ausgewählt ein).'),

    (29,
     '{0} has not configured slot 1 of their pet team yet.',
     '{0} todavía no tiene configurada la ranura 1 de su equipo de mascotas.',
     '{0} n''a pas encore configuré l''emplacement 1 de son équipe de mascottes.',
     '{0} hat Platz 1 seines Haustierteams noch nicht konfiguriert.'),

    (30,
     'You challenged {0} to a pet battle.',
     'Has desafiado a {0} a un combate de mascotas.',
     'Vous avez défié {0} à un combat de mascottes.',
     'Du hast {0} zu einem Haustierkampf herausgefordert.'),

    (31,
     '{0} challenged you to a pet battle. A window was opened on screen to respond.',
     '{0} te ha desafiado a un combate de mascotas. Se abrió una ventana en pantalla para responder.',
     '{0} vous a défié en combat de mascottes. Une fenêtre s''est ouverte à l''écran pour répondre (ou tapez /dp accepter // /dp refuser).',
     '{0} hat dich zu einem Haustierkampf herausgefordert. Ein Fenster wurde geöffnet, um zu antworten (oder /dp akzeptieren // /dp ablehnen eingeben).'),

    (32,
     'You have no pending pet challenge.',
     'No tienes ningún desafío de mascotas pendiente.',
     'Vous n''avez aucun défi de mascottes en attente.',
     'Du hast keine ausstehende Haustierkampf-Herausforderung.'),

    (33,
     'The player who challenged you is no longer available.',
     'El jugador que te desafió ya no está disponible.',
     'Le joueur qui vous a défié n''est plus disponible.',
     'Der Spieler, der dich herausgefordert hat, ist nicht mehr verfügbar.'),

    (34,
     'One of the two players is already in another pet battle.',
     'Uno de los dos jugadores ya está en otro combate de mascotas.',
     'L''un des deux joueurs est déjà dans un autre combat de mascottes.',
     'Einer der beiden Spieler befindet sich bereits in einem anderen Haustierkampf.'),

    (35,
     'The battle was cancelled: one of the two players does not have slot 1 configured in their pet team.',
     'El combate se canceló: uno de los dos jugadores no tiene configurada la ranura 1 de su equipo de mascotas.',
     'Le combat a été annulé : l''un des deux joueurs n''a pas configuré l''emplacement 1 de son équipe de mascottes.',
     'Der Kampf wurde abgebrochen: Einer der beiden Spieler hat Platz 1 seines Haustierteams nicht konfiguriert.'),

    (36,
     'The pet battle has begun. Roll the dice to see who attacks first.',
     'El combate de mascotas ha comenzado. Tiren los dados para ver quién ataca primero.',
     'Le combat de mascottes a commencé. Lancez les dés pour déterminer qui attaque en premier.',
     'Der Haustierkampf hat begonnen. Würfelt, um zu bestimmen, wer zuerst angreift.'),

    (37,
     '{0} rejected your pet battle challenge.',
     '{0} ha rechazado tu desafío de mascotas.',
     '{0} a refusé votre défi de mascottes.',
     '{0} hat deine Haustierkampf-Herausforderung abgelehnt.'),

    (38,
     'You rejected the pet battle.',
     'Has rechazado el combate de mascotas.',
     'Vous avez refusé le combat de mascottes.',
     'Du hast den Haustierkampf abgelehnt.'),

    (39,
     'You abandoned the pet battle.',
     'Has abandonado el combate de mascotas.',
     'Du hast abandonné le combat de mascottes.',
     'Du hast den Haustierkampf verlassen.'),

    (40,
     'You abandoned the pet battle and lost.',
     'Has abandonado el combate de mascotas y has perdido.',
     'Vous avez abandonné le combat de mascottes et vous avez perdu.',
     'Du hast den Haustierkampf verlassen und verloren.'),

    (41,
     'One of the duelists modified their pet team. The battle ends automatically.',
     'Uno de los duelistas modificó su equipo de mascotas. El combate termina automáticamente.',
     'L''un des duellistes a modifié son équipe de mascottes. Le combat se termine automatiquement.',
     'Einer der Duellanten hat sein Haustierteam geändert. Der Kampf endet automatisch.'),

    (42,
     'You modified your team. You lost the pet battle.',
     'Modificaste tu equipo. Has perdido el combate de mascotas.',
     'Vous avez modifié votre équipe. Vous avez perdu le combat de mascottes.',
     'Du hast dein Team geändert. Du hast den Haustierkampf verloren.'),

    (43,
     'You modified your pet team and lost the battle.',
     'Modificaste tu equipo de mascotas y has perdido el combate.',
     'Vous avez modifié votre équipe de mascottes et vous avez perdu le combat.',
     'Du hast dein Haustierteam geändert und den Kampf verloren.'),

    (44,
     'Time ran out to attack. You lost the pet battle.',
     'Se acabó el tiempo para atacar. Has perdido el combate de mascotas.',
     'Le temps d''attaque est écoulé. Vous avez perdu le combat de mascottes.',
     'Die Angriffszeit ist abgelaufen. Du hast den Haustierkampf verloren.'),

    (45,
     'Time ran out to attack and you lost the pet battle.',
     'Se acabó el tiempo para atacar y has perdido el combate de mascotas.',
     'Le temps d''attaque est écoulé et vous avez perdu le combat de mascottes.',
     'Die Angriffszeit ist abgelaufen und du hast den Haustierkampf verloren.'),

    (46,
     'The turn time expired. The player who failed to attack in time loses the battle.',
     'Se acabó el tiempo del turno. El jugador que no atacó a tiempo pierde el combate.',
     'Le temps du tour est écoulé. Le joueur qui n''a pas attaqué à temps perd le combat.',
     'Die Zeit für den Zug ist abgelaufen. Der Spieler, der nicht rechtzeitig angegriffen hat, verliert den Kampf.'),

    (47,
     'Roll the dice',
     'Tirar los dados',
     'Lancer les dés',
     'Würfeln'),

    (48,
     'You rolled {0} on the die.',
     'Has sacado un {0} en el dado.',
     'Vous avez obtenu {0} au dé.',
     'Du hast eine {0} gewürfelt.'),

    (49,
     'The dice are tied. Roll again.',
     'Empate en los dados. Vuelvan a tirar.',
     'Égalité aux dés. Relancez les dés.',
     'Gleichstand beim Würfeln. Würfelt erneut.'),

    (50,
     '{0} won the roll and attacks first.',
     '{0} ganó la tirada y ataca primero.',
     '{0} a remporté le lancer et attaque en premier.',
     '{0} hat den Wurf gewonnen und greift zuerst an.'),

    (51,
     'Your pet: {0} | Opponent: {1}',
     'Tu mascota: {0} | Rival: {1}',
     'Votre mascotte : {0} | Adversaire : {1}',
     'Dein Haustier: {0} | Gegner: {1}'),

    (52,
     'Attack {0} (Damage: {1})',
     'Ataque {0} (Daño: {1})',
     'Attaque {0} (Dégâts : {1})',
     'Angriff {0} (Schaden: {1})'),

    (53,
     'That ability is on cooldown for {0} turn(s).',
     'Esa habilidad está en tiempo de reutilización durante {0} turno(s).',
     'Cette capacité est en recharge pendant {0} tour(s).',
     'Diese Fähigkeit hat noch {0} Runde(n) Abklingzeit.'),

    (54,
     'The wild pet',
     'La mascota salvaje',
     'La mascotte sauvage',
     'Das wilde Haustier'),

    (55,
     '{0} attacks... but misses!',
     '{0} ataca... ¡pero falla el golpe!',
     '{0} attaque... mais rate son coup !',
     '{0} greift an... aber verfehlt!'),

    (56,
     ' (Super effective! x2)',
     ' (¡Súper efectivo! x2)',
     ' (Super efficace ! x2)',
     ' (Sehr effektiv! x2)'),

    (57,
     '{0} attacks for {1} damage{2}. Remaining health of the opposing pet: {3}',
     '{0} ataca causando {1} de daño{2}. Vida restante de la mascota rival: {3}',
     '{0} inflige {1} points de dégâts{2}. Vie restante de la mascotte adverse : {3}',
     '{0} verursacht {1} Schaden{2}. Verbleibende Gesundheit des gegnerischen Haustiers: {3}'),

    (58,
     'A pet has been defeated. The next pet enters the battle.',
     'Una mascota ha caído. Entra la siguiente mascota.',
     'Une mascotte a été vaincue. La mascotte suivante entre en combat.',
     'Ein Haustier wurde besiegt. Das nächste Haustier kommt in den Kampf.'),

    (59,
     'You won the pet battle!',
     '|cff40ff40¡Has ganado el combate de mascotas!|r',
     'Vous avez gagné le combat de mascottes !',
     'Du hast den Haustierkampf gewonnen!'),

    (60,
     'You lost the pet battle.',
     '|cffff4040Has perdido el combate de mascotas.|r',
     'Vous avez perdu le combat de mascottes.',
     'Du hast den Haustierkampf verloren.'),

    (61,
     'You gain {0} experience ({1}% of your level bar).',
     'Ganas {0} de experiencia ({1}% de tu barra de nivel).',
     'Vous gagnez {0} points d''expérience ({1} % de votre barre de niveau).',
     'Du erhältst {0} Erfahrung ({1}% deiner Erfahrungsleiste).'),

    (62,
     'You captured the companion, but the wild creature could not be found in creature_template.',
     'Has capturado al compañero, pero no se pudo encontrar la criatura salvaje en creature_template.',
     'Vous avez capturé le compagnon, mais la créature sauvage est introuvable dans creature_template.',
     'Du hast den Begleiter gefangen, aber die wilde Kreatur wurde in creature_template nicht gefunden.'),

    (63,
     'You captured the companion, but the wild creature has no valid model.',
     'Has capturado al compañero, pero la criatura salvaje no tiene un modelo válido.',
     'Vous avez capturé le compagnon, mais la créature sauvage n''a pas de modèle valide.',
     'Du hast den Begleiter gefangen, aber die wilde Kreatur hat kein gültiges Modell.'),

    (64,
     'You captured the companion, but no items with companion spells were found.',
     'Has capturado al compañero, pero no se encontraron objetos con hechizos de companion.',
     'Vous avez capturé le compagnon, mais aucun objet contenant des sorts de compagnon n''a été trouvé.',
     'Du hast den Begleiter gefangen, aber es wurden keine Gegenstände mit Begleitersprüchen gefunden.'),

    (65,
     'You captured the companion, but no item with a compatible model was found.',
     'Has capturado al compañero, pero no se encontró ningún objeto con un modelo compatible.',
     'Vous avez capturé le compagnon, mais aucun objet avec un modèle compatible n''a été trouvé.',
     'Du hast den Begleiter gefangen, aber es wurde kein Gegenstand mit einem kompatiblen Modell gefunden.'),

    (66,
     'You captured the companion, but you have no inventory space for {0}! Make room and try again later.',
     '¡Capturaste al compañero, pero no tienes espacio en el inventario para {0}! Haz espacio e inténtalo de nuevo más tarde.',
     'Vous avez capturé le compagnon, mais vous n''avez pas de place dans votre inventaire pour {0} ! Faites de la place et réessayez plus tard.',
     'Du hast den Begleiter gefangen, aber keinen Platz im Inventar für {0}! Schaffe Platz und versuche es später erneut.'),

    (67,
     'You captured the companion! You receive {0} — you can learn it, give it away, or sell it.',
     '¡Has capturado al compañero! Recibes {0}; puedes aprenderlo, regalarlo o venderlo.',
     'Vous avez capturé le compagnon ! Vous recevez {0} — vous pouvez l''apprendre, le donner ou le vendre.',
     'Du hast den Begleiter gefangen! Du erhältst {0} – du kannst ihn erlernen, verschenken oder verkaufen.'),

    (68,
     'Water',
     'Agua',
     'Eau',
     'Wasser'),

    (69,
     'Earth',
     'Tierra',
     'Terre',
     'Erde'),

    (70,
     'Fire',
     'Fuego',
     'Feu',
     'Feuer'),

    (71,
     'Light',
     'Luz',
     'Lumière',
     'Licht'),

    (72,
     'Darkness',
     'Oscuridad',
     'Ténèbres',
     'Dunkelheit'),

    (73,
     'Basic',
     'Básico',
     'Basique',
     'Normal'),

    (74,
	 'Unknown',
	 'Desconocido',
	 'Inconnu',
	 'Unbekannt'),
	
	(75,
	 'That creature is not a capturable pet companion.',
	 'Esa criatura no es un compañero de mascotas capturable.',
	 'Cette créature n\'est pas un compagnon de mascottes capturable.',
	 'Diese Kreatur ist kein fangbarer Haustierbegleiter.'),
	
	(76,
	 'You are too far from the opponent.',
	 'Estas muy lejos del oponente.',
	 'Vous êtes trop loin de l\'adversaire.',
	 'Du bist zu weit vom Gegner entfernt.'),
	
	(77,
	 '{0} has recovered {1} health points. Current HP: {2}',
	 '{0} ha recuperado {1} puntos de salud. HP actual: {2}',
	 '{0} a récupéré {1} points de vie. PV actuels : {2}',
	 '{0} hat {1} Lebenspunkte wiederhergestellt. Aktuelle LP: {2}'),
	
	(78,
	 '{0} change opinion and has recovered {1} health points. Current HP: {2}',
	 '{0} cambió de opinión y ha recuperado {1} puntos de salud. HP actual: {2}',
	 '{0} a changé d\'avis et a récupéré {1} points de vie. PV actuels : {2}',
	 '{0} hat seine Meinung geändert und {1} Gesundheitspunkte wiederhergestellt. Aktuelle LP: {2}')
ON DUPLICATE KEY UPDATE
    `enUS` = VALUES(`enUS`),
    `esES` = VALUES(`esES`),
    `frFR` = VALUES(`frFR`),
    `deDE` = VALUES(`deDE`);

-- ========================================================
-- RESTAURAR CONFIGURACIÓN MYSQL
-- ========================================================

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;