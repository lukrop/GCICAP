# GCICAP
Autonomous GCI and CAP script for DCS: World.

## Overview
Originally created by Snafu and then further enhanced by Stonehouse, Chameleon Silk, Rivvern. Rewritten by lukrop.

The script provides an autonomous model of combat air patrols and ground controlled interceptors for use with DCS World by mission builders. After minimal setup the script will automatically spawn CAP and GCI flights for two sides and give them patrol and intercept tasks as well as returning them to base when threats cease to be detected.

### TOC
* [Overview](#overview)
  * [TOC](#toc)
* [Requirements](#requirements)
* [Rewrite changes](#rewrite-changes)
* [How to use](#how-to-use)
  * [CAP zones](#cap-zones)
  * [Template units](#template-units)
  * [Borders](#borders)
* [API](#api)
  * [Flights](#flights)
* [Further reading](#further-reading)


## Requirements
At the time of writing this script requires the development version of MIST.
Download it here https://github.com/mrSkortch/MissionScriptingTools/blob/development/mist.lua

## Rewrite changes
This is a rewrite of Stonehouse's version but it's written with backwards compatibility in mind. In the best case you should be able to use it in your mission as a drop-in replacement for the original version. The main differences to the original are:

* GCI messages can be displayed only to given groups (not every helo pilot will want to know about intruders that often, probably).
* If a CAP flight is closer to the intruder than the airfield an interceptor would start from, it gets tasked with the intercept. In return if a airfield is closer the GCI would start, even if there are CAP flights active.
* GCI flights will only use their radar to attack (not for searching) since they are guided from the ground which makes them stealthier and should make them more deadly.
* You can choose the maximum distance a CAP flight would divert from it's route to engage any enemys. This is useful if used without borders but overlapping radar coverage. This distance doesn't affect any intercept missions a CAP flight might get tasked with.
* Choose the amount of waypoints a CAP flight has in the CAP zone.
* Some more options/variables.
* Simultaneously active groups fixed.
* Almost all options/variables can be set for each side differently.
* It's possible to choose any type of unit for the group whose waypoints define a border line.
* Optionally also use AWACS aircraft for target acquisition.
* Currently it's missing the cleanup functionality around airfields on the ground, because I want to solve the problem slightly different.
* some major performance improvements as well as about 4000 lines less than the original :eyes: :dash: :smile:

## How to use
To use this script in a mission you need to add a trigger which executes this script after the mission start (eg. *TIME MORE 2*). Make sure it is also executed **after** MIST. Have a look at the sample mission if you are not sure about the trigger.

### CAP zones
You'll need to define triggerzones in which the units, spawned by the script, will conduct combat air patrols. The default name for the triggerzone is `sideCAPzone#` where *side* is either *red* or *blue* and "#" is the number of the zone. So for example you would have `redCAPzone3` as a name for you third CAP zone of red. If you don't like the default you can change the name, which will be prefixed by the number. Change `gcicap.red.cap.zone_name` and `gcicap.blue.cap.zone_name` accordingly.

The size of the triggerzone will also define the size of the CAP zone. The route of the CAP flight will only have waypoints inside the triggerzone so choose the size with that in mind. I'd recommend a radius of about 30.000 to 50.000 meters.

### Template units
By default the script needs *four* template units which define what aircraft are spawned by it. The template unit's type, livery, loadout and skill are used as template for each aircraft spawend by the script. Keep in mind that the aircraft needs to be able to conduct CAP/GCI missions. Choose CAP as the Task for the group. You can name the group anything you like but you need to give the unit (pilot) a name the script knows. You can go either by the default, left for backwards compatibility: `__GCI__side#` for GCI flights and `__CAP__side#` for CAP flights, eg. `__GCI__blue1` for the first blue GCI template unit. Or you choose to set `gcicap.gci.template_prefix` or `gcicap.cap.template_prefix` to a different string. The name will be postfixed with the side and number.

You can also choose the amount of template units you want to have by changing `gcicap.template_count`. Keep in mind that if you use the default of `gcicap.template_count = 2` you'll need two GCI and two CAP template units for each side (eight units in total).

The script will choose one template unit as template at random for each group it spawns. Don't forget to set the template units/groups to *LATE ACTIVATION* so they don't show up in the mission.

### Borders
If you choose to use borders the CAP flights will only engage enemy groups, detected by ground or air radar (EWR/AWACS), if they penetrated the border. Keep in mind that they will engage targets also if they are close enough. In this case you might need to adjust `gcicap.cap.max_engage_distance`. This is the maximum distance the group will divert from it's assigned route to engage targets.

To use borders you need to set `gcicap.red.borders_enabled = true` for the appropriate side. You can also enable borders for one side only. If you choose to enable borders you need to place a group whose waypoints build a polygon which defines the borders. The group needs to have the name defined in `gcicap.red.border_group` or `gcicap.blue.border_group`. The default is `redborder` for red and `blueborder` for blue. Don't forget to set the group to *LATE ACTIVATION* so it doesn't show up in the mission.

## API
You might want to checkout the [API documentation here](https://lukrop.github.io/GCICAP/doc/).

### Flights
Internally this script is using LUA tables to keep track of the units/groups spawned by it. They are called flights. I'll write something up soon, to explain their structure. In the meanwhile you can check them out in the source code. ;-)

## Further reading
You might want to have a look at the great [GCI CAP User Guide](https://github.com/457Stonehouse/GCICAP/blob/Interim/GCI%20CAP%20User%20guide.pdf) provided by Stonehouse. Most of it's contents still apply to this script.
