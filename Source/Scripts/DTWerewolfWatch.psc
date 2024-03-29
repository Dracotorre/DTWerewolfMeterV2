scriptName DTWerewolfWatch extends Quest  
{watch player and if beast race then display timer using the magicka meter}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Werewolf Time Meter - WerewolfWatch main controller
; Author: DracoTorre
; Version: 2.25
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
GlobalVariable Property DTWW_InitialPrefVal auto		; v2.26
;Race property DLC1VampireBeastRace auto
;Keyword property ActorTypeUndead auto

bool property MeterDisplayed auto hidden
float property LastOnHitTime auto hidden				; to avoid checking/updating too frequently
bool property GrowlModInstalled auto hidden				; if true, handle magicka scaling to compensate
float property MyBaseMana auto hidden					; for scaling, record on scale to reverse scale later
 
Event OnLoad()
	self.OnInit()
endEvent

Event OnInit()
	InitOnGameLoad()
	RegisterForSingleUpdate(5.0)
endEvent

Event OnUpdate()

	actor playerActorRef = game.GetPlayer()
	bool tisEnabled = true
	bool lastEnabled = false
	if (DTWW_Enabled.GetValueInt() >= 1)
		lastEnabled = true
	endIf
	
	if (DTWW_Initialized.GetValueInt() > 0 || playerActorRef.HasSpell(DTWW_WolfMeterToggleSpell))
		tisEnabled = lastEnabled
	elseIf !Game.IsFightingControlsEnabled()
		; player busy - wait to init later
		UnregisterForUpdate()
		RegisterForSingleUpdate(33.0)
		return
	else
		tisEnabled = InitializeMeterWatch(playerActorRef)
		;
		; v2.26 - announce initial preference
		if (tisEnabled)
			Utility.Wait(1.2)
			ShowPreferenceMessage()
		endIf
		
	endIf
	
	if (!tisEnabled)
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
	endIf
	
	ShowPreferenceMessage()				; v2.26 moved to function
	 
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

; call well after "Growl" scales magicka such as on delayed meter display init
Function CheckInitMagickaScale(Actor playerRef)

	int enableVal = DTWW_Enabled.GetValueInt()
	
	; only for settingEnabled 1 and 2 -- 3+ considered no scale
	if (GrowlModInstalled && MyBaseMana <= 0.0 && enableVal >= 1 && enableVal < 3)
		
		; is magicka scaled too low?
		float maxMana = (playerRef.GetActorValue("Magicka") / playerRef.GetActorValuePercentage("Magicka"))
		if (maxMana < 100.0)
			MyBaseMana = playerRef.GetBaseActorValue("Magicka")
		
			playerRef.ModActorValue("Magicka", MyBaseMana - 1.0)
		endIf
	endIf
endFunction

Function CheckRestoreMagickaScale(Actor playerRef)
	if (MyBaseMana > 0.0)
		; restore
		playerRef.ModActorValue("Magicka", -(MyBaseMana - 1.0))
		MyBaseMana = 0.0
	endIf
endFunction

Function DidChangeToWerewolf(Actor playerRef)
	; v2.25 - do nothing - will check for "Growl" and init MyBaseMana after delay on first meter display
endFunction

Function DidChangeFromWerewolf(Actor playerRef)
	CheckRestoreMagickaScale(playerRef)
endFunction

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
	; do not reset StartAltMagTotalVal here--may load into werewolf
	
	Form growlForm = IsPluginActive(0x04014C1A, "Growl - Werebeasts of Skyrim.esp")
	if (growlForm != None)
		GrowlModInstalled = true
	else
		GrowlModInstalled = false
	endIf
endFunction

Form Function IsPluginActive(int formID, string pluginName)
	; from CreationKit.com: "Note the top most byte in the given ID is unused so 0000ABCD works as well as 0400ABCD"	
	Form formFound = Game.GetFormFromFile(formID, pluginName)
	if (formFound)
		Debug.Trace("[DTWW] found plugin: " + pluginName)
		return formFound 
	endIf
	return None
EndFunction
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
					if (playerLastKnownShiftTime == 0)
						; initial shift - setup for meter
						if (playerShiftTime > lunarShiftLimit)
							; lunar transformation adjustment
							playerShiftTime = GetLunarTransformEndTime(currenTime)
							;Debug.Notification("DTWW - set Lunar transform time: " + playerShiftTime)
						endIf
						
						CheckInitMagickaScale(playerActorRef)		; v2.25 - added--check before storing
						
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

	bool result = true
	StartAltMagTotalVal = -3.0
	
	if (playActor != None)
		if (!playActor.HasSpell(DTWW_WolfMeterToggleSpell))
			playActor.AddSpell(DTWW_WolfMeterToggleSpell)
		endIf
		DTWW_Initialized.SetValueInt(1)
		
		; v2.26 - optional initialized value
		int initVal = -1
		if (DTWW_InitialPrefVal != None)
			initVal = DTWW_InitialPrefVal.GetValueInt()
		endIf
		if (initVal >= 0)
			DTWW_Enabled.SetValueInt(initVal)
			if (initVal == 0)
				result = false				; initialized to disabled
			endIf
		else
			DTWW_Enabled.SetValueInt(1)
		endIf
	endIf
	
	return result
endFunction

bool Function RestoreMagickaAndGlobals(Actor playerActorRef)
	
	bool spellRemoved = true
	MeterDisplayed = false
	
	if playerActorRef.HasSpell(DTWW_WerwolfMeterSpell)
		spellRemoved = playerActorRef.RemoveSpell(DTWW_WerwolfMeterSpell)
	endIf
	
	if spellRemoved
	
		DTWW_PlayerLastKnownShiftBackTime.SetValue(0.0)
		float origMagicka = DTWW_PlayerOrigMagicka.GetValue()

		if origMagicka <= 5.0
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
	
	StartAltMagTotalVal = -2.0								; reset
	
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

float StartAltMagTotalVal = -1.0			; save the first calc here, reset when done

float Function GetMaxMagickaActorValue(Actor starget)

	float currentVal = starget.GetActorValue("Magicka")
	if currentVal <= 0.0
		; base not including buffs
		return starget.GetBaseActorValue("Magicka")
	endIf
	
	float valPerc = starget.GetActorValuePercentage("Magicka")
	
	; v2.25 - check if growl and scaling on
	bool growlOn = false
	if (GrowlModInstalled && DTWW_Enabled.GetValueInt() <= 2 && MyBaseMana > 0.0)
		growlOn = true
	endIf
	
	if (valPerc >= 2.0 && valPerc == currentVal && !growlOn)
		; error when scale magicka too low - use initial currentVal as start
		if (StartAltMagTotalVal < 0.0)
			; just set to current val as the starting point
			
			StartAltMagTotalVal = currentVal
		endIf
		
		return StartAltMagTotalVal
	endIf

	; max including buffs, but not modifications
	float maxVal = Math.Ceiling(currentVal / valPerc)
	
	if (valPerc > 1.0 && valPerc <= 1.1)
		; v2.25 - start with higher value. Fuller bar to start, but will drop lower on next update
		maxVal = Math.Floor(maxVal * valPerc)
	endIf
	
	return maxVal
endFunction

;
; v2.26 moved into this function for multiple uses
;
Function ShowPreferenceMessage()					
	int prefVal = DTWW_Enabled.GetValueInt()
	
	if (prefVal >= 2)
		; v2.25 - growl may be installed with scaling on or off
		if (prefVal == 2)
			if (GrowlModInstalled)
				; scaling on
				DTWW_EnableMeterUneqMessage.Show(1)
			else
				DTWW_EnableMeterUneqMessage.Show(0)
			endIf
		else
			; 3+ no scaling
			DTWW_EnableMeterUneqMessage.Show(2)
		endIf
	elseIf (prefVal > 0)
		DTWW_EnableMeterMessage.Show()
	endIf
endFunction