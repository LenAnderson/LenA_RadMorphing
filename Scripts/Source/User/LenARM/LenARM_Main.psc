Scriptname LenARM:LenARM_Main extends Quest
{Main quest script.}


;-----------------------------------------------------------------------------------------------------
; general properties
Group Properties
	Actor Property Player Auto Const
	{reference to the player}

	Keyword Property kwMorph Auto Const
	{keyword required for looksmenu morphing}

	Scene Property DoctorGreetScene Auto Const
	Scene Property DoctorMedicineScene02_Exam Auto Const

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

Group MessageBoxes
	Message Property HealMorphMessage Auto Const
EndGroup

Group LenARM
	LenARM_Debug Property D Auto Const
	LenARM_Util Property Util Auto Const
	LenARM_SliderSet Property SliderSets Auto Const
EndGroup

Group MCM
	string[] Property MCM_TriggerNames Auto
EndGroup


;-----------------------------------------------------------------------------------------------------
; enums
Group EnumTimerId
	int Property ETimerMorph = 1 Auto Const
	{timer for applying morphs}
	int Property ETimerShutdownRestoreMorphs = 2 Auto Const
	{timer for restoring original morphs on shutdown}
EndGroup

Group EnumSex
	int Property ESexNone = -1 Auto Const
	int Property ESexMale = 0 Auto Const
	int Property ESexFemale = 1 Auto Const
EndGroup

Group EnumHealMorphChoice
	int Property EHealMorphChoiceYes = 0 Auto Const
	int Property EHealMorphChoiceNo = 1 Auto Const
EndGroup


;-----------------------------------------------------------------------------------------------------
; variables

; TRUE while the mod is stopping.
bool IsShuttingDown = false

int RestartStackSize = 0

; seconds between applying morphs
float UpdateDelay

; when to apply morphs; see EnumUpdateType
int UpdateType

; how many slider sets are available
int NumberOfSliderSets

; whether the heal morph message box has just been shown
bool HealMorphMessageShown = false


;-----------------------------------------------------------------------------------------------------
; custom events

CustomEvent OnStartup
CustomEvent OnShutdown
CustomEvent OnMorphChange


;-----------------------------------------------------------------------------------------------------
; versioning

; version the mod was last run with
string Version

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
	RegisterForRemoteEvent(Player, "OnPlayerLoadGame")
	Startup()
EndEvent

Event OnQuestShutdown()
	D.Log("OnQuestShutdown")
	UnregisterForExternalEvent("OnMCMSettingChange|LenA_RadMorphing")
	UnregisterForRemoteEvent(Player, "OnPlayerLoadGame")
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


Event Scene.OnBegin(Scene akSender)
	D.Log("Scene.OnBegin: " + akSender)
	If (akSender == DoctorGreetScene)
		D.Log("  DoctorGreetScene --> setting HealMorphMessageShown to false")
		HealMorphMessageShown = false
	ElseIf (!HealMorphMessageShown && akSender == DoctorMedicineScene02_Exam)
		D.Log("  DoctorMedicineScene02_Exam --> setting HealMorphMessageShown to true")
		HealMorphMessageShown = true
		float baseMorphs = GetBaseMorphPercentage() * 100.0
		float morphs = GetMorphPercentage() * 100.0
		float cost = baseMorphs * 10.0
		D.Log("    morphs:     " + morphs + "%")
		D.Log("    baseMorphs: " + baseMorphs + "%")
		D.Log("    cost:       " + cost + " caps")
		int choice = HealMorphMessage.Show(morphs, baseMorphs, cost)
		D.Log("    choice: " + choice)
		If (choice == EHealMorphChoiceYes)
			D.Log("      -> heal morphs")
		ElseIf (choice == EHealMorphChoiceNo)
			D.Log("      -> don't heal morphs")
		Else
			D.Log("      -> unknown choice")
		EndIf
	EndIf
EndEvent


Event OnTimer(int timerId)
	If (timerId == ETimerMorph)
		ApplyPeriodicMorphs()
	ElseIf (timerId == ETimerShutdownRestoreMorphs)
		ShutdownRestoreMorphs()
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
	If (Util.StringStartsWith(id, "iTriggerNameIndex:Slider"))
		string sliderName = Util.StringSplit(id, ":")[1]
		int idxTriggerName = MCM.GetModSettingInt("LenA_RadMorphing", id)
		string triggerName = MCM_TriggerNames[idxTriggerName]
		D.Log("  " + idxTriggerName + " --> " + triggerName)
		D.Log("  setting MCM: " + "sTriggerName:" + sliderName + " -> " + triggerName)
		MCM.SetModSettingString("LenA_RadMorphing", "sTriggerName:" + sliderName, triggerName)
		D.Log("    check MCM: " + MCM.GetModSettingString("LenA_RadMorphing", "sTriggerName:" + sliderName))
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
	If (MCM.GetModSettingBool("LenA_RadMorphing", "bIsEnabled:General"))
		; mod is enabled in MCM: start setting everything up
		D.Log("  is enabled")
		
		; get update delay from MCM
		UpdateDelay = MCM.GetModSettingFloat("LenA_RadMorphing", "fUpdateDelay:General")

		; get number of available SliderSets
		NumberOfSliderSets = MCM.GetModSettingInt("LenA_RadMorphing", "iNumberOfSliderSets:Static")

		; load SliderSets
		SliderSets.LoadSliderSets(NumberOfSliderSets, Player)

		;TODO listen for item equip
		
		;TODO listen for combat state (helper script/quest?)
		
		;TODO prepare companion arrays --> handled in SliderSet

		; listen for doctor scenes
		RegisterForRemoteEvent(DoctorGreetScene, "OnBegin")
		RegisterForRemoteEvent(DoctorMedicineScene02_Exam, "OnBegin")

		; reapply base morphs (additive morphing)
		ApplyBaseMorphs()
		
		; start timer for periodic updates
		ApplyPeriodicMorphs()
		; listen for sleep events, for on sleep updates
		RegisterForPlayerSleep()

		; set up trigger names for MCM
		MCM_TriggerNames = new string[0]
		MCM_TriggerNames.Add("-- SELECT A TRIGGER --")
		int idxSliderSet = 0
		While (idxSliderSet < NumberOfSliderSets)
			MCM.SetModSettingInt("LenA_RadMorphing", "iTriggerNameIndex:Slider" + idxSliderSet, 0)
			idxSliderSet += 1
		EndWhile

		; notify plugins that mod is running
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
Function Shutdown(bool withRestoreMorphs=true)
	If (!IsShuttingDown)
		D.Log("Shutdown")
		IsShuttingDown = true

		; notify plugins that mod has stopped
		SendCustomEvent("OnShutdown")

		; stop listening for sleep events
		UnregisterForPlayerSleep()

		; stop timer
		CancelTimer(ETimerMorph)

		;TODO stop listening for equipping items
		
		;TODO stop listening for doctor scenes

		;TODO stop listening for combat state

		If (withRestoreMorphs)
			StartTimer(Math.Max(UpdateDelay + 0.5, 2.0), ETimerShutdownRestoreMorphs)
		Else
			FinishShutdown()
		EndIf
	EndIf
EndFunction

Function ShutdownRestoreMorphs()
	D.Log("ShutdownRestoreMorphs")
	RestoreOriginalMorphs()
	FinishShutdown()
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
	RestartStackSize += 1
	Utility.Wait(1.0)
	If (RestartStackSize <= 1)
		D.Log("Restart")
		Shutdown()
		While (IsShuttingDown)
			Utility.Wait(1.0)
		EndWhile
		Startup()
		D.Log("Restart completed")
	Else
		D.Log("RestartStackSize: " + RestartStackSize)
	EndIf
	RestartStackSize -= 1
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
; Register a trigger name with RMR.
; Returns false if the name is already registered, otherwise true.
;
bool Function AddTriggerName(string triggerName)
	D.Log("AddTriggerName: " + triggerName)
	If (MCM_TriggerNames.Find(triggerName) < 0)
		MCM_TriggerNames.Add(triggerName)
		int triggerNameIndex = MCM_TriggerNames.Length - 1
		int idxSliderSet = 0
		While (idxSliderSet < NumberOfSliderSets)
			If (MCM.GetModSettingString("LenA_RadMorphing", "sTriggerName:Slider" + idxSliderSet) == triggerName)
				D.Log("  updating MCM for SliderSet " + idxSliderSet)
				MCM.SetModSettingInt("LenA_RadMorphing", "iTriggerNameIndex:Slider" + idxSliderSet, triggerNameIndex)
			EndIf
			idxSliderSet += 1
		EndWhile
		return true
	Else
		D.Log("  trigger already exists")
		return false
	EndIf
EndFunction


;
; Get the total (max) percentage of morphs (base + current) currently applied.
; Relative to lower and upper threshold.
; 
; When SliderSet.TargetMorph has been reached, morph percentage is 100% (=1.0).
; With additive morphing the value may go above 100%.
;
float Function GetMorphPercentage()
	D.Log("GetMorphPercentage")
	return SliderSets.GetMorphPercentage()
EndFunction

;
; Get the total (max) percentage of base morphs (permanent morphs) currently applied.
; Relative to lower and upper threshold.
;
float Function GetBaseMorphPercentage()
	D.Log("GetBaseMorphPercentage")
	return SliderSets.GetBaseMorphPercentage()
EndFunction


;
; Update the value of a morph trigger.
;
Function SetTriggerValue(string triggerName, float value)
	D.Log("SetTriggerValue: " + triggerName + " = " + value)
	SliderSets.SetTriggerValue(triggerName, value)
	ApplyImmediateMorphs()
EndFunction

;
; Apply morphs immediately when the trigger value changes.
; This is used when UpdateType is set to EUpdateTypeImmediate.
;
Function ApplyImmediateMorphs()
	D.Log("ApplyImmediateMorphs")
	LenARM_SliderSet:Slider[] updates = SliderSets.CalculateMorphUpdates(SliderSets.EUpdateTypeImmediate)
	D.Log(" updates: " + updates)

	ApplyMorphUpdates(updates)
EndFunction

;
; Apply morphs at regular intervals.
; This is used when UpdateType is set to EUpdateTypePeriodic.
;
Function ApplyPeriodicMorphs()
	D.Log("ApplyPeriodicMorphs")
	LenARM_SliderSet:Slider[] updates = SliderSets.CalculateMorphUpdates(SliderSets.EUpdateTypePeriodic)
	D.Log(" updates: " + updates)

	ApplyMorphUpdates(updates)

	If (!IsShuttingDown)
		; restart the timer if not shutting down
		StartTimer(UpdateDelay, ETimerMorph)
	EndIf
EndFunction


;
; Apply morphs after sleeping.
; This is used when UpdateType is set to EUpdateTypeOnSleep.
;
Function ApplySleepMorphs()
	D.Log("ApplySleepMorphs")
	LenARM_SliderSet:Slider[] updates = SliderSets.CalculateMorphUpdates(SliderSets.EUpdateTypeOnSleep)
	D.Log(" updates: " + updates)

	ApplyMorphUpdates(updates)
EndFunction


;
; Apply a list of morph updates (sliderName:newValue) through BodyGen.
;
Function ApplyMorphUpdates(LenARM_SliderSet:Slider[] updates)
	If (updates.Length > 0)
		D.Log("ApplyMorphUpdates: " + updates)
		int sex = Player.GetLeveledActorBase().GetSex()
		int idxUpdate = 0
		While (idxUpdate < updates.Length)
			LenARM_SliderSet:Slider update = updates[idxUpdate]
			BodyGen.SetMorph(Player, sex==ESexFemale, update.Name, kwMorph, update.Value)
			idxUpdate += 1
		EndWhile
		BodyGen.UpdateMorphs(Player)
		var[] eventArgs = new var[1]
		eventArgs[0] = GetMorphPercentage()
		SendCustomEvent("OnMorphChange", eventArgs)
	EndIf
EndFunction


;
; Apply base morphs (permanent morphs) through BodyGen.
;
Function ApplyBaseMorphs()
	D.Log("ApplyBaseMorphs")
	int sex = Player.GetLeveledActorBase().GetSex()
	LenARM_SliderSet:Slider[] baseMorphs = SliderSets.GetBaseMorphs()
	If (baseMorphs.Length > 0)
		int idxSlider = 0
		While (idxSlider < baseMorphs.Length)
			LenARM_SliderSet:Slider slider = baseMorphs[idxSlider]
			BodyGen.SetMorph(Player, sex==ESexFemale, slider.Name, kwMorph, slider.Value)
			idxSlider += 1
		EndWhile
		BodyGen.UpdateMorphs(Player)
	EndIf
EndFunction


;
; Restore the original (unmorphed) slider values through BodyGen.
;
Function RestoreOriginalMorphs()
	D.Log("RestoreOriginalMorphs")
	int sex = Player.GetLeveledActorBase().GetSex()
	LenARM_SliderSet:Slider[] sliders = SliderSets.GetSliders()
	int idxSlider = 0
	While (idxSlider < sliders.Length)
		LenARM_SliderSet:Slider slider = sliders[idxSlider]
		BodyGen.SetMorph(Player, sex==ESexFemale, slider.Name, kwMorph, slider.Value)
		idxSlider += 1
	EndWhile
	BodyGen.UpdateMorphs(Player)
EndFunction




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; helpers / MCM

;
; Show a message box with all the currently equipped items and their slots.
;
Function ShowEquippedClothes()
	D.Log("ShowEquippedClothes")
	string[] items = new string[0]
	int slot = 0
	While (slot < 62)
		Actor:WornItem item = Player.GetWornItem(slot)
		If (item != None && item.item != None)
			items.Add(slot + ": " + item.item.GetName())
			D.Log("  " + slot + ": " + item.item.GetName() + " (" + item.modelName + ")")
		Else
			D.Log("  Slot " + slot + " is empty")
		EndIf
		slot += 1
	EndWhile

	Debug.MessageBox(LL_FourPlay.StringJoin(items, "\n"))
EndFunction