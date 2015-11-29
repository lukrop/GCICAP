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

-- CAP minimum and maximum altitudes in meters
gcicap.cap.min_alt = 4500
gcicap.cap.max_alt = 7500

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

-- display GCI messages with metric or imperial units.
gcicap.red.gci.messages_imperial = false
gcicap.blue.gci.messages_imperial = true

-- CAP units only engage if enemy units intrude their airspace
gcicap.red.cap.borders_enabled = false
gcicap.blue.cap.borders_enabled = false

-- can be "parking", "takeoff" or "air" and defines the way the fighters spawn
gcicap.red.cap.spawn_mode = "parking"
gcicap.red.gci.spawn_mode = "parking"

gcicap.blue.cap.spawn_mode = "parking"
gcicap.blue.gci.spawn_mode = "parking"

-- option to hide or reveal air units in the mission.
-- This setting affects both sides. Valid values are true/false to make units hidden/unhidden
gcicap.blue.hide_groups = false
gcicap.red.hide_groups = false

-- wether the side doe combat air patrols.
-- if set to false the side will only do GCI
gcicap.red.cap.enabled = true
gcicap.blue.cap.enabled = true

-- if set to true limits the amount of groups a side can spawn.
gcicap.red.limit_resources = false
gcicap.blue.limit_resources = false

-- amount of groups(!) for blue and red
gcicap.red.supply = 24
gcicap.blue.supply = 24

-- time limit, in seconds, after which a group gets removed, if a unit of it is still
-- on the ground. Consider big airfields and long taxi ways.
gcicap.stuck_limit = 1080

-- radius for cleaning up wrecks around airfields
gcicap.cleanup_radius = 3000

-- enable debug messages
gcicap.debug = true

-- name of the triggerzone which defines a CAP zone, postfixed with the number of
-- the zone. e.g. "redCAPzone3" or "blueCAPzone1".
gcicap.red.cap.zone_name = 'redCAPzone'
gcicap.blue.cap.zone_name = 'blueCAPzone'


-- name of group which waypoints define the border
gcicap.red.border_group = 'redborder'
gcicap.blue.border_group = 'blueborder'

-- i'd vouch for a better default but for the sake of backwards compatibility with
-- current missions we go with the old default.
gcicap.unit_template_prefix = '__TMP__'

gcicap.sides = { "red", "blue" }

-- Time interval in which ongoing intercepts are renewed, NOTE: Do not use too small a value
-- as it interrupts intercepts and resets limit on active GCIs which can cause mission to be spammed by aircraft
--gcicap.tasking_interval = 1800

-- returns airfields of given side which are marked with
-- triggerzones (triggerzone name is exactly the same as airfield name).
function gcicap.getAirfields(side)
    if side == "red" then
        side = coalition.side.RED
    elseif side == "blue" then
        side = coalition.side.BLUE
    end

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

    if gcicap.debug and #gcicap_airfields == 0 then
        env.warning("GCICAP: No airbases for " .. side .. " found.")
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
                active_aircraft[#active_aircraft + 1] = { name = ac }
            end
        end
    end
    if gcicap.debug and #active_aircraft == 0 then
        env.info("GCICAP: No active aircraft for " .. side)
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
                    or vec_type == "Patriot str"
                    or vec_type == "A-50"
                    or vec_type == "E-2D"
                    or vec_type == "E-3A" then
                    active_ewr[#active_ewr + 1] = { name = vec }
                end
            end
        end
    end
    if gcicap.debug and #active_ewr == 0 then
        env.info ("GCICAP: No active EWR for " .. side)
    end
    return active_ewr
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
            local ac = Unit.getByName(active_ac[i].name)
            local ac_detected = false
            local ac_intruded = false
            local ac_pos = {}
            local ac_group = nil
            if ac ~= nil then
                ac_pos = ac:getPosition()
                ac_group = ac:getGroup()

                -- now loop over all ewr units
                for n = 1, #active_ewr do
                    local ewr_group = (Unit.getByName(active_ewr[n].name)):getGroup()
                    local ewr_controller = ewr_group:getController()
                    -- and check if the EWR detected the aircraft
                    if ewr_controller:isTargetDetected(ac, RADAR) then
                        ac_detected = true
                        -- stop once it was detected by one EWR
                        break
                    end
                end

                if ac_detected then
                    -- do we check borders?
                    if gcicap.cap.borders then
                        ac_intruded = mist.pointInPolygon(ac_pos, border)
                    else
                        -- if not the aircarft is always intruding
                        ac_intruded = true
                    end

                    if ac_intruded then
                        intruder_count = intruder_count + 1

                        if gcicap.debug then
                            env.info("GCICAP: Unit: "..active_ac[i].name.." intruded airspace \
                                     of "..side.." detected by "..active_ewr[n].name)
                        end

                        local in_list = false
                        -- check if the intruder is already
                        for j = 1, #gcicap[side].intruders do
                            if gcicap[side].intruders[i].name == active_ac[i].name then
                                in_list = true
                            end
                        end
                        if not in_list then
                            gcicap[side].intruders[#gcicap[side].intruders + 1] = {
                                name = active_ac[i].name,
                                unit = ac,
                                group = ac_group,
                                GroupID = ac_group:getID(),
                                UnitID = ac:getID(),
                                unittype = unit:getTypeName(),
                                size = ac_group:getSize(),
                                -- number = intruder_count,
                                intercepted = false,
                            }
                        end

                        if gcicap.gci.messages then
                            -- show gci messages here
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

function gcicap.getClosestAirfieldToUnit(side, unit)
    local airfields = gcicap[side].airfields

    if #airfields == 0 then
        if gcicap.debug then
            env.error("GCICAP: There are no airfields of side " .. side)
        end
        return
    end

    local unit_pos = unit:getPosition()
    local min_distance = -1
    local closest_af = nil

    for i = 1, #airfields do
        local af = Airbase.getByName(#airfields[i].name)
        local af_pos = af:getPosition()
        local distance = mist.utils.get2DDist(unit_pos, af_pos)

        if distance < min_distance or min_distance == -1 then
            min_distance = distance
            closest_af = af
        end
    end
    return closest_af
end

function gcicap.buildFirstWP(airbase, spawn_mode, cold)
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

    if not cold then
        -- this makes them effectivley go hot
        wp.task = {
            id = "ComboTask",
            params = {
                tasks = {
                    [1] = {
                        id = 'EngageTargets',
                        params = {
                            maxDist = 60,
                            priority = 1,
                            targetTypes = {
                                [1] = "Air"
                            },
                        }
                    },
                },
            },
        }
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
    end

    if gcicap.debug then
        env.info("[GCICAP] Built CAP route with "..wp_count.." waypoints in "..zone)
    end

    local route = {}
    route.points = points
    return route
end

function gcicap.taskEngage(group)
    local ctl = group:getController()
    local hot = {
        id = 'EngageTargets',
        params = {
            maxDist = 60,
            targetTypes = { [1] = "Air" },
            priority = 1
        }
    }
    ctl:pushTask(hot)
end

function gcicap.vectorOnTarget(group, target, cold)
    local target_pos = target:getPoint()
    local ctl = group:getController()
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
                    }
                }
            }
        }
    }
    ctl:setTask(gci_task)

    if not cold then
        gcicap.taskEngage(group)
    end

    if gcicap.debug then
        env.info("[GCICAP] Vectoring "..group:getName().." on "..target:getName())
    end
end

function gcicap.taskWithCAP(group, zone, cold)
    local ctl = group:getController()
    local cap_route = gcicap.buildCAPRoute(zone, 10)
    local cap_task = {
        id = 'Mission',
        params = {
            route = cap_route
        }
    }
    ctl:setTask(cap_task)
    if not cold then
        gcicap.taskEngage(group)
    end
    if gcicap.debug then
        env.info("[GCICAP] Tasking "..group:getName().." with CAP in zone "..zone)
    end
end

function gcicap.spawnFighterGroup(side, name, size, airbase, spawn_mode, cold)
    local template_unit = Unit.getByName(gcicap.unit_template_prefix..side..math.random(1, 4))
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

    route.points = {}
    route.points[1] = gcicap.buildFirstWP(airbase, spawn_mode)
    group_data.route = route

    if mist.groupTableCheck(group_data) then
        if gcicap.debug then
            env.info("[GCICAS] Spawning fighter group "..name.." at "..airbase:getName())
        end
        mist.dynAdd(group_data)
    else
        if gcicap.debug then
            env.error("[GCICAS] Couldn't spawn group with following groupTable: ")
            env.error(mist.utils.serialize("[GCICAS] group_data", group_data))
        end
    end
    return Group.getByName(name)
end

function gcicap.spawnCAP(side, zone, spawn_mode)
    -- increase flight number
    gcicap[side].cap.flight_num = gcicap[side].cap.flight_num + 1
    -- select random airbase (for now) TODO: choose closest airfield
    local airbase = gcicap[side].airfields[math.random(1,#gcicap[side].airfields)]
    local group_name = "CAP "..side.." "..gcicap[side].cap.flight_num
    local size = gcicap[side].cap.group_size
    if size == "randomized" then
        size = math.random(1,2)*2
    else
        size = tonumber(size)
    end
    local group = gcicap.spawnFighterGroup(side, group_name, size, airbase, spawn_mode)
    -- task the group, for some odd reason we have to wait until we use setTask
    -- on a freshly spawned group.
    mist.scheduleFunction(gcicap.taskWithCAP, {group, zone}, timer.getTime() + 5)
    return group
end

function gcicap.manageCAP(side)
    for i = 1, #gcicap[side].cap.flights do
    end
end

function gcicap.init()
    for i, side in ipairs(gcicap.sides) do
        if gcicap[side].cap.borders_enabled then
            gcicap[side].border = mist.getGroupPoints(gcicap[side].border_group)
        end
        gcicap[side].intruders = {}
        gcicap[side].cap.zones = {}
        gcicap[side].cap.flights = {}
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
                }
            end

            -- loop through all flights
            for i = 1, gcicap[side].cap.groups_count do
                local spawn_mode = "takeoff"
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
                local grp = gcicap.spawnCAP(side, zone.name, spawn_mode)

                if gcicap[side].cap.start_airborne then
                    -- if we airstart telport the group into the CAP zone
                    mist.teleportInZone(grp, zone.name)
                end

                gcicap[side].cap.flights[i] = {
                    group = grp,
                    zone_name = zone,
                    intercepting = false,
                }
            end
        end
    end
end

function gcicap.main()
    for i, side in ipairs(gcicap.sides) do
        -- update list of occupied airfields
        gcicap[side].airfields = gcicap.getAirfields(side)
        -- update list of all aircraft
        gcicap[side].active_aircraft = gcicap.getAllActiveAircraft(side)
        -- update list of all EWR
        gcicap[side].active_ewr = gcicap.getAllActiveEWR(side)
        -- check for airspace intrusion
    end
    -- check for airspace intrusions after updating all the lists
    gcicap.checkForAirspaceIntrusion("red")
    gcicap.checkForAirspaceIntrusion("blue")
end

do
    -- local airbase = Airbase.getByName("Gudauta")
    -- local target = Unit.getByName("player")
    -- local target_pos = target:getPoint()
    -- local route = gcicap.buildCAPRoute(target)

    -- local gci = gcicap.spawnFighterGroup("red", "GCI Test", 2, airbase, "takeoff")
    -- local gci = Group.getByName("GCI Test")
    -- local cap = gcicap.spawnFighterGroup("red", "CAP Test", 2, airbase, "CAP", "redCAPzone1")

    --mist.scheduleFunction(gcicap.vectorOnTarget, {gci, target}, timer.getTime() + 10)

    gcicap.init()
    mist.scheduleFunction(gcicap.main, {}, timer.getTime() + 15, 15)
end
