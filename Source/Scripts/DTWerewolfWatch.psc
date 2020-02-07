scriptName DTWerewolfWatch extends Quest  
{watch player and if beast race then display timer using the magicka meter}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Werewolf Time Meter - WerewolfWatch main controller
; Author: DracoTorre
; Version: 2.0
; Source: http://www.nexusmods.com/skyrimspecialedition/mods/8389/?
; Homepage: http://www.dracotorre.com/mods/werewolfmeter/
;
; DTWWPlayerAliasScript.OnRaceSwitchComplete() checks ProcessCheckMeter() to determine if need to start or end/restore 
; during beast, polls to update magicka bar by calculating time-remain
;
; Note that Moonlight Tales lunar tranformation sets PlayerWerewolfShiftBackTime to a very large value--999 days.
; - Moonlight Tales SE lunar transformation ends at 5am,
; - Moonlight Tales Essentials transformation ends at 6am.
; This script decides if 5am or 6am endtime depending on number of DLC1 werewolf perks.
;   in function: GetLunarTransformEndTime
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GlobalVariable property PlayerWerewolfShiftBackTime auto
GlobalVariable property DTWW_Enabled auto
GlobalVariable property DTWW_PlayerLastKnownShiftBackTime auto 
GlobalVariable property DTWW_PlayerShiftedToWerwolfTime auto 
GlobalVariable property DTWW_PlayerOrigMagicka auto
GlobalVariable property DTWW_PlayerHasAtronochStone auto 
GlobalVariable property DTWW_PlayerHasAtronochPerk auto
GlobalVariable property DTWW_Initialized auto
Spell property DTWW_WerwolfMeterSpell auto
Spell property DTWW_WolfMeterToggleSpell auto 
Spell Property BeastForm auto
Spell property DoomAtronochAbility auto 
Perk property Atronoch auto 
Keyword property ActorTypeCreature auto
Quest property PlayerWerewolfQuest auto
Message property DTWW_DisableMeterMessage auto 
Message property DTWW_EnableMeterMessage auto
Message property DTWW_EnableMeterUneqMessage auto
Message property DTWW_DisableSoonMeterMessage auto
Message property DTWW_MinRemainMessage auto
MagicEffect property DTWW_DamageMagickaRate auto

GlobalVariable Property DLC1WerewolfMaxPerks  Auto
;Race property DLC1VampireBeastRace auto
;Keyword property ActorTypeUndead auto

bool property MeterDisplayed auto hidden
float property LastOnHitTime auto hidden				; to avoid checking/updating too frequently
 
Event OnLoad()
	self.OnInit()
endEvent

Event OnInit()
	InitOnGameLoad()
	RegisterForSingleUpdate(5.0)
endEvent

Event OnUpdate()

	actor playerActorRef = game.GetPlayer()
	bool isEnabled = true
	bool lastEnabled = false
	if (DTWW_Enabled.GetValueInt() >= 1)
		lastEnabled = true
	endIf
	
	if (DTWW_Initialized.GetValueInt() > 0 || playerActorRef.HasSpell(DTWW_WolfMeterToggleSpell))
		isEnabled = lastEnabled
	elseIf !Game.IsFightingControlsEnabled()
		; player busy - wait to init later
		UnregisterForUpdate()
		RegisterForSingleUpdate(33.0)
		return
	else
		isEnabled = InitializeMeterWatch(playerActorRef)
	endIf
	
	if (!isEnabled)
		UnregisterForUpdate()
		DisableMeter(playerActorRef)
		return
	endIf
	
	ProcessCheckMeter(playerActorRef)
	
endEvent

; *************************************************************
;  register / unregister
; **************

Function Register()
	
	UnregisterForUpdate() 
	int toggleVal = DTWW_Enabled.GetValueInt()
	if (toggleVal >= 2)
		if (DTWW_Initialized.GetValueInt() < 2)
			; player toggled, so consider initialized
			DTWW_Initialized.SetValueInt(2)
		endIf
		DTWW_EnableMeterUneqMessage.Show()
	elseIf (toggleVal > 0)
		DTWW_EnableMeterMessage.Show()
	endIf
	 
	RegisterForSingleUpdate(3.0)
endFunction

Function UnRegister()
	
	UnregisterForUpdate()
	actor playerActorRef = Game.GetPlayer()
	DisableMeter(playerActorRef)
	
endFunction

; *************************************************************
;  functions 
; **************

Function DisableMeter(actor playerActorRef)
	bool restored = true
	
	if (MeterDisplayed || playerActorRef.HasSpell(DTWW_WerwolfMeterSpell) || playerActorRef.HasMagicEffect(DTWW_DamageMagickaRate))
		restored = RestoreMagickaAndGlobals(playerActorRef)
	
	endIf
	if restored
		Utility.wait(0.22)
		DTWW_DisableMeterMessage.Show()
	else
		DTWW_DisableSoonMeterMessage.Show()
		RegisterForSingleUpdate(8.2)
	endIf
EndFunction

Function InitOnGameLoad()
	LastOnHitTime = 0.0
endFunction
;
;bool Function PlayerIsVampireLord(Actor playerActorRef, bool alwaysCheck = true)
;	bool okayToCheck = false
;	if (alwaysCheck)
;		okayToCheck = true
;	elseIf (DTWW_Enabled.GetValueInt() >= 3)
;		okayToCheck = true
;	endIf
;	
;	if (okayToCheck && ActorTypeUndead != None && DLC1VampireBeastRace != None)
;		if (playerActorRef == None)
;			playerActorRef = Game.GetPlayer()
;		endIf
;		if (playerActorRef.HasKeyword(ActorTypeUndead))
;			if ((playerActorRef.GetBaseObject() as ActorBase).GetRace() == DLC1VampireBeastRace)
;				return true
;			endIf
;		endIf
;	endIf
;	
;	return false
;endFunction

bool Function PlayerIsWerewolfBeast(Actor playerActorRef)
	if (playerActorRef == None)
		playerActorRef = Game.GetPlayer()
	endIf
	if (playerActorRef.HasKeyword(ActorTypeCreature) && PlayerWerewolfQuest.IsRunning() && PlayerWerewolfQuest.GetStage() < 100)
		return true
	endIf
	
	return false
endFunction

; player was hit, do we need to update meter for spell absorption?
Function ProccessCheckHitPlayer(Actor playerActorRef)
	
	if (DTWW_Enabled.GetValueInt() >= 1 && MeterDisplayed)
		; only check if enabled and has atronoch stone/perk/ability
		if (DTWW_PlayerHasAtronochStone.GetValueInt() >= 1 || DTWW_PlayerHasAtronochPerk.GetValueInt() >= 1)
			if (playerActorRef == None)
				playerActorRef = Game.GetPlayer()
			endIf
			float secSinceLastHit = 200.0
			float currentTimeInSec = Utility.GetCurrentRealTime()
			if (LastOnHitTime > 0.0)
				secSinceLastHit = currentTimeInSec - LastOnHitTime
			endIf
			
			; magic and enchanted attacks record 2 or 3 hits at once - limit
			if (secSinceLastHit > 0.3333)
				LastOnHitTime = currentTimeInSec

				ProcessCheckMeter(playerActorRef)
			endIf
		endIf
	endIf
endFunction

Function ProcessCheckMeter(actor playerActorRef)

	if (playerActorRef != None)
		if (DTWW_Enabled.GetValue() > 0.0)
		
			float updateSecs = 90.0			; to update
			float playerLastKnownShiftTime = DTWW_PlayerLastKnownShiftBackTime.GetValue()
			bool isBeast = false
			bool retryRemove = false
			
			if (PlayerIsWerewolfBeast(playerActorRef))
			
				isBeast = true
			
				float playerShiftTime = PlayerWerewolfShiftBackTime.GetValue()
				float playerBecameWerwolfTime = DTWW_PlayerShiftedToWerwolfTime.GetValue()
				float currenTime = Utility.GetCurrentGameTime()
				float lunarShiftLimit = currenTime + 100.0   ;mtse sets 999 + days passed 
				bool showTimeMeter = playerActorRef.HasSpell(DTWW_WerwolfMeterSpell)
				
				if (playerShiftTime > lunarShiftLimit && playerLastKnownShiftTime > 0.0)
				
					; did we enter MTSE all-night while in beast form?
					float shiftHour = GetHourFromGameTime(playerLastKnownShiftTime)

					if (playerLastKnownShiftTime < (currenTime + 0.1667) && (shiftHour < 5.0 || shiftHour > 6.0))
						; all-night activation! Update end-transform time
						playerShiftTime = GetLunarTransformEndTime(currenTime)
					else
						playerShiftTime = playerLastKnownShiftTime
					endIf
				endIf 
				
				if (playerShiftTime != playerLastKnownShiftTime)
					if playerLastKnownShiftTime == 0
						if playerShiftTime > lunarShiftLimit
							; lunar transformation adjustment
							playerShiftTime = GetLunarTransformEndTime(currenTime)
							;Debug.Notification("DTWW - set Lunar transform time: " + playerShiftTime)
						endIf
						
						playerLastKnownShiftTime = playerShiftTime
						playerBecameWerwolfTime = currenTime
						float magickaCurrent = playerActorRef.GetActorValue("Magicka")

						DTWW_PlayerOrigMagicka.SetValue(magickaCurrent)
						DTWW_PlayerShiftedToWerwolfTime.SetValue(playerBecameWerwolfTime)
						
						if playerActorRef.HasPerk(Atronoch)
							DTWW_PlayerHasAtronochPerk.SetValue(1.0)
						else
							DTWW_PlayerHasAtronochPerk.SetValue(0.0)
						endIf
						
						if playerActorRef.HasSpell(DoomAtronochAbility)
							DTWW_PlayerHasAtronochStone.SetValue(1.0)
						else
							DTWW_PlayerHasAtronochStone.SetValue(0.0)
						endIf
						
						if (playerActorRef.HasSpell(DTWW_WerwolfMeterSpell) || playerActorRef.HasMagicEffect(DTWW_DamageMagickaRate))
							showTimeMeter = true 
						else
							showTimeMeter = playerActorRef.AddSpell(DTWW_WerwolfMeterSpell, false)
						endIf 
						
					endIf
				
					DTWW_PlayerLastKnownShiftBackTime.SetValue(playerShiftTime)
					
				elseIf (showTimeMeter == false)
					; try adding again
					showTimeMeter = playerActorRef.AddSpell(DTWW_WerwolfMeterSpell, false)
				endIf
				
				; calculate time remain in hours for meter and update
				float totalTime = (playerShiftTime - playerBecameWerwolfTime) * 24.0
				float currentHoursRemaining = (playerShiftTime - currenTime) * 24.0

				if currentHoursRemaining < 0.0
					currentHoursRemaining = 0.0
				endIf
				
				if totalTime <= 0.0
					totalTime = 0.01
				endIf
				
				updateSecs = 3.0					; default beast-form update				
				if currentHoursRemaining > 2.0
					updateSecs = 5.0
				elseIf currentHoursRemaining < 0.0125
					updateSecs = 1.67				; time almost out
				endIf
				
				if showTimeMeter
					MeterDisplayed = true
					float fractionTimeRemaining = currentHoursRemaining / totalTime
					float magickaMax = GetMaxMagickaActorValue(playerActorRef)
					float timerValue = fractionTimeRemaining * magickaMax
					
					UpdateMagickaMeterWithValue(timerValue, playerActorRef)
				else
					MeterDisplayed = false
					float minsRemain = 60 * currentHoursRemaining
					;Debug.Notification("DTWW - minutes remaining: " + minsRemain)
					DTWW_MinRemainMessage.Show(minsRemain)
					updateSecs += 1.0
				endIf 
			elseIf (playerLastKnownShiftTime != 0.0)
				; restore

				if (RestoreMagickaAndGlobals(playerActorRef) == false)
					;Debug.Notification("DTWW - failed restore...try again")
					retryRemove = true
					updateSecs = 1.5
				endIf
			elseIf playerActorRef.HasSpell(DTWW_WerwolfMeterSpell)
				; if failed to remove before, try again
				;Debug.Notification("DTWW - Has meterSpell - removing")
				if (RestoreMagickaAndGlobals(playerActorRef) == false)
					retryRemove = true
					updateSecs = 1.5
				endIf
			else
				MeterDisplayed = false
			endIf
			
			if (isBeast || retryRemove)
				if (updateSecs > 0.333)
					RegisterForSingleUpdate(updateSecs)
				else
					RegisterForSingleUpdate(2.0)	
				endIf
			endIf
			
		elseIf (MeterDisplayed || playerActorRef.HasSpell(DTWW_WerwolfMeterSpell))
			; disabled, but still have spell - remove
			
			RestoreMagickaAndGlobals(playerActorRef)
		endIf
	endIf
endFunction

bool function InitializeMeterWatch(Actor playActor)
	if (playActor != None)
		if (!playActor.HasSpell(DTWW_WolfMeterToggleSpell))
			playActor.AddSpell(DTWW_WolfMeterToggleSpell)
		endIf
		DTWW_Initialized.SetValueInt(1)
		
		DTWW_Enabled.SetValueInt(1)
	endIf
	
	return true
endFunction

bool Function RestoreMagickaAndGlobals(Actor playerActorRef)
	
	bool spellRemoved = true
	MeterDisplayed = false
	
	if playerActorRef.HasSpell(DTWW_WerwolfMeterSpell)
		spellRemoved = playerActorRef.RemoveSpell(DTWW_WerwolfMeterSpell)
	endIf
	
	if spellRemoved
	
		DTWW_PlayerLastKnownShiftBackTime.SetValue(0 as Float)
		float origMagicka = DTWW_PlayerOrigMagicka.GetValue()

		if origMagicka <= 5
			origMagicka = GetMaxMagickaActorValue(playerActorRef)
		endIf 
		
		if origMagicka >= playerActorRef.GetBaseActorValue("Magicka")
			; ensure refills completely
			origMagicka = origMagicka + 100
		endIf
		
		DTWW_PlayerShiftedToWerwolfTime.SetValue(0)
		
		UpdateMagickaMeterWithValue(origMagicka, playerActorRef)
		
		DTWW_PlayerOrigMagicka.SetValue(0)
		
	endIf
	
	return spellRemoved
EndFunction

;float Function SecondsSinceLastMeterUpdate()
;	float timeInSec = 200.0
;	
;	if (LastMeterUpdateTime > 0.0)
;		timeInSec = Utility.GetCurrentRealTime() - LastMeterUpdateTime
;	endIf
;	
;	return timeInSec
;endFunction

function UpdateMagickaMeterWithValue(float newVal, Actor playActor)

	float magickaCurrent = playActor.GetActorValue("Magicka")
	;float magickaMax = GetMaxMagickaActorValue(playActor)
	
	if newVal < 0
		newVal = 0
	endIf
	float diffVal = newVal - magickaCurrent
	
	if diffVal < 0
		diffVal = diffVal * -1
		playActor.DamageActorValue("Magicka", diffVal)
	else
		playActor.RestoreActorValue("Magicka", diffVal)
	endIf
	
	;LastMeterUpdateTime = Utility.GetCurrentRealTime()
	
endFunction

float Function GetHourFromGameTime(float gameTime)
	gameTime -= Math.Floor(gameTime)
	gameTime *= 24.0
	return gameTime 
endFunction

; default assume MTSE by Brevi for Special Edition
float Function GetLunarTransformEndTime(float currentTime)

	int dayNum = currentTime as Int
	float endHour = 0.20833333  ;5am for MTSE 
	if DLC1WerewolfMaxPerks.GetValue() < 32
		endHour = 0.250 ; 6am for MTE
	endIf
	float fractionDay = currentTime - dayNum as Float
	if fractionDay > 0.1667
		dayNum += 1
	endIf
	
	return dayNum as Float + endHour
endFunction

float Function GetMaxMagickaActorValue(Actor starget)
	float currentVal = starget.GetActorValue("Magicka")
	if currentVal <= 0.0
		return starget.GetBaseActorValue("Magicka")
	endIf
  return ( currentVal / starget.GetActorValuePercentage("Magicka"))
EndFunction