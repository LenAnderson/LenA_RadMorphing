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

; TRUE while the mod is active.
bool IsRunning = false

int RestartStackSize = 0

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
	PerformUpdateIfNecessary()
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
		LenARM_SliderSet:MorphUpdate[] updates = SliderSets.GetFullMorphs()
		ApplyMorphUpdates(updates)
	Else
		int idxCompanion = CompanionList.Find(companion)
		CompanionList.Remove(idxCompanion)
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

		; load SliderSets
		SliderSets.LoadSliderSets(NumberOfSliderSets, Player)

		;TODO listen for item equip

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

		; notify plugins that mod is running
		IsRunning = true
		SendCustomEvent("OnStartup")
	ElseIf (MCM.GetModSettingBool("RadMorphingRedux", "bWarnDisabled:General"))
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
		IsRunning = false
		SendCustomEvent("OnShutdown")

		; stop listening for sleep events
		UnregisterForPlayerSleep()

		; stop timer
		CancelTimer(ETimerMorph)

		;TODO stop listening for equipping items
		
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

Function RemoveTriggerName(string triggerName)
	D.Log("RemoveTriggerName: " + triggerName)
	int idxTrigger = MCM_TriggerNames.Find(triggerName)
	If (idxTrigger > -1)
		MCM_TriggerNames.Remove(idxTrigger)
		int idxSliderSet = 0
		While (idxSliderSet < NumberOfSliderSets)
			If (MCM.GetModSettingString("RadMorphingRedux", "sTriggerName:Slider" + idxSliderSet) == triggerName)
				D.Log("  updating MCM for SliderSet " + idxSliderSet)
				MCM.SetModSettingInt("RadMorphingRedux", "iTriggerNameIndex:Slider" + idxSliderSet, 0)
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
	float clampedValue = Util.Clamp(value, 0.0, 1.0)
	D.Log("SetTriggerValue: " + triggerName + " = " + value + " --> " + clampedValue)
	SliderSets.SetTriggerValue(triggerName, clampedValue)
	ApplyImmediateMorphs()
EndFunction

;
; Apply morphs immediately when the trigger value changes.
; This is used when UpdateType is set to EUpdateTypeImmediate.
;
Function ApplyImmediateMorphs()
	D.Log("ApplyImmediateMorphs")
	LenARM_SliderSet:MorphUpdate[] updates = SliderSets.CalculateMorphUpdates(SliderSets.EUpdateTypeImmediate)
	D.Log("  updates: " + updates)

	ApplyMorphUpdates(updates)
EndFunction

;
; Apply morphs at regular intervals.
; This is used when UpdateType is set to EUpdateTypePeriodic.
;
Function ApplyPeriodicMorphs()
	LenARM_SliderSet:MorphUpdate[] updates = SliderSets.CalculateMorphUpdates(SliderSets.EUpdateTypePeriodic)
	
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
	LenARM_SliderSet:MorphUpdate[] updates = SliderSets.CalculateMorphUpdates(SliderSets.EUpdateTypeOnSleep)
	D.Log(" updates: " + updates)

	ApplyMorphUpdates(updates)
EndFunction


;
; Apply a list of morph updates (sliderName:newValue) through BodyGen.
;
Function ApplyMorphUpdates(LenARM_SliderSet:MorphUpdate[] updates)
	If (updates.Length > 0)
		D.Log("ApplyMorphUpdates: " + updates)
		LenARM_SliderSet:MorphUpdate[] femaleUpdates = new LenARM_SliderSet:MorphUpdate[0]
		LenARM_SliderSet:MorphUpdate[] maleUpdates = new LenARM_SliderSet:MorphUpdate[0]
		int sex = Player.GetLeveledActorBase().GetSex()
		int idxUpdate = 0
		While (idxUpdate < updates.Length)
			LenARM_SliderSet:MorphUpdate update = updates[idxUpdate]
			If (update.ApplyCompanion == SliderSets.EApplyCompanionFemale || update.ApplyCompanion == SliderSets.EApplyCompanionAll)
				femaleUpdates.Add(update)
			EndIf
			If (update.ApplyCompanion == SliderSets.EApplyCompanionMale || update.ApplyCompanion == SliderSets.EApplyCompanionAll)
				maleUpdates.Add(update)
			EndIf
			BodyGen.SetMorph(Player, sex==ESexFemale, update.Name, kwMorph, update.Value)
			idxUpdate += 1
		EndWhile
		BodyGen.UpdateMorphs(Player)

		ApplyMorphUpdatesToCompanions(femaleUpdates, maleUpdates)

		var[] eventArgs = new var[1]
		eventArgs[0] = GetMorphPercentage()
		SendCustomEvent("OnMorphChange", eventArgs)
	EndIf
EndFunction

;
; Apply a list of morph updates (sliderName:newValue) through BodyGen on all companions.
;
Function ApplyMorphUpdatesToCompanions(LenARM_SliderSet:MorphUpdate[] femaleUpdates, LenARM_SliderSet:MorphUpdate[] maleUpdates)
	If (CompanionList.Length > 0 && (femaleUpdates.Length > 0 || maleUpdates.Length > 0))
		D.Log("ApplyMorphUpdatesToCompanions: female=" + femaleUpdates + "  male=" + maleUpdates)
		int idxCompanion = 0
		While (idxCompanion < CompanionList.Length)
			Actor companion = CompanionList[idxCompanion]
			D.Log("  " + companion.GetLeveledActorBase().GetName() + " (" + companion + ")")
			LenARM_SliderSet:MorphUpdate[] updates = new LenARM_SliderSet:MorphUpdate[0]
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
					LenARM_SliderSet:MorphUpdate update = updates[idxUpdate]
					BodyGen.SetMorph(companion, sex==ESexFemale, update.Name, kwMorph, update.Value)
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
	LenARM_SliderSet:MorphUpdate[] baseMorphs = SliderSets.GetBaseMorphs()
	ApplyMorphUpdates(baseMorphs)
EndFunction


;
; Restore the original (unmorphed) slider values through BodyGen.
;
Function RestoreOriginalMorphs(Actor target)
	D.Log("RestoreOriginalMorphs: " + target)
	int sex = target.GetLeveledActorBase().GetSex()
	string[] sliderNames = SliderSets.GetSliderNames()
	int idxSlider = 0
	While (idxSlider < sliderNames.Length)
		string sliderName = sliderNames[idxSlider]
		BodyGen.SetMorph(target, sex==ESexFemale, sliderName, kwMorph, 0)
		idxSlider += 1
	EndWhile
	BodyGen.UpdateMorphs(target)
EndFunction


;
; Interrupts doctor exam scene and shows morph healing dialog when the player has base morphs.
;
Function ShowHealMorphDialog()
	float baseMorphs = GetBaseMorphPercentage() * 100.0
	If (baseMorphs > 0.0)
		float morphs = GetMorphPercentage() * 100.0
		int cost = (baseMorphs * HealCost) as int
		int capsCount = Player.GetItemCount(caps)
		D.Log("    morphs:     " + morphs + "%")
		D.Log("    baseMorphs: " + baseMorphs + "%")
		D.Log("    cost:       " + cost + " caps")
		int choice = HealMorphMessage.Show(morphs, baseMorphs, cost, capsCount)
		D.Log("    choice: " + choice)
		If (choice == EHealMorphChoiceYes)
			D.Log("      -> heal morphs")
			If (capsCount >= cost)
				D.Log("        -> healing")
				HealBaseMorphs()
				D.Log("        -> removing " + cost + " caps")
				Player.RemoveItem(caps, cost)
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
Function HealBaseMorphs()
	D.Log("HealBaseMorphs")
	int sex = Player.GetLeveledActorBase().GetSex()
	SliderSets.ClearBaseMorphs()
	LenARM_SliderSet:MorphUpdate[] fullMorphs = SliderSets.CalculateFullMorphs()
	ApplyMorphUpdates(fullMorphs)
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