# Rad Morphing Redux v2
Extensible Body Morphing Framework


Rad Morphing Redux reacts to external triggers and modifies LooksMenu sliders on your (or your companion's) body based on the values provided by those triggers.

Pretty much every aspect of the mod can be configured via MCM (which sliders to change, by how much, thresholds for the trigger values, unequipping of clothes, ...).

Originally, all morphing was done based on the player's radiation (hence the name Rad Morphing), but the mod has now been extended to allow input from any other mod instead. That means you could apply morphs not just based on radiation, but also SPECIAL stats, health, Sex Attributes, calorie intake, weather, addictions... as long as a mod provides the respective triggers.

---

Based on the mod [Rad Morphing](https://www.loverslab.com/files/file/11586-rad-morphing/) by @Invictusblade.

Cover image on LoversLab graciously provided by @Narsdarknest

---

**By default this mod is disabled.**  
**You need to open MCM to configure and enable it.**




---




## Getting Started




### Dependencies

- [MCM](https://www.nexusmods.com/fallout4/mods/21497) to configure the mod
- [LooksMenu](https://www.nexusmods.com/fallout4/mods/12631) to apply morphs
- A BodySlide compatible body (any body that can be modified with BodySlide / LooksMenu will work)
- All clothes must be built with morphs enabled in BodySlide
- [F4SE](https://f4se.silverlock.org/) *0.6.23* for Fallout 4 *1.10.163*
- At least one RMR trigger (e.g. RMR Rads Trigger)




### Conflicts

The mod comes with the [LL_FourPlay library](https://www.loverslab.com/files/file/4317-devtestbeta-ll-fourplay-community-f4se-plugin-v42-2021-09-13/) (LL_FourPlay.pex/psc/dll) that is also included in other mods (e.g., AAF). When your mod manager complains about a conflict I would suggest letting AAF overwrite this file.




### Integration

- [Combat Strip Lite](https://www.loverslab.com/files/file/5275-combat-strip-lite-1262020/) or [Combat Strip Lite, Sound Replacer (Ripping Sounds)](https://www.loverslab.com/files/file/5388-combat-strip-lite-sound-replacer-ripping-sounds/)  
Installing either of these mods (or both) allows Rad Morphing Redux to play a sound from that mod when clothes are removed due to rads.
- Devious Devices will not be unequipped by this mod.




### Installing

Install with your mod manager of choice. The FOMOD installer asks you how many slider sets you want to have available and lets you pick an optional default slider configuration for a couple of different bodies.  
Unless you're already familiar with RMR and know how many slider sets you need, I would suggest starting with 10 to keep the MCM small. You can always re-run the installer and increase the number of slider sets later.

**By default this mod is disabled through MCM.**  
**You need to open MCM to configure and enable Rad Morphing Redux before it does anything.**




### Uninstalling

Before uninstalling, disable this mod in MCM to restore the original body. If you uninstall without disabling the mod first in MCM you will be stuck with a morphed body.




### Triggers

Rad Morphing Redux does nothing on its own. You must install a mod that provides a trigger for this mod to be able to do anything.

- RMR Rads
- RMR SPECIAL




---




## Configuration

The FOMOD installer comes with default settings for Atomic Beauty, CBBE, Fusion Girl, and Jane Bod. However, you can configure it to your liking through MCM with up to 50 sets of sliders with individual morphing strengths and ranges. By using the RMR Helper or editing the MCM ini file you can use even more slider sets.

Start or load a game, pause, open **MCM**, and select **Rad Morphing Redux**.


### General Settings

- **Enable Rad Morphing Redux**  
Enable or disable Rad Morphing Redux. On disabling RMR, the original body is restored.
- **Display disabled warning**  
Whether to display a warning message when you load a game with RMR disabled. This only really exists as a notice for first installs, since RMR is disabled by default.
- **Reload MCM settings**  
Reload all settings from MCM. Use this if you have modified the settings outside of the game (e.g., by using RMR Helper or directly editing the ini file) or made changes in another savegame.
- **Morph Updates**
	- **Update delay**  
	Seconds between morph updates when *Update Type* is set to *Periodically*.
- **Companions**
	- **Restore companion morphs when dismissed**  
	Whether to restore morphed companion bodies to their original body when dismissing them.
- **Healing (permanent morphing)**
	- **Caps to heal 1% of morphs**  
	Number of caps to heal 1% of morphs at a doctor. This only applies when permanent morphing (only doctors can reset morphs) is enabled.


### Global Overrides

Settings made in this section will override all individual settings on the slider set pages. Descriptions for each setting can be found further down.

- **Permanent Morphs**
	- **Only doctors can reset morphs**
	- **Additive morphing**
	- **Limit additive morphing**
	- **Additive morphing limit**


### Debug Tools

- **Enable logging**  
If you experience any problems with RMR, please enable logging and provide your papyrus log when reporting your issue.


### Slider Set *X*

Use the slider sets to configure how the body should be morphed when a trigger changes. A slider set is a group of sliders (or a single slider) that react the same way when their trigger value changes.

- **Click to show worn clothes**  
Click this button to see a list of currently equipped items and their slot numbers.
- **Sliders**
	- **Slider names**  
	Enter the names of the sliders that should be affected. When entering multiple sliders, separate them with `|` (e.g., `Boobs Yuge|Bum Chubby`).  
	Unfortunately you cannot just use the labels shown in BodySlide as the game needs the internal name / keyword of the slider. You can look these up in the body's `SliderCategories` XML file, found in `.../Data/Tools/BodySlide/SliderCategories/`.  
	Each slider has a `name` and a `displayname` attribute. The `displayname` is the label shown in BodySlide while `name` is the internal name that you have to enter in MCM.  
	One example from Fusgion Girl (ZeX-FusionG.xml): `<Slider name="Boobs Yuge" displayname="Breast Size (Larger)" />`  
	The internal name for the slider labeled `Breast Size (Larger)` in BodySlide is `BoobsYuge`. So `BoobsYuge` is what you need to enter in MCM if you want this slider to change.
- **Targets**
	- **Apply to**  
	Whether to apply this slider set to only the player, only companions, or player and companions.
	- **Sex**  
	Whether to apply this slider only to female characters, only to male characters, or to both.
- **Trigger**
	- **Trigger name**  
	Choose the trigger that you want to base the morphs for this slider set on.
	- **Invert trigger**  
	When inverting the trigger value, morphs will take full effect when the trigger value reaches 0% and no effect at 100%.  
	This would allow for example to apply morphs as the player's HP goes down (i.e., no morphs at 100% HP, full morphs at 0% HP).
	- **Update type**  
	Whether to update immediately when the trigger sends an update, periodically every X seconds (see *Update delay* in *General Settings*), or after you sleep.  
	When this is set to *After sleeping*, morphs will according by the current trigger value everytime you go to sleep; i.e., after sleeping four times with a trigger value of 25% morphs will reach 100%. This way, only doctors will be able to reset your morphs, as a 0% trigger only means that no additional morphs will be added.
- **Size**
	- **Target size increase**  
	How much the slider will change when the trigger value reaches its maximum.  
	These are absolute perentage points, not percentage of the current slider value. If the slider on your onmorphed body is at 50% and target size increase is set to 100% the slider will end up at 150% when fully morphed. When set to -100% it will end up at -50% when fully morphed.
	- **Lower threshold**  
	Percentage of the trigger value at which morphing should start. While the trigger value is lower than this, no morphs will be applied.
	- **Upper threshold**  
	Percentage of the trigger value at which morphing should end. While the trigger value is higher than this, full morphs will be applied.
- **Unequipping**
	- **Armor slots to unequip**  
	Enter the numbers of the armor slots to unequip when the unequip threshold is reached. Separate multiple slot numbers with `|` (e.g., `9|11|15`). You can only equip the items again once the morphing is again below the threshold.  
	To see what you have currently equipped, use the button labeled "Show worn clothes" at the top of the slider set config page.
	- **Unequip threshold**  
	When x% of the morphing target is reached, the above slots will be unequipped. This is a percentage value that refers to the target size increase.
- **Permanent morphs**
	- **Only doctors can reset morphs**  
	With this option enabled, the body will not restore its original shape on its own when the trigger values goes down again. You will have to visit a doctor to restore your mody.
	- **Additive morphing**  
	If enabled, morphs are added every time the trigger value increases, even if the trigger value decreases in between. This can lead to reaching a fully morphed body without a 100% trigger value, or even morphing beyond the target size increase.  
	Example with rads as trigger: You take 50% radiation and get morphed to 50% of your target size increase. You reduce rads to 20% (no morph change due to permanent morphs / only doctors can reset). You take some more rads and are now back up to 30% and morph a further 10% to 60% of the target size increase.
	- **Limit additive morphing**  
	If enabled, you can limit how far additive morphing can exceed the target size increase.  
	If disabled, there is no limit and you can morph until Fallout crashes... I would keep this enabled.
	- **Additive morphing limit**  
	Percentage how far additive morphing can exceed the target size increase.  
	0%: morphing will stop once the target size increase is reached.
	100%: morphing will stop once 2x the target size increase is reached.




---




## Tips




### How to restore your original body if you are stuck with a morphed body

If you are stuck with a morphed body you can follow the below steps to restore your original BodySlide preset.

Requirements:

- [Looksmenu](https://www.nexusmods.com/fallout4/mods/12631)
- [BodySlide](https://www.nexusmods.com/fallout4/mods/25)
- [BodyConvert](https://www.nexusmods.com/fallout4/mods/41781)

1. Open the **console** and type `showlooksmenu 14` to open the player's **looksmenu**
1. Select **PRESETS**
1. Select **SAVE**
1. Enter a name that is not already on the list
1. Exit the looksmenu (I don't know if this is fully necessary but it can't hurt) by selecting **BACK** and then **DONE**
1. **Alt-TAB** out of Fallout to your **desktop**.
1. Find the **BodySlide** `.xml` file of the **preset** that you originally used for your player and now want to restore in `...\Data\tools\BodySlide\SliderPresets`
1. Open that file with a **text editor** (e.g. Notepad, Notepad++, VS Code; *not MS Word* or other word processors!)
1. **Copy** everything
1. Open **BodyConvert**
1. **Paste** the contents of the BodySlide file into the **BodySlide (XML)** section
1. Click on **ToBodyGen**
1. Click on **ToBodyMorph**
1. **Copy** everything from the **BodyMorph (JSon)** section
1. Find the `.json` file of the **looksmenu preset** that you just saved in `...\Data\F4SE\Plugins\F4EE\Presets`
1. Open that file with a **text editor**
1. Find the **BodyMorphs** part of the file. `"BodyMorphs": { lots of lines... }`,
1. **Replace** that block with the content you copied from BodyConvert
1. **Save** the file
1. **Switch back** to Fallout 4
1. Open the console and type `showlooksmenu 14` to open the player's **looksmenu**
1. Go to **PRESETS**
1. Select the **preset that you saved and edited earlier**, select **LOAD**, then **BACK**, and finally **DONE** to exit looksmenu



### Creating a new trigger

Rad Morphing Redux provides an API for other mods (like triggers) to interact with RMR.

- Get a reference to the API `Game.GetFormFromFile(0x4C50, "LenA_RadMorphing.esp") as LenARM:LenARM_API`
- When first running your trigger mod, register your trigger name with RMR by calling `RegisterTrigger("YourTriggerName")`.
- Call `UpdateTrigger("YourTriggerName", value)` with `value` as float between `0.0`(0%) and `1.0` (100%) to update the trigger value.
- Register for the `OnStartup` and `OnShutdown` events to keep track of RMR's state and avoid wasting resources while RMR is inactive.
- Register for the `OnRequestTriggers` event. Re-register your trigger name and provide the current value whenever this event is raised.

For more details have a look at the Rads and SPECIAL triggers. The full source code is included in each mod and also available on GitHub.

- Rads Trigger | [GitHub](https://github.com/LenAnderson/RMR-Trigger-Rads)
- SPECIAL Trigger | [GitHub](https://github.com/LenAnderson/RMR-Trigger-SPECIAL)





### Source Code

All source code is included with the mod and also available on [GitHub](https://github.com/LenAnderson/LenA_RadMorphing).




---




## Changelog