## Group cell description

Here is a description of what is displayed in the group cells, as of version 1.7.1.

### Health bar

The health works in reverse logic, compared to single units frame: the full bar is dark when the unit is at full life and it fills from the right when the units looses life. Basically, when your group units are all empty, everything is fine.

### Incoming heals

Incoming heals are displayed using colored overlays:
* when the unit is healed by only one player, the overlay is green,
* when you are healing the unit along other healers, your heals are colored in green and the others' heals are colored in purple.

### Name

The name is normally colored using the class color. When the unit is about to receive more than 10% overheal, it turns green. If the unit is about to receive more than 30% overheal, the name will also be replaced by the overheal amount.

### Borders

There is two separate borders:

* a outer, thin border: target/mana status. It turns white to indicate your current target and blue to indicate mana-users that are running out of mana.
* a inner, thick border: the threat status. It always displays the highest threat against all engaged mobs, using the standard threat colors:
    * red: has aggro,
    * orange: has aggro but is about to lose it,
    * yellow: does not have aggro but is about to gain it,
    * hidden: does not have aggro.

### Icons

Inside the cell, icons are layed out this way:

<pre>
<code>
 +-------------------------+
 | [a]       [b]       [c] |
 |                         |
 | [A]  [1]  [2]  [3]  [B] |
 |                         |
 | [d]                 [e] |
 +-------------------------+
</code>
</pre>

#### Symbols and roles: `[A]`, <code>[B]</code>

`[A]` is the role/symbol icon: it displays either the raid symbol (skull, cross, ...), or the healer/tank role icon, as assigned by the LFD tool or defined by the player or raid leader.
<code>[B]</code> is the symbol of the unit target. This helps checking the unit is actually targeting the skull or whatever.

#### Generic buffs and debuffs: <code>[1]</code>, <code>[2]</code>, <code>[3]</code>

<code>[1]</code> displays important buffs: mainly cooldowns, like defensive ones (Shield Wall, Barkskin, Cloak of Shadows, Feign Death, ...) or mana-regenerating ones (Innervate, Hymn of Hope, ...). The lists of spells is provided by LibPlayerSpells-1.0.

<code>[2]</code> displays generic debuffs. If several debuffs exist, it favors debuffs you can dispell, debuffs with the highest stack count or longuest debuffs, in that order. Please note this ignores special debuffs (see below). It ignores debuffs with no duration (boss auras), or applied by friendly units (like Weakened Souls).

<code>[3]</code> displays special debuffs, based on three sources:
# PvE encounter debuffs according to Blizzard's API.
# PvE encounter debuffs watched by BigWigs (r11425 or higher).
# PvP crowd-control debuffs (Sap, Polymorph, ...).

#### Class-specific buffs: <code>[a]</code>-<code>[e]</code>

These icons display specific buffs depending on *your* class. Most of the time they displays only *your* buffs.
