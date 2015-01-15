# GCICAP
Autonomous GCI and CAP script for DCS World

Originally created by Snafu and then further enhanced by Stonehouse, Chameleon Silk, Rivvern.

**Note requires MIST 3.5.37 or later. Download it here https://github.com/mrSkortch/MissionScriptingTools/releases/tag/3.5.37

# Overview
The script provides an autonomous model of combat air patrols and ground controlled interceptors for use with DCS World by mission builders. After minimal setup the script will automatically spawn CAP and GCI flights for two sides and give them patrol and intercept tasks as well as returning them to base when threats cease to be detected.

Version: b6_5x
requires MIST3.5.37 or later by Grimes and Speed
Modifications for b6_1x by Stonehouse, Rivvern, Chameleon Silk May-July 2014 
Modifications for b6_2x by Chameleon_Silk with some bug fixes by Stonehouse 
Modifications for b6_3x by Stonehouse 7 July 2014  
Modifications for b6_4x by Stonehouse 10 July 2014  
Modifications for b6_5x by Stonehouse 2 August 2014  
Modifications for b6_6x by Stonehouse 9 August 2014  
Modifications for b7 by Stonehouse 7 September 2014  
Modifications for b8 by Stonehouse 16 September 2014  
Modifications for b9 by Stonehouse 20 October 2014  

*******************************************************************************************************************************
* Change log
*******************************************************************************************************************************

74t: 	-added do-end block and disable debugging message env.
b4: 	-CAP tasks ROE set to Return fire and task of "generatetask" modified to set ROE to OPEN FIRE WEAPON FREE
b5: 	-added option for CAP and interceptors to take off from runway, suggested by "Quip",
		-added option to limit number of interceptors spawned, if a certain amount of intercepts are ongoing
		-added function which shall remove AI plane/helicopter groups, which have a damaged unit on the ground in the trigger zones created around the airfields
b5_1: 	-corrected counter for spawn limiter
b5_2: 	-corrected the correction, thanks to eric963
b6t: 	testing version: -changed waypoint alt type from BARO to RADIO
		-first CAP in mission will spawn in air in the CAP zone
		-randomized flight size of the CAP and interceptor flights, they will now consist randomly either of 4 or of 2 planes or of choice, GCI might also spawn in the same size as the intruder group
b6_1x 	-fixed runway usage
		-spawns and way points now consider terrain height
		-bort numbers on aircraft
		-logic around airbase selection corrected
		-numberofspawnedandactiveinterceptorgroups initialisation
		-parameterise hiding of enemy aircraft for both sides
		-attempt to improve scope of some variables
		-added table of correct airfield names that are available to use above
		-changed back using BARO
b6_2x 	-added interceptor and CAP country parameter
		-added min and maximum CAP and intercept altitude parameter
		-fixed numberofCAPzones and Spawnmode capitalisation. Particularly Spawnmode where original script incorrectly used spawnmode at times.
		-added parameter to change behaviour of first wave of fighters at mission start	
b6_3x 	-fixed GCI aircraft so they use spawn mode
b6_4x 	-increased airbases to 4 to try and avoid taxiway problems and increase dynamics of mission, 
		-added logic to handle AI aircraft stuck on taxiways, 
		-changed scheduling of interceptmain to try to minimise taxiway problems
		-commented out the mist.tableShow lines as they are for debugging and might affect performance
b6_5x 	-added GCI bandit calls to players when a border violation is confirmed. Bearing & range to bullseye and ASL altitude given.
		-Revised scheduling of interceptmain again to a higher frequency
b6_6x   -Add parameterised skill for CAP and GCI pilots by side	
b7		-Make borders and border violation checks optional via the noborders variable, 
		-fix stuck aircraft time, 
		-add CAP and GCI template handling so these aircraft are now defined in the mission editor not the script and all types, skill and skin are taken from these template aircraft 
		removing the need for multiple versions and editing the script. 
		-Increased blue cap and gci planes to 4 to simplify logic and align blue and red sides.
		-corrected original logic so that aircraft manually placed in the mission editor, player aircraft and late activation aircraft are not picked as being available for interception tasks
b8		-pick up airbase info from map so users no longer need to edit script and also makes it possible to have different airbase setups for each side, add helos as possible targets, pick up country for red and blue cap and gci 
		aircraft from the 16 template aircraft. Note that this means theoretically, assuming you have set it up in the mission editor, that you can have 8 countries per side for aircraft spawning. ie 1 for each CAP and GCI template
		aircraft.
b9		-correct airbase logic to allow human only bases for a coalition (no trigger zone defined=human only base)
		-add parameters noblueCAPs and noredCAPs to allow a mission designer to suppress CAP flights on one or both sides
		-add logistics so that takeoffs reduce a side's supply pool and successful landings increase a side's supply pool of groups. This means as aircraft are 
		 destroyed the pool of available aircraft groups for a side diminishes.
		-fix stuck aircraft logic so it doesn't conflict with handling landed aircraft.
		-change task reset interval to much higher value to prevent the reset of max spawned and active intercepts leading to too many GCI flights spawning
		-parameterise the units (KM or NM) the GCI messages are delivered in
		-Add parameter to control whether GCI messages are displayed or not
		-make EWRs available to both sides