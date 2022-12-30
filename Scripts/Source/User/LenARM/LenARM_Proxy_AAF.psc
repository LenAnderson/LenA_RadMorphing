Scriptname LenARM:LenARM_Proxy_AAF extends Quest
{Proxy for AAF}


;-----------------------------------------------------------------------------------------------------
; general properties
Group Properties
	Actor Property Player Auto Const
	{reference to the player}
EndGroup


;-----------------------------------------------------------------------------------------------------
; this mod's resources
Group LenARM
	LenARM_Debug Property D Auto Const
EndGroup


;-----------------------------------------------------------------------------------------------------
; variables

; AAF API
AAF:AAF_API AAF

; current body double (None if no player-scene active)
Actor BodyDouble

;
; For some reason doc comments from the first function after variable declarations are not picked up.
;
Function DummyFunction()
EndFunction


;-----------------------------------------------------------------------------------------------------
; custom events

CustomEvent OnBodyDouble




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; event listeners


;-----------------------------------------------------------------------------------------------------
; game events


Event Actor.OnItemEquipped(Actor akSender, Form akBaseObject, ObjectReference akReference)
	D.Log("AAF.OnItemEquipped: actor=" + akSender + ", object=" + akBaseObject)
EndEvent

Event Actor.OnItemUnequipped(Actor akSender, Form akBaseObject, ObjectReference akReference)
	D.Log("AAF.OnItemUnequipped: actor=" + akSender + ", object=" + akBaseObject)
EndEvent


;-----------------------------------------------------------------------------------------------------
; AAF events

Event AAF:AAF_API.OnSceneInit(AAF:AAF_API akSender, Var[] akArgs)
	D.Log("AAF.OnSceneInit")
	; check status (0 = all good)
	If (akArgs[0] as int != 0)
		D.Log("  scene start failed")
	Else
		D.Log("  scene started successfully")
		; check if player is involved and get the body double
		Actor aafBody = akArgs[2] as Actor
		If (!aafBody)
			D.Log("  player is not part of scene")
		Else
			D.Log("  player is part of scene, body double: " + aafBody)
			BodyDouble = aafBody
			Var[] args = new Var[1]
			args[0] = BodyDouble
			StartListeners(BodyDouble)
			SendCustomEvent("OnBodyDouble", args)
		EndIf
	EndIf
EndEvent

Event AAF:AAF_API.OnSceneEnd(AAF:AAF_API akSender, Var[] akArgs)
	D.Log("AAF.OnSceneEnd")
	; check status (0 = all good)
	If (akArgs[0] as int != 0)
		D.Log("  scene end failed")
	Else
		D.Log("  scene ended successfully")
		; check if player is involved
		Var[] actors = Utility.VarToVarArray(akArgs[1])
		bool involvesPlayer = false
		int idxActor = 0
		While (!involvesPlayer && idxActor < actors.Length)
			Actor item = actors[idxActor] as Actor
			If (item == Player)
				involvesPlayer = true
			EndIf
			idxActor += 1
		EndWhile
		If (!involvesPlayer)
			D.Log("  player is not part of scene")
		Else
			D.Log("  player is part of scene, unsetting body double")
			StopListeners(BodyDouble)
			BodyDouble = None
			SendCustomEvent("OnBodyDouble", None)
		EndIf
	EndIf
EndEvent



Function StartListeners(Actor target)
	RegisterForRemoteEvent(target, "OnItemEquipped")
	RegisterForRemoteEvent(target, "OnItemUnequipped")
EndFunction

Function StopListeners(Actor target)
	UnregisterForRemoteEvent(target, "OnItemEquipped")
	UnregisterForRemoteEvent(target, "OnItemUnequipped")
EndFunction




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; getters / setters

;
; Get the body double from the current player-involved AAF scene.
;
; @returns Actor The current body-double, None if no player-involved scene is running.
Actor Function GetBodyDouble()
	return BodyDouble
EndFunction




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; proxy functions

;
; Try to get AAF API
;
Function LoadAAF()
	D.Log("AAF.LoadAAF")
	AAF = Game.GetFormFromFile(0x00000F99, "AAF.esm") as AAF:AAF_API
	If !AAF
		D.Log("  AAF not found")
	Else
		D.Log("  AAF found")
		RegisterForCustomEvent(AAF, "OnSceneInit")
		RegisterForCustomEvent(AAF, "OnSceneEnd")
		StartListeners(Player)
	Endif
EndFunction

Function UnloadAAF()
	D.Log("AAF.UnloadAAF")
	If (AAF)
		UnregisterForCustomEvent(AAF, "OnSceneInit")
		UnregisterForCustomEvent(AAF, "OnSceneEnd")
		AAF = None
		StopListeners(Player)
	EndIf
EndFunction