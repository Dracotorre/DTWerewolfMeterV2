Scriptname DTWWPlayerAliasScript extends ReferenceAlias

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Werewolf Time Meter  - playerAlias
; Author: DracoTorre
; Version: 2.0
; Source: http://www.nexusmods.com/skyrimspecialedition/mods/8389/?
; Homepage: http://www.dracotorre.com/mods/werewolfmeter/
;
; uses OnRaceSwitchComplete to call main DTWerewolfWatch
; uses OnLycanthropyStateChanged to enable or disable meter
; hides Toggle spell about 2 minutes after game load
; *******************

Quest property DTWerewolfWatchP auto
Spell property DTWW_WolfMeterToggleSpell auto
GlobalVariable property DTWW_Initialized auto

Bool property IsCreature auto hidden

Event OnPlayerLoadGame()
	(DTWerewolfWatchP as DTWerewolfWatch).InitOnGameLoad()
	Actor playerRef = self.GetActorReference()
	
	int initVal = DTWW_Initialized.GetValueInt()
	
	if (initVal > 0 && playerRef != None && !playerRef.HasSpell(DTWW_WolfMeterToggleSpell))
		playerRef.AddSpell(DTWW_WolfMeterToggleSpell, false)
	endIf
	
	if (initVal < 2)
		; show update message if we have one 
		
		RegisterForSingleUpdate(7.0)
	else
		; until remove toggle spell
		RegisterForSingleUpdate(120.0)
	endIf
EndEvent

Event OnUpdate()
	MaintainMod()
	
EndEvent

;https://www.creationkit.com/index.php?title=OnHit_-_ObjectReference
;
Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, \
  bool abBashAttack, bool abHitBlocked)
 
	; a single attack may have 2+ hits
	if ((DTWerewolfWatchP as DTWerewolfWatch).MeterDisplayed)

		if (akSource == None)
			; projectile not from weapon/spell or bash from torch
			(DTWerewolfWatchP as DTWerewolfWatch).ProccessCheckHitPlayer(self.GetActorReference())
			
		elseIf (akAggressor != None)
			Actor attacker = akAggressor as Actor
			if (attacker != None)
				Form mainWeapon = attacker.GetEquippedWeapon(0)
				if (mainWeapon != None && mainWeapon == (akSource as Weapon))
					; do nothing - only interested in effects
				else
					(DTWerewolfWatchP as DTWerewolfWatch).ProccessCheckHitPlayer(self.GetActorReference())
				endIf
			endIf
		endIf
	endIf
EndEvent

; this event added in SE v1.5.3
; when becomes werewolf let's enable or disable meter
Event OnLycanthropyStateChanged(bool abIsWerewolf)
	if (abIsWerewolf)
		if ((DTWerewolfWatchP as DTWerewolfWatch).DTWW_Enabled.GetValueInt() == 0)
			(DTWerewolfWatchP as DTWerewolfWatch).DTWW_Enabled.SetValueInt(1)
			(DTWerewolfWatchP as DTWerewolfWatch).Register()
			
			Utility.Wait(4.0)
			(DTWerewolfWatchP as DTWerewolfWatch).ProcessCheckMeter(self.GetActorReference())
		endIf
	endIf
endEvent

; from comment: It is possible for this event to be hit when loading a save with a player character of a different race.
Event OnRaceSwitchComplete()

	Actor playerRef = self.GetActorReference()
	
	if (DTWW_Initialized.GetValueInt() <= 0)
		(DTWerewolfWatchP as DTWerewolfWatch).InitializeMeterWatch(playerRef)
	endIf
	
	if ((DTWerewolfWatchP as DTWerewolfWatch).PlayerIsWerewolfBeast(playerRef))
		; mark as creature to check later to avoid issue with other race switches
		IsCreature = true
	
	; clothing visible during transform effect 
	;elseIf ((DTWerewolfWatchP as DTWerewolfWatch).PlayerIsVampireLord(playerRef))
	;	IsCreature = true
		
	else
		; check if was a creature and setting to unequip
		if (IsCreature && (DTWerewolfWatchP as DTWerewolfWatch).DTWW_Enabled.GetValueInt() >= 2)
			playerRef.UnequipAll()
		endIf
		IsCreature = false
	endIf
	; wait a bit before updating meter
	Utility.Wait(5.25)
	(DTWerewolfWatchP as DTWerewolfWatch).ProcessCheckMeter(playerRef)
endEvent


Function MaintainMod()
	Actor playerRef = self.GetActorReference()
	int initVal = DTWW_Initialized.GetValueInt()
	
	if (initVal <= 0)
		if (playerRef != None && playerRef.HasSpell(DTWW_WolfMeterToggleSpell))
			DTWW_Initialized.SetValueInt(1)
			initVal = 1
		endIf
	endIf
	
	if (initVal == 1)
		DTWW_Initialized.SetValueInt(2)
		; may show welcome message here
		
		; time until remove toggle spell
		RegisterForSingleUpdate(120.0)
		
	elseIf (playerRef != None && playerRef.HasSpell(DTWW_WolfMeterToggleSpell))
		;hide the toggle spell
		playerRef.RemoveSpell(DTWW_WolfMeterToggleSpell)
	endIf
EndFunction
