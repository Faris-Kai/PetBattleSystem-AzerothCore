# mod-pet-battle

An AzerothCore module that adds a "Pokémon-style" pet battle minigame,
playable through the `.dp` command, with PvP duels between players and
duels against wild creatures that, when defeated, can drop an item
that teaches that creature as a permanent companion.

---

## 1. What the module does

- Each player builds a team of up to **3 pets**
- **PvP duel**: select another player and type `.dp` to challenge
  them.
- **Wild duel**: select a creature in the world and type `.dp`. If
  that creature is "capturable" (see section 4), the battle starts
  automatically against it.
- Combat is turn-based: a die roll decides who attacks first, then
  each player chooses among 3 attacks, each with its own cooldown.
  There are two elemental type triangles:
  - Water > Fire > Earth > Water (x2 damage)
  - Darkness > Basic > Light > Darkness (x2 damage)
- If you win a wild battle, your pet gains experience and you also
  **receive the item that teaches the defeated creature as a
  companion** (if the system finds a compatible item — see section 4).
- There is also a **client addon** interface (prefix `PETBTL`,
  messages like `TEAM`, `SWAP`, `ATK`, `COINCLICK`, etc.) that
  replaces most of the gossip menus. The module does not include the
  addon itself (that's a separate client-side `.lua`/`.toc`); if
  players don't have it installed, the gossip menus (`ShowTeamMenu`,
  `ShowDiceMenu`, `ShowAttackMenu`, the challenge popup) still work as
  a fallback.

---

## 2. Installation

1. Copy the module folder into your AzerothCore checkout's `modules/`
   directory (e.g. `modules/mod-pet-battle/`).
2. Re-run CMake / rebuild `worldserver` (modules are detected at CMake
   configuration time, not at runtime).
3. Create the SQL tables in the **world** database (section 5).
4. add a `mod_pet_battle.conf` (section 6), or leave it to
   use the defaults.
5. install the `PetBattleUI` client addon if your players
   are going to use it; otherwise the system still works fully through
   gossip.

---

## 3. How capture works under the hood (important for section 5)

This is the key piece for being able to add new content, so it's worth
understanding before touching the database.

### 3.1. The module does NOT define its own spells

"Companion pets" in WoW (WotLK) are spells with a `SPELL_EFFECT_SUMMON`
effect whose `MiscValue` is the `entry` of the creature they summon.
Those spells live in the client/server `.dbc` files (`Spell.dbc`),
**not** in a hand-editable SQL table. The module doesn't create new
spells: it reuses the ones that already exist in the game.

### 3.2. Indexed by model (`DisplayID`), not by `entry`

On startup, `EnsurePetSpellIndexBuilt()` iterates through **every**
spell loaded on the server, and for each one that has a
`SPELL_EFFECT_SUMMON` effect pointing at a `creatureEntry` that exists
in `creature_template`, it stores in a map:

```
DisplayID of that creature  →  SpellID that summons it
```

When you select a creature in the world and type `.dp`
(`TryStartWildBattle`), the module looks up that creature's
`DisplayID` in the map. If there's a match, the battle starts; if not,
it tells you that creature isn't a capturable companion.

**Practical takeaway: what makes a creature "capturable" is that its
model (`DisplayID`) matches the model summoned by some companion spell
that already exists in the game — the `entry` you use for the wild
spawn doesn't matter.**

### 3.3. On victory, the item is looked up the same way, in reverse

`GrantWildCaptureReward()` does the inverse: it scans `item_template`
for any item with `spellid_1..spellid_5` that has a
`SPELL_EFFECT_SUMMON` effect whose target creature's `DisplayID`
matches the wild creature you just defeated. The first matching item
is delivered straight to your inventory
(`StoreNewItemInBestSlots`).

If no compatible item is found, you'll see the
`PETTXT_CAPTURE_NO_MATCH` message ("you captured the companion but no
item with a compatible model was found") — you still win the battle,
but you don't receive anything. **That's why step 3 of the guide in
section 7 is mandatory.**

### 3.4. Using the item registers the combat sheet

Using the item makes the client permanently learn the companion spell.
That triggers the `OnPlayerLearnSpell` hook →
`RegisterPetIfSummonSpell()`, which:

1. Confirms the learned spell has `SPELL_EFFECT_SUMMON`.
2. Creates a row in `bp_pet_info` for THAT player and THAT creature,
   with **randomly generated health, elemental type, and 3 attack
   damage values** (there's no way to hardcode these from the current
   code — every player who learns the same pet can end up with
   different stats).
3. Looks up in `item_template` the item whose `spellid_X` exactly
   matches that `spellID` and stores it as `item_entry` (the "source"
   item), which is what gets returned to you if you later "detach"
   the pet (`.dp` → Detach / `PETDETACH`).

Only then does the pet become available to assign to a team slot
(`.dp` → select it, or `TEAM:<slot>:<spellID>` from the addon).

---

## 4. SQL tables (`world` database)

```sql
-- Each player's battle team (3 slots, storing the pet's creature_entry)
CREATE TABLE IF NOT EXISTS `bp_pet_team` (
  `guid`                  INT UNSIGNED NOT NULL,
  `slot1_creature_entry`  INT UNSIGNED NOT NULL DEFAULT 0,
  `slot2_creature_entry`  INT UNSIGNED NOT NULL DEFAULT 0,
  `slot3_creature_entry`  INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Combat sheet for each pet a player has learned
-- (composite key: a player can have several different creatures)
CREATE TABLE IF NOT EXISTS `bp_pet_info` (
  `guid_jugador`  INT UNSIGNED NOT NULL,
  `mascotaID`     INT UNSIGNED NOT NULL,   -- creature_entry
  `spell_id`      INT UNSIGNED NOT NULL DEFAULT 0,
  `item_entry`    INT UNSIGNED NOT NULL DEFAULT 0,
  `vida`          INT UNSIGNED NOT NULL DEFAULT 100, -- Life[random value]
  `tipo`          TINYINT UNSIGNED NOT NULL DEFAULT 0, -- Type[random value]
  `cant_daño_1`   INT UNSIGNED NOT NULL DEFAULT 0, -- damage[random value]
  `cant_daño_2`   INT UNSIGNED NOT NULL DEFAULT 0, -- damage[random value]
  `cant_daño_3`   INT UNSIGNED NOT NULL DEFAULT 0, -- damage[random value]
  PRIMARY KEY (`guid_jugador`, `mascotaID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Localized texts (optional: if empty, the English texts hardcoded
-- in GetDefaultText() are used as a fallback)
CREATE TABLE IF NOT EXISTS `bp_pet_locale` (
  `id`    INT UNSIGNED NOT NULL,
  `enUS`  TEXT,
  `esES`  TEXT,
  `frFR`  TEXT,
  `deDE`  TEXT,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Auxiliary table declared in the code (GetDetachItemEntry) to allow
-- manually forcing which item a pet returns when detached. The actual
-- current "detach" flow uses the item_entry stored in bp_pet_info, so
-- this table is optional/reserved for future use, but it's worth
-- creating so nothing breaks if it's used later.
CREATE TABLE IF NOT EXISTS `bp_pet_detach_items` (
  `creature_entry`  INT UNSIGNED NOT NULL,
  `item_entry`      INT UNSIGNED NOT NULL,
  PRIMARY KEY (`creature_entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

> Use `utf8mb4` (or at least `utf8`) since some column names and texts
> use accented characters (e.g. `daño`).

---

## 5. Configuration (`mod_pet_battle.conf`)

The module doesn't ship a `.conf` in what was uploaded, but it reads
these keys via `sConfigMgr->GetOption`, all optional (if the file
doesn't exist, the default is used):

| Key                                  | Type   | Default | Effect |
|---------------------------------------|--------|---------|--------|
| `PetBattle.Enable`                    | bool   | `true`  | Turns the whole system on/off (`.dp` will say it's disabled). |
| `PetBattle.TurnTimeoutSeconds`        | uint32 | `15`    | Seconds to attack before auto-losing by timeout. `0` disables the limit. |
| `PetBattle.DebugDamageMessages`       | bool   | `false` | Sends each hit's damage over chat (prefix `[PETDMG]`) for addon debugging. |
| `PetBattle.SummonVisualSpellId`       | uint32 | `0`     | Visual spell cast when the active pet is summoned. If `0`, an exclamation emote is used instead. |

Example file:

```ini
[worldserver]
PetBattle.Enable = 1
PetBattle.TurnTimeoutSeconds = 15
PetBattle.DebugDamageMessages = 0
PetBattle.SummonVisualSpellId = 0
```

---

## 6. How to use it in-game

- `.dp` with no target → opens the team configuration menu (assign a
  pet per slot, clear the team, save).
- `.dp` with a **player** selected → challenges them to a duel.
- `.dp` with a **world creature** selected → if it's capturable, a
  wild duel starts; if not, you're told it's not a capturable
  companion.
- `.dp accept` (`.dp aceptar`) / `.dp decline` (`.dp rechazar`) →
  respond to a pending PvP challenge.
- During combat: roll the die, choose an attack (respecting
  cooldowns), and on a win you may receive the capture item (only in
  wild duels, and only if you're the challenger, not the creature).
- Closing the battle window = forfeiting = an automatic loss
  (`FORFEIT`).
- Modifying your team while in battle also makes you lose
  automatically.

**Important rule:** slot 1 of the team is mandatory to be able to
fight (PvP or wild). Having pets only in slots 2 and/or 3 isn't
enough.

---

## 7. Practical guide: creating a capturable wild creature + its item + its spell

This is the main ask, so here it is step by step. There are two paths.

### Path A — Recommended: reuse a companion spell that already exists (no client editing)

As seen in section 3, the spell **must already exist** in the game (it
comes from the `.dbc`), so the practical way to add a new capturable
pet is to lean on an official companion Blizzard already shipped, and
create the "wild" version yourself (and the item, if needed).

**Step 1 — Pick the base companion.**
Search your `item_template` for items that already have a "use" spell
loaded (these are the most likely candidates to be companion pets):

```sql
SELECT entry, name, spellid_1
FROM item_template
WHERE spellid_1 > 0
ORDER BY entry
LIMIT 100;
```

The server doesn't store spell effects in a SQL table (that lives in
the `.dbc`), so to confirm that a given `spellid_1` is really a
"Summon Companion" and see which `creature entry` it summons, you need
to check it with an external tool: a DBC viewer (e.g. WDBX Editor /
MyDbcEditor opening your `Spell.dbc`), or a public WotLK spell
database. There you'll see something like "Effect 1: Summon
(Companion) → NPC #12345".

**Step 2 — Confirm the creature and its model.**

```sql
SELECT entry, Name FROM creature_template WHERE entry = <creatureEntry>;
SELECT CreatureDisplayID FROM creature_template_model WHERE CreatureID = <creatureEntry>;
```

**Step 3 — Spawn the wild version.**
The simplest and 100%-guaranteed way to make the `DisplayID` match is
to spawn **that exact same `creature_entry`** in the world (no need to
create a new `creature_template` row, unless you want it to behave
differently — level, health, aggression, etc. — in which case you can
clone the row with your own `entry` while keeping the same
`CreatureDisplayID` in `creature_template_model`).

The fastest way is to stand where you want the spawn and use the GM
command:

```
.npc add <creatureEntry>
```

Or insert it directly into the `creature` table with whatever
coordinates you want (adjust `map`, `zoneId`, `areaId`, position, and
GUID to your server).

**Step 4 — Make sure an item is linked to that spell.**

```sql
SELECT entry, name FROM item_template
WHERE spellid_1 = <spellId> OR spellid_2 = <spellId> OR spellid_3 = <spellId>
   OR spellid_4 = <spellId> OR spellid_5 = <spellId>;
```

If an item already shows up (the common case, since that's usually how
that companion is normally sold somewhere in the game), you're done —
**that** item is what will be handed out on victory. If nothing shows
up, create one:

```sql
INSERT INTO `item_template`
(`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`,
 `InventoryType`, `maxcount`, `stackable`, `spellid_1`, `spelltrigger_1`,
 `spellcharges_1`, `spellcooldown_1`, `spellcategory_1`,
 `spellcategorycooldown_1`, `bonding`)
VALUES
(<newItemEntry>, 15, 2, 'Item Name', <itemDisplayId>, 1,
 0, 1, 1, <spellId>, 0,
 -1, -1, 0,
 -1, 1);
```

(Class `15` = Miscellaneous, which is where companion pets normally
live; adjust `displayid` to whatever item icon/model you want.)

**Step 5 — Test it in-game.**
1. Set slot 1 of your team with `.dp` (any pet you already have).
2. Select the newly spawned wild creature and type `.dp`.
3. Win the battle → you should receive the item automatically
   (`PETTXT_CAPTURE_SUCCESS` message). If instead you get
   `PETTXT_CAPTURE_NO_MATCH`, go back to Step 4 — no item with a
   matching model was found.
4. Use the item from your bag → you learn the companion → its combat
   sheet (random health/type/damage) is automatically generated in
   `bp_pet_info`.
5. Assign the new pet to a team slot (`.dp` → select it) so you can
   fight with it.

### Path B — Advanced: a brand-new pet (a model/creature not tied to any official companion)

This requires creating a new spell with a `SPELL_EFFECT_SUMMON`
effect, which means editing `Spell.dbc` (and related `.dbc` files,
like `SpellIcon.dbc`) and distributing that `.dbc`/patch to clients,
because WotLK spells aren't defined via SQL: the server reads them
from the `.dbc` loaded in memory. At a high level:

1. Create your creature in `creature_template` +
   `creature_template_model` with whatever `CreatureDisplayID` you
   want (you can reuse an existing in-game model, no need for a new 3D
   model).
2. Using a DBC editor, duplicate/create a spell with a "Summon"
   (companion category) effect pointing at that creature's `entry`,
   and distribute the resulting `Spell.dbc` to clients (via your
   server's own patch/MPQ).
3. Create the `item_template` row with `spellid_1` = your new
   `spellID`.
4. From there, everything else (Steps 3 through 5 of Path A) works the
   same way.

This path is outside the scope of this module (which is pure
C++/SQL) — it's typically handled with WotLK modding community tools
(DBC editors), and this document doesn't cover it in detail.

---

## 8. Common issues

- **"Not a capturable companion" when using `.dp` on a creature**: its
  `DisplayID` doesn't match any existing companion's. See section 4.2
  — you need to reuse the right entry/model.
- **You win but receive nothing (`PETTXT_CAPTURE_NO_MATCH`)**: there's
  no `item_template` row with a `spellid_X` pointing at a summon with
  that `DisplayID`. See Step 4 of Path A.
- **`PETTXT_CAPTURE_NO_SPACE`**: you won and there is an item, but you
  don't have bag space; the system doesn't lose it, it simply doesn't
  grant it until you free up space and try again (there's no automatic
  retry — you'd have to defeat it again).
- **Can't start a fight**: check that slot 1 of your team has a pet
  assigned.

---

Menu:
<video src="Funciones-Menu.mp4" controls width="600"></video>

Battle vs Creature:
<video src="CriaturaVs.mp4" controls width="600"></video>

Battle vs Player:
[![Watch on YouTube](https://img.youtube.com/vi/gc6cSDInFuk/hqdefault.jpg)](https://youtu.be/gc6cSDInFuk)

*(click the image to open the video on YouTube — GitHub doesn't allow
embedding the player directly in the README)*
---

Well, my stomach is growling louder than a raid boss. 🍖😂

If you’d like to support the project, you can feed the starving developer here:
[PayPal – Support]
(https://paypal.me/Marquesini1992)

I’ll slowly fade into the distance now… 🚶‍♂️💨
*Probably heading straight for the nearest food.* 🍔

