Scriptname LenARM:LenARM_API extends Quest
{API script for other mods to communicate with Rad Morphing Redux}


;-----------------------------------------------------------------------------------------------------
; this mod's resources
Group LenARM
	LenARM_Debug Property D Auto Const
	LenARM_Util Property Util Auto Const
	LenARM_Main Property Main Auto Const
	LenARM_Proxy_AAF Property AAF Auto Const
EndGroup


;-----------------------------------------------------------------------------------------------------
; custom events

CustomEvent OnStartup
CustomEvent OnShutdown
CustomEvent OnRequestTriggers
CustomEvent OnMorphChange
CustomEvent OnTriggerAdd
CustomEvent OnTriggerRemove
CustomEvent OnTriggerUpdate
CustomEvent OnAAFBodyDouble




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; events


;-----------------------------------------------------------------------------------------------------
; game events

Event OnQuestInit()
	RegisterForCustomEvent(Main, "OnStartup")
	RegisterForCustomEvent(Main, "OnShutdown")
	RegisterForCustomEvent(Main, "OnRequestTriggers")
	RegisterForCustomEvent(Main, "OnMorphChange")
EndEvent

Event OnQuestShutdown()
	UnregisterForCustomEvent(Main, "OnStartup")
	UnregisterForCustomEvent(Main, "OnShutdown")
	UnregisterForCustomEvent(Main, "OnRequestTriggers")
	UnregisterForCustomEvent(Main, "OnMorphChange")
EndEvent


;-----------------------------------------------------------------------------------------------------
; this mod's events

Event LenARM:LenARM_Main.OnStartup(LenARM:LenARM_Main sender, Var[] args)
	Startup()
EndEvent

Event LenARM:LenARM_Main.OnShutdown(LenARM:LenARM_Main sender, Var[] args)
	Shutdown()
EndEvent

Event LenARM:LenARM_Main.OnRequestTriggers(LenARM:LenARM_Main akSender, Var[] akArgs)
	D.Log("API.OnRequestTriggers")
	SendCustomEvent("OnRequestTriggers")
EndEvent

Event LenARM:LenARM_Main.OnMorphChange(LenARM:LenARM_Main sender, Var[] args)
	D.Log("API.OnMorphChange: " + args)
	SendCustomEvent("OnMorphChange", args)
EndEvent


Event LenARM:LenARM_Proxy_AAF.OnBodyDouble(LenARM:LenARM_Proxy_AAF akSender, Var[] args)
	D.Log("API.OnBodyDouble: " + args)
	SendCustomEvent("OnAAFBodyDouble", args)
EndEvent




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; startup and shutdown

Function Startup()
	SendCustomEvent("OnStartup")
	RegisterForCustomEvent(AAF, "OnBodyDouble")
EndFunction

Function Shutdown()
	SendCustomEvent("OnShutdown")
	UnregisterForCustomEvent(AAF, "OnBodyDouble")
EndFunction




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; API functions

;
; For some reason doc comments from the first function after variable declarations are not picked up.
;
Function DummyFunction()
EndFunction


;
; Get the overall progress of morphs.
; Returns total morph percentage (0.0 - 1.0).
;
; @returns float The current total morph progress across all slider sets.
;
float Function GetMorphProgress()
	D.Log("API.GetMorphProgress")
	return Main.GetMorphPercentage()
EndFunction

;
; Get the overall progress of morphs for a specific trigger.
; Returns total morph percentage (0.0 - 1.0).
;
; @param string triggerName Name of the trigger.
; @param bool inverted Whether to check only for slider sets that invert the trigger value or only for slider sets that don't invert the trigger value.
; @returns float The current total morph progress for that trigger, relative to the minimum lower threshold and maximum upper threshold for all relevant slider sets.
;
float Function GetMorphProgressForTrigger(string triggerName, bool inverted)
	D.Log("API.GetMorphProgressForTrigger: " + triggerName + ", inverted=" + inverted)
	return Main.GetMorphPercentageForTrigger(triggerName, inverted)
EndFunction


;
; Register a trigger name with RMR.
; Returns false if the name is already registered, otherwise true.
;
; @param string triggerName The name to be used.
; @returns bool False if the name is already registered, otherwise true.
;
bool Function RegisterTrigger(string triggerName)
	D.Log("API.RegisterTrigger: " + triggerName)
	bool isRegistered = Main.AddTriggerName(triggerName)
	If (isRegistered)
		Var[] eventArgs = new Var[1]
		eventArgs[0] = triggerName
		SendCustomEvent("OnTriggerAdd", eventArgs)
	EndIf
	return isRegistered
EndFunction

;
; Unregister a trigger name from RMR.
;
; @param triggerName string Name of the trigger.
;
Function UnregisterTrigger(string triggerName)
	D.Log("API.UnregisterTrigger: " + triggerName)
	Main.RemoveTriggerName(triggerName)
	
	Var[] eventArgs = new Var[1]
	eventArgs[0] = triggerName
	SendCustomEvent("OnTriggerRemove", eventArgs)
EndFunction


;
; Update the value of a morph trigger.
;
; @param triggerName Name of the trigger to update.
; @param value New trigger value.
;
Function UpdateTrigger(string triggerName, float value)
	D.Log("API.UpdateTrigger: " + triggerName + " = " + value)
	float actualValue = Main.SetTriggerValue(triggerName, value)
	
	Var[] eventArgs = new Var[2]
	eventArgs[0] = triggerName
	eventArgs[1] = actualValue
	SendCustomEvent("OnTriggerUpdate", eventArgs)
EndFunction


;
; Returns true if RMR is currently active / running.
;
; @returns bool True if RMR is active, otherwise false.
;
bool Function IsRunning()
	return Main.GetIsRunning()
EndFunction


;
; Get the list of trigger names that are registered with RMR.
;
; @returns string[] Array containing all the currently registered trigger names.
;
string[] Function GetRegisteredTriggerNames()
	return Main.GetTriggerNames()
EndFunction


;
; Get the list of trigger names that are used by SliderSets.
;
; @returns string[] Array containing all the trigger names currently used in at least one slider set.
;
string[] Function GetUsedTriggerNames()
	return Main.GetUsedTriggerNames()
EndFunction