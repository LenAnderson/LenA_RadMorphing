Scriptname LenARM:LenARM_Main extends Quest
{Main quest script.}


;-----------------------------------------------------------------------------------------------------
; general properties
Group Properties
	Actor Property Player Auto Const
	{reference to the player}

	Keyword Property kwMorph Auto Const
	{keyword required for looksmenu morphing}

	Scene[] Property DoctorGreetScenes Auto Const
	{first part of a doctor dialogue scene: greeting
		- DoctorGreetScene
		- DLC03DialogueFarHarbor_TeddyWright
		- DialogueNucleusArchemist_GreetScene
		- DLC03AcadiaDialogueAsterDoctorIntro
		- DLC04SettlementDoctor_GreetScene
	}
	Scene[] Property DoctorExamScenes Auto Const
	{second part of a doctor dialogue scene: exam
		- DoctorMedicineScene02_Exam
		- DLC03DialogueFarHarbor_TeddyExam
		- DialogueNucleusArchemist_GreetScene02_Exam
		- DLC03AcadiaDialogueAsterExamScene
		- DLC04SettlementDoctor_ExamScene
	}

	FollowersScript Property Followers Auto Const
	{script for handling follower and companion systems}

	MiscObject Property Caps Auto Const
	{caps (currency)}
EndGroup


;-----------------------------------------------------------------------------------------------------
; proxy scripts
Group Proxy
	; proxy for devious devices
	LenARM_Proxy_DeviousDevices Property DD Auto Const
EndGroup


;-----------------------------------------------------------------------------------------------------
; this mod's resources

Group MessageBoxes
	Message Property HealMorphMessage Auto Const
EndGroup

Group Sounds
	Sound Property LenARM_DropClothesSound Auto Const
EndGroup

Group LenARM
	LenARM_Debug Property D Auto Const
	LenARM_Util Property Util Auto Const
	LenARM_SliderSet Property SliderSets Auto Const
EndGroup

Group MCM
	string[] Property MCM_TriggerNames Auto
EndGroup
string[] Function GetTriggerNames()
	return MCM_TriggerNames
EndFunction


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

; TRUE while the mod is starting up
bool IsStartingUp = true

; TRUE while the mod is active.
bool IsRunning = false

int RestartStackSize = 0

int UnequipStackSize = 0

; how many slider sets are available
int NumberOfSliderSets

; whether the heal morph message box has just been shown
bool HealMorphMessageShown = false

; list of current companions
Actor[] CompanionList


; MCM: seconds between applying morphs
float UpdateDelay

; MCM: whether to restore companions on dismiss
bool RestoreCompanionsOnDismiss

; MCM: cost to heal morphs
int HealCost

; last time the MCM settings were read
string SettingsTimeStamp


;-----------------------------------------------------------------------------------------------------
; custom events

CustomEvent OnStartup
CustomEvent OnShutdown
CustomEvent OnRequestTriggers
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
	return "2.2.1"; Wed Dec 21 14:55:38 CET 2022
EndFunction




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; event listeners


;-----------------------------------------------------------------------------------------------------
; game events

Event OnQuestInit()
	D.Log("OnQuestInit")
	RegisterForExternalEvent("OnMCMSettingChange|RadMorphingRedux", "OnMCMSettingChange")
	RegisterForRemoteEvent(Player, "OnPlayerLoadGame")
	Startup()
EndEvent

Event OnQuestShutdown()
	D.Log("OnQuestShutdown")
	UnregisterForExternalEvent("OnMCMSettingChange|RadMorphingRedux")
	UnregisterForRemoteEvent(Player, "OnPlayerLoadGame")
	Shutdown()
EndEvent


Event Actor.OnPlayerLoadGame(Actor akSender)
	D.Log("Actor.OnPlayerLoadGame: " + akSender)
	If (!PerformUpdateIfNecessary())
		string timeStamp = MCM.GetModSettingString("RadMorphingRedux", "sModified:Internal")
		D.Log("timestamp in MCM:   " + timeStamp)
		D.Log("timestamp savegame: " + SettingsTimeStamp)
		If (timeStamp != SettingsTimeStamp)
			D.Log("MCM settings have been changed --> restart")
			D.Note("Reloading MCM settings")
			Restart()
		Else
			MCM_TriggerNames = new string[0]
			SendCustomEvent("OnRequestTriggers", new Var[0])
			DD.LoadDD()
		EndIf
	EndIf
EndEvent

Event Actor.OnItemEquipped(Actor akSender, Form akBaseObject, ObjectReference akReference)
	D.Log("Actor.OnItemEquipped: akSender=" + akSender + "  akBaseObject=" + akBaseObject + "  akReference=" + akReference)
	UnequipSlots()
EndEvent

Event OnPlayerSleepStop(bool abInterrupted, ObjectReference akBed)
	D.Log("OnPlayerSleepStop: abInterrupted=" + abInterrupted + ";  akBed=" + akBed)
	ApplySleepMorphs()
EndEvent


Event Scene.OnBegin(Scene theScene)
	D.Log("Scene.OnBegin: " + theScene)
	If (DoctorGreetScenes.Find(theScene) > -1)
		D.Log("  DoctorGreetScene --> setting HealMorphMessageShown to false")
		HealMorphMessageShown = false
	ElseIf (SliderSets.HasDoctorOnly() && !HealMorphMessageShown && DoctorExamScenes.Find(theScene) > -1)
		D.Log("  DoctorMedicineScene02_Exam --> setting HealMorphMessageShown to true")
		HealMorphMessageShown = true
		ShowHealMorphDialog()
	EndIf
EndEvent


Event FollowersScript.CompanionChange(FollowersScript akSender, Var[] eventArgs)
	Actor companion = eventArgs[0] as Actor
	bool isNowCompanion = eventArgs[1] as bool
	D.Log("FollowersScript.CompanionChange: " + companion.GetLeveledActorBase().GetName() + "(" + companion + ")  -->  " + isNowCompanion)
	If (isNowCompanion)
		If (CompanionList == None)
			CompanionList = new Actor[0]
		EndIf
		CompanionList.Add(companion)
		RegisterForRemoteEvent(companion, "OnItemEquipped")
		LenARM_SliderSet:CumulativeMorphUpdate[] updates = SliderSets.GetFullMorphs()
		RestoreOriginalMorphs(companion)
		ApplyMorphUpdates(updates)
	Else
		int idxCompanion = CompanionList.Find(companion)
		CompanionList.Remove(idxCompanion)
		UnregisterForRemoteEvent(companion, "OnItemEquipped")
		If (RestoreCompanionsOnDismiss)
			RestoreOriginalMorphs(companion)
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
		int idxTriggerName = MCM.GetModSettingInt("RadMorphingRedux", id)
		string triggerName = MCM_TriggerNames[idxTriggerName]
		D.Log("  " + idxTriggerName + " --> " + triggerName)
		D.Log("  setting MCM: " + "sTriggerName:" + sliderName + " -> " + triggerName)
		MCM.SetModSettingString("RadMorphingRedux", "sTriggerName:" + sliderName, triggerName)
		D.Log("    check MCM: " + MCM.GetModSettingString("RadMorphingRedux", "sTriggerName:" + sliderName))
	EndIf
	MCM.SetModSettingString("RadMorphingRedux", "sModified:Internal", SUP_F4SE.GetUserTimeStamp())
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
	IsStartingUp = true
	If (MCM.GetModSettingBool("RadMorphingRedux", "bIsEnabled:General"))
		; mod is enabled in MCM: start setting everything up
		D.Log("  is enabled")
		
		; get number of available SliderSets
		NumberOfSliderSets = MCM.GetModSettingInt("RadMorphingRedux", "iNumberOfSliderSets:Static")
		
		; get update delay from MCM
		UpdateDelay = MCM.GetModSettingFloat("RadMorphingRedux", "fUpdateDelay:General")

		; get whether to restore companions on dismiss from MCM
		RestoreCompanionsOnDismiss = MCM.GetModSettingBool("RadMorphingRedux", "bRestoreCompanionsOnDismiss:General")

		; get heal cost from MCM
		HealCost = MCM.GetModSettingInt("RadMorphingRedux", "iHealCost:General")

		; get timestamp from MCM
		SettingsTimeStamp = MCM.GetModSettingString("RadMorphingRedux", "sModified:Internal")

		; load SliderSets
		SliderSets.LoadSliderSets(NumberOfSliderSets, Player)

		; start proxy for Devious Devices
		DD.LoadDD()

		; listen for item equip
		RegisterForRemoteEvent(Player, "OnItemEquipped")
		int idxCompanion = 0
		While (idxCompanion < CompanionList.Length)
			Actor companion = CompanionList[idxCompanion]
			RegisterForRemoteEvent(companion, "OnItemEquipped")
			idxCompanion += 1
		EndWhile

		; listen for doctor scenes
		int idxDoctorGreetScene = 0
		While (idxDoctorGreetScene < DoctorGreetScenes.Length)
			Scene greetScene = DoctorGreetScenes[idxDoctorGreetScene]
			RegisterForRemoteEvent(greetScene, "OnBegin")
			idxDoctorGreetScene += 1
		EndWhile
		int idxDoctorExamScene = 0
		While (idxDoctorExamScene < DoctorExamScenes.Length)
			Scene examScene = DoctorExamScenes[idxDoctorExamScene]
			RegisterForRemoteEvent(examScene, "OnBegin")
			idxDoctorExamScene += 1
		EndWhile

		; listen for companion changes
		RegisterForCustomEvent(Followers, "CompanionChange")

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
			MCM.SetModSettingInt("RadMorphingRedux", "iTriggerNameIndex:Slider" + idxSliderSet, 0)
			idxSliderSet += 1
		EndWhile
		SendCustomEvent("OnRequestTriggers", new Var[0])

		; get debug setting from MCM
		bool enableLogging = MCM.GetModSettingBool("RadMorphingRedux", "bIsLoggingEnabled:Debug")
		D.SetIsLoggingEnabled(enableLogging)

		; notify plugins that mod is running
		IsRunning = true
		SendCustomEvent("OnStartup")

		D.Log("Startup complete", true)
		If (enableLogging)
			D.Log("logging is enabled", true)
		Else
			D.Log("logging is disabled", true)
		EndIf
	Else
		If (MCM.GetModSettingBool("RadMorphingRedux", "bWarnDisabled:General"))
			; mod is disabled in MCM, warning is enabled: let the player know that the mod is disabled
			D.Log("  is disabled, with warning")
			Debug.MessageBox("Rad Morphing is currently disabled. You can enable it in MCM > Rad Morphing > Enable Rad Morphing")
		Else
			; mod is disabled in MCM, warning is disabled
			D.Log("  is disabled, no warning")
		EndIf

		; set up trigger names for MCM
		If (MCM_TriggerNames == none)
			MCM_TriggerNames = new string[0]
			MCM_TriggerNames.Add("-- SELECT A TRIGGER --")
			SendCustomEvent("OnRequestTriggers", new Var[0])
		EndIf
	EndIf

	IsStartingUp = false
EndFunction


;
; Stop the mod.
;
Function Shutdown(bool withRestoreMorphs=true)
	If (!IsShuttingDown)
		D.SetIsLoggingEnabled(true)
		D.Log("Shutdown")
		IsShuttingDown = true

		; notify plugins that mod has stopped
		IsRunning = false
		SendCustomEvent("OnShutdown")

		; stop listening for sleep events
		UnregisterForPlayerSleep()

		; stop timer
		CancelTimer(ETimerMorph)

		; stop listening for equipping items
		UnregisterForRemoteEvent(Player, "OnItemEquipped")
		int idxCompanion = 0
		While (idxCompanion < CompanionList.Length)
			Actor companion = CompanionList[idxCompanion]
			UnregisterForRemoteEvent(companion, "OnItemEquipped")
			idxCompanion += 1
		EndWhile
		
		; stop listening for doctor scenes
		int idxDoctorGreetScene = 0
		While (idxDoctorGreetScene < DoctorGreetScenes.Length)
			Scene greetScene = DoctorGreetScenes[idxDoctorGreetScene]
			UnregisterForRemoteEvent(greetScene, "OnBegin")
			idxDoctorGreetScene += 1
		EndWhile
		int idxDoctorExamScene = 0
		While (idxDoctorExamScene < DoctorExamScenes.Length)
			Scene examScene = DoctorExamScenes[idxDoctorExamScene]
			UnregisterForRemoteEvent(examScene, "OnBegin")
			idxDoctorExamScene += 1
		EndWhile

		; stop listening for companion changes
		UnregisterForCustomEvent(Followers, "CompanionChange")

		If (withRestoreMorphs)
			StartTimer(Math.Max(UpdateDelay + 0.5, 2.0), ETimerShutdownRestoreMorphs)
		Else
			FinishShutdown()
		EndIf
	EndIf
EndFunction

;
; Continuation of Shutdown: restore morphs and then finalize shutdown.
;
Function ShutdownRestoreMorphs()
	D.Log("ShutdownRestoreMorphs")
	RestoreOriginalMorphs(Player)
	int idxCompanion = 0
	While (idxCompanion < CompanionList.Length)
		RestoreOriginalMorphs(CompanionList[idxCompanion])
		idxCompanion += 1
	EndWhile
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
	If (RestartStackSize == 0)
		D.Note("Restarting Rad Morphing Redux")
	EndIf
	RestartStackSize += 1
	Utility.Wait(1.0)
	If (RestartStackSize <= 1)
		Shutdown()
		While (IsShuttingDown)
			Utility.Wait(1.0)
		EndWhile
		Startup()
		D.Note("Rad Morphing Redux has been restarted")
	Else
		D.Log("RestartStackSize: " + RestartStackSize)
	EndIf
	RestartStackSize -= 1
EndFunction


;
; Check if a new version has been installed and restart the mod if necessary.
; Returns true if an update was performed, otherwise false.
;
bool Function PerformUpdateIfNecessary()
	D.Log("PerformUpdateIfNecessary: " + Version + " != " + GetVersion() + " -> " + (Version != GetVersion()))
	If (Version == "")
		; mod has never run before
		Version = GetVersion()
	ElseIf (Version != GetVersion())
		If (Util.StringStartsWith(Version, "1.") || Util.StringStartsWith(Version, "0."))
			Debug.MessageBox("Rad Morphing Redux version " + Version + " is too old to update. Please load a save with the old version removed or start a new game.")
			return false
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
		return true
	Else
		D.Log("  no update")
		return false
	EndIf
EndFunction


;
; Getter for IsRunning.
; Returns true if the mod is running, false if not.
;
bool Function GetIsRunning()
	return IsRunning
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
	If (MCM_TriggerNames == None)
		MCM_TriggerNames = new string[0]
		MCM_TriggerNames.Add("-- SELECT A TRIGGER --")
	EndIf
	If (MCM_TriggerNames.Find(triggerName) < 0)
		MCM_TriggerNames.Add(triggerName)
		int triggerNameIndex = MCM_TriggerNames.Length - 1
		int idxSliderSet = 0
		While (idxSliderSet < NumberOfSliderSets)
			If (MCM.GetModSettingString("RadMorphingRedux", "sTriggerName:Slider" + idxSliderSet) == triggerName)
				D.Log("  updating MCM for SliderSet " + idxSliderSet)
				MCM.SetModSettingInt("RadMorphingRedux", "iTriggerNameIndex:Slider" + idxSliderSet, triggerNameIndex)
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
; Unregister a trigger name.
;
Function RemoveTriggerName(string triggerName)
	D.Log("RemoveTriggerName: " + triggerName)
	int idxTrigger = MCM_TriggerNames.Find(triggerName)
	If (idxTrigger > -1)
		MCM_TriggerNames.Remove(idxTrigger)
		int idxSliderSet = 0
		While (idxSliderSet < NumberOfSliderSets)
			int index = MCM.GetModSettingInt("RadMorphingRedux", "iTriggerNameIndex:Slider" + idxSliderSet)
			If (index == idxTrigger)
				D.Log("  updating MCM for SliderSet " + idxSliderSet)
				MCM.SetModSettingInt("RadMorphingRedux", "iTriggerNameIndex:Slider" + idxSliderSet, 0)
			ElseIf (index > idxTrigger)
				MCM.SetModSettingInt("RadMorphingRedux", "iTriggerNameIndex:Slider" + idxSliderSet, index - 1)
			EndIf
			idxSliderSet += 1
		EndWhile
	Else
		D.Log("  trigger does not exist")
	EndIf
EndFunction


;
; Get the total (max) percentage of morphs (base + current) currently applied.
; Relative to lower and upper threshold.
; 
; When SliderSet.TargetMorph has been reached, morph percentage is 100% (=1.0).
; With additive morphing the value may go above 100%.
;
; @param onlyPermanent - only include slider sets with permanent / only doctor morphs
;
float Function GetMorphPercentage(bool onlyPermanent=false)
	D.Log("GetMorphPercentage")
	return SliderSets.GetMorphPercentage(onlyPermanent)
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
; Get the total (max) percentage of morphs (base + current) for a specific trigger name.
; Relative to the minimum lower threshold and maximum upper threshold across all relevant slider sets.
;
float Function GetMorphPercentageForTrigger(string triggerName, bool inverted)
	D.Log("GetMorphPercentageForTrigger: " + triggerName  + ", inverted=" + inverted)
	return SliderSets.GetMorphPercentageForTrigger(triggerName, inverted)
EndFunction

;
; Get the total (max) percentage of base morphs (permanent morphs) for a specific trigger name.
; Relative to the minimum lower threshold and maximum upper threshold across all relevant slider sets.
;
float Function GetBaseMorphPercentageForTrigger(string triggerName, bool inverted)
	D.Log("GetBaseMorphPercentageForTrigger: " + triggerName  + ", inverted=" + inverted)
	return SliderSets.GetBaseMorphPercentageForTrigger(triggerName, inverted)
EndFunction

;
; Get the list of used (in SliderSets) trigger names.
;
string[] Function GetUsedTriggerNames()
	return SliderSets.GetTriggerNames()
EndFunction


;
; Update the value of a morph trigger.
; Returns the value that is used on the trigger, clamped between 0.0 and 1.0
;
float Function SetTriggerValue(string triggerName, float value)
	float clampedValue = Util.Clamp(value, 0.0, 1.0)
	D.Log("SetTriggerValue: " + triggerName + " = " + value + " --> " + clampedValue)
	SliderSets.SetTriggerValue(triggerName, clampedValue)
	ApplyImmediateMorphs()
	return clampedValue
EndFunction

;
; Apply morphs immediately when the trigger value changes.
; This is used when UpdateType is set to EUpdateTypeImmediate.
;
Function ApplyImmediateMorphs()
	D.Log("ApplyImmediateMorphs")
	LenARM_SliderSet:CumulativeMorphUpdate[] updates = SliderSets.CalculateMorphUpdates(SliderSets.EUpdateTypeImmediate)
	D.Log("  updates: " + updates)

	ApplyMorphUpdates(updates)
EndFunction

;
; Apply morphs at regular intervals.
; This is used when UpdateType is set to EUpdateTypePeriodic.
;
Function ApplyPeriodicMorphs()
	LenARM_SliderSet:CumulativeMorphUpdate[] updates = SliderSets.CalculateMorphUpdates(SliderSets.EUpdateTypePeriodic)
	
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
	LenARM_SliderSet:CumulativeMorphUpdate[] updates = SliderSets.CalculateMorphUpdates(SliderSets.EUpdateTypeOnSleep)
	D.Log(" updates: " + updates)

	ApplyMorphUpdates(updates)
EndFunction


;
; Apply a list of morph updates (sliderName:newValue) through BodyGen.
;
Function ApplyMorphUpdates(LenARM_SliderSet:CumulativeMorphUpdate[] updates)
	If (updates.Length > 0)
		D.Log("ApplyMorphUpdates: " + updates)
		LenARM_SliderSet:CumulativeMorphUpdate[] femaleUpdates = new LenARM_SliderSet:CumulativeMorphUpdate[0]
		LenARM_SliderSet:CumulativeMorphUpdate[] maleUpdates = new LenARM_SliderSet:CumulativeMorphUpdate[0]
		int sex = Player.GetLeveledActorBase().GetSex()
		int idxUpdate = 0
		bool playerMorphed = false
		While (idxUpdate < updates.Length)
			LenARM_SliderSet:CumulativeMorphUpdate update = updates[idxUpdate]
			If (update.ApplyCompanionFemale)
				femaleUpdates.Add(update)
			EndIf
			If (update.ApplyCompanionMale)
				maleUpdates.Add(update)
			EndIf
			If ((sex == ESexFemale && update.ApplyPlayerFemale) || (sex == ESexMale && update.ApplyPlayerMale))
				float value = 0.0
				If (sex == ESexFemale)
					value = update.PlayerFemaleValue
				ElseIf (sex == ESexMale)
					value = update.PlayerMaleValue
				EndIf
				D.Log("  player morph: " + update.Name + "=" + value)
				BodyGen.SetMorph(Player, sex==ESexFemale, update.Name, kwMorph, value)
				playerMorphed = true
			EndIf
			idxUpdate += 1
		EndWhile
		If (playerMorphed)
			BodyGen.UpdateMorphs(Player)
		EndIf

		ApplyMorphUpdatesToCompanions(femaleUpdates, maleUpdates)

		UnequipSlots()

		Var[] eventArgs = new Var[1]
		eventArgs[0] = GetMorphPercentage()
		SendCustomEvent("OnMorphChange", eventArgs)
	EndIf
EndFunction

;
; Apply a list of morph updates (sliderName:newValue) through BodyGen on all companions.
;
Function ApplyMorphUpdatesToCompanions(LenARM_SliderSet:CumulativeMorphUpdate[] femaleUpdates, LenARM_SliderSet:CumulativeMorphUpdate[] maleUpdates)
	If (CompanionList.Length > 0 && (femaleUpdates.Length > 0 || maleUpdates.Length > 0))
		D.Log("ApplyMorphUpdatesToCompanions: female=" + femaleUpdates + "  male=" + maleUpdates)
		int idxCompanion = 0
		While (idxCompanion < CompanionList.Length)
			Actor companion = CompanionList[idxCompanion]
			D.Log("  " + companion.GetLeveledActorBase().GetName() + " (" + companion + ")")
			LenARM_SliderSet:CumulativeMorphUpdate[] updates = new LenARM_SliderSet:CumulativeMorphUpdate[0]
			int sex = companion.GetLeveledActorBase().GetSex()
			If (sex == ESexFemale)
				updates = femaleUpdates
			ElseIf (sex == ESexMale)
				updates = maleUpdates
			EndIf
			D.Log("    " + updates)
			If (updates.Length > 0)
				int idxUpdate = 0
				While (idxUpdate < updates.Length)
					LenARM_SliderSet:CumulativeMorphUpdate update = updates[idxUpdate]
					float value = 0.0
					If (sex == ESexFemale)
						value = update.CompanionFemaleValue
					ElseIf (sex == ESexMale)
						value = update.CompanionMaleValue
					EndIf
					D.Log("  companion morph (" + companion + "): " + update.Name + "=" + value)
					BodyGen.SetMorph(companion, sex==ESexFemale, update.Name, kwMorph, value)
					idxUpdate += 1
				EndWhile
				BodyGen.UpdateMorphs(companion)
			EndIf
			idxCompanion += 1
		EndWhile
	EndIf
EndFunction


;
; Apply base morphs (permanent morphs) through BodyGen.
;
Function ApplyBaseMorphs()
	D.Log("ApplyBaseMorphs")
	int sex = Player.GetLeveledActorBase().GetSex()
	LenARM_SliderSet:CumulativeMorphUpdate[] baseMorphs = SliderSets.GetBaseMorphs()
	ApplyMorphUpdates(baseMorphs)
EndFunction


;
; Restore the original (unmorphed) slider values through BodyGen.
;
Function RestoreOriginalMorphs(Actor target)
	D.Log("RestoreOriginalMorphs: " + target)
	int sex = target.GetLeveledActorBase().GetSex()
	BodyGen.RemoveMorphsByKeyword(target, sex==ESexFemale, kwMorph)
	BodyGen.UpdateMorphs(target)
EndFunction


;
; Interrupts doctor exam scene and shows morph healing dialog when the player has base morphs.
;
Function ShowHealMorphDialog()
	float baseMorphs = GetBaseMorphPercentage() * 100.0
	If (baseMorphs > 0.0)
		float morphs = GetMorphPercentage(true) * 100.0
		int cost = (baseMorphs * HealCost) as int
		int capsCount = Player.GetItemCount(caps)
		float canAfford = Math.Min(baseMorphs, Math.Floor(capsCount / HealCost))
		float resultingBaseMorphs = baseMorphs - canAfford
		int canAffordCost = (canAfford * HealCost) as int
		D.Log("    morphs:              " + morphs + "%")
		D.Log("    baseMorphs:          " + baseMorphs + "%")
		D.Log("    cost:                " + cost + " caps")
		D.Log("    caps:                " + capsCount + " caps")
		D.Log("    canAfford:           " + canAfford + "%")
		D.Log("    canAffordCost:       " + canAffordCost + " caps")
		D.Log("    resultingBaseMorphs: " + resultingBaseMorphs + "%")
		int choice = HealMorphMessage.Show(morphs, baseMorphs, cost, capsCount, canAfford, canAffordCost)
		D.Log("    choice: " + choice)
		If (choice == EHealMorphChoiceYes)
			D.Log("      -> heal morphs")
			If (canAfford > 0)
				D.Log("        -> healing")
				HealBaseMorphs(resultingBaseMorphs / 100.0)
				D.Log("        -> removing " + canAffordCost + " caps")
				Player.RemoveItem(caps, canAffordCost)
			Else
				D.Log("        -> not enough caps (" + capsCount + " < " + cost + ")")
				Debug.MessageBox("You don't have enough caps.")
			EndIf
		ElseIf (choice == EHealMorphChoiceNo)
			D.Log("      -> don't heal morphs")
		Else
			D.Log("      -> unknown choice")
		EndIf
	EndIf
EndFunction

;
; Remove the base morphs (permanent morphs) through BodyGen.
;
Function HealBaseMorphs(float targetBaseMorph)
	D.Log("HealBaseMorphs: " + targetBaseMorph)
	LenARM_SliderSet:CumulativeMorphUpdate[] fullMorphs = None
	If (targetBaseMorph > 0.0)
		fullMorphs = SliderSets.ReduceBaseMorphs(targetBaseMorph)
	Else
		SliderSets.ClearBaseMorphs()
		fullMorphs = SliderSets.CalculateFullMorphs()
	EndIf
	ApplyMorphUpdates(fullMorphs)
EndFunction


;
; Check whether the worn item can be unequipped or should be ignored.
;
bool Function CheckIgnoreItem(Actor:WornItem item)
	D.Log("    CheckIgnoreItem: " + item)
	; don't try to unequip hands or pipboy
	If (LL_Fourplay.StringSubstring(item.modelName, 0, 6) == "Actors" || LL_Fourplay.StringSubstring(item.modelName, 0, 6) == "Pipboy")
		return true
	EndIf

	; check DeviousDevices
	Armor armorItem = item.item as Armor
	If (armorItem == None)
		; item is not an armor --> ignore
		D.Log("      --> item is not an Armor, do not unequip")
		return true
	Else
		bool isDD = DD.CheckItem(armorItem)
		If (isDD)
			D.Log("      --> item is a DD device, do not unequip")
			return true
		Else
			D.Log("      --> item not found in DD list, unequip")
		EndIf
	EndIf

	return false
EndFunction

;
; Unequip a list of slots on the target actor.
;
Function UnequipActorSlots(Actor target, LenARM_SliderSet:UnequipSlot[] slots)
	If (!target.IsInPowerArmor())
		D.Log("UnequipActorSlots: target=" + target.GetLeveledActorBase().GetName() + " (" + target + ")  slots=" + slots)
		int sex = target.GetLeveledActorBase().GetSex()
		bool playedSound = false
		int idxSlot = 0
		While (idxSlot < slots.Length)
			LenARM_SliderSet:UnequipSlot slot = slots[idxSlot]
			If ((target == Player && slot.ApplyPlayer) || (target != Player && slot.ApplyCompanion))
				If ((sex == ESexFemale && slot.ApplyFemale) || (sex == ESexMale && slot.ApplyMale))
					D.Log("  checking slot " + slot)
					Actor:WornItem item = target.GetWornItem(slot.slot)
					D.Log("    -->  " + item)
					If (item && item.item)
						bool ignoreItem = CheckIgnoreItem(item)
						D.Log("    ignoreItem: " + ignoreItem)
						If (!ignoreItem)
							D.Log("    unequipping slot " + slot + " (" + item.item.GetName() + " / " + item.modelName + ")")
							target.UnequipItem(item.item)
							If (!target.IsEquipped(item.item))
								If (slot.Drop)
									D.Log("    chance to drop item: " + slot.DropChance)
									If (slot.DropChance <= Utility.RandomFloat())
										D.Log("      -> dropping item")
										target.DropObject(item.item)
									Else
										D.Log("      -> not dropping item")
									EndIf
								ElseIf (slot.Destroy)
									D.Log("    chance to destroy item: " + slot.DropChance)
									If (slot.DropChance <= Utility.RandomFloat())
										D.Log("      -> destroying item")
										target.RemoveItem(item.item)
									Else
										D.Log("      -> not destroying item")
									EndIf
								EndIf
								If (!playedSound)
									D.Log("    playing sound")
									LenARM_DropClothesSound.PlayAndWait(target)
									playedSound = true
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
			idxSlot += 1
		EndWhile
	EndIf
EndFunction

;
; Check any slots need to be unequipped due to morphs and unequip them.
;
Function UnequipSlots()
	UnequipStackSize += 1
	Utility.Wait(1.0)
	If (UnequipStackSize <= 1 && !Player.IsInPowerArmor())
		D.Log("UnequipSlots")
		LenARM_SliderSet:UnequipSlot[] slots = SliderSets.GetUnequipSlots()
		UnequipActorSlots(Player, slots)
		int idxCompanion = 0
		While (idxCompanion < CompanionList.Length)
			Actor companion = CompanionList[idxCompanion]
			UnequipActorSlots(companion, slots)
			idxCompanion += 1
		EndWhile
	Else
		D.Log("UnequipStackSize: " + UnequipStackSize)
	EndIf
	UnequipStackSize -= 1
EndFunction




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; helpers / MCM

;
; Refresh the MCM page with all the currently equipped items and their slots.
;
Function RefreshEquippedClothes()
	D.Log("RefreshEquippedClothes")
	int idxMcm = 0

	MCM.SetModSettingString("RadMorphingRedux", "sSlot" + idxMcm + ":EquippedItems", "Loading...")
	idxMcm += 1
	While (idxMcm < 62)
		MCM.SetModSettingString("RadMorphingRedux", "sSlot" + idxMcm + ":EquippedItems", "")
		idxMcm += 1
	EndWhile
	MCM.RefreshMenu()

	idxMcm = 0
	int slot = 0
	While (slot < 62)
		Actor:WornItem item = Player.GetWornItem(slot)
		If (item != None && item.item != None)
			D.Log("  " + slot + ": " + item.item.GetName() + " (" + item.modelName + ")")
			MCM.SetModSettingString("RadMorphingRedux", "sSlot" + idxMcm + ":EquippedItems", slot + ": " + item.item.GetName() + " (" + item.modelName + ")")
			idxMcm += 1
		Else
			D.Log("  Slot " + slot + " is empty")
		EndIf
		slot += 1
	EndWhile

	While (idxMcm < 62)
		MCM.SetModSettingString("RadMorphingRedux", "sSlot" + idxMcm + ":EquippedItems", "")
		idxMcm += 1
	EndWhile

	MCM.RefreshMenu()
EndFunction


;
; Reload all MCM settings (restart RMR)
;
Function ReloadMCM()
	Restart()
EndFunction