--[[
Copyright (c) 2016 Snafu, Stonehouse, Rivvern, Chameleon Silk, lukrop.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software and the Software shall not be
included in whole or part in any sort of paid for software or paid for downloadable
content (DLC) without the express permission of the copyright holders.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

--[[--
## Overview
Autonomous GCI and CAP script for DCS: World.
The script provides an autonomous model of combat air patrols and ground controlled
interceptors for use with DCS World by mission builders.

After minimal setup the script will automatically spawn CAP and GCI flights for two
sides and give them patrol and intercept tasks as well as returning them to base when
threats cease to be detected.

Originally created by Snafu, enhanced and further modified by Stonehouse,
Rivvern, Chameleon Silk.

Rewritten by lukrop.

## Links

Github repository: <https://github.com/lukrop/GCICAP>

@script GCICAP
@author Snafu
@author Stonehouse
@author Rivvern
@author Chameleon Silk
@author lukrop
@copyright 2016 Snafu, Stonehouse, Rivvern, Chameleon Silk, lukrop.
@license Modified MIT. See LICENSE file.
]]

gcicap = {}
gcicap.red = {}
gcicap.red.gci = {}
gcicap.red.cap = {}
gcicap.blue = {}
gcicap.blue.gci = {}
gcicap.blue.cap = {}
gcicap.cap = {}
gcicap.gci = {}

--- Sets how verbose the log output will be.
-- Possible values are "none", "info", "warning" and "error".
-- I recommend "error" for production.
gcicap.log_level = "info"

--- Interval, in seconds, of main function.
-- Default 30 seconds.
gcicap.interval = 30

--- Interval, in seconds, GCI flights get vectors on targets.
-- AI GCI flights don't use their radar, to be as stealth as
-- possible, relying on those vectors.
-- Default 15 seconds.
gcicap.vector_interval = 15

--- How far does a target have to move before an intercept is revectored
gcicap.revector_threshold = 15000

--- Initial spawn delay between CAPs
-- Default 30 seconds.
gcicap.initial_spawn_delay = 30

--- Enable/disable borders for the red side.
-- CAP units only engage if enemy units intrude their airspace
gcicap.red.borders_enabled = false

--- Enable/disable borders for the blue side.
-- CAP units only engage if enemy units intrude their airspace
gcicap.blue.borders_enabled = false

--- CAP minimum altitudes in meters.
-- Default 4500
gcicap.cap.min_alt = 4500

--- CAP maximum altitudes in meters.
-- Default 7500
gcicap.cap.max_alt = 7500

--- Speed for CAP flights on their CAP route.
-- speed is in m/s. Default 220.
gcicap.cap.speed = 220

--- Speed for GCI flights on intercept
-- speed is in m/s. Default 300.
gcicap.gci.speed = 300

--- Maximum engage distance for CAP flights as long as they are on patrol.
-- this might be overruled by an intercept vector given from
-- ground control (EWR). Default 15000.
gcicap.cap.max_engage_distance = 15000

--- Minimum red CAP VUL time in minutes.
-- Minimum time the red CAP flight will orbit on station.
gcicap.red.cap.vul_time_min = 25

--- Maximum red CAP VUL time in minutes.
-- Maximum time the red CAP flight will orbit on station.
gcicap.red.cap.vul_time_max = 40

--- Minimum blue CAP VUL time in minutes.
gcicap.blue.cap.vul_time_min = 25

--- Maximum blue CAP VUL time in minutes.
gcicap.blue.cap.vul_time_max = 30

--- Use race-track orbit for CAP flights
-- If true CAPs will use a race-track pattern for orbit
-- between two points in the CAP zone.
gcicap.cap.race_track_orbit = false

--[[ INOP at the time
--- Minimum leg length for red CAP orbits in meters.
gcicap.red.cap.leg_min = 10000

--- Maximum leg length for red CAP orbits in meters.
gcicap.red.cap.leg_min = 20000

--- Minimum leg length for blue CAP orbits in meters.
gcicap.blue.cap.leg_min = 10000

--- Maximum leg length for blue CAP orbits in meters.
gcicap.blue.cap.leg_min = 20000
]]--

--- Enable/disable red CAP flights airborne start.
-- set to true for CAP flight to start airborne at script initialisation
-- (mission start), false for taking off from the airfield.
-- Default true.
gcicap.red.cap.start_airborne = true

--- Enable/disable blue CAP flights airborne start.
gcicap.blue.cap.start_airborne = true

--- Amount of red CAP zones.
-- placed with triggerzones in the ME.
gcicap.red.cap.zones_count = 3

--- Amount of blue CAP zones.
gcicap.blue.cap.zones_count = 3

--- Amount of red CAP groups concurrently in the air.
gcicap.red.cap.groups_count = 3

--- Amount of blue CAP groups concurrently in the air.
gcicap.blue.cap.groups_count = 3

--- Group size of red CAP flights.
-- Can be "2", "4" or "randomized"
--
-- If "2" it consists of 2 planes, if "4" it consists of 4 planes
-- if "randomized", the CAP groups consist of either 2 or 4 planes
gcicap.red.cap.group_size = "2"

--- Group size of blue CAP flights.
-- See @{gcicap.red.cap.group_size}
gcicap.blue.cap.group_size = "2"

--- Maximum amount of concurrent red intercepts.
gcicap.red.gci.groups_count = 2

--- Maximum amount of concurrent blue intercepts.
gcicap.blue.gci.groups_count = 2

--- Group size of red GCI flights.
-- Can be "2", "4" or "dynamic"
--
-- If "2" it consists of 2 planes, if "4" it consists of 4 planes
-- if "dynamic", the GCI groups consist of as much aircrafts
-- as the intruder group.
gcicap.red.gci.group_size = "dynamic"

--- Group size of blue GCI flights.
-- See @{gcicap.red.gci.group_size}
gcicap.blue.gci.group_size = "dynamic"

--- Enable/disable GCI messages for red
gcicap.red.gci.messages = true

--- Enable/disable GCI messages for blue
gcicap.blue.gci.messages = true

--- How long a GCI message will be shown in seconds.
gcicap.gci.message_time = 5

--- Display GCI messages with metric measurment for red.
-- If false the imperial system is used.
gcicap.red.gci.messages_metric = true

--- Display GCI messages with metric measurment for blue.
-- If false the imperial system is used.
gcicap.blue.gci.messages_metric = false

--- Names of red groups which will receive GCI messages.
-- Leave blank for all groups of coalition
-- @usage gcicap.red.gci.messages_to = { "my group 1", "GCI Flight" }
gcicap.red.gci.messages_to = {}

--- Names of blue groups which will receive GCI messages.
-- See @{gcicap.red.gci.messages_to} for format.
gcicap.blue.gci.messages_to = {}

--- How red CAP flights are spawned.
-- can be "parking", "takeoff" or "air" and defines the way the fighters spawn
-- takeoff is NOT RECOMMENDED currently since their occur timing issues with tasking
-- if a flight is queued for takeoff and not already in the game world while getting tasked
--
-- Default 'parking'
gcicap.red.cap.spawn_mode = "parking"

--- How red GCI flights are spawned.
-- @see gcicap.red.cap.spawn_mode
gcicap.red.gci.spawn_mode = "parking"

--- How blue CAP flights are spawned.
-- @see gcicap.red.cap.spawn_mode
gcicap.blue.cap.spawn_mode = "parking"

--- How blue GCI flights are spawned.
-- @see gcicap.red.cap.spawn_mode
gcicap.blue.gci.spawn_mode = "parking"

--- Hide or reveal blue air units in the mission.
gcicap.blue.hide_groups = false

--- Hide or reveal red air units in the mission.
gcicap.red.hide_groups = false

--- Enable/disable red CAP flights.
gcicap.red.cap.enabled = true

--- Enable/disable blue CAP flights.
gcicap.blue.cap.enabled = true

--- Enable/disable red GCI flights.
gcicap.red.gci.enabled = true

--- Enable/disable blue GCI flights.
gcicap.blue.gci.enabled = true

--- Enabel/disable resource limitation for red.
-- If set to true limits the amount of groups a side can spawn.
gcicap.red.limit_resources = false

--- Enabel/disable resource limitation for blue.
-- @see gcicap.red.limit_resources
gcicap.blue.limit_resources = false

--- Amount of groups(!) red has at it's disposal.
-- In other words how many Groups of airplanes
-- this side can spawn.
gcicap.red.supply = 24

--- Amount of groups(!) red has at it's disposal.
-- @see gcicap.red.supply
gcicap.blue.supply = 24

--- Name of the trigger zone which defines red CAP zones.
-- This will be postfixed with the number of
-- the zone. e.g. "redCAPzone3" or "blueCAPzone1".
--
-- Default: 'redCAPzone'.
gcicap.red.cap.zone_name = 'redCAPzone'

--- Name of the trigger zone which defines blue CAP zones.
-- Default: 'blueCAPzone'.
-- @see gcicap.red.cap.zone_name
gcicap.blue.cap.zone_name = 'blueCAPzone'

--- Name of group which waypoints define the red border.
-- Default: 'redborder'.
gcicap.red.border_group = 'redborder'

--- Name of group which waypoints define the blue border.
-- Default: 'blueborder'.
gcicap.blue.border_group = 'blueborder'

--- GCI template unit's names prefix.
gcicap.gci.template_prefix = '__GCI__'

--- CAP template unit's names prefix.
gcicap.cap.template_prefix = '__CAP__'

--- Count of template units.
-- Remember that this means you need that many
-- template units for each type. E.g. if the template_count is 2 you
-- would need two GCI and two CAP template units for each side.
gcicap.template_count = 2

--- Wether red will also acquire targets by AWACS aircraft.
-- This is is currently broken since isTargetDetected doesn't
-- seem to work with AWACS airplanes. Needs a workaround.
--
-- Default false.
gcicap.red.awacs = false

--- Wether blue will also acquire targets by AWACS aircraft.
-- @see gcicap.red.awacs
gcicap.blue.awacs = false

--- Garbage collector move timeout
-- If a unit (aircraft) is on the ground and didn't move
-- since this timeout, in seconds, it will be removed.
-- This applies only to aircraft spawned by GCICAP.
gcicap.move_timeout = 300

-- shortcut to the bullseye
gcicap.red.bullseye = coalition.getMainRefPoint(coalition.side.RED)
gcicap.blue.bullseye = coalition.getMainRefPoint(coalition.side.BLUE)

gcicap.sides = { "red", "blue" }
gcicap.tasks = { "cap", "gci" }

gcicap.log = mist.Logger:new("GCICAP", gcicap.log_level)

do
  --- Flight class.
  -- @type gcicap.Flight
  gcicap.Flight = {}

  local function getFlightIndex(group)
    if type(group) ~= "string" then
      if group:getName() then
        group = group:getName()
      else
        return false
      end
    end
    for i, side in pairs(gcicap.sides) do
      for j, task in pairs(gcicap.tasks) do
        for n = 1, #gcicap[side][task].flights do
          if gcicap[side][task].flights[n].group_name == group then
            return {side = side, task = task, index = n}
          end
        end
      end
    end
    return false
  end

  --- Returns the flight for the given group.
  -- @tparam string|Group group this can be a Group object
  -- or the group name.
  -- @treturn gcicap.Flight the flight for the given group.
  function gcicap.Flight.getFlight(group)
    f = getFlightIndex(group)
    if f then
      return gcicap[f.side][f.task].flights[f.index]
    else
      return false
    end
  end

  --- Creates a new flight.
  -- @tparam Group group group of the flight.
  -- @tparam Airbase airbase homplate of the new flight.
  -- @tparam string task task of the new flight. Can be "cap" or "gci".
  -- @param param task parameter. This can be a zone table if it's a
  -- CAP flight or it could be a target unit if it's a GCI flight.
  function gcicap.Flight:new(group, airbase, task, param)
    if group:isExist() then
      local side = gcicap.coalitionToSide(group:getCoalition())
      local f = {}
      f.side = side
      f.give_up = false
      f.group = group
      f.group_name = group:getName()
      f.airbase = airbase
      f.task = task
      -- is the flight RTB?
      f.rtb = false
      f.in_zone = false

      if task == "cap" then
        f.zone = param
        f.zone_name = param.name
        f.intercepting = false
        f.vul_time = math.random(gcicap[side].cap.vul_time_min,
                                 gcicap[side].cap.vul_time_max)
      else -- task should be "gci"
        f.target = param
        f.target_group = param.group
        f.intercepting = true
        f.intercept_point = { x = 0, y = 0, z = 0 }
      end

      -- get current timestamp
      local timestamp = timer.getAbsTime()
      f.units_moved = {}
      -- set timestamp for each unit
      -- this is later used for garbage collection checks
      for u, unit in pairs(group:getUnits()) do
        f.units_moved[u] = {}
        f.units_moved[u].unit = unit
        f.units_moved[u].last_moved = timestamp
        f.units_moved[u].spawned_at = timestamp
      end

      setmetatable(f, self)
      self.__index = self

      table.insert(gcicap[side][task].flights, f)
      gcicap.log:info("Registered flight: $1", f.group_name)

      return f
    else
      return nil
    end
  end

  --- Removes the flight
  -- @tparam gcicap.Flight self flight object
  function gcicap.Flight:remove()
    if self.zone then
      -- if we didn't already leave the zone do it now.
      self:leaveCAPZone()
    end
    local f = getFlightIndex(self.group_name)
    local r = table.remove(gcicap[f.side][f.task].flights, f.index)
    if r then
      gcicap.log:info("Removing flight $1 with index $2", r.group_name, f.index)
    end
  end

  --- Decreases active flights counter in this flights zone.
  -- Actually just decreases the active flights
  -- counter of a zone. Does NOT task the flight itself.
  function gcicap.Flight:leaveCAPZone()
    if self.in_zone then
      local zone = self.zone
      if zone.patrol_count <= 1 then
        zone.patrol_count = 0
      else
        zone.patrol_count = zone.patrol_count - 1
      end
      self.in_zone = false

      -- get current time
      local time_now = timer.getAbsTime()
      -- get time on station by substracting vul start time from current time
      -- and convert it to minutes
      local time_on_station = 0
      if self.vul_start then
        time_on_station = (time_now - self.vul_start) / 60
      end
      local vul_diff = self.vul_time - time_on_station
      -- set new vul time only if more than 5 minutes
      if vul_diff > 5 then
        self.vul_time = vul_diff
      else
        self.vul_time = 0
      end
    end
  end

  --- Increases active flights counter in this flights zone.
  -- Actually just increases the active flights
  -- counter of a zone. Does NOT task the flight itself.
  function gcicap.Flight:enterCAPZone()
    if not self.in_zone then
      self.intercepting = false
      self.in_zone = true
      local zone = self.zone
      zone.patrol_count = zone.patrol_count + 1
    end
  end

  --- Tasks the flight to search and engage the target.
  -- @tparam Unit intruder target unit.
  -- @tparam[opt] boolean cold whether the flight should not destroy
  -- the target and just follow it. Default false.
  function gcicap.Flight:vectorToTarget(intruder, cold)
    local target = nil
    if intruder.group then
      target = gcicap.getFirstActiveUnit(intruder.group)
    end
    if target == nil or intruder.group == nil then return end

    -- check if interceptor even still exists
    if self.group:isExist() then
      if target:isExist() and target:inAir() and self.give_up ~= true then
        local target_pos = target:getPoint()
        local ctl = self.group:getController()

        local gci_task = {
          id = 'Mission',
          params = {
            route = {
              points = {
                [1] = {
                  alt = target_pos.y,
                  x = target_pos.x,
                  y = target_pos.z,
                  speed = gcicap.gci.speed,
                  action = "Turning Point",
                  type = "Turning Point",
                  task = {
                    id = "ComboTask",
                    params = {
                      tasks = {
                        [1] = {
                          number = 1,
                          key = "CAP",
                          id = "EngageTargets",
                          enabled = true,
                          auto = true,
                          params = {
                            targetTypes = { [1] = "Air" },
                            priority = 0
                          }
                        }
                      }
                    }
                  }
                },
                [2] = {
                  alt = target_pos.y,
                  x = target_pos.x,
                  y = target_pos.z,
                  speed = gcicap.gci.speed,
                  action = "Turning Point",
                  type = "Turning Point",
                  task = {
                    -- i don't really like this WrappedAction but it's needed in
                    -- the case the CGI completes this waypoint because of lack/loss
                    -- of target
                    id = 'WrappedAction',
                    params = {
                      action = {
                        id = 'Script',
                        params = {
                          command = "local group = ...\
                          local flight = gcicap.Flight.getFlight(group)\
                          if flight then\
                            flight.give_up = true\
                            if flight.zone then\
                              if flight.intercepting then\
                                flight:taskWithCAP()\
                              end\
                            else\
                              if not flight.target then\
                                flight:taskWithRTB()\
                              end\
                            end\
                          else\
                            gcicap.log:error('Could not find flight')\
                          end"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        -- checkout of the patrol zone
        if self.zone and not self.intercepting then
          self:leaveCAPZone()
        end

        intruder.intercepted = true
        -- only set/reset the task if the target has moved significantly since last GCI update
        if mist.utils.get3DDist( target_pos, self.intercept_point ) > gcicap.revector_threshold then
          -- if there's still an EWR detecting or we are responding to the initial call
          -- then set the target position. do not allow revectoring if no EWR is detecting us now
          if (Unit.isExist(intruder.detected_by) and intruder.detected_by:isActive()) then
            self.give_up = false
            self.intercept_point = mist.utils.deepCopy(target_pos)
            ctl:setTask(gci_task)
            gcicap.log:info("Vectoring $1 to $2 ($3)", self.group:getName(),
                 intruder.group:getName(), target:getName())

          else
            gcicap.log:info("Cannot revector $1 to $2 because no longer detecting",self.group:getName(),intruder.group:getName())
          end
        end
        self.intercepting = true
        
        -- taskEngageGroup provides omniscient knowledge of where the group to be attacked is, which sucks
        if not cold then
          --gcicap.taskEngageGroup(self.group, intruder.group)
          gcicap.taskEngage(self.group, 15000)
        end

        -- reschedule function until either the interceptor or the intruder is dead
        mist.scheduleFunction(gcicap.Flight.vectorToTarget, {self, intruder, cold},
                              timer.getTime() + gcicap.vector_interval)

      else -- the target is dead or we had to give up, resume CAP or RTB
        if self.zone then
          -- send CAP back to work only if still intercepting
          if self.intercepting then
            self:taskWithCAP()
          end
        else
          self.intercepting = false
          -- send GCI back to homeplate
          self:taskWithRTB()
        end
      end
    else
      -- our interceptor group is dead let's see if the
      -- intruder is still there and set him to not beeing intercepted anymore
      if target:isExist() then
        intruder.intercepted = false
      end
    end
  end

  --- Tasks flight with combat air patrol.
  -- Creates waypoints inside it's assigned zone and tasks
  -- the flight with patroling along the route.
  -- @tparam[opt] boolean cold If set to true the flight won't
  -- engage any enemy unit's it detects by itself. Default false.
  function gcicap.Flight:taskWithCAP(cold)
    -- only task with CAP if ther is still vul time left
    if self.vul_time == 0 then
      -- send flight RTB if no vul time left.
      gcicap.log:info("No vul time left for $1", self.group_name)
      self:taskWithRTB()
    else
      local group = self.group
      local ctl = group:getController()
      local side = gcicap.coalitionToSide(group:getCoalition())
      local start_pos = gcicap.getFirstActiveUnit(group):getPoint()
      local leg_dist = math.random(gcicap[side].cap.leg_min, gcicap[side].cap.leg_max)
      local cap_route = gcicap.buildCAPRoute(start_pos, self.zone.name, self.vul_time, leg_dist)
      local cap_task = {
        id = 'Mission',
        params = {
          route = cap_route
        }
      }

      self.intercepting = false
      self.intercept_point = { x = 0, y = 0, z = 0 }
      ctl:setTask(cap_task)
      self:enterCAPZone()
      ctl:setOption(AI.Option.Air.id.RADAR_USING, AI.Option.Air.val.RADAR_USING.FOR_SEARCH_IF_REQUIRED)

      if not cold then
        gcicap.taskEngage(group)
      end
      gcicap.log:info("Tasking $1 with CAP in zone $2", group:getName(), self.zone.name)
    end
  end

  --- Tasks the flight to return to it's homeplate.
  -- @tparam[opt] Airbase airbase optionally use this as homeplate/airbase
  -- to return to.
  -- @tparam[opt] boolean cold If set to true the flight won't
  -- engage any targets it detects on the way back to base.
  -- Default false.
  function gcicap.Flight:taskWithRTB(airbase, cold)
    if not airbase then
      airbase = self.airbase
    end

    if self.zone then
      self:leaveCAPZone()
      local side = self.side
      -- let's try to spawn a new CAP flight as soon as the current one is tasked with RTB.
      -- never spawn more than 2 x the groups_count, to prevent spam in case something ever goes wrong.
      if (not gcicap[side].limit_resources or
        (gcicap[side].limit_resources and gcicap[side].supply > 0))
        and #gcicap[side].cap.flights < gcicap[side].cap.groups_count * 2 then
        gcicap.spawnCAP(side, self.zone, gcicap[side].cap.spawn_mode)
      end
    end
    self.rtb = true
    local group = self.group
    local ctl = group:getController()
    local af_pos = mist.utils.makeVec2(airbase:getPoint())
    local af_id = airbase:getID()
    local rtb_task = {
      id = 'Mission',
      params = {
        route = {
          points = {
            [1] = {
              alt = gcicap.cap.min_alt,
              alt_type = "BARO",
              speed = gcicap.cap.speed,
              x = af_pos.x,
              y = af_pos.y,
              aerodromeId = af_id,
              type = "Land",
              action = "Landing",
            }
          }
        }
      }
    }

    ctl:setTask(rtb_task)

    if not cold then
      -- only engage if enemy is inside of 10km of the leg
      gcicap.taskEngage(group, 10000)
    end

    gcicap.log:info("Tasking $1 with RTB to $2", group:getName(), airbase:getName())
  end

  --- Functions
  -- @section gcicap

  --- Clean up inactive/stuck flights.
  local function garbageCollector(side)
    local timestamp = timer.getAbsTime()
    for t, task in pairs(gcicap.tasks) do
      for f, flight in pairs(gcicap[side][task].flights) do
        if flight.group then
          if flight.group:isExist() then
            for u = 1, #flight.units_moved do
              local unit = flight.units_moved[u].unit
              -- check if unit exists
              if unit then
                if unit:isExist() then
                  -- if unit is in air we won't do anything
                  if not unit:inAir() then
                    -- check if unit is moving
                    local mag = mist.vec.mag(unit:getVelocity())
                    if mag == 0 then
                      -- get the last time the unit moved
                      local last_moved = flight.units_moved[u].last_moved
                      if timestamp - last_moved > gcicap.move_timeout then
                        gcicap.log:info("Cleaning up $1", flight.group:getName())
                        flight.group:destroy()
                        flight:remove()
                      end
                    else
                      flight.units_moved[u].last_moved = timestamp
                    end
                  end
                end
              end
            end
          else
            flight:remove()
          end
        else
          flight:remove()
        end
      end
    end
  end

  local function checkForTemplateUnits(side)
    if gcicap[side].gci.enabled then
      for i = 1, gcicap.template_count do
        local unit = gcicap.gci.template_prefix..side..i
        if not Unit.getByName(unit) then
          gcicap.log:alert("GCI template unit missing: $1", unit)
          return false
        end
      end
    end
    if gcicap[side].cap.enabled then
      for i = 1, gcicap.template_count do
        local unit = gcicap.cap.template_prefix..side..i
        if not Unit.getByName(unit) then
          gcicap.log:alert("CAP template unit missing: $1", unit)
          return false
        end
      end
    end
    if gcicap[side].borders_enabled then
      if not Group.getByName(gcicap[side].border_group) then
        gcicap.log:alert("Border group is missing: $1", gcicap[side].border_group)
        return false
      end
    end
    return true
  end

  local function checkForTriggerZones(side)
    for i = 1, gcicap[side].cap.zones_count do
      local zone_name = gcicap[side].cap.zone_name..i
      if not trigger.misc.getZone(zone_name) then
        gcicap.log:alert("CAP trigger zone is missing: $1", zone_name)
        return false
      end
    end
    return true
  end

  local function manageCAP(side)
    local patroled_zones = 0

    for i = 1, #gcicap[side].cap.zones do
      local zone = gcicap[side].cap.zones[i]
      gcicap.log:info("Zone $1 has $2 patrols", zone.name, zone.patrol_count)

      -- see if we can send a new CAP into the zone
      if zone.patrol_count <= 0 then
        -- first check if we already hit the maximum amounts of routine CAP groups
        if #gcicap[side].cap.flights < gcicap[side].cap.groups_count then
          -- check if we limit resources and if we have enough supplies
          -- if we don't limit resource or have enough supplies we spawn
          if not gcicap[side].limit_resources or
            (gcicap[side].limit_resources and gcicap[side].supply > 0) then
            -- finally spawn it
            gcicap.spawnCAP(side, gcicap[side].cap.zones[i], gcicap[side].cap.spawn_mode)
          end
        end
      else
        patroled_zones = patroled_zones + 1
      end
    end
    -- if all zones are patroled and we still have cap groups left
    -- send them to a random zone
    if #gcicap[side].cap.flights < gcicap[side].cap.groups_count then
      if not gcicap[side].limit_resources or
        (gcicap[side].limit_resources and gcicap[side].supply > 0) then
        local random_zone = math.random(1, #gcicap[side].cap.zones)
        gcicap.spawnCAP(side, gcicap[side].cap.zones[random_zone], gcicap[side].cap.spawn_mode)
      end
    end
    gcicap.log:info("$1 patrols in $2/$3 zones with $4 flights",
                    side, patroled_zones, gcicap[side].cap.zones_count, #gcicap[side].cap.flights)
  end

  local function handleIntrusion(side)
    for i = 1, #gcicap[side].intruders do
      local intruder = gcicap[side].intruders[i]
      if intruder.group then
        if intruder.group:isExist() then
          -- check if we need to do something about him
          if not intruder.intercepted then
            -- first check if we have something to work with
            if #gcicap[side].cap.flights > 0
              or #gcicap[side].gci.flights > 0
              or #gcicap[side].gci.flights < gcicap[side].gci.groups_count then
              -- get closest flight to intruder if there is any
              local closest = nil
              local intruder_unit = gcicap.getFirstActiveUnit(intruder.group)
              local closest_flights = gcicap.getClosestFlightsToUnit(side, intruder_unit)
              -- we found close flights
              local flight_avail = false
              if closest_flights then
                for j = 1, #closest_flights do
                  closest = closest_flights[j]
                  --fligh_avail = (not closest.flight.rtb) and (not closest.flight.intercepting)
                  flight_avail = (not closest.flight.intercepting)
                  if flight_avail then
                    gcicap.log:info("Found flight $1 which is avaliable for tasking.",
                                    closest.flight.group:getName())
                    break
                  end
                end
              end
              if flight_avail then
                -- check if we have a airfield which is closer to the unit than the closest flight
                -- but add some distance to the airfield since it takes time for a potential spawned
                -- flight to take-off
                local closest_af, af_distance = gcicap.getClosestAirfieldToUnit(side, intruder_unit)
                af_distance = af_distance + 15000 -- add 15km
                if closest.distance < af_distance or af_distance == -1 then
                  -- task flight with intercept
                  closest.flight.give_up = false
                  closest.flight:vectorToTarget(intruder)
                  return
                end
                if (not gcicap[side].limit_resources
                    or (gcicap[side].limit_resources and gcicap[side].supply > 0))
                  and #gcicap[side].gci.flights < gcicap[side].gci.groups_count
                  and gcicap[side].gci.enabled then
                  -- spawn CGI
                  gcicap.log:info("Airfield closer to intruder than flight or no flight available. Spawning GCI")
                  local gci = gcicap.spawnGCI(side, intruder)
                end
              else
                if (not gcicap[side].limit_resources
                    or (gcicap[side].limit_resources and gcicap[side].supply > 0))
                  and #gcicap[side].gci.flights < gcicap[side].gci.groups_count
                  and gcicap[side].gci.enabled then
                  -- spawn CGI
                  gcicap.log:info("No CAP flights or already airborne GCI. Spawning GCI")
                  local gci = gcicap.spawnGCI(side, intruder)
                end
              end
            end
          end
        end
      else
        -- the intruder group doesn't exist (anymore) remove it
        table.remove(gcicap[side].intruders, i)
      end
    end
  end

  -- returns airfields of given side which are marked with
  -- triggerzones (triggerzone name is exactly the same as airfield name).
  local function getAirfields(side)
    local coal_airfields = coalition.getAirbases(gcicap.sideToCoalition(side))
    local gcicap_airfields = {}

    -- loop over all coalition airfields
    for i = 1, #coal_airfields do
      -- get name of airfield
      local af_name = coal_airfields[i]:getName()
      if not string.match(af_name, "FARP") then
        -- check if a triggerzone exists with that exact name
        if mist.DBs.zonesByName[af_name] then
          -- add it to our airfield list for gcicap
          gcicap_airfields[#gcicap_airfields + 1] = coal_airfields[i]
        end
      end
    end

    if #gcicap_airfields == 0 then
      gcicap.log:warn("No airbase for $1 found", side)
    end
    return gcicap_airfields
  end

  -- returns all currently active aircraft of the given side
  -- parameter side has to be "red" or "blue"
  local function getAllActiveAircrafts(side)
    local filter = { "[" .. side .. "][plane]", "[" .. side .. "][helicopter]"}
    local all_aircraft = mist.makeUnitTable(filter)
    local active_aircraft = {}

    for i = 1, #all_aircraft do
      local ac = Unit.getByName(all_aircraft[i])
      if ac ~= nil then
        if Unit.isActive(ac) then
          table.insert(active_aircraft, ac)
        end
      end
    end
    if #active_aircraft == 0 then
      gcicap.log:warn("No active aircraft for $1 found", side)
    end
    return active_aircraft
  end

  -- returns all currently active EWR and AWACS units of the given side
  -- parameter side has to be "red" or "blue"
  local function getAllActiveEWR(side)
    local filter = { "[" .. side .. "][plane]", "[" .. side .. "][vehicle]", "[" .. side .. "][ship]"}
    local all_vecs = mist.makeUnitTable(filter)
    local active_ewr = {}

    for i = 1, #all_vecs do
      local vec = Unit.getByName(all_vecs[i])
      if vec ~= nil then
        if Unit.isActive(vec) then
          local vec_type = Unit.getTypeName(vec)
          if vec_type == "55G6 EWR"
            or vec_type == "1L13 EWR"
            or vec_type == "Hawk sr"
            or vec_type == "Patriot str" then
            table.insert(active_ewr, { unit = vec, is_awacs = false} )
          end
          -- ED has a bug; the E-2D vehicle has type E-2C
          if (vec_type == "A-50" and gcicap[side].awacs)
            or (vec_type == "E-2C" and gcicap[side].awacs)
            or (vec_type == "E-3A" and gcicap[side].awacs) then
            table.insert(active_ewr, { unit = vec, is_awacs = true} )
          end
        end
      end
    end
    if #active_ewr == 0 then
      gcicap.log:warn("No active EWR for $1 found", side)
    end
    return active_ewr
  end

  local function checkForAirspaceIntrusion(side)
    -- init some local vars
    local border = gcicap[side].border
    local active_ewr = gcicap[side].active_ewr
    local intruder_count = 0
    local intruder_side = ""
    local toremove = {}
    if side == "red" then
      -- set the side of the intruder
      intruder_side = "blue"
    elseif side == "blue" then
      intruder_side = "red"
    end
    local active_ac = gcicap[intruder_side].active_aircraft

    -- only do something if we have active ewr and active aircraft
    if #active_ac > 0 and #active_ewr > 0 then
      -- loop over all aircraft
      for i = 1, #active_ac do
        local ac = active_ac[i]
        local ac_detected = false
        local ac_intruded = false
        local ac_pos = {}
        local ac_group = nil
        local intruder_num = 0
        local ewr = nil
        if ac ~= nil then
          ac_group = ac:getGroup()
          if ac_group:isExist() then
            ac_pos = ac:getPoint()

            -- now loop over all ewr units
            for n = 1, #active_ewr do
              local ewr_controller = nil
              if active_ewr[n].is_awacs then
                ewr_controller = active_ewr[n].unit:getController()
              else
                ewr_controller = active_ewr[n].unit:getGroup():getController()
              end
              -- and check if the EWR detected the aircraft
              if ewr_controller:isTargetDetected(ac, RADAR) then
                ewr = active_ewr[n].unit
                ac_detected = true
                -- stop once it was detected by one EWR
                break
              end
            end

            if ac_detected then
              -- do we check borders?
              if gcicap[side].borders_enabled then
                ac_intruded = mist.pointInPolygon(ac_pos, border)
              else
                -- if not the aircarft is always intruding
                ac_intruded = true
              end

              if ac_intruded then
                local in_list = false
                -- check if we already know about the intruder
                for j = 1, #gcicap[side].intruders do
                  if gcicap[side].intruders[j].name == ac_group:getName() then
                    in_list = true
                    intruder_num = j
                    break
                  end
                end
                if not in_list then
                  intruder_count = intruder_count + 1

                  gcicap.log:info("$1 ($2) intruded airspace of $3 detected by $4 ($5)",
                                  ac_group:getName(), ac:getName(), side,
                                  ewr:getGroup():getName(), ewr:getName())

                  intruder = {
                    name = ac_group:getName(),
                    --unit = ac,
                    group = ac_group,
                    detected_by = ewr,
                    --groupID = ac_group:getID(),
                    --unitID = ac:getID(),
                    --unitType = ac:getTypeName(),
                    size = ac_group:getSize(),
                    intercepted = false,
                  }
                  table.insert(gcicap[side].intruders, intruder)
                  intruder_num = #gcicap[side].intruders
                end

                -- send message to all units of coalition or some specified groups
                -- that we have a intruder
                if gcicap[side].gci.messages then
                  local par = {
                    units = { ac:getName() },
                    ref = gcicap[side].bullseye,
                    alt = ac_pos.y,
                  }
                  -- do we want to display in metric units?
                  if gcicap[side].gci.messages_metric then
                    par.metric = true
                  end

                  local msg_for = {}
                  -- if groups are specified find their units names and add them to the list
                  if #gcicap[side].gci.messages_to > 0 then
                    msg_for.units = {}
                    for g, group_name in pairs(gcicap[side].gci.messages_to) do
                      group = Group.getByName(group_name)
                      if group ~= nil then
                        for u, unit in pairs(group:getUnits()) do
                          table.insert(msg_for.units, unit:getName())
                        end
                      end
                    end
                  else
                    msg_for.coa = { side }
                  end
                  -- get the bearing, range and altitude from bullseye to intruder
                  local bra = mist.getBRString(par)
                  local bra_string = "Airpsace intrusion! BRA from bullseye "..bra
                  local msg = {
                    text = bra_string,
                    displayTime = gcicap.gci.message_time,
                    msgFor = msg_for,
                    name = "gcicap.gci.msg"..intruder_num,
                  }
                  -- finally send the message
                  mist.message.add(msg)
                end
              end -- if ac_intruded
            else
              -- the ac is _not_ intruding so we should remove it from the intruders list

              local in_list = false
              local intruder_num = 0
              -- check if we already know about the intruder
              for j = 1, #gcicap[side].intruders do
                if gcicap[side].intruders[j].name == ac_group:getName() then
                  in_list = true
                  intruder_num = j
                  break
                end
              end
              if in_list then toremove[#toremove + 1] = intruder_num end
            end -- if ac_detected
          end -- if ac_group is existing
        end -- if ac ~= nil
      end -- for #active_ac
    end -- if active_ac > 0 and active_ewr > 0

    -- we need to remove intruders from outside the loop
    if #toremove > 0 then
      for i = 1,#toremove do
        intruder_count = intruder_count - 1
        gcicap.log:info("Aircraft "..gcicap[side].intruders[i].name.." no longer intruding")
        table.remove(gcicap[side].intruders,i)
      end
    end
    if intruder_count > 0 then
      return true
    else
      return false
    end
    --return gcicap[side].intruders
  end

  -- returns a random airfield for the given side
  local function getRandomAirfield(side)
    local rand = math.random(1, #gcicap[side].airfields)
    return gcicap[side].airfields[rand]
  end

  local function buildFirstWp(airbase, spawn_mode)
    local airbase_pos = airbase:getPoint()
    local airbase_id = airbase:getID()
    local wp = mist.fixedWing.buildWP(airbase_pos)

    if spawn_mode == "parking" then -- start from parking area
      wp.airdromeId = airbase_id
      wp.type = "TakeOffParking"
      wp.action = "From Parking Area"
    elseif spawn_mode == "takeoff" then -- or start from runway
      wp.airdromeId = airbase_id
      wp.type = "TakeOff"
      wp.action = "From Runway"
    elseif spawn_mode == "air" then
      -- randomize spawn position a little bit in case of air start
      wp.x = wp.x + (50 * math.sin(math.random(10)))
      wp.y = wp.y + (50 * math.sin(math.random(10)))
    end

    return wp
  end

  --- Converts coaltion number to side string.
  -- 0 = "neutral", 1 = "red", 2 = "blue"
  -- @tparam number coal coaltion number.
  -- @treturn string side
  function gcicap.coalitionToSide(coal)
    if coal == coalition.side.NEUTRAL then return "neutral"
    elseif coal == coalition.side.RED then return "red"
    elseif coal == coalition.side.BLUE then return "blue"
    end
  end

  --- Converts side string to coaltion number.
  -- 0 = "neutral", 1 = "red", 2 = "blue"
  -- @tparam string side side string.
  -- @treturn number coalition number.
  -- @see coalitionToSide
  function gcicap.sideToCoalition(side)
    if side == "neutral" then return coalition.side.NEUTRAL
    elseif side == "red" then return coalition.side.RED
    elseif side == "blue" then return coalition.side.BLUE
    end
  end

  --- Returns first active unit of a group.
  -- @tparam Group group group whose first active
  -- unit to return.
  -- @treturn Unit first active unit of group.
    function gcicap.getFirstActiveUnit(group)
    if group ~= nil then
      -- engrish mast0r isExistsingsed
      if not group:isExist() then return nil end
      local units = group:getUnits()
      for i = 1, group:getSize() do
        if units[i] then
          return units[i]
        end
      end
      return nil
    else
      return nil
    end
  end

  --- Returns the closest airfield to unit.
  -- Returned airfield is controlled by given side. This function
  -- also returns the distance to the unit.
  -- @tparam string side side string, either "red" or "blue".
  -- The airfield returned has to be controlled by this side.
  -- @tparam Unit unit unit to use as reference.
  -- @treturn table @{closestAirfieldReturn}
  function gcicap.getClosestAirfieldToUnit(side, unit)
    if not unit then
      gcicap.log:error("Couldn't find unit.")
      return
    end
    local airfields = gcicap[side].airfields

    if #airfields == 0 then
      gcicap.log:warn("There are no airfields of side $1", side)
      return nil
    end

    local unit_pos = mist.utils.makeVec2(unit:getPoint())
    local min_distance = -1
    local closest_af = nil

    for i = 1, #airfields do
      local af = airfields[i]
      local af_pos = mist.utils.makeVec2(af:getPoint())
      local distance = mist.utils.get2DDist(unit_pos, af_pos)

      if distance < min_distance or min_distance == -1 then
        min_distance = distance
        closest_af = af
      end
    end

    --- Table returned by getClosestAirfieldToUnit.
    -- @table closestAirfieldReturn
    -- @tfield Airbase airfield the Airbase object
    -- @tfield number distance the distance in meters
    -- to the unit.
    --return {airfield = closest_af, distance = min_distance}
    return closest_af, min_distance
  end

  --- Returns the closest flights to the given unit.
  -- Flights returned are of given side. This function also returns
  -- their distance to the unit. The returned flights are sorted
  -- by distance. First is the closest.
  -- @tparam string side side whose flights to search.
  -- @tparam Unit unit unit object used as reference.
  -- @treturn table Array sorted by distance
  -- containing @{closestFlightsReturn} tables.
  function gcicap.getClosestFlightsToUnit(side, unit)
    if not unit then
      gcicap.log:error("Couldn't find unit.")
      return
    end
    local closest_flights = {}
    if #gcicap[side].cap.flights == 0 and #gcicap[side].gci.flights == 0 then
      gcicap.log:info("No CAP or GCI flights of side $1 active", side)
      return nil
    else
      local unit_pos = mist.utils.makeVec2(unit:getPoint())
      local min_distance = -1
      for t, task in pairs(gcicap.tasks) do
        local flights = gcicap[side][task].flights
        for i = 1, #flights do
          if flights[i].group then
            local u = gcicap.getFirstActiveUnit(flights[i].group)
            if u then
              local u_pos = mist.utils.makeVec2(u:getPoint())
              local distance = mist.utils.get2DDist(unit_pos, u_pos)
              table.insert(closest_flights, {flight = flights[i], distance = distance })
            else
              break
            end
          end
        end
      end

      -- sort closest flights
      table.sort(closest_flights, function(a,b)
        if a.distance < b.distance then
          return true
        else
          return false
        end
      end)

      --- Table returned by getClosestFlightsToUnit.
      -- @table closestFlightsReturn
      -- @tfield gcicap.Flight flight object
      -- @tfield number distance distance in meters from
      -- the unit.
      return closest_flights
    end
  end

  --- Returns a table containting a CAP route.
  -- Route originating from given airbase, waypoints
  -- are placed randomly inside given zone. Optionally
  -- you can specify the amount of waypoints inside the zone.
  -- @tparam string zone trigger zone name
  -- @tparam number vul_time time on station
  -- @tparam number leg_distance leg distance for race-track pattern orbit.
  function gcicap.buildCAPRoute(start_pos, zone, vul_time, leg_distance)
    local points = {}
    -- make altitude consistent for the whole route.
    local alt = math.random(gcicap.cap.min_alt, gcicap.cap.max_alt)

    local start_vul_script = "local group = ...\
                local flight = gcicap.Flight.getFlight(group)\
                if flight then\
                  gcicap.log:info('$1 starting vul time $2 at $3',\
                                  flight.group_name, flight.vul_time, flight.zone.name)\
                  flight.vul_start = timer.getAbsTime()\
                else\
                  gcicap.log:error('Could not find flight')\
                end"

    local end_vul_script = "local group = ...\
                local flight = gcicap.Flight.getFlight(group)\
                if flight then\
                  gcicap.log:info('$1 vul time over at $2',\
                                  flight.group_name, flight.zone.name)\
                  flight:taskWithRTB()\
                else\
                  gcicap.log:error('Could not find flight')\
                end"

    -- build orbit start waypoint
    local orbit_start_point = mist.getRandomPointInZone(zone)
    -- add a bogus waypoint so the start vul time script block
    -- isn't executed instantly after tasking
    points[1] = mist.fixedWing.buildWP(start_pos)
    points[2] = mist.fixedWing.buildWP(orbit_start_point)
    points[2].task = {}
    points[2].task.id = 'ComboTask'
    points[2].task.params = {}
    points[2].task.params.tasks = {}
    points[2].task.params.tasks[1] = {
      number = 1,
      auto = false,
      id = 'WrappedAction',
      enabled = true,
      params = {
        action = {
          id = 'Script',
          params = {
            command = start_vul_script
          }
        }
      }
    }
    points[2].task.params.tasks[2] = {
      number = 2,
      auto = false,
      id = 'ControlledTask',
      enabled = true,
      params = {
        task = {
          id = 'Orbit',
          params = {
            altitude = alt,
            pattern = 'Race-Track',
            speed = gcicap.cap.speed
          }
        },
        stopCondition = {
          duration = vul_time * 60
        }
      }
    }

    -- if we don't use the race-track pattern we'll add the vul end time
    -- waypoint right where the start waypoint is and use the 'Circle' pattern.
    local orbit_end_point
    if not gcicap.cap.race_track_orbit then
      points[2].task.params.tasks[2].params.task.params.pattern = 'Circle'
      orbit_end_point = start_pos
    else
      -- build second waypoint (leg end waypoint)
      --local orbit_end_point = mist.getRandPointInCircle(orbit_start_point, leg_distance, leg_distance)
      orbit_end_point = mist.getRandomPointInZone(zone)
    end

    points[3] = mist.fixedWing.buildWP(orbit_end_point)
    points[3].task = {
      id = 'WrappedAction',
      params = {
        action = {
          id = 'Script',
          params = {
            command = end_vul_script
          }
        }
      }
    }

    for i = 1, 3 do
      points[i].speed = gcicap.cap.speed
      points[i].alt = alt
    end

    -- local ground_level = land.getHeight(point)
    -- -- avoid crashing into hills
    -- if (alt - 100) < ground_level then
    --   alt = alt + ground_level
    -- end

    gcicap.log:info("Built CAP route with $1 min vul time at $2 meters in $3", vul_time, alt, zone)

    local route = {}
    route.points = points
    return route
  end

  --- Tasks group to automatically engage any spotted targets.
  -- @tparam Group group group to task.
  -- @tparam[opt] number max_dist maximum engagment distance.
  -- Targets further out (from the route) won't be engaged.
  function gcicap.taskEngage(group, max_dist)
    if not max_dist then
      max_dist = gcicap.cap.max_engage_distance
    end
    local ctl = group:getController()
    local engage = {
      id = 'EngageTargets',
      params = {
        maxDist = max_dist,
        maxDistEnabled = true,
        targetTypes = { [1] = "Air" },
        priority = 0
      }
    }
    ctl:pushTask(engage)
  end

  --- Tasks group to engage a group.
  -- @tparam Group group group to task.
  -- @tparam Group target group that should be engaged by
  -- given group.
  function gcicap.taskEngageGroup(group, target)
    local ctl = group:getController()
    local engage_group = {
      id = 'EngageGroup',
      params = {
        groupId = target:getID(),
        directionEnabled = false,
        priority = 0,
        altittudeEnabled = false,
      }
    }
    ctl:pushTask(engage_group)
  end

  --- Spawns a fighter group.
  -- @tparam string side side of the newly created group.
  -- Can be "red" or "blue".
  -- @tparam string name new group name.
  -- @tparam number size count of aircraft in the new group.
  -- @tparam Airbase airbase home plate of the new group.
  -- @tparam string spawn_mode How the new group will be spawned.
  -- Can be 'parking' or 'air'. 'parking' will spawn them at the ramp
  -- wit engines turned off. 'air' will spawn them in the air already
  -- flying.
  -- @tparam string task Task of the new group. Can either be 'cap',
  -- for combat air patrol, or 'gci', for ground controlled intercept.
  -- @tparam[opt] string zone zone name in which to spawn the unit. This only is
  -- taken into account if spawn_mode is "in-zone".
  -- @tparam[opt] boolean cold if set to true the newly group won't engage
  -- any enemys until tasked otherwise. Default false.
  -- @treturn Group|nil newly spawned group or nil on failure.
  function gcicap.spawnFighterGroup(side, name, size, airbase, spawn_mode, task, zone, cold)
    local template_unit_name = gcicap[task].template_prefix..side..math.random(1, gcicap.template_count)
    local template_unit = Unit.getByName(template_unit_name)
    if not template_unit then
      gcicap.log:error("Can't find template unit $1. This should never happen.\
                       Somehow the template unit got deleted.", template_unit_name)
      return nil
    end
    local template_group = mist.getGroupData(template_unit:getGroup():getName())
    local template_unit_data = template_group.units[1]
    local airbase_pos = airbase:getPoint()
    local group_data = {}
    local unit_data = {}
    local onboard_num = template_unit_data.onboard_num - 1
    local route = {}

    local rand_point = {}
    if spawn_mode == "in-zone" then
      rand_point = mist.getRandomPointInZone(zone)
    end

    for i = 1, size do
      unit_data[i] = {}
      unit_data[i].type = template_unit_data.type
      unit_data[i].name = name.." Pilot "..i
      if spawn_mode == "in-zone" then
        unit_data[i].x = rand_point.x + (50 * math.sin(math.random(10)))
        unit_data[i].y = rand_point.y + (50 * math.sin(math.random(10)))
      else
        unit_data[i].x = airbase_pos.x + (50 * math.sin(math.random(10)))
        unit_data[i].y = airbase_pos.z + (50 * math.sin(math.random(10)))
      end
      unit_data[i].alt = gcicap[side].cap.min_alt
      unit_data[i].onboard_num =  onboard_num + i
      unit_data[i].groupName = name
      unit_data[i].payload = template_unit_data.payload
      unit_data[i].skill = template_unit_data.skill
      unit_data[i].livery_id = template_unit_data.livery_id
      if side == 'blue' then
        unit_data[i].callsign = {}
        unit_data[i].callsign[1] = 4 -- Colt
        unit_data[i].callsign[2] = gcicap[side].cap.flight_num
        unit_data[i].callsign[3] = i
      else
        unit_data[i].callsign = 600 + gcicap[side].cap.flight_num + i
      end
    end

    group_data.units = unit_data
    group_data.groupName = name
    group_data.hidden = gcicap[side].hide_groups
    --group_data.country = template_group.country
    group_data.country = template_unit:getCountry()
    group_data.category = template_group.category
    group_data.task = "CAP"

    route.points = {}
    if spawn_mode == "in-zone" then
      route.points[1] = mist.fixedWing.buildWP(rand_point)
      route.points[1].alt = gcicap[side].cap.min_alt
      route.points[1].speed = gcicap[side].cap.speed
    else
      route.points[1] = buildFirstWp(airbase, spawn_mode)
    end
    group_data.route = route

    if mist.groupTableCheck(group_data) then
      local spawn_pos = airbase:getName()
      if spawn_mode == "in-zone" then
        spawn_pos = zone
      end
      gcicap.log:info("Spawning fighter group $1 at $2", name, spawn_pos)
      mist.dynAdd(group_data)
    else
      gcicap.log:error("Couldn't spawn group with following groupTable: $1", group_data)
    end

    return Group.getByName(name)
  end

  --- Spawns a CAP flight.
  -- @tparam string side side for the new CAP.
  -- @tparam string zone CAP zone (trigger zone) name.
  -- @tparam string spawn_mode how the new CAP will be spawned.
  -- Can be 'parking' or 'air'.
  function gcicap.spawnCAP(side, zone, spawn_mode)
    -- increase flight number
    gcicap[side].cap.flight_num = gcicap[side].cap.flight_num + 1
    -- select random airbase (for now) TODO: choose closest airfield
    local airbase = getRandomAirfield(side)
    local group_name = "CAP "..side.." "..gcicap[side].cap.flight_num
    -- define size of the flight
    local size = gcicap[side].cap.group_size
    if size == "randomized" then
      size = math.random(1,2)*2
    else
      size = tonumber(size)
    end
    -- actually spawn something
    local group = gcicap.spawnFighterGroup(side, group_name, size, airbase, spawn_mode, "cap", zone.name)
    --local ctl = group:getController()
    --ctl:setOption(AI.Option.Air.id.RADAR_USING, AI.Option.Air.val.RADAR_USING.FOR_ATTACK_ONLY)
    gcicap[side].supply = gcicap[side].supply - 1
    -- keep track of the flight
    local flight = gcicap.Flight:new(group, airbase, "cap", zone)
    -- task the group, for some odd reason we have to wait until we use setTask
    -- on a freshly spawned group.
    mist.scheduleFunction(gcicap.Flight.taskWithCAP, {flight}, timer.getTime() + 5)
    return group
  end

  --- Spawns a GCI flight.
  -- @tparam string side side for the new GCI.
  -- @tparam Unit intruder unit to intercept.
  -- @tparam Airbase airbase airbase at which to spawn the GCI flight.
  function gcicap.spawnGCI(side, intruder, airbase)
    -- increase flight number
    gcicap[side].gci.flight_num = gcicap[side].gci.flight_num + 1
    -- select closest airfield to unit
    local intruder_unit = gcicap.getFirstActiveUnit(intruder.group)
    local closest_af = gcicap.getClosestAirfieldToUnit(side, intruder_unit)
    if closest_af then
      airbase = closest_af
    else
      gcicap.log:warn("Couldn't find close airfield for GCI. Choosing one at random.")
      airbase = getRandomAirfield(side)
    end
    local tgt_units = intruder.group:getUnits()
    local group_name = "GCI "..side.." "..gcicap[side].gci.flight_num
    -- define size of the flight
    local size = gcicap[side].gci.group_size
    if size == "randomized" then
      size = math.random(1,2)*2
    elseif size == "dynamic" then
      size = #tgt_units
    else
      size = tonumber(size)
    end
    -- actually spawn something
    local group = gcicap.spawnFighterGroup(side, group_name, size, airbase, gcicap[side].gci.spawn_mode, "gci")
    local ctl = group:getController()
    -- make the GCI units only use their radar for attacking
    ctl:setOption(AI.Option.Air.id.RADAR_USING, AI.Option.Air.val.RADAR_USING.FOR_ATTACK_ONLY)
    gcicap[side].supply = gcicap[side].supply - 1
    -- keep track of the flight
    local flight = gcicap.Flight:new(group, airbase, "gci", intruder)
    -- vector the interceptor group on the target the first time.
    mist.scheduleFunction(gcicap.Flight.vectorToTarget, {flight, intruder}, timer.getTime() + 5)
    return group
  end

  --- Initialization function
  -- Checks if all template units are present. Creates
  -- border polygons if borders enabled.
  -- @todo complete documentation.
  function gcicap.init()
    for i, side in pairs(gcicap.sides) do
      if not (checkForTemplateUnits(side) and checkForTriggerZones(side)) then
        return false
      end
      if gcicap[side].borders_enabled then
        gcicap[side].border = mist.getGroupPoints(gcicap[side].border_group)
      end
      gcicap[side].intruders = {}
      gcicap[side].cap.zones = {}
      gcicap[side].cap.flights = {}
      gcicap[side].gci.flights = {}
      gcicap[side].cap.flight_num = 0
      gcicap[side].gci.flight_num = 0
      gcicap[side].airfields = getAirfields(side)

      if gcicap[side].cap.enabled then
        -- loop through all zones
        for i = 1, gcicap[side].cap.zones_count do
          local zone_name = gcicap[side].cap.zone_name..i
          local point = trigger.misc.getZone(zone_name).point
          local size = trigger.misc.getZone(zone_name).radius

          -- create zone table
          gcicap[side].cap.zones[i] = {
            name = zone_name,
            pos = point,
            radius = size,
            patrol_count = 0,
          }
        end

        for i = 1, gcicap[side].cap.groups_count do
          local spawn_mode = "parking"
          if gcicap[side].cap.start_airborne then
            spawn_mode = "in-zone"
          end
          -- try to fill all zones
          local zone = gcicap[side].cap.zones[i]
          -- if we have more flights than zones we select one random zone
          if zone == nil then
            zone = gcicap[side].cap.zones[math.random(1, gcicap[side].cap.zones_count)]
          end
          -- actually spawn the group
          --local grp = gcicap.spawnCAP(side, zone, spawn_mode)
          -- delay the spawn by gcicap interval seconds after one another
          local spawn_delay = (i - 1) * gcicap.initial_spawn_delay
          mist.scheduleFunction(gcicap.spawnCAP, {side, zone, spawn_mode}, timer.getTime() + spawn_delay)
        end
      end
    end
    -- add event handler managing despawns
    return true
  end

  --- Main function.
  -- Run approx. every @{gcicap.interval} sconds. A random amount
  -- of 0 to 2 seconds is added for declustering.
  -- @todo do the "declustering" at a different level. Probably
  -- more efficient.
  function gcicap.main()
    for i, side in pairs(gcicap.sides) do
      -- update list of occupied airfields
      gcicap[side].airfields = getAirfields(side)
      -- update list of all aircraft
      gcicap[side].active_aircraft = getAllActiveAircrafts(side)
      -- update list of all EWR
      gcicap[side].active_ewr = getAllActiveEWR(side)
    end

    -- check for airspace intrusions after updating all the lists
    for i, side in pairs(gcicap.sides) do
      if gcicap[side].cap.enabled then
        manageCAP(side)
      end
      checkForAirspaceIntrusion(side)
      handleIntrusion(side)
      garbageCollector(side)
    end
  end

end

if gcicap.init() then
  local start_delay = gcicap.initial_spawn_delay * math.max(gcicap.red.cap.groups_count, gcicap.blue.cap.groups_count)
  mist.scheduleFunction(gcicap.main, {}, timer.getTime() + start_delay, gcicap.interval)
end

-- vim: sw=2:ts=2
