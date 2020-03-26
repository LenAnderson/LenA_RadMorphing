Scriptname LenARM:LenARM_Main extends Quest

Group Properties
	Actor Property PlayerRef Auto Const

	Keyword Property kwMorph Auto Const

	ActorValue Property Rads Auto Const

	Scene Property DoctorMedicineScene03_AllDone Auto Const

	Sound Property LenARM_DropClothesSound Auto Const

	Faction Property CurrentCompanionFaction Auto Const
EndGroup


Group EnumTimerId
	int Property ETimerMorphTick = 1 Auto Const
EndGroup

Group EnumApplyCompanion
	int Property EApplyCompanionNone = 0 Auto Const
	int Property EApplyCompanionFemale = 1 Auto Const
	int Property EApplyCompanionMale = 2 Auto Const
	int Property EApplyCompanionAll = 3 Auto Const
EndGroup

Group EnumSex
	int Property ESexMale = 0 Auto Const
	int Property ESexFemale = 1 Auto Const
EndGroup


Group Constants
	int Property _NUMBER_OF_SLIDERSETS_ = 20 Auto Const
EndGroup



Struct SliderSet
	bool IsUsed

	; MCM values
	string SliderName
	float TargetMorph
	float ThresholdMin
	float ThresholdMax
	string UnequipSlot
	float ThresholdUnequip
	bool OnlyDoctorCanReset
	bool IsAdditive
	bool HasAdditiveLimit
	float AdditiveLimit
	int ApplyCompanion
	; END: MCM values

	int NumberOfSliderNames
	int NumberOfUnequipSlots

	float BaseMorph
	float CurrentMorph
EndStruct

SliderSet[] SliderSets

; flattened two-dimensional array[idxSliderSet][idxSliderName]
string[] SliderNames

; flattened two-dimensional array[idxSliderSet][idxSlot]
int[] UnequipSlots

; flattened two-dimensional array[idxSliderSet][idxSliderName]
float[] OriginalMorphs

; flattened array[idxCompanion][idxSliderSet][idxSliderName]
float[] OriginalCompanionMorphs

Actor[] CurrentCompanions


float UpdateDelay


float CurrentRads


int RestartStackSize
int UnequipStackSize


string Version



;
; wrappers for debug functions
;
Function Note(string msg)
	Debug.Notification("[LenARM] " + msg)
	Log(msg)
EndFunction
Function Log(string msg)
	Debug.Trace("[LenARM] " + msg)
EndFunction
;
; END: wrappers for debug functions




;
; utility functions
;
string[] Function StringSplit(string target, string delimiter)
	Log("splitting '" + target + "' with '" + delimiter + "'")
	string[] result = new string[0]
	string current = target
	int idx = LL_Fourplay.StringFind(current, delimiter)
	Log("split idx: " + idx + " current: '" + current + "'")
	While (idx > -1 && current)
		result.Add(LL_Fourplay.StringSubstring(current, 0, idx))
		current = LL_Fourplay.StringSubstring(current, idx+1)
		idx = LL_Fourplay.StringFind(current, delimiter)
		Log("split idx: " + idx + " current: '" + current + "'")
	EndWhile
	If (current)
		result.Add(current)
	EndIf
	Log("split result: " + result)
	return result
EndFunction


float Function Clamp(float value, float limit1, float limit2)
	float lower = Math.Min(limit1, limit2)
	float upper = Math.Max(limit1, limit2)
	return Math.Min(Math.Max(value, lower), upper)
EndFunction
;
; END: utility functions




string Function GetVersion()
	return "0.3.1"; Thu Mar 26 19:27:26 CET 2020
EndFunction




;
; SliderSet functions
;
SliderSet Function SliderSet_Constructor(int idxSet)
	Log("SliderSet_Constructor: " + idxSet)
	SliderSet set = new SliderSet
	set.SliderName = MCM.GetModSettingString("LenA_RadMorphing", "sSliderName:Slider" + idxSet)
	If (set.SliderName != "")
		set.IsUsed = true
		set.TargetMorph = MCM.GetModSettingFloat("LenA_RadMorphing", "fTargetMorph:Slider" + idxSet) / 100.0
		set.ThresholdMin = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdMin:Slider" + idxSet) / 100.0
		set.ThresholdMax = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdMax:Slider" + idxSet) / 100.0
		set.UnequipSlot = MCM.GetModSettingString("LenA_RadMorphing", "sUnequipSlot:Slider" + idxSet)
		set.ThresholdUnequip = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdUnequip:Slider" + idxSet) / 100.0
		set.OnlyDoctorCanReset = MCM.GetModSettingBool("LenA_RadMorphing", "bOnlyDoctorCanReset:Slider" + idxSet)
		set.IsAdditive = MCM.GetModSettingBool("LenA_RadMorphing", "bIsAdditive:Slider" + idxSet)
		set.HasAdditiveLimit = MCM.GetModSettingBool("LenA_RadMorphing", "bHasAdditiveLimit:Slider" + idxSet)
		set.AdditiveLimit = MCM.GetModSettingFloat("LenA_RadMorphing", "fAdditiveLimit:Slider" + idxSet) / 100.0
		set.ApplyCompanion = MCM.GetModSettingInt("LenA_RadMorphing", "iApplyCompanion:Slider" + idxSet)

		string[] names = StringSplit(set.SliderName, "|")
		set.NumberOfSliderNames = names.Length

		If (set.UnequipSlot != "")
			string[] slots = StringSplit(set.UnequipSlot, "|")
			set.NumberOfUnequipSlots = slots.Length
		Else
			set.NumberOfUnequipSlots = 0
		EndIf
	Else
		set.IsUsed = false
	EndIf

	Log("  " + set)
	return set
EndFunction

int Function SliderSet_GetSliderNameOffset(int idxSet)
	int offset = 0
	int index = 0
	While (index < idxSet)
		offset += SliderSets[index].NumberOfSliderNames
		index += 1
	EndWhile
	return offset
EndFunction

int Function SliderSet_GetUnequipSlotOffset(int idxSet)
	int offset = 0
	int index = 0
	While (index < idxSet)
		offset += SliderSets[index].NumberOfUnequipSlots
		index += 1
	EndWhile
	return offset
EndFunction
;
; END: SliderSet functions







Event OnQuestInit()
	Log("OnQuestInit")
	RegisterForRemoteEvent(PlayerRef, "OnPlayerLoadGame")
	RegisterForExternalEvent("OnMCMSettingChange|LenA_RadMorphing", "OnMCMSettingChange")
	Startup()
EndEvent

Event OnQuestShutdown()
	Log("OnQuestShutdown")
	Shutdown()
EndEvent




Event Actor.OnPlayerLoadGame(Actor akSender)
	Log("Actor.OnPlayerLoadGame: " + akSender)
	PerformUpdateIfNecessary()
EndEvent


Function OnMCMSettingChange(string modName, string id)
	Log("OnMCMSettingChange: " + modName + "; " + id)
	Restart()
EndFunction




Function ReactToSettingsChange(string id)
	If (LL_FourPlay.StringSubstring(id, 0, 11) == "sSliderName")
		Restart()
	EndIf
EndFunction




Function PerformUpdateIfNecessary()
	Log("PerformUpdateIfNecessary: " + Version + " != " + GetVersion() + " -> " + (Version != GetVersion()))
	If (Version != GetVersion())
		Restart()
		Version = GetVersion()
	EndIf
EndFunction




Function Startup()
	Log("Startup")
	If (MCM.GetModSettingBool("LenA_RadMorphing", "bIsEnabled:General"))
		Log("  is enabled")
		CurrentRads = 0

		LoadSliderSets()

		; get duration from MCM
		UpdateDelay = MCM.GetModSettingFloat("LenA_RadMorphing", "fUpdateDelay:General")

		; start listening for equipping items
		RegisterForRemoteEvent(PlayerRef, "OnItemEquipped")

		; start listening for doctor scene
		RegisterForRemoteEvent(DoctorMedicineScene03_AllDone, "OnBegin")
		RegisterForRemoteEvent(DoctorMedicineScene03_AllDone, "OnEnd")

		; set up companions
		CurrentCompanions = new Actor[0]

		; start timer
		TimerMorphTick()
	ElseIf (MCM.GetModSettingBool("LenA_RadMorphing", "bWarnDisabled:General"))
		Log("  is disabled, with warning")
		Debug.MessageBox("Rad Morphing is currently disabled. You can enable it in MCM > Rad Morphing > Enable Rad Morphing")
	Else
		Log("  is disabled, no warning")
	EndIf
EndFunction

Function LoadSliderSets()
	Log("LoadSliderSets")
	; create arrays if not exist
	If (!SliderSets)
		SliderSets = new SliderSet[_NUMBER_OF_SLIDERSETS_]
	EndIf
	If (!SliderNames)
		SliderNames = new string[0]
	EndIf
	If (!UnequipSlots)
		UnequipSlots = new int[0]
	EndIf
	If (!OriginalMorphs)
		OriginalMorphs = new float[0]
		OriginalCompanionMorphs = new float[0]
	EndIf
	
	; get slider sets
	int idxSet = 0
	While (idxSet < _NUMBER_OF_SLIDERSETS_)
		SliderSet oldSet = SliderSets[idxSet]
		SliderSet newSet = SliderSet_Constructor(idxSet)
		SliderSets[idxSet] = newSet

		If (oldSet)
			newSet.BaseMorph = oldSet.BaseMorph
			newSet.CurrentMorph = 0.0
		EndIf
		
		; populate flattened arrays
		int sliderNameOffset = SliderSet_GetSliderNameOffset(idxSet)
		If (newSet.IsUsed)
			string[] names = StringSplit(newSet.SliderName, "|")
			int idxSlider = 0
			While (idxSlider < newSet.NumberOfSliderNames)
				float morph = BodyGen.GetMorph(playerRef, True, names[idxSlider], None)
				int currentIndex = sliderNameOffset + idxSlider
				If (!oldSet || idxSlider >= oldSet.NumberOfSliderNames)
					; insert into array
					SliderNames.Insert(names[idxSlider], currentIndex)
					OriginalMorphs.Insert(morph, currentIndex)
				Else
					; replace item
					SliderNames[currentIndex] = names[idxSlider]
					OriginalMorphs[currentIndex] = morph
				EndIf
				idxSlider += 1
			EndWhile
		EndIf
		; remove unused items
		If (oldSet && newSet.NumberOfSliderNames < oldSet.NumberOfSliderNames)
			SliderNames.Remove(sliderNameOffset + newSet.NumberOfSliderNames, oldSet.NumberOfSliderNames - newSet.NumberOfSliderNames)
		EndIf

		int unequipSlotOffset = SliderSet_GetUnequipSlotOffset(idxSet)
		If (newSet.IsUsed && newSet.NumberOfUnequipSlots > 0)
			string[] slots = StringSplit(newSet.UnequipSlot, "|")
			int idxSlot = 0
			While (idxSlot < newSet.NumberOfUnequipSlots)
				int currentIndex = unequipSlotOffset + idxSlot
				If (!oldSet || idxSlot >= oldSet.NumberOfUnequipSlots)
					; insert into array
					UnequipSlots.Insert(slots[idxSlot] as int, currentIndex)
				Else
					; replace item
					UnequipSlots[currentIndex] = slots[idxSlot] as int
				EndIf
				idxSlot += 1
			EndWhile
		EndIf
		; remove unused items
		If (oldSet && newSet.NumberOfUnequipSlots < oldSet.NumberOfUnequipSlots)
			UnequipSlots.Remove(unequipSlotOffset + newSet.NumberOfUnequipSlots, oldSet.NumberOfUnequipSlots - newSet.NumberOfUnequipSlots)
		EndIf
		idxSet += 1
	EndWhile
	Log("  SliderSets: " + SliderSets)
	Log("  SliderNames: " + SliderNames)
	Log("  OriginalMorphs: " + OriginalMorphs)
	Log("  UnequipSlots: " + UnequipSlots)

	RetrieveAllOriginalCompanionMorphs()
EndFunction


Function Shutdown()
	Log("Shutdown")
	; stop timer
	CancelTimer(ETimerMorphTick)

	; stop listening for equipping items
	UnregisterForRemoteEvent(PlayerRef, "OnItemEquipped")

	; stop listening for doctor scene
	UnregisterForRemoteEvent(DoctorMedicineScene03_AllDone, "OnBegin")
	UnregisterForRemoteEvent(DoctorMedicineScene03_AllDone, "OnEnd")
	
	Utility.Wait(Math.Max(UpdateDelay + 0.5, 2.0))
	; restore base values
	RestoreOriginalMorphs()
EndFunction


Function Restart()
	RestartStackSize += 1
	Utility.Wait(1.0)
	If (RestartStackSize <= 1)
		Log("Restart")
		Shutdown()
		Utility.Wait(1.0)
		Startup()
		Log("Restart completed")
	Else
		Log("RestartStackSize: " + RestartStackSize)
	EndIf
	RestartStackSize -= 1
EndFunction




Event OnTimer(int tid)
	If (tid == ETimerMorphTick)
		TimerMorphTick()
	EndIf
EndEvent




Event Actor.OnItemEquipped(Actor akSender, Form akBaseObject, ObjectReference akReference)
	Log("Actor.OnItemEquipped: " + akBaseObject.GetName() + " (" + akBaseObject.GetSlotMask() + ")")
	;TODO get slot number
	;TODO check if slot is allowed
	;TODO if slot is not allowed -> unequip
	Utility.Wait(1.0)
	TriggerUnequipSlots()
EndEvent


Event Scene.OnBegin(Scene akSender)
	float radsBeforeDoc = PlayerRef.GetValue(Rads)
	Log("Scene.OnBegin: " + akSender + " (rads: " + radsBeforeDoc + ")")
EndEvent

Event Scene.OnEnd(Scene akSender)
	float radsNow = PlayerRef.GetValue(Rads)
	Log("Scene.OnEnd: " + akSender + " (rads: " + radsNow + ")")
	If (radsNow == 0.0)
		ResetMorphs()
	EndIf
EndEvent




Function ResetMorphs()
	Log("ResetMorphs")
	RestoreOriginalMorphs()
	; reset saved morphs in SliderSets
	int idxSet = 0
	While (idxSet < SliderSets.Length)
		SliderSet set = SliderSets[idxSet]
		set.BaseMorph = 0.0
		set.CurrentMorph = 0.0
		idxSet += 1
	EndWhile
EndFunction

Function RestoreOriginalMorphs()
	Log("RestoreOriginalMorphs")
	; restore base values
	int i = 0
	While (i < SliderNames.Length)
		BodyGen.SetMorph(PlayerRef, True, SliderNames[i], kwMorph, OriginalMorphs[i])
		i += 1
	EndWhile
	BodyGen.UpdateMorphs(PlayerRef)

	RestoreAllOriginalCompanionMorphs()
EndFunction




Function RestoreAllOriginalCompanionMorphs()
	Log("RestoreAllOriginalCompanionMorphs")
	int idxComp = 0
	While (idxComp < CurrentCompanions.Length)
		Actor companion = CurrentCompanions[idxComp]
		RestoreOriginalCompanionMorphs(companion, idxComp)
		idxComp += 1
	EndWhile
EndFunction

Function RestoreOriginalCompanionMorphs(Actor companion, int idxCompanion)
	Log("RestoreOriginalCompanionMorphs: " + companion + "; " + idxCompanion)
	int offsetIdx = SliderNames.Length * idxCompanion
	int idxSlider = 0
	While (idxSlider < SliderNames.Length)
		BodyGen.SetMorph(companion, True, SliderNames[idxSlider], kwMorph, OriginalCompanionMorphs[offsetIdx + idxSlider])
		idxSlider += 1
	EndWhile
	BodyGen.UpdateMorphs(companion)
EndFunction


Function RetrieveAllOriginalCompanionMorphs()
	Log("RetrieveAllOriginalCompanionMorphs")
	OriginalCompanionMorphs = new float[0]
	int idxComp = 0
	While (idxComp < CurrentCompanions.Length)
		Actor companion = CurrentCompanions[idxComp]
		RetrieveOriginalCompanionMorphs(companion)
		idxComp += 1
	EndWhile
EndFunction

Function RetrieveOriginalCompanionMorphs(Actor companion)
	Log("RetrieveOriginalCompanionMorphs: " + companion)
	int idxSlider = 0
	While (idxSlider < SliderNames.Length)
		OriginalCompanionMorphs.Add(BodyGen.GetMorph(companion, True, SliderNames[idxSlider], None))
		idxSlider += 1
	EndWhile
EndFunction


Function SetCompanionMorphs(int idxSlider, float morph, int applyCompanion)
	Log("SetCompanionMorphs: " + idxSlider + "; " + morph + "; " + applyCompanion)
	int idxComp = 0
	While (idxComp < CurrentCompanions.Length)
		Actor companion = CurrentCompanions[idxComp]
		int sex = companion.GetLeveledActorBase().GetSex()
		If (applyCompanion == EApplyCompanionAll || (sex == ESexFemale && applyCompanion == EApplyCompanionFemale) || (sex == ESexMale && applyCompanion == EApplyCompanionMale))
			int offsetIdx = SliderNames.Length * idxComp
			Log("    setting companion(" + companion + ") slider '" + SliderNames[idxSlider] + "' to " + (OriginalMorphs[offsetIdx + idxSlider] + morph) + " (base value is " + OriginalMorphs[offsetIdx + idxSlider] + ")")
			BodyGen.SetMorph(companion, True, SliderNames[idxSlider], kwMorph, OriginalCompanionMorphs[offsetIdx + idxSlider] + morph)
		Else
			Log("    skipping companion slider:  sex=" + sex)
		EndIf
		idxComp += 1
	EndWhile
EndFunction

Function ApplyAllCompanionMorphs()
	Log("ApplyAllCompanionMorphs")
	int idxComp = 0
	While (idxComp < CurrentCompanions.Length)
		BodyGen.UpdateMorphs(CurrentCompanions[idxComp])
		idxComp += 1
	EndWhile
EndFunction




Function RemoveDismissedCompanions(Actor[] newCompanions)
	Log("RemoveDismissedCompanions: " + newCompanions)
	int idxOld = CurrentCompanions.Length - 1
	While (idxOld >= 0)
		Actor oldComp = CurrentCompanions[idxOld]
		If (newCompanions.Find(oldComp) == -1)
			Log("  removing companion " + oldComp)
			CurrentCompanions.Remove(idxOld)
			RestoreOriginalCompanionMorphs(oldComp, idxOld)
		EndIf
		idxOld -= 1
	EndWhile
EndFunction

Function AddNewCompanions(Actor[] newCompanions)
	Log("AddNewCompanions: " + newCompanions)
	int idxNew = 0
	While (idxNew < newCompanions.Length)
		Actor newComp = newCompanions[idxNew]
		Log("  looking for " + newComp + " -> " + CurrentCompanions.Find(newComp))
		If (CurrentCompanions.Find(newComp) == -1)
			Log("  adding companion " + newComp)
			CurrentCompanions.Add(newComp)
			RegisterForRemoteEvent(newComp, "OnCompanionDismiss")
			RetrieveOriginalCompanionMorphs(newComp)
		EndIf
		idxNew += 1
	EndWhile
EndFunction

Event Actor.OnCompanionDismiss(Actor akSender)
	Log("Actor.OnCompanionDismiss: " + akSender)
	int idxComp = CurrentCompanions.Find(akSender)
	If (idxComp > -1)
		CurrentCompanions.Remove(idxComp)
		RestoreOriginalCompanionMorphs(akSender, idxComp)
	EndIf
EndEvent

Actor[] Function GetCompanions()
	Log("GetCompanions")
	Actor[] allCompanions = Game.GetPlayerFollowers() as Actor[]
	Log("  allCompanions: " + allCompanions)
	Actor[] filteredCompanions = new Actor[0]
	int idxFilterCompanions = 0
	While (idxFilterCompanions < allCompanions.Length)
		Actor companion = allCompanions[idxFilterCompanions]
		If (companion.IsInFaction(CurrentCompanionFaction))
			filteredCompanions.Add(companion)
		EndIf
		idxFilterCompanions += 1
	EndWhile
	return filteredCompanions
EndFunction

Function UpdateCompanions()
	Log("UpdateCompanions")
	Actor[] newComps = GetCompanions()
	RemoveDismissedCompanions(newComps)
	AddNewCompanions(newComps)
	Log("  CurrentCompanions: " + CurrentCompanions)
EndFunction




Function TimerMorphTick()
	; get rads (0-1000)
	float newRads = PlayerRef.GetValue(Rads) / 1000.0
	If (newRads != CurrentRads)
		Log("new rads: " + newRads + " (" + CurrentRads + ")")
		CurrentRads = newRads
		; companions
		UpdateCompanions()

		; apply morphs
		int idxSet = 0
		While (idxSet < SliderSets.Length)
			SliderSet sliderSet = SliderSets[idxSet]
			If (sliderSet.NumberOfSliderNames > 0)
				Log("  SliderSet " + idxSet)
				float newMorph
				If (newRads < sliderSet.ThresholdMin)
					newMorph = 0.0
				ElseIf (newRads > sliderSet.ThresholdMax)
					newMorph = 1.0
				Else
					newMorph = (newRads - sliderSet.ThresholdMin) / (sliderSet.ThresholdMax - sliderSet.ThresholdMin)
				EndIf
	
				Log("    morph " + idxSet + ": " + sliderSet.CurrentMorph + " -> " + newMorph)
				If (newMorph > sliderSet.CurrentMorph || !sliderSet.OnlyDoctorCanReset)
					float fullMorph = newMorph
					If (sliderSet.IsAdditive)
						fullMorph += sliderSet.BaseMorph
						If (sliderSet.HasAdditiveLimit)
							fullMorph = Math.Min(fullMorph, 1.0 + sliderSet.AdditiveLimit)
						EndIf
					EndIf
					Log("    morph " + idxSet + ": " + sliderSet.CurrentMorph + " -> " + newMorph + " -> " + fullMorph)
					int sliderNameOffset = SliderSet_GetSliderNameOffset(idxSet)
					int idxSlider = sliderNameOffset
					While (idxSlider < sliderNameOffset + sliderSet.NumberOfSliderNames)
						BodyGen.SetMorph(PlayerRef, true, SliderNames[idxSlider], kwMorph, OriginalMorphs[idxSlider] + fullMorph * sliderSet.TargetMorph)
						Log("    setting slider '" + SliderNames[idxSlider] + "' to " + (OriginalMorphs[idxSlider] + fullMorph * sliderSet.TargetMorph) + " (base value is " + OriginalMorphs[idxSlider] + ") (base morph is " + sliderSet.BaseMorph + ") (target is " + sliderSet.TargetMorph + ")")
						If (sliderSet.ApplyCompanion != EApplyCompanionNone)
							SetCompanionMorphs(idxSlider, fullMorph * sliderSet.TargetMorph, sliderSet.ApplyCompanion)
						EndIf
						idxSlider += 1
					EndWhile
				ElseIf (sliderSet.IsAdditive)
					sliderSet.BaseMorph += sliderSet.CurrentMorph + newMorph
					Log("    setting baseMorph " + idxSet + " to " + sliderSet.BaseMorph)
				EndIf
				sliderSet.CurrentMorph = newMorph
			EndIf
			idxSet += 1
		EndWhile
		BodyGen.UpdateMorphs(PlayerRef)
		ApplyAllCompanionMorphs()
		TriggerUnequipSlots()
	EndIf
	StartTimer(UpdateDelay, ETimerMorphTick)
EndFunction


Function UnequipSlots()
	Log("UnequipSlots: " + UnequipStackSize)
	If (UnequipStackSize <= 1)
		bool found = false
		bool[] compFound = new bool[CurrentCompanions.Length]
		int idxSet = 0
		While (idxSet < SliderSets.Length)
			SliderSet sliderSet = SliderSets[idxSet]
			If (sliderSet.BaseMorph + sliderSet.CurrentMorph > sliderSet.ThresholdUnequip)
				int unequipSlotOffset = SliderSet_GetUnequipSlotOffset(idxSet)
				int idxSlot = unequipSlotOffset
				While (idxSlot < unequipSlotOffset + sliderSet.NumberOfUnequipSlots)
					Actor:WornItem item = PlayerRef.GetWornItem(UnequipSlots[idxSlot])
					If (item.item)
						Log("  unequipping slot " + UnequipSlots[idxSlot] + " (" + item.item.GetName() + " / " + item.modelName + ")")
						PlayerRef.UnequipItemSlot(UnequipSlots[idxSlot])
						If (!found)
							Log("  playing sound")
							LenARM_DropClothesSound.PlayAndWait(PlayerRef)
							found = true
						EndIf
					EndIf
					int idxComp = 0
					While (idxComp < CurrentCompanions.Length)
						Actor companion = CurrentCompanions[idxComp]
						int sex = companion.GetLeveledActorBase().GetSex()
						If (sliderSet.ApplyCompanion == EApplyCompanionAll || (sex == ESexFemale && sliderSet.ApplyCompanion == EApplyCompanionFemale) || (sex == ESexMale && sliderSet.ApplyCompanion == EApplyCompanionMale))
							Actor:WornItem compItem = companion.GetWornItem(UnequipSlots[idxSlot])
							If (compItem.item)
								Log("  unequipping companion(" + companion + ") slot " + UnequipSlots[idxSlot] + " (" + compItem.item.GetName() + " / " + compItem.modelName + ")")
								; companion.UnequipItemSlot(UnequipSlots[idxSlot])
								companion.UnequipItem(compItem.item)
								If (!compFound[idxComp])
									Log("  playing companion sound")
									LenARM_DropClothesSound.PlayAndWait(CurrentCompanions[idxComp])
									compFound[idxComp] = true
								EndIf
							EndIf
						EndIf
						idxComp += 1
					EndWhile
					idxSlot += 1
				EndWhile
			EndIf
			idxSet += 1
		EndWhile
	EndIf
	UnequipStackSize -= 1
EndFunction

Function TriggerUnequipSlots()
	Log("TriggerUnequipSlots")
	UnequipStackSize += 1
	Utility.Wait(0.1)
	UnequipSlots()
EndFunction




Function ShowEquippedClothes()
	Note("ShowEquippedClothes")
	string[] items = new string[0]
	int slot = 0
	While (slot < 62)
		Actor:WornItem item = PlayerRef.GetWornItem(slot)
		If (item != None && item.item != None)
			items.Add(slot + ": " + item.item.GetName())
			Log("  " + slot + ": " + item.item.GetName() + " (" + item.modelName + ")")
		Else
			Log("  Slot " + slot + " is empty")
		EndIf
		slot += 1
	EndWhile

	Debug.MessageBox(LL_FourPlay.StringJoin(items, "\n"))
EndFunction