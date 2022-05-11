# Rad Morphing Redux




## Environment

The setup of this repository assumes the use of 
[Visual Studio Code](https://code.visualstudio.com/) with the 
[Papyrus extension by Joel Day](https://marketplace.visualstudio.com/items?itemName=joelday.papyrus-lang-vscode) 
and Vortex with hardlink deployment. Other environments may work as well but are untested.

The build scripts are written in [Groovy](https://groovy-lang.org/) and are tested in Groovy 
version 3.0.2. Other minor versions of Groovy 3 should not pose a problem, but I have no idea 
if they are compatible with Groovy 4.


## Setup

1. Clone this repository into a temporary folder.
1. Rename the folder as "Data".
1. Create a zip or 7zip file of the "Data" folder, this will be the mod that gets imported in 
Vortex. Give the zip file a descriptive name (e.g. LenARM-DEV or RMR-DEV).
1. Import the zip file in Vortex and install, enable, deploy.
1. Find the mod's folder in Vortex's staging folder (if you're not sure where: right-click the 
mod in Vortex -> Open in File Manager) and open LenARM.code-workspace (VS Code workspace file).
1. Open `/Scripts/Source/User/fallout4.ppj.sample` and update the `Import` paths. Save the file 
as `fallout4.ppj`.


## Structure

```
/
├── .fomod/                                  contents for the final FOMOD file to be published
├── .options/                                optional content for the FOMOD
├── .vscode/                                 VS Code configuration
├── F4SE/                                    F4SE DLLs (FourPlay library)
├── MCM/                                     
│   ├── config.json                          compiled MCM config
│   ├── config.sliderSet.page.tpl.json       template for a slider set page
│   ├── config.sliderSet.tpl.json            template for the slider set part of a slider set page
│   ├── config.tpl.json                      root template for the MCM config
│   └── settings.ini                         default MCM values
├── Scripts/                                 
│   ├── LenARM/                              compiled .pex files
│   └── Source/                              
│       ├── User/                            
│       │   └── LenARM/                      
│       │       ├── LenARM_API.psc           API script
│       │       ├── LenARM_Debug.psc         debug functions (logging etc.)
│       │       ├── LenARM_Main.psc          main script, entry point for this mod
│       │       ├── LenARM_SliderSet.psc     slider set logic
│       │       └── LenARM_Util.psc          utility functions (e.g. string splitting)
│       ├── BodyGen.psc                      definition of BodyGen functions
│       ├── fallout4.ppj.sample              Papyrus project file for Papyrus extension
│       └── LL_FourPlay.psc                  definition FourPlay library functions
├── .version                                 current version number
├── bumpVersion.groovy                       script to change version number
├── copyToFomod.groovy                       script to copy all content to .fomod folder
├── createMCM.groovy                         script to build MCM config.json from template files
├── LenA_RadMorphing.esp                     this mod's Bethesda Plugin
├── LenARM.code-workspace                    VS Code workspace configuration
└── README.MD                                this readme file
```

The ESP has a single quest `LenARM_Main` and a message `LenARM_HealMorphMessage`. All scripts 
are attached to the quest.


## Workflow

Launch Vortex, open the workspace in VS Code, and open the ESP in Creation Kit (set the ESP as 
active file).

Edit the scripts in VS Code and compile in Creation Kit.

Most of the time Vortex / the hardlinks seem to keep the psc files in sync, however, sometimes 
you may have to manually deploy with Vortex. You will certainly have to manually deploy and 
then resolve conflicts (check single files and keep changes / use deployed version) to get the 
compiled pex files and updated esp back into your development directory.

After making changes to the MCM files (json templates, or settings.ini), run `createMCM.groovy`
to compile these into the files used by MCM. The values from region `[Slider0]` in settings.ini 
will be used as default values (written to settings.ini) for all slider sets when compiling.

To change the version number, run `bumpVersion.groovy` and enter the new version number in 
the prompt that pops up. This will update the version number in all relevant places. Then 
recompile the psc scripts, to make sure the return value of `GetVersion()` in `LenARM_Main.psc`
is updated in the compiled pex files.


## Releasing a new version

1. Run `bumpVersion.groovy` to change the version number
1. Recompile the papyrus scripts
1. Run `copyToFomod.groovy` to copy all relevant files into the FOMOD directory
1. Zip/7zip the contents of the `.fomod` folder as `LenA_RadMorphing_vXX.YY.ZZ.7zip` where 
`XX.YY.ZZ` is the new version number