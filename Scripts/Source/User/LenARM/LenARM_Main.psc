Scriptname LenARM:LenARM_Main extends Quest
{Main quest script.}


;-----------------------------------------------------------------------------------------------------
; general properties
Group Properties
	Actor Property Player Auto Const
	{reference to the player}

	Keyword Property kwMorph Auto Const
	{keyword required for looksmenu morphing}

	Faction Property CurrentCompanionFaction Auto Const
	{one of the factions used to find companions}
	Faction Property PlayerAllyFaction Auto Const
	{one of the factions used to find companions}
EndGroup


;-----------------------------------------------------------------------------------------------------
; this mod's resources
Group LenARM
	LenARM_Debug Property D Auto Const
	LenARM_Util Property Util Auto Const
EndGroup


;-----------------------------------------------------------------------------------------------------
; enums


;-----------------------------------------------------------------------------------------------------
; variables

bool IsShuttingDown = false
{TRUE while the mod is stopping.}


;-----------------------------------------------------------------------------------------------------
; versioning

string Version
{version the mod was last run with}

;
; Get the current version of this mod.
;
string Function GetVersion()
	return "1.0.1"; Fri Apr 08 09:58:24 CEST 2022
EndFunction




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; events


;-----------------------------------------------------------------------------------------------------
; game events

Event OnQuestInit()
	D.Log("OnQuestInit")
	RegisterForExternalEvent("OnMCMSettingChange|LenA_RadMorphing", "OnMCMSettingChange")
	Startup()
EndEvent

Event OnQuestShutdown()
	D.Log("OnQuestShutdown")
	UnregisterForExternalEvent("OnMCMSettingChange|LenA_RadMorphing")
	Shutdown()
EndEvent


Event Actor.OnPlayerLoadGame(Actor akSender)
	D.Log("Actor.OnPlayerLoadGame: " + akSender)
	PerformUpdateIfNecessary()
EndEvent


;-----------------------------------------------------------------------------------------------------
; MCM events

Function OnMCMSettingChange(string modName, string id)
	D.Log("OnMCMSettingChange: " + modName + "; " + id)
	If (LL_Fourplay.StringSubstring(id, 0, 1) == "s")
		string value = MCM.GetModSettingString(modName, id)
		If (LL_Fourplay.StringSubstring(value, 0, 1) == " ")
			string msg = "The value you have just changed has leading whitespace:\n\n'" + value + "'"
			Debug.MessageBox(msg)
		EndIf
	EndIf
	Restart()
EndFunction




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; startup and shutdown

;
; Start the mod if enabled in MCM.
;
Function Startup()
	D.Log("Startup")
	RegisterForRemoteEvent(Player, "OnPlayerLoadGame")
	If (MCM.GetModSettingBool("LenA_RadMorphing", "bIsEnabled:General"))
		D.Log("  is enabled")
	ElseIf (MCM.GetModSettingBool("LenA_RadMorphing", "bWarnDisabled:General"))
		D.Log("  is disabled, with warning")
		Debug.MessageBox("Rad Morphing is currently disabled. You can enable it in MCM > Rad Morphing > Enable Rad Morphing")
	Else
		D.Log("  is disabled, no warning")
	EndIf
EndFunction


;
; Stop the mod.
;
Function Shutdown()
	If (!IsShuttingDown)
		D.Log("Shutdown")
		IsShuttingDown = true
		UnregisterForRemoteEvent(Player, "OnPlayerLoadGame")
		FinishShutdown()
	EndIf
EndFunction

;
; Finalize stopping the mod.
;
Function FinishShutdown()
	D.Log("FinishShutdown")
	IsShuttingDown = false
EndFunction


;
; Restart the mod.
;
Function Restart()
	Shutdown()
	While (IsShuttingDown)
		Utility.Wait(1.0)
	EndWhile
	Startup()
EndFunction


;
; check if a new version has been installed and restart the mod if necessary
;
Function PerformUpdateIfNecessary()
	D.Log("PerformUpdateIfNecessary: " + Version + " != " + GetVersion() + " -> " + (Version != GetVersion()))
	If (Version != GetVersion())
		D.Log("  update")
		D.Note("Updating Rad Morphing Redux from version " + Version + " to " + GetVersion())
		Shutdown()
		While (IsShuttingDown)
			Utility.Wait(1.0)
		EndWhile
		Startup()
		Version = GetVersion()
		D.Note("Rad Morphing Redux has been updated to version " + Version + ".")
	Else
		D.Log("  no update")
	EndIf
EndFunction