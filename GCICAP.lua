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

--- Enable/disable log messages completly
gcicap.log = true

--- Sets how verbose the log output will be.
-- Possible values are "info", "warning" and "error".
-- I recommend "error" for production.
gcicap.log_level = "info"

--- Interval, in seconds, of main and vectorToTarget functions.
-- Default 30 seconds.
gcicap.interval = 30

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

--- Amount of waypoints inside the CAP zone.
-- Default 10.
gcicap.cap.waypoints_count = 10

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

-- shortcut to the bullseye
gcicap.red.bullseye = coalition.getMainRefPoint(coalition.side.RED)
gcicap.blue.bullseye = coalition.getMainRefPoint(coalition.side.BLUE)

gcicap.sides = { "red", "blue" }
gcicap.tasks = { "cap", "gci" }

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
      f.group = group
      f.group_name = group:getName()
      f.airbase = airbase
      f.task = task
      if task == "cap" then
        f.zone = param
        f.zone_name = param.name
      elseif task == "gci" then
        f.target = param
        f.target_group = param.group
      end
      if task == "cap" then
        f.intercepting = false
      else
        f.intercepting = true
      end
      f.rtb = false

      setmetatable(f, self)
      self.__index = self

      table.insert(gcicap[side][task].flights, f)
      f.index = #gcicap[side][task].flights
      env.info("[GCICAP] Registered flight: "..f.group_name)

      return f
    else
      return nil
    end
  end

  --- Removes the flight
  -- @tparam gcicap.Flight self flight object
  function gcicap.Flight:remove()
    if self.zone then
      if not self.intercepting then
        --gcicap.Flight.leaveCAPZone(self)
        self:leaveCAPZone()
      end
    end
    table.remove(gcicap[self.side][self.task].flights, self.index)
  end

  --- Decreases active flights counter in this flights zone.
  -- Actually just decreases the active flights
  -- counter of a zone. Does NOT task the flight itself.
  function gcicap.Flight:leaveCAPZone()
    local zone = self.zone
    if zone.patrol_count <= 1 then
      zone.patrol_count = 0
      zone.patroled = false
    else
      zone.patrol_count = zone.patrol_count - 1
    end
  end

  --- Increases active flights counter in this flights zone.
  -- Actually just increases the active flights
  -- counter of a zone. Does NOT task the flight itself.
  function gcicap.Flight:enterCAPZone()
    self.intercepting = false
    local zone = self.zone
    zone.patrol_count = zone.patrol_count + 1
    if not zone.patroled then
      zone.patroled = true
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
      if target:isExist() and target:inAir() then
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
                            if flight.zone then\
                              flight:taskWithCAP()\
                            else\
                              flight:taskWithRTB()\
                            end\
                          else\
                            env.error('Could not find flight')\
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
          --gcicap.Flight.leaveCAPZone(self)
          self:leaveCAPZone()
        end

        intruder.intercepted = true
        self.intercepting = true
        ctl:setTask(gci_task)

        if not cold then
          --gcicap.taskEngageInZone(flight.group, target_pos, 15000)
          gcicap.taskEngageGroup(self.group, intruder.group)
        end

        if gcicap.log then
          env.info("[GCICAP] Vectoring "..self.group:getName().." to "..
                   intruder.group:getName().." ("..target:getName()..").")
        end

        -- reschedule function until either the interceptor or the intruder is dead
        --mist.scheduleFunction(gcicap.vectorToTarget, {flight, intruder, cold},
        --                      timer.getTime() + gcicap.interval)
        mist.scheduleFunction(gcicap.Flight.vectorToTarget, {self, intruder, cold},
        timer.getTime() + gcicap.interval)
        -- the target is dead, resume CAP or RTB
      else
        if self.zone then
          -- send CAP back to work
          self:taskWithCAP()
        else
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
    local group = self.group
    local ctl = group:getController()
    local cap_route = gcicap.buildCAPRoute(self.zone.name, gcicap.cap.waypoints_count)
    local cap_task = {
      id = 'Mission',
      params = {
        route = cap_route
      }
    }
    ctl:setTask(cap_task)
    self:enterCAPZone()
    ctl:setOption(AI.Option.Air.id.RADAR_USING, AI.Option.Air.val.RADAR_USING.FOR_SEARCH_IF_REQUIRED)

    if not cold then
      gcicap.taskEngage(group)
    end
    if gcicap.log then
      env.info("[GCICAP] Tasking "..group:getName().." with CAP in zone "..self.zone.name)
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
      if not gcicap[side].limit_resources or
        (gcicap[side].limit_resources and gcicap[side].supply > 0) then
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
              alt = 2000,
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

    if gcicap.log then
      env.info("[GCICAP] Tasking "..group:getName().." with RTB to "..airbase:getName())
    end
  end

  --- Functions
  -- @section gcicap
  local function checkForTemplateUnits(side)
    if gcicap[side].gci.enabled then
      for i = 1, gcicap.template_count do
        local unit = gcicap.gci.template_prefix..side..i
        if not Unit.getByName(unit) then
          env.error("[GCICAP] GCI template unit missing: "..unit, true)
          return false
        end
      end
    end
    if gcicap[side].cap.enabled then
      for i = 1, gcicap.template_count do
        local unit = gcicap.cap.template_prefix..side..i
        if not Unit.getByName(unit) then
          env.error("[GCICAP] CAP template unit missing: "..unit, true)
          return false
        end
      end
    end
    return true
  end

  local function manageCAP(side)
    local patroled_zones = 0

    for i = 1, #gcicap[side].cap.zones do
      local zone = gcicap[side].cap.zones[i]

      -- see if we can send a new CAP into the zone
      if not zone.patroled then
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
    if gcicap.log then
      env.info("[GCICAP] "..side..": patrols in "..patroled_zones.."/"..gcicap[side].cap.zones_count.." zones.")
    end
  end

  local function handleIntrusion(side)
    for i = 1, #gcicap[side].intruders do
      local intruder = gcicap[side].intruders[i]
      if intruder.group then
        if intruder.group:isExist() then
          -- check if we need to do something about him
          if not intruder.intercepted then
            -- check if we have something to work with
            if #gcicap[side].cap.flights > 0 or
              #gcicap[side].gci.flights < gcicap[side].gci.groups_count then
              -- get closest unit
              local closest_cap = nil
              local intruder_unit = gcicap.getFirstActiveUnit(intruder.group)
              local closest_flights = gcicap.getClosestFlightsToUnit(side, intruder_unit)
              local cap_avail = false
              if closest_flights then
                for j = 1, #closest_flights do
                  closest_cap = closest_flights[j]
                  cap_avail = (not closest_cap.flight.rtb) and (not closest_cap.flight.intercepting)
                  if cap_avail then
                    if gcicap.log then
                      env.info("[GCICAP] Found close CAP flight which is available for tasking")
                      env.info("name: "..closest_cap.flight.group:getName())
                    end
                    break
                  end
                end
              end
              if cap_avail then
                -- check if we have a airfield which is closer to the unit than the CAP group
                local closest_af = gcicap.getClosestAirfieldToUnit(side, intruder_unit)
                if closest_af then
                  if closest_cap.distance < closest_af.distance then
                    -- task CAP flight with intercept
                    closest_cap.flight:vectorToTarget(intruder)
                    return
                  end
                end
              end
              if (not gcicap[side].limit_resources
                  or (gcicap[side].limit_resources and gcicap[side].supply > 0))
                and gcicap[side].gci.enabled then
                -- spawn CGI
                gcicap.spawnGCI(side, intruder)
                if gcicap.log then
                  env.info("[GCICAP] Airfield closer to intruder than CAP flight. Starting GCI.")
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
    side = gcicap.sideToCoalition(side)

    local coal_airfields = coalition.getAirbases(side)
    local gcicap_airfields = {}

    -- loop over all coalition airfields
    for i = 1, #coal_airfields do
      -- get name of airfield
      local af_name = coal_airfields[i]:getName()
      -- check if a triggerzone exists with that exact name
      if mist.DBs.zonesByName[af_name] then
        -- add it to our airfield list for gcicap
        -- gcicap_airfields[#gcicap_airfields + 1] = { name = af_name }
        gcicap_airfields[#gcicap_airfields + 1] = coal_airfields[i]
      end
    end

    if gcicap.log and #gcicap_airfields == 0 then
      env.warning("[GCICAP] No airbases for " .. side .. " found.")
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
    if gcicap.log and #active_aircraft == 0 then
      env.warning("[GCICAP] No active aircraft for " .. side)
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
            table.insert(active_ewr, vec)
          end
          if (vec_type == "A-50" and gcicap[side].awacas)
            or (vec_type == "E-2D" and gcicap[side].awacs)
            or (vec_type == "E-3A" and gcicap[side].awacs) then
            table.insert(active_ewr, vec)
          end
        end
      end
    end
    if gcicap.log and #active_ewr == 0 then
      env.warning ("[GCICAP] No active EWR for " .. side)
    end
    return active_ewr
  end

  local function checkForAirspaceIntrusion(side)
    -- init some local vars
    local border = gcicap[side].border
    local active_ewr = gcicap[side].active_ewr
    local intruder_count = 0
    local intruder_side = ""
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
              local ewr_controller = active_ewr[n]:getGroup():getController()
              -- and check if the EWR detected the aircraft
              if ewr_controller:isTargetDetected(ac, RADAR) then
                ewr = active_ewr[n]
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
                  if gcicap.log then
                    env.info("[GCICAP] "..ac_group:getName().." ("..ac:getName()..
                             ") intruded airspace of "..side.." detected by "..ewr:getGroup():getName()..
                             " ("..ewr:getName()..").")
                  end

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
            end -- if ac_detected
          end -- if ac_group is existing
        end -- if ac ~= nil
      end -- for #active_ac
    end -- if active_ac > 0 and active_ewr > 0
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
    if unit == nil then return nil end
    local airfields = gcicap[side].airfields

    if #airfields == 0 then
      if gcicap.log then
        env.warning("[GCICAP] There are no airfields of side " .. side)
      end
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
    return {airfield = closest_af, distance = min_distance}
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
    if unit == nil then return nil end
    local flights = gcicap[side].cap.flights
    local closest_flights = {}
    if #flights == 0 then
      if gcicap.log then
        env.info("[GCICAP] No CAP flights of side "..side.." active")
      end
      return nil
    else
      local unit_pos = mist.utils.makeVec2(unit:getPoint())
      local min_distance = -1
      --local closest_flight = nil
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
  -- @tparam[opt] number wp_count count of waypoints to
  -- create.
  function gcicap.buildCAPRoute(zone, wp_count)
    -- randomize waypoint count if none given
    if wp_count == nil then
      wp_count = math.random(5,10)
    end
    local points = {}
    -- create waypoints
    for i = 1, wp_count do
      -- get a random point inside the CAP zone
      local point = mist.getRandomPointInZone(zone)
      -- build a basic waypoint
      points[i] = mist.fixedWing.buildWP(point)
      local alt = math.random(gcicap.cap.min_alt, gcicap.cap.max_alt)
      local ground_level = land.getHeight(point)

      -- avoid crashing into hills
      if (alt - 50) < ground_level then
        alt = alt + ground_level
      end

      points[i].alt = alt
      points[i].alt_type = "BARO"
      points[i].x = point.x
      points[i].y = point.y
      points[i].speed = gcicap.cap.speed

      if i == wp_count then
        points[i].task = {
          id = 'WrappedAction',
          params = {
            action = {
              id = 'Script',
              params = {
                command = "local group = ...\
                local flight = gcicap.Flight.getFlight(group)\
                if flight then\
                  flight:taskWithRTB()\
                else\
                  env.error('Could not find flight')\
                end"
              }
            }
          }
        }
      end
    end

    if gcicap.log then
      env.info("[GCICAP] Built CAP route with "..wp_count.." waypoints in "..zone)
    end

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

  --- Tasks group to engage targets inside a zone.
  -- @tparam Group group group to task.
  -- @tparam Vec2|Point center center of the zone.
  -- @tparam number radius zone radius.
  function gcicap.taskEngageInZone(group, center, radius)
    local ctl = group:getController()
    local engage_zone = {
      id = 'EngageTargetsInZone',
      params = {
        point = center,
        radius = radius,
        targetTypes = { [1] = "Air" },
        priority = 0
      }
    }
    ctl:pushTask(engage_zone)
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
  -- @tparam[opt] boolean cold if set to true the newly group won't engage
  -- any enemys until tasked otherwise. Default false.
  -- @treturn Group|nil newly spawned group or nil on failure.
  function gcicap.spawnFighterGroup(side, name, size, airbase, spawn_mode, task, cold)
    local template_unit_name = gcicap[task].template_prefix..side..math.random(1, gcicap.template_count)
    local template_unit = Unit.getByName(template_unit_name)
    if not template_unit then
      env.error("[GCICAP] Can't find template unit with name "..template_unit_name..". This should never happen. Somehow the template unit got deleted.")
      return nil
    end
    local template_group = mist.getGroupData(template_unit:getGroup():getName())
    local template_unit_data = template_group.units[1]
    local airbase_pos = airbase:getPoint()
    local group_data = {}
    local unit_data = {}
    local onboard_num = template_unit_data.onboard_num - 1
    local route = {}

    for i = 1, size do
      unit_data[i] = {}
      unit_data[i].type = template_unit_data.type
      unit_data[i].name = name.." Pilot "..i
      unit_data[i].x = airbase_pos.x
      unit_data[i].y = airbase_pos.z
      unit_data[i].onboard_num =  onboard_num + i
      unit_data[i].groupName = name
      unit_data[i].payload = template_unit_data.payload
      unit_data[i].skill = template_unit_data.skill
      unit_data[i].livery_id = template_unit_data.livery_id
    end

    group_data.units = unit_data
    group_data.groupName = name
    group_data.hidden = gcicap[side].hide_groups
    --group_data.country = template_group.country
    group_data.country = template_unit:getCountry()
    group_data.category = template_group.category
    group_data.task = "CAP"

    route.points = {}
    route.points[1] = buildFirstWp(airbase, spawn_mode)
    group_data.route = route

    if mist.groupTableCheck(group_data) then
      if gcicap.log then
        env.info("[GCICAP] Spawning fighter group "..name.." at "..airbase:getName())
      end
      mist.dynAdd(group_data)
    else
      if gcicap.log then
        env.error("[GCICAP] Couldn't spawn group with following groupTable: ")
        env.error(mist.utils.serialize("[GCICAP] group_data", group_data))
      end
    end

    return Group.getByName(name)
  end

  --- Handle despawns/removal of flights created by GCICAP.
  -- Don't call this function. It's automatically called by MIST.
  -- @param event event table
  function gcicap.despawnHandler(event)
    if event.id == world.event.S_EVENT_DEAD or
      event.id == world.event.S_EVENT_CRASH or
      event.id == world.event.S_EVENT_ENGINE_SHUTDOWN then
      local unit = event.initiator
      local group = unit:getGroup()
      if not group:isExist() then return end
      local side = gcicap.coalitionToSide(unit:getCoalition())
      local flight = gcicap.Flight.getFlight(group:getName())
      -- check if we manage this group
      if flight then
        if event.id == world.event.S_EVENT_DEAD or
          event.id == world.event.S_EVENT_CRASH then
          -- it was the last unit of the flight so remove the flight
          if group:getSize() <= 1 then
            flight:remove()
          end
        else
          -- check if all units of the group are on the ground or damaged
          local all_landed = true
          local someone_damaged = false
          for u, unit in pairs (group:getUnits()) do
            if unit:inAir() then all_landed = false end
            if unit:getLife0() > unit:getLife() then someone_damaged = true end
          end
          -- if al units are on the ground remove the flight and
          -- remove the units from the game world after 300 seconds
          if (all_landed and flight.rtb) or (all_landed and someone_damaged) then
            flight:remove()
            gcicap[side].supply = gcicap[side].supply + 1
            mist.scheduleFunction(Group.destroy, {group}, timer.getTime() + 300)
          end
        end
      end
    end
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
    local group = gcicap.spawnFighterGroup(side, group_name, size, airbase, spawn_mode, "cap")
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
  -- @tparam Airbase airbase airbase where this GCI should spawn.
  function gcicap.spawnGCI(side, intruder, airbase)
    -- increase flight number
    gcicap[side].gci.flight_num = gcicap[side].gci.flight_num + 1
    -- select closest airfield to unit
    local airbase = gcicap.getClosestAirfieldToUnit(side, target)
    if airbase then
      airbase = airbase.airbase
    else
      if gcicap.log then
        env.warning("[GCICAP] Couldn't find close airfield for GCI. Choosing one at random.")
      end
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
      if not checkForTemplateUnits(side) then
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
            patroled = false,
            patrol_count = 0,
          }
        end

        for i = 1, gcicap[side].cap.groups_count do
          local spawn_mode = "parking"
          if gcicap[side].cap.start_airborne then
            spawn_mode = "air"
          end
          -- try to fill all zones
          local zone = gcicap[side].cap.zones[i]
          -- if we have more flights than zones we select one random zone
          if zone == nil then
            zone = gcicap[side].cap.zones[math.random(1, gcicap[side].cap.zones_count)]
          end
          -- actually spawn the group
          local grp = gcicap.spawnCAP(side, zone, spawn_mode)
          -- delay the spawn by 30 seconds after one another
          -- local spawn_delay = (i - 1) * gcicap.interval
          -- mist.scheduleFunction(gcicap.spawnCAP, {side, zone, spawn_mode}, timer.getTime() + spawn_delay)

          if gcicap[side].cap.start_airborne then
            -- if we airstart telport the group into the CAP zone
            -- seems to work only with ME units
            --mist.scheduleFunction(mist.teleportInZone, {grp:getName(), zone.name}, timer.getTime() + 10)
          end
        end
      end
    end
    -- add event handler managing despawns
    mist.addEventHandler(gcicap.despawnHandler)
    return true
  end

  --- Main function.
  -- Run approx. every @{gcicap.interval} sconds. A random amount
  -- of 0 to 2 seconds is added for declustering.
  -- @todo do the "declustering" at a different level. Probably
  -- more efficient.
  function gcicap.main()
    for i, side in ipairs(gcicap.sides) do
      -- update list of occupied airfields
      gcicap[side].airfields = getAirfields(side)
      -- update list of all aircraft
      gcicap[side].active_aircraft = getAllActiveAircrafts(side)
      -- update list of all EWR
      gcicap[side].active_ewr = getAllActiveEWR(side)
    end
    -- check for airspace intrusions after updating all the lists
    for i, side in ipairs(gcicap.sides) do
      manageCAP(side)
      checkForAirspaceIntrusion(side)
      handleIntrusion(side)
    end
  end

end

if gcicap.init() then
  --local start_delay = gcicap.interval * math.max(gcicap.red.cap.groups_count, gcicap.blue.cap.groups_count)
  mist.scheduleFunction(gcicap.main, {}, timer.getTime() + 2, gcicap.interval + math.random(0,2))
end

-- vim: sw=2:ts=2
