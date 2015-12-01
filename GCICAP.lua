--[[
Originally created by Snafu, enhanced and further modified by Stonehouse,
Rivvern, Chameleon Silk.

Rewritten by lukrop.

Copyright (c) 2015 Snafu, Stonehouse, Rivvern, Chameleon Silk, lukrop.

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

]]--

gcicap = {}
gcicap.red = {}
gcicap.red.gci = {}
gcicap.red.cap = {}
gcicap.blue = {}
gcicap.blue.gci = {}
gcicap.blue.cap = {}
gcicap.cap = {}
gcicap.gci = {}

-- enable/disable log messages completly
gcicap.log = true
-- sets how verbose the log output will be. Possible values are "info",
-- "warning" and "error". I recommend "error" for production.
gcicap.log_level = "info"

-- interval, in seconds, of main and vectorToTarget functions
gcicap.interval = 30

-- CAP units only engage if enemy units intrude their airspace
gcicap.red.borders_enabled = false
gcicap.blue.borders_enabled = false

-- CAP minimum and maximum altitudes in meters
gcicap.cap.min_alt = 4500
gcicap.cap.max_alt = 7500

-- maximum engage distance for CAP flights as long as they are on patrol.
-- this might be overruled by an intercept vector given from
-- ground control (EWR).
gcicap.cap.max_engage_distance = 15000

-- amount of waypoints inside the CAP zone.
gcicap.cap.waypoints_count = 10

-- set to true for CAP flight to start airborne at script initialisation,
-- false for taking off from airfield at start
gcicap.red.cap.start_airborne = true
gcicap.blue.cap.start_airborne = true

-- amount of CAP zones (placed with triggerzones in the ME) for each side
gcicap.red.cap.zones_count = 3
gcicap.blue.cap.zones_count = 3

-- amount of CAP groups concurrently in the air.
gcicap.red.cap.groups_count = 3
gcicap.blue.cap.groups_count = 3

-- can be "2", "4" or "randomized"
-- if "2" it consists of 2 planes, if "4" it consists of 4 planes
-- if "randomized", the CAP groups consist of either 2 or 4 planes
gcicap.red.cap.group_size = "2"
gcicap.blue.cap.group_size = "2"

-- maximum number of at the same time ongoing active intercepts
gcicap.red.gci.groups_count = 2
gcicap.blue.gci.groups_count = 2

-- can be "2", "4", "randomized" or "dynamic"
-- if "2" it consists of 2 planes, if "4" it consists of 4 planes
-- if "randomized", the CAP groups consist of either 2 or 4 planes
-- if "dynamic" it has the same size as the intercepted group
gcicap.red.gci.group_size = "dynamic"
gcicap.blue.gci.group_size = "dynamic"

-- enable messages from GCI
gcicap.red.gci.messages = true
gcicap.blue.gci.messages = true

-- how long a GCI message will be shown in seconds
gcicap.gci.message_time = 5

-- display GCI messages with metric measurment. If false the imperial system is used.
gcicap.red.gci.messages_metric = true
gcicap.blue.gci.messages_metric = false

-- names of groups which will receive GCI messages
-- leave blank for all groups of coalition
-- e.g. gcicap.red.gci.messages_to = { "my group 1", "GCI Flight" }
gcicap.red.gci.messages_to = {}
gcicap.red.gci.messages_to = {}

-- can be "parking", "takeoff" or "air" and defines the way the fighters spawn
-- takeoff is NOT RECOMMENDED currently since their occur timing issues with tasking
-- if a flight is queued for takeoff and not already in the game world while getting tasked
gcicap.red.cap.spawn_mode = "parking"
gcicap.red.gci.spawn_mode = "parking"

gcicap.blue.cap.spawn_mode = "parking"
gcicap.blue.gci.spawn_mode = "parking"

-- option to hide or reveal air units in the mission.
-- This setting affects both sides. Valid values are true/false to make units hidden/unhidden
gcicap.blue.hide_groups = false
gcicap.red.hide_groups = false

-- wether the side does spawn groups for combat air patrols.
gcicap.red.cap.enabled = true
gcicap.blue.cap.enabled = true

-- wether the side does spawn groups for ground controlled intercepts
gcicap.red.gci.enabled = true
gcicap.blue.gci.enabled = true

-- if set to true limits the amount of groups a side can spawn.
gcicap.red.limit_resources = false
gcicap.blue.limit_resources = false

-- amount of groups(!) for blue and red
gcicap.red.supply = 24
gcicap.blue.supply = 24

-- time limit, in seconds, after which a group gets removed, if a unit of it is still
-- on the ground. Consider big airfields and long taxi ways.
-- gcicap.stuck_limit = 1080

-- radius for cleaning up wrecks around airfields
-- gcicap.cleanup_radius = 3000

-- name of the triggerzone which defines a CAP zone, postfixed with the number of
-- the zone. e.g. "redCAPzone3" or "blueCAPzone1".
gcicap.red.cap.zone_name = 'redCAPzone'
gcicap.blue.cap.zone_name = 'blueCAPzone'

-- name of group which waypoints define the border
gcicap.red.border_group = 'redborder'
gcicap.blue.border_group = 'blueborder'

-- i'd vouch for a better default but for the sake of backwards compatibility with
-- current missions we go with the old default.
gcicap.template_prefix = '__TMP__'
gcicap.template_count = 4

gcicap.sides = { "red", "blue" }
gcicap.tasks = { "cap", "gci" }

-- wether to also acquire targets by AWACS aircraft
gcicap.red.awacs = true
gcicap.blue.awacs = true

-- shortcut to the bullseye
gcicap.red.bullseye = coalition.getMainRefPoint(coalition.side.RED)
gcicap.blue.bullseye = coalition.getMainRefPoint(coalition.side.BLUE)

function gcicap.coalitionToSide(coal)
  if coal == coalition.side.NEUTRAL then return "neutral"
  elseif coal == coalition.side.RED then return "red"
  elseif coal == coalition.side.BLUE then return "blue"
  end
end

function gcicap.sideToCoalition(side)
  if side == "neutral" then return coalition.side.NEUTRAL
  elseif side == "red" then return coalition.side.RED
  elseif side == "blue" then return coalition.side.BLUE
  end
end

-- returns airfields of given side which are marked with
-- triggerzones (triggerzone name is exactly the same as airfield name).
function gcicap.getAirfields(side)
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
function gcicap.getAllActiveAircrafts(side)
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
function gcicap.getAllActiveEWR(side)
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

function gcicap.checkForAirspaceIntrusion(side)
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
        ac_pos = ac:getPoint()
        ac_group = ac:getGroup()

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
            if gcicap.gci.messages then
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
              if #gcicap[side].gci.message_for > 0 then
                msg_for.units = {}
                for g, group_name in pairs(gcicap[side].gci.message_for) do
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
function gcicap.getRandomAirfield(side)
  local rand = math.random(1, #gcicap[side].airfields)
  return gcicap[side].airfields[rand]
end

-- returns the closest airfield, of given side, and it's distance to the given unit
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
  return {airfield = closest_af, distance = min_distance}
end

-- returns the closest flights, of given side, and their distances to the given unit
function gcicap.getClosestFlightsToUnit(side, unit)
  if unit == nil then return nil end
  local units = gcicap[side].cap.flights
  local closest_flights = {}
  if #units == 0 then
    if gcicap.log then
      env.info("[GCICAP] No CAP flights of side "..side.." active")
    end
    return nil
  else
    local unit_pos = mist.utils.makeVec2(unit:getPoint())
    local min_distance = -1
    --local closest_flight = nil
    for i = 1, #units do
      if units[i].group then
        local u = gcicap.getFirstActiveUnit(units[i].group)
        local u_pos = mist.utils.makeVec2(u:getPoint())
        local distance = mist.utils.get2DDist(unit_pos, u_pos)
        table.insert(closest_flights, {flight = units[i], distance = distance })
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
    return closest_flights
  end
end

function gcicap.buildFirstWP(airbase, spawn_mode)
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

-- Returns a table containting a CAP route, originating from given airbase
-- inside given zone. Optionally you can specify the amount of waypoints
-- inside the zone.
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

    if i == wp_count then
      points[i].task = {
        id = 'WrappedAction',
        params = {
          action = {
            id = 'Script',
            params = {
              command = "local group = ...\
              local flight = gcicap.getFlight(group)\
              gcicap.taskWithRTB(flight)"
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

function gcicap.getFlightIndex(group)
  if type(group) ~= "string" then
    if group:getName() then
      group = group:getName()
    else
      return false
    end
  end
  for i, side in ipairs(gcicap.sides) do
    for j, task in ipairs(gcicap.tasks) do
      for n = 1, #gcicap[side][task].flights do
        if gcicap[side][task].flights[n].group_name == group then
          return {side = side, task = task, index = n}
        end
      end
    end
  end
  return false
end

function gcicap.getFlight(group)
  f = gcicap.getFlightIndex(group)
  if f then
    return gcicap[f.side][f.task].flights[f.index]
  else
    return false
  end
end

function gcicap.registerFlight(side, task, airbase, group, param)
  local flight = {}
  flight.group_name = group:getName()
  flight.group = group
  if task == "cap" then
    flight.zone = param
    flight.zone_name = param.name
  elseif task == "gci" then
    flight.target = param
    flight.target_group = param.group
  end
  if task == "cap" then
    flight.intercepting = false
  else
    flight.intercepting = true
  end
  flight.rtb = false
  flight.airbase = airbase
  table.insert(gcicap[side][task].flights, flight)
  return gcicap[side][task].flights[#gcicap[side][task].flights]
end

function gcicap.removeFlight(name)
  f = gcicap.getFlightIndex(name)
  if gcicap.log then
    env.info("[GCICAP] Removing flight: "..name)
  end
  local flight = gcicap[f.side][f.task].flights[f.index]
  if flight.zone then
    if not flight.intercepting then
      gcicap.leaveCAPZone(flight)
    end
  end
  table.remove(gcicap[f.side][f.task].flights, f.index)
end

function gcicap.setFlightIsRTB(group)
  local flight = gcicap.getFlight(group)
  flight.rtb = true
end

function gcicap.setFlightIsIntercepting(group, intercepting, target)
  local flight = gcicap.getFlight(group)
  flight.intercepting = intercepting
  if target then
    flight.target = target
  else
    flight.target = nil
  end
end

function gcicap.leaveCAPZone(flight)
  local zone = flight.zone
  if zone.patrol_count <= 1 then
    zone.patrol_count = 0
    zone.patroled = false
  else
    zone.patrol_count = zone.patrol_count - 1
  end
end

function gcicap.enterCAPZone(flight)
  flight.intercepting = false
  local zone = flight.zone
  zone.patrol_count = zone.patrol_count + 1
  if not zone.patroled then
    zone.patroled = true
  end
end

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

function gcicap.vectorToTarget(flight, intruder, cold)
  local target = nil
  if intruder.group then
    target = gcicap.getFirstActiveUnit(intruder.group)
  end
  if target == nil or intruder.group == nil then return end
  -- check if interceptor even still exists
  if flight.group:isExist() then
    if target:isExist() then
      local target_pos = target:getPoint()
      local ctl = flight.group:getController()

      local gci_task = {
        id = 'Mission',
        params = {
          route = {
            points = {
              [1] = {
                alt = target_pos.y,
                x = target_pos.x,
                y = target_pos.z,
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
                        local flight = gcicap.getFlight(group)\
                        if flight.zone then\
                          gcicap.taskWithCAP(flight)\
                        else\
                          gcicap.taskWithRTB(flight)\
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
      if flight.zone and not flight.intercepting then
        gcicap.leaveCAPZone(flight)
      end

      intruder.intercepted = true
      flight.intercepting = true
      ctl:setTask(gci_task)

      if not cold then
        --gcicap.taskEngageInZone(flight.group, target_pos, 15000)
        gcicap.taskEngageGroup(flight.group, intruder.group)
      end

      if gcicap.log then
        env.info("[GCICAP] Vectoring "..flight.group:getName().." to "..
                 intruder.group:getName().." ("..target:getName()..").")
      end

      -- reschedule function until either the interceptor or the intruder is dead
      mist.scheduleFunction(gcicap.vectorToTarget, {flight, intruder, cold},
                            timer.getTime() + gcicap.interval)
      -- the target is dead, resume CAP or RTB
    else
      if flight.zone then
        -- send CAP back to work
        gcicap.taskWithCAP(flight)
      else
        -- send GCI back to homeplate
        gcicap.taskWithRTB(flight)
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

function gcicap.taskWithCAP(flight, cold)
  local group = flight.group
  local ctl = group:getController()
  local cap_route = gcicap.buildCAPRoute(flight.zone.name, gcicap.cap.waypoints_count)
  local cap_task = {
    id = 'Mission',
    params = {
      route = cap_route
    }
  }
  ctl:setTask(cap_task)
  gcicap.enterCAPZone(flight)
  ctl:setOption(AI.Option.Air.id.RADAR_USING, AI.Option.Air.val.RADAR_USING.FOR_SEARCH_IF_REQUIRED)

  if not cold then
    gcicap.taskEngage(group)
  end
  if gcicap.log then
    env.info("[GCICAP] Tasking "..group:getName().." with CAP in zone "..flight.zone.name)
  end
end

function gcicap.taskWithRTB(flight, airbase, cold)
  if not airbase then
    airbase = flight.airbase
  end

  if flight.zone then
    gcicap.leaveCAPZone(flight)
  end
  flight.rtb = true
  local group = flight.group
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

function gcicap.spawnFighterGroup(side, name, size, airbase, spawn_mode, cold)
  local template_unit = Unit.getByName(gcicap.template_prefix..side..math.random(1, gcicap.template_count))
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
  group_data.country = template_group.country
  group_data.category = template_group.category
  group_data.task = "CAP"

  route.points = {}
  route.points[1] = gcicap.buildFirstWP(airbase, spawn_mode)
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

function gcicap.despawnHandler(event)
  if event.id == world.event.S_EVENT_PILOT_DEAD or
    event.id == world.event.S_EVENT_ENGINE_SHUTDOWN then
    local unit = event.initiator
    local group = unit:getGroup()
    local side = gcicap.coalitionToSide(unit:getCoalition())
    local flight = gcicap.getFlight(group:getName())
    -- check if we manage this group
    if flight then
      if event.id == world.event.S_EVENT_PILOT_DEAD then
        -- it was the last unit of the flight so remove the flight
        if group:getSize() == 1 then
          gcicap.removeFlight(group:getName())
        end
      else
        -- check if the flight is order to RTB
        if flight.rtb then
          -- check if all units of the group are on the ground
          local all_landed = true
          for u, unit in pairs (group:getUnits()) do
            if unit:inAir() then all_landed = false end
          end
          -- if al units are on the ground remove the flight and
          -- remove the units from the game world after 300 seconds
          if all_landed then
            gcicap.removeFlight(group:getName())
            gcicap[side].supply = gcicap[side].supply + 1
            mist.scheduleFunction(Group.destroy, {group}, timer.getTime() + 300)
          end
        end
      end
    end
  end
end

function gcicap.spawnCAP(side, zone, spawn_mode)
  -- increase flight number
  gcicap[side].cap.flight_num = gcicap[side].cap.flight_num + 1
  -- select random airbase (for now) TODO: choose closest airfield
  local airbase = gcicap.getRandomAirfield(side)
  local group_name = "CAP "..side.." "..gcicap[side].cap.flight_num
  -- define size of the flight
  local size = gcicap[side].cap.group_size
  if size == "randomized" then
    size = math.random(1,2)*2
  else
    size = tonumber(size)
  end
  -- actually spawn something
  local group = gcicap.spawnFighterGroup(side, group_name, size, airbase, spawn_mode)
  --local ctl = group:getController()
  --ctl:setOption(AI.Option.Air.id.RADAR_USING, AI.Option.Air.val.RADAR_USING.FOR_ATTACK_ONLY)
  gcicap[side].supply = gcicap[side].supply - 1
  -- keep track of the flight
  local flight = gcicap.registerFlight(side, "cap", airbase, group, zone)
  -- task the group, for some odd reason we have to wait until we use setTask
  -- on a freshly spawned group.
  mist.scheduleFunction(gcicap.taskWithCAP, {flight}, timer.getTime() + 5)
  return group
end

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
    airbase = gcicap.getRandomAirfield(side)
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
  local group = gcicap.spawnFighterGroup(side, group_name, size, airbase, gcicap[side].gci.spawn_mode)
  local ctl = group:getController()
  -- make the GCI units only use their radar for attacking
  ctl:setOption(AI.Option.Air.id.RADAR_USING, AI.Option.Air.val.RADAR_USING.FOR_ATTACK_ONLY)
  gcicap[side].supply = gcicap[side].supply - 1
  -- keep track of the flight
  local flight = gcicap.registerFlight(side, "gci", airbase, group, intruder)
  -- vector the interceptor group on the target the first time.
  mist.scheduleFunction(gcicap.vectorToTarget, {flight, intruder}, timer.getTime() + 5)
  return group
end

function gcicap.manageCAP(side)
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

function gcicap.handleIntrusion(side)
  for i = 1, #gcicap[side].intruders do
    local intruder = gcicap[side].intruders[i]
    -- check if we need to do something about him
    if not intruder.intercepted and intruder.group then
      -- check if we have something to work with
      if #gcicap[side].cap.flights > 0 or
        #gcicap[side].gci.flights < gcicap[side].gci.groups_count then
        -- get closest unit
        local closest_cap = nil
        local intruder_unit = gcicap.getFirstActiveUnit(intruder.group)
        local closest_flights = gcicap.getClosestFlightsToUnit(side, intruder_unit)
        local cap_avail = false
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
        if cap_avail then
          -- check if we have a airfield which is closer to the unit than the CAP group
          local closest_af = gcicap.getClosestAirfieldToUnit(side, intruder_unit)
          if closest_af then
            if closest_cap.distance < closest_af.distance then
              -- task CAP flight with intercept
              gcicap.vectorToTarget(closest_cap.flight, intruder)
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
end

function gcicap.init()
  for i, side in ipairs(gcicap.sides) do
    if gcicap[side].borders_enabled then
      gcicap[side].border = mist.getGroupPoints(gcicap[side].border_group)
    end
    gcicap[side].intruders = {}
    gcicap[side].cap.zones = {}
    gcicap[side].cap.flights = {}
    gcicap[side].gci.flights = {}
    gcicap[side].cap.flight_num = 0
    gcicap[side].gci.flight_num = 0
    gcicap[side].airfields = gcicap.getAirfields(side)

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
end

function gcicap.main()
  for i, side in ipairs(gcicap.sides) do
    -- update list of occupied airfields
    gcicap[side].airfields = gcicap.getAirfields(side)
    -- update list of all aircraft
    gcicap[side].active_aircraft = gcicap.getAllActiveAircrafts(side)
    -- update list of all EWR
    gcicap[side].active_ewr = gcicap.getAllActiveEWR(side)
  end
  -- check for airspace intrusions after updating all the lists
  for i, side in ipairs(gcicap.sides) do
    gcicap.manageCAP(side)
    gcicap.checkForAirspaceIntrusion(side)
    gcicap.handleIntrusion(side)
  end
end

do
  gcicap.init()
  --local start_delay = gcicap.interval * math.max(gcicap.red.cap.groups_count, gcicap.blue.cap.groups_count)
  mist.scheduleFunction(gcicap.main, {}, timer.getTime(), gcicap.interval + math.random(0,2))
end

-- vim: sw=2:ts=2
