return {
	{
		Time = 1626376564867,
		Changes = [[- You can no longer salvage the Hestinian Ignition Bow.
- Wands turned out to be a bit underwhelming because you're getting average DPS while also still needing to spend mana. In an effort to alleviate this, I've increased Wand base damage by 20%. I'd like to have something consistent for this, e.g. (spending X mana grants you Y extra percent damage) but for now I'll just go with 20% for wands.
- Wands now properly apply the ranged weapon slowdown on their attacks. Their exclusion from this was an oversight.
- Increased the projectile speed of javelins by 50%.
- If a thrown javelin kills its target, retrieve it instantly.
- Fixed a bug that allowed you to pull javelins out of nowhere.
- Reduced the "long range" damage buff for javelins to 2x instead of 3x.
- Added a hit streak mechanic to javelins. Whenever you land a throw, you gain a buff to further throws. Each successful hit increases this buff, which has no cap, but each successful hit has diminishing returns.]],
	},
	{
		Time = 1625801436378,
		Changes = [[- The three raid missions now have a different method for handling lives. Instead of being given 50 at the beginning, your lives are reset to 10 at the beginning of each floor. In addition, the "lives earned" number, which determines how many points are required to earn bonus lives, is also reset. This should make raids appropriately more interesting without making them gruelingly difficult.

New Mineshaft tileset now in place! In this new tileset, sometimes ore will spawn which you can mine for some bonus resources. The following missions have been affected:
- Rookie's Grave
- Homefront Defense
- Tower at Kastakar
- Corrupted Heritage
- A Grave Issue
- Tunneling Threat
- Broken Bones
- Sudden Incursion
- Scouting Ahead
- Outskirts of Fyreth
- A Glorious Battle
- Worst Case Scenario
- A Shocking Development]]
	},
	{
		Time = 1625628294161,
		Changes = [[- You can no longer use two Erstwhile Vainglories to jump out of bounds while mid-air.
- If you reforge the weapon you have equipped, you no longer have to re-equip it for the reforge to take effect.
- The name in the details window of the inventory screen will now properly be green for Legendary weapons.
- The damage of Axe & Buckler's shield throw has been dramatically reduced.
- Axe & Buckler weapons can only parry once per 3 seconds, now. This should make it significantly more balanced and also reduce the frustrating effect of walking into a gas trap or poison cloud and instantly losing all of your parries.
- Dual Dirks' hitbox is now 25% larger.
- Rapier's hitbox is now 15% longer.
- Failed perfect hits on rapiers have had their cooldown penalties increased to make perfect hits the higher DPS option.
- 3rd Age Pirate Cutlasses' swagger spin is now a channeled ability meaning you can cancel it as with other channeled stuff.
- Changed the name of "Spiked Hatchet & Buckler" to "Spiked Axe & Buckler."

**Dual Wield Abilities!**
These new abilities can be used with any dual-wield weapon: sabers, claws, dirks, and handaxes (but only when you're holding both).

- Flurry. Unleash a very rapid sequence of attacks, hitting everyone before you. Acquired in Corrupted Heritage.
- Spin Attack. Spin, dealing damage to enemies around you for a duration. Acquired in A Promise Fulfilled.
- Ferocious Charge. Basically become a Ricochet projectile and be untargetable while in flight. Acquired in Grimstone Keep.]]
	},
	{
		Time = 1625537811202,
		Changes = [[- If you kite Fiara for too long, she will move to a different spot in her attack pattern to punish you for it.
- You can no longer remove an ability's cooldown by moving it to a different spot in your hotbar.
- Erstwhile Vainglory now grants Untargetable while in mid-air and its leap has been made more stable.
- Reset the leaderboards.

I am frustrated to announce that, due to the explotation of an oversight with the programming of Fiara, I cannot in good integrity allow anyone to keep any Erstwhile Vainglories they may have earned. I'm sorry if you felt like you got yours legitimately, but I have no way of knowing whose is real and whose was earned through cheating. If you did it once, I believe you'll be able to do it again. I'm sorry. I will strive to not let this happen again in the future.]]
	},
	{
		Time = 1625512103485,
		Changes = [[A new challenge awaits you. Undertake the brutal and unwavering difficulty of Guard at the Gate, an extremely challenging boss fight for the game's first Legendary weapon. Good luck, slayers. You'll need it.]]
	},
	{
		Time = 1625355514484,
		Changes = [[- The Mana Bow is now based on Agility. The mana you're paying is for homing arrows, not Dominance-based damage.
- Tunnels and Breaches are somewhat less likely in Castle tile sets.

Mana Regeneration
- You now passively regenerate mana when you haven't used any in the last 5 seconds.
- Your mana regeneration rate is a percentage of your maximum mana, meaning high-perseverance builds are not penalized for having a larger mana pool.
- Staff weapons no longer grant mana when you attack a target. Instead, they reduce your mana regeneration cooldown by 1 second, making your mana regeneration start sooner (great for comboing faster).

Wands
- New weapon type: wands. Currently two in-game, both craftable. Intended as a replacement for the Mana Bow for mage builds who want to keep their distance.
- Iron-ringed Wand. Basic weapon. Shoots cheap single-target projectiles. Secondary attack fires an explosive projectile. If the explosion kills a target, your mana regeneration starts immediately. Good for a finisher.
- Shadow Wand. Shadow weapon. Secondary attack deals 50% less damage but afflicts targets with shadow. If the primary attack hits a shadow-afflicted enemy, they take 50% more damage and the mana cost for that attack is refunded.]],
	},
	{
		Time = 1625291464207,
		Changes = [[- Ricochet bullets don't bounce quite as far anymore, and the initial projectile range has also been reduced. Damage and bounce count unchanged.
- Fan of Projectiles now has a damage falloff mechanic. If multiple projectiles from a fan hit the same target, the first will deal full damage and the remaining projectiles will deal only 20% damage. Cooldown has been reduced to 6 seconds to compensate.
- Increased Explosive Projectile's radius and reduced its cooldown.
- Increased Projectile Barrage's cooldown from 30 to 90 seconds.
- All ranger abilities now apply their weapon's damage tags appropriately, which for now just means that they all deal magical damage if used with the Mana Bow.
- Added a new damage type: Electrical. I think it makes more sense to have a dedicated damage type for this rather than just using Heat, because conductivity of electricity is a bit different, physically speaking.

- New enemy type: Corrupted Lightning. Casts lightning at range, and flees quickly and far if you get too close.

- New mission: A Shocking Discovery. Help Elle investigate some corrupted elemental sightings on Thundertop Mountain.

- New ability: Lightning Strike. Shoot a bolt of lightning which chains to nearby enemies at lightning speed.]]
	},
	{
		Time = 1625205877413,
		Changes = [[- Fixed a bug with the UI on Blessed Spring not disappearing between retried runs.
- Reduced the Blessed Water Flask healing cooldown to 30 seconds.
- Reverted the change that prevented you from equipping two of the same weapon.
- There is now a 0.75 second cooldown on quick switching weapons.

Added five new abilities for rangers! In order to use the following abilities, you must have a bow, crossbow, or musket equipped.

- Ricochet. Shoot a projectile that bounces between enemies.
- Fan of Projectiles. Shoot a fan of projectiles, damaging several enemies at range or dealing a devastating close-range hit.
- Rain of Projectiles. Launch a volley of projectiles that rain down on the targeted area, dealing damage to enemies there for a few seconds.
- Explosive Projectile. Fire a projectile that explodes when it hits a target or wall, dealing damage to nearby enemies.
- Projectile Barrage. Channel for a short duration, unleashing a barrage of projectiles towards your target position.

These abilities do not require any mana and could be considered the first of what will hopefully be many "weapon abilities" -- abilities that are tied to you having a certain class of weapon equipped. More to come on this.

How do you acquire these new abilities? Well, a friendly Evrigan named Norov is waiting in the League's tavern to show you the ropes of being a ranger. Why don't you drop by and see what he has to say?]],
	},
	{
		Time = 1625031847498,
		Changes = [[- Fixed a bug with Fiery/Frozen corruption that was causing the game to break.
- The save file deletion button works now. It does not preserve _any in-game items, including event items._ Your purchases are preserved -- I'm not double-charging anyone. Use at your own risk.
- The Kakastan Lightning Staff's cast is now interrupted by walls (if you try to aim over a wall, you'll hit the wall you're facing instead). Let me know if there's any dungeons where this proves to be really annoying due to props.
- You can no longer offhand the same exact weapon that you have in your main hand. Unfortunately, there were a lot of extremely broken builds relying on using two of the same weapon like Musket or Mana Bow. I realize there isn't a complete 1:1 with factors like upgrades or modifiers, but I strongly feel this will be healthier for the metagame in the long run.
- Orcs now take 25% extra piercing damage.
- Lowered the requirement of all tier 1 talents down from 70 to 60.

New ability!
- Blessed Water Flask. Throw a flask of blessed water, dealing magical disintegration damage to spiritual enemies such as Undead and Shadows. Also heals allies. Costs no mana.

New mission!
- Blessed Spring. Help Drillmaster Leon create flasks of blessed water in his homeland of Yakund in a unique new mission. Be sure to bring a friend...]]
	},
	{
		Time = 1624939574085,
		Changes = [[- There is now an `/unstuck` command. You channel for 10 seconds and then get moved to where you would have respawned if you died (you don't die, though). Taking damage, moving, or using any ability will break this channel. Use it only when you need to.
- The Jukumai Necromancer's basic ice toss and rapid-fire barrage both have been made easier to react to.
- The talent limit actually works now.
- Torches in the new castle dungeon do not block attacks or stop movement anymore.
- The maximum block value of a Sword & Shield's shield is now updated per frame which prevents current and future bugs related to getting the incorrect maximum block value.
- Spawner traps such as tunnels and breaches can no longer be defended by any defender-type enemies.
- The description of Claws-type weapons now properly explains that you gain 5 health back per hit you successfully land during Adrenaline Rush and that you only sacrifice 35% of your current health to start an Adrenaline Rush with the secondary attack.
- A spawner trap can only have 3 active enemies out before it stops spawning. Killing these enemies will, as it has before, allow more enemies to spawn, but the limit before this patch was 5.
- Fiery Corruptions now telegraph which direction they're going to throw their fireball.
- Frozen Corruptions now telegraph which direction they're going to throw their ice chunk. They also telegraph which directions their ice chunks will fly when they die.
- Timed floors such as the one in Raid: Worst Case Scenario do not cause you to lose if the timer ends during the "floor cleared" message.
- The enemies in the first floor of Raid: Worst Case Scenario have their detection range increased which prevents a curious exploit that made defending the cannons much easier.
- Fixed a bugged interaction between Deep Spirit and Fortitude such that using Combat Teleport when at exactly 10 mana would result in Fortitude not being given.
- Fixed how Shields (such as the one given by Selfless) render on all health bars. Old rendering was wacky, it now attaches to the tip of your current health and scales properly when it gives you more health than what your normal maximum health.]]
	},
	{
		Time = 1624734277852,
		Changes = [[- Changed Orc Aegis. Now travels in a straight line during his triple-slash dash and the attack is preceeded by a directional telegraph similar to other ranged enemies. Also fixed a bug where this enemy would sometimes jump into the floor and die.
- Fixed a bug with Greatsword enemy types where their leap would sometimes jump them into the floor and then they would die.
- Fixed a bug which allowed you to have a higher health than your maximum health which would make your health bar look silly.
- The healing bar for Vampiric now appears even when you switch off of a Vampiric weapon and disappears once the healing has worn off (but only if you are no longer wielding a Vampiric weapon, of course).
- The Amulet of Purity now increases Constitution (not max health).
- The Amulet of Valor now increases Agility (not sprint speed).
- The Amulet of Magic now increases Perseverance (not max mana).
- The Gilded Branch now increases Compassion (not healing power).
(I understand these trinkets filled niches people would like to fill, and I will try to add replacements later.)
- The Agile modifier now increases Agility by 25 points instead of increasing your movement speed.
- The Vital modifier now increases Constitution by 25 points instead of increasing your maximum health.
- The Spiritual modifier now increases Perseverance by 25 points instead of increasing your maximum mana.
- New weapon modifier: Fierce. Increases Strength by 25 points.
- New weapon modifier: Willful. Increases Dominance by 25 points.
- New weapon modifier: Empathetic. Increases Compassion by 25 points.
- Each point of Constitution now grants 2.5 points of maximum health instead of 1.
- Each point Perseverance now grants 1 point of maximum mana instead of 0.5.
- Changes in Constitution and Perseverance that adjust your maximum health or mana respectively will preserve the ratio of your health or mana respectively as they change. This means that if you go from 300/300 health and gain 25 Constitution, you'll be at 362/362 health instead of 300/362 health.
- There's now a "Respec" sign above the knight who can refund your stat points.
- There's now a "Reforge" sign above the blacksmith.
- Reduced the collision fidelity of some assets in the Sewer map to increase performance.
- The Reforge gui has a scrollbar for weapons with too many reforges to fit on the screen.
- Adjusted salvaging rates so that you can't spawn materials out of nowhere.
- Perfected now caps at 50% bonus damage but stacks twice as quickly as it used to.
- The speed buff from Grimstone Greatsword is now considered a buff and has a proper text placeholder.
- Valiant Jukumai Staff's secondary attack propogates every 0.5 seconds instead of every 0.1 seconds.
- Ensouled Strike can no longer be granted if the killing blow to the enemy was itself damage from an Ensouled Strike.]]
	},
	{
		Time = 1624687842111,
		Changes = [[- Confirmed a patch for an exploit that allowed players to instantly kill every enemy on the map.
- Confirmed a patch for an exploit that allowed players to kick down doors and pick up treasure without actually being next to them.
- Wiped the leaderboards to remove the exploited times and because of major dungeon changes.
- The "Distance to Shore" gui in Grimstone Keep no longer persists after you disembark the Komodo.
- The Mana Bow now properly deals magical damage with its arrows.
- Musket weapon types can now acquire and make use of the Loaded modifer.
- The Quest Log no longer captures scroll wheel inputs.

New dungeons are live in some missions! Currently Castle and Sewer maps have been replaced in the following missions:
- Rookie's Grave
- Tower at Kastakar
- Tunneling Threat
- Corrupted Heritage
- A Grave Issue
- Clawing at the Walls
- Raid: The Yawning Abyss
- Homefront Defense
- Pushing Forward
- Outskirts of Fyreth
- Siege of Fyreth (significant changes)
- A Fire Below
- Lessons in the Arcane I
- Lessons in the Arcane II
- Lessons in the Arcane III
- Pilgrim Rock
- A Valorous Stand
- Grimstone Keep

Lorithas Expedition changes!
- Null enemies will now appear
- Immortal Shadow enemies will now appear
- Orc Aegis enemies will now appear
- Orc Pistoleer enemies will now appear
- Orc Grenadier enemies will now appear
- Will now generate the new Castle dungeon instead of the old one
- Will now generate the new Sewer dungeon instead of the old one
- Will now generate Frozen Castle dungeons
- Will now generate Magma Cave dungeons
- Will now generate Crypt dungeons
- Will now generate Swamp dungeons]]
	},
	{
		Time = 1624639664303,
		Changes = [[- Mana Bow can now acquire the Loaded modifier.
- Axe & Buckler Weapons acquire fewer extra parries based on Agility. At 500 Agility, an Axe & Buckler will have 3 extra parries.
- The Bluesteel Axe's parry restore mechanic now has a five second cooldown. The weapon's behavior against bosses is essentially unchanged due to the frost immunity mechanic, but the weapon no longer essentially grants invincibility in regular rooms due to the glut of available frost targets.]],
	},
	{
		Time = 1624509897075,
		Changes = [[- Greatsword primary attack no longer puts its secondary attack on such a long cooldown which makes comboing the two much better. The secondary also doesn't put the primary on a very long cooldown. This makes the greatsword combo much better.
- Added status placeholder names for a couple of statuses that had been missing
- Vampiric no longer heals for 2% of the damage you deal immediately. Instead, 5% of the damage you deal is stored in a pool which is expended to heal you over time. The fastest this pool can heal you is 1% of your maximum health per second. There is now UI to show you how much Vampiric healing you have saved up, it appears just below your health bar.
- Perfected is now a status effect that shows on your status bar. It is no longer removed when you swap weapons, which means you can carry your stacks to a non-Perfected weapon. We'll see how this affects the meta, it may need adjustment in the future.]]
	},
	{
		Time = 1612932305705,
		Changes = [[* The Frosty effect (applied by Bluesteel weapons) now shatters after 3 hits instead of 6. It now deals half damage, and after a shatter, a target cannot be affected by Frosty again for 5 seconds.
* Drastically reduced the radius of War Cry at high levels.
* The Vital perk on weapons now increases health by 100 rather than 50.
* Canopy leaves in Forest-type maps are now transparent.
* More work to be done on the Missile modifier, but for now, stunned enemies do not produce missiles.
* Sharp and Heavy modifiers now grant 15% bonus damage rather than 10%.
* You can now hold down ability keys and they will be re-used automatically (hold Space to roll repeatedly, for example).
* Converted Mana Darts. It now aims a dart at your targeted position, passing through walls. Upgrading reduces the cost and cooldown time, allowing you to machine gun mana darts if you so choose.]]
	},
	{
		Time = 1612750363727,
		Changes = [[- Claws:
    * Increased adrenaline duration slightly
    * Increased hitbox width slightly
    * Landing an attack while under the effects of Adrenaline Rush grant 5 health
    * Reduced current health cost of secondary attack to 35%
- Battleaxe charge doesn't land you as close to your target as before.
- Scythe:
    * Increased damage
    * Fixed a bug where the secondary attack was not dealing as much damage as it should've been
    * Decreased the casting time of the secondary attack
- Saber and Pistol:
    * Increased pistol damage
    * Pistol no longer slows you down when firing it
    * You must melee attack 3 times in order to be able to fire your pistol]]
	},
	{
		Time = 1612576320559,
		Changes = [[- Changed a fundamental aspect of how the game determines if you're inputting a primary or secondary attack. While light attacks will be prioritized if both types of attacks are off cooldown, holding both attack buttons can still make you use both.
- Dual Dirks
	* Increase damage
	* Decreased hitbox length, increased hitbox width
	* Primary attack no longer puts secondary attack on cooldown, allowing you to use the speed boost whenever you want
- Staff of Shadows will no longer go on cooldown if there are no nearby shadow-afflicted enemies to yeet at
- Rapier
	* Primary attack no longer locks you out of secondary attack for so long. Riposte to your heart's content.
	* Completely changed the primary attack. Now, you hold down the attack button to charge up an attack. Release the attack button with perfect timing to get a reduced cooldown time on the primary attack. Very interesting mini-game, give it a try.]]
	},
	{
		Time = 1612412625892,
		Changes = [[- Fixed a bug where you could pull a javelin out of nowhere if one was already in flight.
- Added War Cry as a drop into Tower at Kastakar, it missing from the game altogether was a bug. Whoopsie.
- Maul attacks are bigger and are centered further away from you than before.
- Increased Mercenary Sabers' secondary attack cooldown from 2 to 4 seconds.
- 3rd Age Pirate Cutlasses:
	* Decreased spins per swagger from 5 to 3
	* Increased spin damage from 0.5x to 0.75x
- Orc Elder Staff:
	* Increased damage of secondary attack
	* Added a mechanic that drains charge. Drain is faster when charge is high, meaning you have to really get into the thick of things to earn an epic fireball barrage. Very orcish.
	* Heavy attack now has a cooldown, yay!
- Fixed a bug where Valiant Jukumai Staff could attack through walls.
- Purified Jukumai Staff:
	* Increased secondary attack projectile speed
	* Increased secondary attack projectile width
	* Increased secondary attack healing
	* Decreased secondary attack damage
- Fixed a bug where Frost Strike was still having its mana cost halved by the Reclaimed Jukumai Staff (unintended, will move mechanic to a trinket at a later time).
- Kakastan Lightning Staff:
	* Increased secondary mana cost
	* Secondary now causes you to slow down briefly
	* Decreased secondary damage slightly
	* Secondary now deals more damage to targets hit in the center of the lightning strike
	* Secondary no longer goes on cooldown if it fails to cast due to lack of mana]]
	},
	{
		Time = 1612325135925,
		Changes = [[- Changed the square icon that held your weapon to a circle icon. Looks nicer!
- Fixed a bug that allowed you to use the secondary attack of Maul weapons sooner than intended.
- Reduced possible bonus damage of Blade of Vengeance from 200% (3x) to 50% (1.5x).
- Javelin secondary attack cooldown is much shorter after throwing so that you can pull an impaled javelin out quickly. Still has a short cooldown after pulling out a javelin, though, so you can't spam this for tons of damage.
- Javelin secondary attack no longer goes on cooldown when attempting to pull a javelin out that isn't there.
- Javelin now deals significantly increased damage if it travels a minimum distance and has effects to denote when this happens.
- Reduced dagger damage of Bow & Dagger weapons.
- Decreased the attack speed of Greatsword weapons and proportionally increased their attack damage.
- Tinkered with the Greatsword spin animation to make it more responsive.]]
	},
	{
		Time = 1612233193329,
		Changes = [[- The hotbar now swaps with the weapon. This allows you to have two separate loadouts, like one ranged-focused and one melee-focused or magic-focused build that you can easily swap between.
- The swap button now just has a permanent arrows icon.
- Your current weapon is shown in a new, larger box to the left of the hotbar. It also features a split cooldown bar. The left cooldown bar shows your primary attack's cooldown, and your right cooldown bar shows you secondary cooldown.]]
	},
	{
		Time = 1611783885045,
		Changes =[[- Fully implemented the 10 slot hotbar! Now you can equip each unique ability you have to your hotbar in any order you wish. Order is recalled and reloaded upon rejoin. It's currently very unbalanced. In the near future, I'll be adding some kind of global cooldown system that prevents you from spamming offensive spells too quickly without sacrificing the flexibility of being able to roll or use other movement abilities. Suggestions on how to do this would be welcome. I'll also be converting abilities as soon as possible so that they're aimed instead of auto-targeted. I will also be implementing the full hotbar quick swap soon. Look forward to it!

- Converted the Torch you carry around inside the Great Glacier. No longer takes up an ability slot, instead its heavy attack is how you drop it.
- Converted the "carryable" category of "weapons" such as the Lava Core and Resurrection Prevention Device. Their light attack is a 10 second cooldown miniature war cry that knocks enemies away. Their heavy attack drops it. Sprinting and ability use are blocked while holding.]]
	},
	{
		Time = 1611094122641,
		Changes = [[- Added a keybind system.]]
	},
	{
		Time = 1605659245079,
		Changes = [[- Added a player versus player mode. Head over to the docks and talk to the new NPC for more information.
- Added a new shop item category: celebrations. Both animations and emotes are available for purchase, and you can celebrate on PC with the C key. Methods for console and mobile will be added soon.]],
	},
	{
		Time = 1605399859736,
		Changes = [[- Terrorknight Summoners, Warden's Soul Cage, and Jukumai Necromancer no longer grant their summoned lackeys Elite status or bonus modifiers based on difficulty.
- Reduced Elite health bonus from 5x to 2x.]]
	},
	{
		Time = 1605216034040,
		Changes = [[- Various bugfixes.
- You can now discard trinkets.
- Removed the Auto Equip option since it is obsolete.
- Some potential fixes to people's lobby UI breaking (might've been causing people not to be able to start missions?)
- Can no longer click out of the missions GUI during the Lobby tutorial.]]
	},
	{
		Time = 1604940393626,
		Changes = [[- Doubled the range of musket's ranged attack.
- Raid: Worst Case Scenario has had various materials added to its drop table.
- Raid: the Yawning Abyss has had its material drops increased.
- Raid: Siege of Fyreth has had its material drops increased.
- Resurrected enemies in Raid: the Yawning Abyss no longer grant experience.
- The Taunt effect now ends early if the taunted target is too far away from the taunter.
- Dramatically reduced the health of most bosses in Raids.
- Slightly reduced the health of Osseous Aberration.
- You can no longer accidentally "click out" of the mission selection screen since apparently this was happening to a lot of people when they missed the actual buttons and they thought it was broken.]]
	},
	{
		Time = 1604783734243,
		Changes = [[- Enemies can no longer acquire the Resilient modifier more than once.
- Enemies can no longer acquire the Electric modifier more than once.
- Enemies can no longer acquire the Missile modifier more than once.
- The Explosive modifier now properly deals damage again.
- Resilient now grants only 25% damage reduction instead of 40%.
- Base damage reduction for all difficulties reduced across the board. Modifiers will help pick up the slack in difficulty without making choosing high difficulties a slog.
- Steel's bleed amount is now based on a kind-of-new stat called "attack power." Attack power is essentially the amount of damage per second that a weapon deals without any modifiers added to it based on your level. Steel weapons now bleed targets for 100% of your attack power over 5 seconds, non-stacking. This should allow steel dirks to actually be viable again. According to tests, Dirks at maximum speed had comprable DPS to Halberd continuous blade hits.
- Orc Elder's Staff's fire bolt damage is now a portion of your attack power based on the amount of mana expended.
- Fixed a bug that allowed handaxes to completely break the UI.
- Fixed a bug that allowed you to abuse quickswap to get infinite throwing axes.
- Jolian Musket now deals 75% more damage when firing as opposed to stabbing with the bayonet.]]
	},
	{
		Time = 1604715235450,
		Changes = [[- Reduced damage of Electric modifier.
- Reduced damage of Missile modifier.
- Reduced the health of Forsaken and Forgotten Shadows bosses in Lorithas Expedition.]]
	},
	{
		Time = 1604702087723,
		Changes = [[- Completely re-made the progression system from the ground up! Now you have levels and experience like a normal RPG.
- Added the Orc Raid with three new enemies, three new bosses, and three new weapons.
- Added trinkets to the game! Currently 6 simple ones, but more complicated ones are coming soon.]]
	},
	{
		Time = 1603249271609,
		Changes = [[- Remade the tutorial! It's now much faster-paced and gets you into the action right away.
- Fixed a bug with 3rd Age Pirate Cutlasses that was causing the spins to activate instantly instead of after the intended 0.75 second timer.]]
	},
	{
		Time = 1603150556854,
		Changes = [[- Added an in-game update log.]],
	},
	{
		Time = 1603145960170,
		Changes = [[- It should no longer be possible for logs to block your way in Forest-type maps.
- The "Traveling to..." screen is now shown immediately before the teleport begins to provide clarity that the teleport is underway (even if it's taking a second).
- It should no longer be possible for large magma spires to block your way in Magma Cave-type maps.
- Having an Ethereal weapon will no longer cause you to fall through the floor when you die.
- Dual Dirks now correctly reflect their reduced damage in the UI (but they still deal significantly more DPS at maximum attack speed).
- Fixed the animation for Dual Dirks' left-handed attack such that your hand no longer moves slightly downwards.
- Added an option that allows you to avoid attacking at point blank range with ranged weapons. Currently this works for bows and crossbows. If you're too close to an enemy, you will simply not attack. If you want to ranged attack, you'll have to get further away. Melee attack? Get closer. Note that this is strictly a DPS decrease, but some people really wanted to be able to conserve ammunition and it wasn't too hard to set up. So here you go.
- Unkillable DPS-counter dummies have been added behind the dummy training area. One of them even deals damage so you can test things like Blade of Vengeance.
- Enemies can no longer become "Elite Elite" anymore.
- Grimstone Javelin now deals 50% damage on the Javelin throw, instead of the normal 200% for other Javelins.
- Grimstone Javelin now stuns targets it pulls very briefly to interrupt their attacks. This should fix a couple issues with it.
- Grimstone Javelin now pulls enemies to you at a much higher speed.
- Landing at Grimstone Keep will no longer grant you victory unless you kill all enemies at the end. Best not to hide behind any masts anymore.]]
	}
}