scriptName DTWerewolfWatchToggle extends ActiveMagicEffect

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Werewolf Time Meter toggle
; Author: DracoTorre
; Version: 2.0
; Source: http://www.nexusmods.com/skyrimspecialedition/mods/8389/?
; Homepage: http://www.dracotorre.com/mods/werewolfmeter/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GlobalVariable property DTWW_Enabled auto
Quest property DTWerewolfWatch_quest auto
Message property DTWW_DisableSoonMeterMessage auto 		; not used / deprecated

Event OnEffectStart(Actor akTarget, Actor akCaster)
	;Debug.Notification("DTWW - Toggle")
	actor playerActorRef = Game.GetPlayer()
	if (akCaster == playerActorRef)
		ToggleWWMeter()
	endif
EndEvent

Function ToggleWWMeter()
	int toggleVal = DTWW_Enabled.GetValueInt()
	if (toggleVal >= 2)
		DTWW_Enabled.SetValueInt(0)

		(DTWerewolfWatch_quest as DTWerewolfWatch).UnRegister()
	elseIf (toggleVal == 1)
		DTWW_Enabled.SetValueInt(2)
		(DTWerewolfWatch_quest as DTWerewolfWatch).Register()
	else
		DTWW_Enabled.SetValueInt(1)
		(DTWerewolfWatch_quest as DTWerewolfWatch).Register()
	endif
endFunction