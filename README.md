# iAPS with autoISF

## Introduction

iAPS - an artificial pancreas system for iOS based on [OpenAPS Reference](https://github.com/openaps/oref0) algorithms (Master 0.7.1) and Ivan Valkous stale Swift repo, freeaps.git.

Thousands of commits later, with many new and unique features added, the iOS app has been renamed to iAPS under a new organisation, Artificial Pancreas. iAPS uses lot of frameworks published by the Loop community.


# autoISF
The autoISF branch is based on dev from the original [iAPS repo](https://github.com/artificial-pancreas/iaps) and includes my implementation of [autoISF by ga-zelle](https://github.com/T-o-b-i-a-s/AndroidAPS) for AAPS and some other extra features. autoISF is off by default.

autoISF adjusts ISF depending on 4 different effects in glucose behaviour that autoISF checks and reacts to:
* acce_ISF is a factor derived from acceleration of glucose levels
* bg_ISF is a factor derived from the deviation of glucose from target
* delta_ISF and pp_ISF are factors derived from glucose rise, 5min, 10min and 45min deltas and postprandial time frames
* dura_ISF is a factor derived from glucose being stuck at high levels

## AIMI B30
Another new feature is an enhanced EatingSoon TT on steroids. It is derived from AAPS AIMI branch and is called B30 (as in basal 30 minutes).
B30 enables an increased basal rate after an EatingSoon TT and a manual bolus. The theory is to saturate the infusion site slowly & consistently with insulin to increase insulin absorption for SMB's following a meal with no carb counting. This of course makes no sense for users striving to go Full Closed Loop (FCL) with autoISF. But for those of you like me, who cannot use Lyumjev or FIASP this is a feature that might speed up your normal insulin and help you to not care about carb counting, using some pre-meal insulin and let autoISF handle the rest.

To use it, it needs 2 conditions besides setting all preferences:
* Setting a TT with a specific adjustable target level.
* A bolus above a specified level, which results in a drastically increased Temp Basal Rate for a short time. If one cancels the TT, also the TBR will cease.

## Ketoacidosis protection
Ketoacidosis protection will apply a small configurable TempBasalRate always or if certain conditions arise instead of a Zero temp! The feature exists because in special cases a person could get ketoacidosis from 0% TBR. The idea is derived from sport. There could be problems when a basal rate of 0% ran for several hours. Muscles in particular could shut off.

This feature enables a small safety TBR to reduce the ketoacidosis risk. Without the Variable Protection Strategy that safety TBR is always applied. The idea behind the variable protection strategy is that the safety TBR is only applied if sum of basal-IOB and bolus-IOB falls negatively below the value of the current basal rate and that current isulin activity is below 0.

## Exercise Modes & Advanced TT's
Exercise Mode with high/low TT can be combined with autoISF. The ratio from the TT, calculated with the Half Basal Exercise target, will be adjusted with the strongest (>1) or weakest (<1) ISF-Ratio from autoISF. This can be substantial. I myself prefer to disable autoISF adjustments while exercising, relying on the TT Ratio, by setting `Exercise toggles all autoISF adjustments off` to on.
There was some discussion how to implement the excercise targets with configurable half basal exercise target variable and a specific desired insulin ratio in iAPS. This requires highTTraisesSens and lowTTlowersSens setting. In this implementation, which is a little different than in iAPS, you first define at which TT level you want to be. Frome this the available insulin percentages are derived:
* with a TT above 100mg/dL you can only have a insulin percentage below 100% (more sensitive to insulin while exercising)
* If you don't have the setting exercise mode or highTTraisesSens enabled, you will not be able to specify an insulin percentage below 100% with a high TT.
* with a TT below 100 mg/dL you can have an Insulin ratio above 100% (less sensitive to insulin) but less than what your autosens_max setting defines. E.g. if you have autosens_max = 2, that means your increased insulin percentage can be max. 200%.
* If you have lowTTlowersSens disabled or you have autosens_max=1, you cannot specify a percentage >100% for low TTs.

If you do have the appropriate settings, you can chose an insulin ratio with the slider for the TT you have set and the half basal exercise target will be calculated and set in background for the time the TT is active.

## Screen Shots

on iPhone 13 mini:

<img src="iAPS_iPhone_01.png"
     alt="standard"
	 width=350
	  />
<img src="iAPS_iPhone_02.png"
     alt="autoISF results"
	 width=350
	 />
<img src="iAPS_iPhone_03.png"
     alt="advanced exercise TTs"
	 width=350
	 />
<img src="iAPS_iPhone_04.png"
     alt="advanced exercise TTs - missing prefs"
	 width=350
	 />
<img src="iAPS_iPhone_05.png"
     alt="autoISF history"
	 width=350
	 />
<img src="iAPS_iPhone_06.png"
     alt="LockScreen Live Activity Widget"
	 width=350
	 />

Watches:

<img src="iAPS_AppleWatch_01.png"
     alt="AppleWatch iAPS"
	 width=200
	 />
	 <img src="iAPS_AppleWatch_02.png"
     alt="AppleWatch watchface"
	 width=200
	 />
<img src="Garmin_DataField.png"
     alt="Garmin screen"
	 width=200
	 />

# Install
For multiple alternative installation methods refer to to the parent repository and its [ReadMe File](https://github.com/Artificial-Pancreas/iAPS/tree/dev#readme). This branch does not deviate from it.

### Please understand that iAPS and especially autoISF is:
- highly experimental and evolving rapidly.
- not CE approved for therapy.

# Changes

Latest version of original iAPS is maintained by Jon and the now departed gang . It brings significant improvements for Omnipod Dash pumps and Dexcom G6 and G7sensors, Statistics, Automations with Shortcuts, Garmin watch and a lot of cool things that make you go Uuh. Looping should be immediate and robust. UI is based on the non-implemented proposals by Dan and the gang before iAPS3.0.

[iAPS repo github](https://github.com/artificial-pancreas/iaps.git)

## autoISF Version
Refers to the changes done to the original oref0 used in FAX, the source can be found at my [oref0-repository](https://github.com/mountrcg/oref0). Also testing autoISF 3.0 adaption

* 3.0
	* IOB threshold changed to percent of maxIOB
 	* adaptable SMB  threshold for low BG's
 	* remove setting for maxDelta BG Threshold and automate it for fullLoop
  	* align log and pop-up panel messages  with AAPS version
  	* some 1min Libre values precautions for acce predictions
  	* NO Activity Tracking as with AAPS
* 2.2.8.3
	* AIMI B30 feature
	* dev release with current mods as of Mar 23, 2023
	* documentation at https://github.com/ga-zelle/autoISF

## Release
Refers to iAPS, which is currently mainly improved by Jon & Pierre at this [github repository](https://github.com/Artificial-Pancreas/iAPS).
I had to disable Overrides/Profiles from the original iAPS, as Jon does not publish the necessary oref code - you would have to use the original if you need it.
Also note that you can achieve almost everything that Profiles do with the Advanced TempTarget and thenecessary settings in preferences.  However, Profiles are a cool feature and easier to handle, just not here in this branch.

* 3.6.2
	* Split out Preferences for AIMI B30
	* Contact Trick improvements by [Yurique](https://github.com/Yurique/)
	* more and revamped Shortcuts by [@avouspierre](https://github.com/avouspierre/)
	You can now check your alarms with shortcuts and automations (I do that at 1:00am) and set a TempTarget in the future - all offline. Love it for automating Morning Runs.
	* looping indicator with [@ABloodyDiabetic](https://github.com/ABloodyDiabetic/)
	* re-instate Apple watch app with TDD
	* harmonize CGM and Pump config view
	* latest bugs fixed by Jon
* 3.6 - will resett all oref1 & autoISF settings to default values
    * DANA RS and -i integration by [@bastiaanv](https://github.com/bastiaanv/iAPS)
	* KetoProtection
		* with a percentage or absolute small basal rate
		* always or depending on IOB and Insulin activity
	* more shortcut and refactoring by avouspierre
	* ContactTrick for AppleWatch by [Yurique](https://github.com/Yurique/)
	* oref fixes
* 3.3
	* get on par with stock iAPS (Jon keeps still cranking out great features) re.
		* data structure as introduced with and after 3.0
			* Overrides still not available but all graphics and data is prepared
		* various dash improvements and bug fixes
		* shortcuts for Bolus & Overrides as in stock iAPS (ofc overrides won't do anything)
		* fastlane improvements
	* tap Bolus Progress Bar for popup
	* Live Activity with charts thanks to [@nas10](https://github.com/10nas/iAPS.git), [@marvout](https://github.com/polscm32/iAPS.git), [@dnzxy](https://github.com/dnzxy/iAPS), [@Andreas](https://github.com/AndreasStokholm/iAPS.git)
	* oref bug fixes
* 2.3.2
	* introduce autosens toggle in oref1 and autoISF prefs. It allows to switch autosens off when not logging any carbs. autosensMax/Min can still be set to !=1, to allow TT setting low sensitivity (uses autosensMax as limiter)
 	*  bug fixes
* 2.3.1
	* fix missing Oref1 preferences for SMB's
	* again 2 decimal digits for bolus in chart (dash relevant)
 	* many experimental UI/UX changes and features from the active team around Jon, [nas10](https://github.com/10nas/iAPS.git), [@marvout](https://github.com/polscm32/iAPS.git), [@dnzxy](https://github.com/dnzxy/iAPS), [@Andreas](https://github.com/AndreasStokholm/iAPS.git)
  		* smaller time scale panel
 		* Live Activity with Charts
  		* advanced calculator overhaul
* 2.2.9
	* refer to [original release notes](https://github.com/Artificial-Pancreas/iAPS/releases)
	* many neat things from Jon & Team, as
		* History table overhaul
			* with some changes from my side
			* also you swipe to delete by [@dnzxy](https://github.com/dnzxy/iAPS)
		* alternative bolus calculater
		* new Omnipod Dash kit
		* changes to the graph with offset manual Bolus, SMB and external Bolus
	* many bug fixes
	* re-ordering of Preferences, splitting out oref1 & autoISF settings
* 2.2.3
	* refer to [original release notes v2.2.3](https://github.com/Artificial-Pancreas/iAPS/releases/tag/v2.2.3)
* 2.2.2
	* FPU on AppleWatch
	* Bug fixes
		* TIR display
		* Target Glucose on new Profile in mmol/L
		* sorting added to the announcements array to guarantee that the variable 'last' actually gets the latest announcement
	* euglycemic range & autoISF algo to optional statistics.json
* 2.2.1
	* Bolus Calculator based on EventualBG
	* and many more refer to [original release notes]( https://github.com/Artificial-Pancreas/iAPS/releases/tag/v2.2.1)
* 2.0.1
	* many localizations and crowdin re-ntegration
	* Overrides/Profile adaptions in iAPS, disabled in autoISF branch as oref Code not published to incorporate with autoISF
* 1.6.0
	* Garmin watch
	* Automation
	* new Statistics page
* 1.2.1
	* Loop Framework 3.2
	* TempTarget changes for Slider & Rounding
* 1.1.1
	* ExerciseMode calculation with InsulinRatio Slider
	* Tag changes in Popup
	* display ratio from TempTargets in InfoPanel
* 1.1.0
	* Meal presets
	* oref fixes
	* G7 smoothing
* 1.09
	* Allow to delete Carbs when connexion with NS is impossible - Alert the user of the issue. (#606), Pierre Avous.
	* Put back DASH strings deleted in Loop3 branch
	* Reverts oref0 commit. Scott Leibrand. Revert "fix(lib/iob): Move value checks up to index.js". Fix for too high predictions.
	* Synchronise upload readings toggle in dexcom settings with FAX settings (#608), Pierre Avous.
	* LibreView
* 1.08
	* Fat Protein conversions
	* AppleHealth Integration, good for manual BG values
	* fixes MDT and G6
* 1.07
	* Dash & G7 frameworks from Loop3
	* CoreData refactoring

## Build Automation with Fastlane
The autoISF branch in your fork can be synched to my Repo. Automated sync of your fork before building (fastlane) requires setting a SCHEDULED_SYNC repository variable to 'true' in your Repo. I have switched on the cron task in `build.yml` on every Wednesday at 8:00 UTC to check for updates and build if any found. It also builds if you yourself push a commit to github.

## Remarks
Due to the heavy refactoring and my changes to Jon's CoreData, when moving from a version (below 1.07) to (1.07 or above) it is advised to delete FAX and install with a new clone. All current stats will be gone and build up again. All settings will be at default values, like `maxIOB = 0`. Due to deleting FAX you should do it in between pods, as you loose this information. Now with iAPS starting v1.6 and autoISF 2.2.8.3 also all settings will revert to standard.

# Documentation

For all the relevant notes for iAPS please refer to to the parent repository and its [ReadMe File](https://github.com/Artificial-Pancreas/iAPS/tree/dev#readme).

Most of the changes for autoISF are made in oref code of OpenAPS, which is minimized in iAPS. So it is not really readable in Xcode, therefore refer to my [oref0-repository](https://github.com/mountrcg/oref0/tree).

[Documentation of autoISF implementation for AAPS](https://github.com/ga-zelle/autoISF) is applicable for iAPS as Algorithm is 100% identical

[AAPS autoISF Branch](https://github.com/T-o-b-i-a-s/AndroidAPS)

