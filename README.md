# DTWerewolfMeterV2
 werewolf meter mod for Skyrim
 
 
Name: Werewolf Time Meter
Version: 2.0
Date: 2020-01-27
Category: User Interface
Requirements: Dawnguard DLC
Author: Dracotorre
Source: http://www.nexusmods.com/skyrimspecialedition/mods/8389/?
Homepage: http://www.dracotorre.com/mods/werewolfmeter/

===========
## Description
===========

Adds a meter using magicka bar for time remaining in werewolf (or werebear) transformation with optional remove all equipment on transformation back (like in old Skyrim) for improved immersion. The meter borrows the magicka meter since it's normally not used during werewolf transformation.

Designed for Brevi's "Moonlight Tales SE" and "Moonlight Tales Essentials" all-night lunar transformations.

Meter started and stopped by game's transform events; no continuously running script.

'Werewolf Meter Toggle' Power spell toggles 3 modes: 

* Disabled			- no magicka bar changes
* Enabled keep equipment	- updates magicka bar during beast form and at end transformation armor/clothing remain on
* Enabled remove equipment 	- updates magicka bar during beast form and at end transformation removes equipped gear

The toggle spell will auto-hide 2 minutes after load game to keep your Power spells list clean of rarely used spell. To use again, load game and select in Power spells. The reason to remove equipment at end of transform back is to allow equipped werewolf jewerly effects and better compatibility with werewolf mods.


What does the mod do?

* on game event transformation to beast (5 seconds after), stores player's magicka total and replaces magicka bar filled with time until beast-form ends
* during beast form, bar updates every 3-5 seconds, or after absorbing spell with atronach stone/ability (update frequency limited which may skip multiple spell absorbs)
* feeding increases bar by re-calculating time until end -- unless all-night transform
* for MTSE/MTE all-night transform, end-time determined by hours until game-time 5am/6am
* detects MTSE all-night lunar starting during normal Beast Form transformation and updates bar accordingly
* on transformation back, magicka bar restored to former level; if optional remove equipment chosen, all equipement removed


Instead of using toggle spell to switch modes, may use console commands:

* for keep equipment: set DTWW_Enabled to 1
* for remove equipment: set DTWW_Enabled to 2
* disable: set DTWW_Enabled to 0


=======
## Install
=======

Place in Skyrim Special Edition Data folder.

Default set to Enabled-keep-equipement. For remove-equipment on end transformation, activate Power spell, Werewolf Meter Toggle.


## Uninstall
=========

Safest removal: load a save from before installation. Alternatively, you may disable and leave the DTWerewolfMeter plugin in your load order. No running script, no harm.

Do NOT remove the mod on a save during beast form which may break your magicka regeneration!


=============
## Compatibility
=============
Supports "Moonlight Tales Special Edition" and "Moonlight Tales Essentials" by Brevi all-night lunar transformation. May be incompatible with other mods updating player's magicka during werewolf transformation or spell-casting werewolf.

Confirmed compatible with "Wintersun" by Enai Siaion - Magnus Follower (which locks magicka regeneration)

Incompatible with "GuruSR's Werewolf Transformation Meter" due to duplicating effects.


=============
## Known issues
============
with Atronach perk/abilty, hit by spell may briefly cause magicka bar to increase

remove equipment on transform end may briefly show equipped items



==============
## Changes v2.0
==============
* adds optional remove-equipment at end of transformation back
* Werewolf Meter Toggle spell now switches 3 modes: Disabled, Enabled keep equipment, Enabled remove equipment
* performance improvements with more immediate display (about 5 seconds after transformation)
* changed handling atronach perk/ability spell absorption from polling to on-hit reaction with frequency limit
* on obtain lyconthropy will automatically enabled meter -- may override with console: set DTWW_Enabled to -1
* updated text for changes to toggle spell, toggle notifications


## Credits
=======

Thanks to candyman457 and spwned (Brevi) on Nexusmods for requesting a timer and giving me the idea.


## Permission
===============

Please do not upload, distribute, or repost this mod to a site without permission.
