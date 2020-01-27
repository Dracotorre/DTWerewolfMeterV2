Scriptname DTWerewolfModQuestScript extends Quest

ReferenceAlias property DTWWPlayerAliasScriptP auto

Event OnLoad()
	self.OnInit()
endEvent

Event OnInit()
	RegisterForSingleUpdate(72.0)
endEvent

Event OnUpdate()
	UnregisterForUpdate()
	Debug.Trace(self + " Initialize")
	if (Game.IsFightingControlsEnabled())
		(DTWWPlayerAliasScriptP as DTWWPlayerAliasScript).MaintainMod()
	endIf
	
endEvent
