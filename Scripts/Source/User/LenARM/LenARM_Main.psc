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
; proxy scripts
; Group Proxy
	;TODO add proxy for devious devices
; EndGroup


;-----------------------------------------------------------------------------------------------------
; this mod's resources
Group LenARM
	LenARM_Debug Property D Auto Const
	LenARM_Util Property Util Auto Const
	LenARM_SliderSet Property SliderSet Auto Const
EndGroup


;-----------------------------------------------------------------------------------------------------
; enums
Group EnumTimerId
	int Property ETimerMorph = 1 Auto Const
	{timer for applying morphs}
EndGroup

Group EnumUpdateType
	int Property EUpdateTypePeriodic = 1 Auto Const
	{update each time the morph timer is up}
	int Property EUpdateTypeOnSleep = 2 Auto Const
	{update after sleeping}
EndGroup


;-----------------------------------------------------------------------------------------------------
; variables

bool IsShuttingDown = false
{TRUE while the mod is stopping.}

float UpdateDelay
{seconds between applying morphs}

int UpdateType
{when to apply morphs; see EnumUpdateType}


;-----------------------------------------------------------------------------------------------------
; custom events

CustomEvent OnStartup
CustomEvent OnShutdown
CustomEvent OnMorphChange


;-----------------------------------------------------------------------------------------------------
; versioning

string Version
{version the mod was last run with}

;
; For some reason doc comments from the first function after variable declarations are not picked up.
;
Function DummyFunction()
EndFunction

;
; Get the current version of this mod.
;
string Function GetVersion()
	return "1.0.1"; Fri Apr 08 09:58:24 CEST 2022
EndFunction




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; event listeners


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

Event OnPlayerSleepStop(bool abInterrupted, ObjectReference akBed)
	D.Log("OnPlayerSleepStop: abInterrupted=" + abInterrupted + ";  akBed=" + akBed)
	ApplySleepMorphs()
EndEvent


Event OnTimer(int timerId)
	If (timerId == ETimerMorph)
		ApplyIntervalMorphs()
	EndIf
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
		; mod is enabled in MCM: start setting everything up
		D.Log("  is enabled")
		
		; get update type from MCM
		UpdateType = MCM.GetModSettingInt("LenA_RadMorphing", "iUpdateType:General")
		
		; get update delay from MCM
		UpdateDelay = MCM.GetModSettingFloat("LenA_RadMorphing", "fUpdateDelay:General")

		; load slider sets
		SliderSet.LoadSliderSets(MCM.GetModSettingInt("LenA_RadMorphing", "iNumberOfSliderSets"), Player)

		;TODO get global overrides from MCM
		;TODO listen for item equip
		;TODO listen for combat state (helper script/quest?)
		;TODO prepare companion arrays
		;TODO reapply base morphs (additive morphing)
		
		If (UpdateType == EUpdateTypePeriodic)
			; start timer
			ApplyIntervalMorphs()
		ElseIf (UpdateType == EUpdateTypeOnSleep)
			; listen for sleep events
			RegisterForPlayerSleep()
		Else
			; unknown update type
			D.Log("unknown update type: '" + UpdateType + "'")
		EndIf

		SendCustomEvent("OnStartup")
	ElseIf (MCM.GetModSettingBool("LenA_RadMorphing", "bWarnDisabled:General"))
		; mod is disabled in MCM, warning is enabled: let the player know that the mod is disabled
		D.Log("  is disabled, with warning")
		Debug.MessageBox("Rad Morphing is currently disabled. You can enable it in MCM > Rad Morphing > Enable Rad Morphing")
	Else
		; mod is disabled in MCM, warning is disabled
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
		UnregisterForPlayerSleep()
		FinishShutdown()

		SendCustomEvent("OnShutdown")
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
	D.Log("Restart")
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
		If (Util.StringStartsWith(Version, "1.") || Util.StringStartsWith(Version, "0."))
			Debug.MessageBox("Rad Morphing Redux version " + Version + " is too old to update. Please load a save with the old version removed or start a new game.")
			return
		EndIf
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




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; mod logic

;
; Applies morphs at regular intervals.
; This is used when UpdateType is set to EUpdateTypePeriodic
;
Function ApplyIntervalMorphs()
	D.Log("ApplyIntervalMorphs")
	;TODO loop through slider sets, check trigger values, apply morphing...
	If (!IsShuttingDown)
		; restart the timer if not shutting down
		StartTimer(UpdateDelay, ETimerMorph)
	EndIf
EndFunction


;
; Applies morphs after sleeping.
; This is used when UpdateType is set to EUpdateTypeOnSleep
;
Function ApplySleepMorphs()
	D.Log("ApplySleepMorphs")
	;TODO loop through slider sets, check trigger values, apply morphing...
EndFunction