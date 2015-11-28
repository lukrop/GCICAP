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
gcicap.cap = {}
gcicap.gci = {}

-- CAP minimum and maximum altitudes in meters
gcicap.cap.min_alt = 4500
gcicap.cap.max_alt = 7500
-- set to true for CAP flight to start airborne at script initialisation,
-- false for taking off from airfield at start
gcicap.cap.start_airborne = true

-- amount of CAP zones (placed with triggerzones in the ME) for each side
gcicap.cap.red_zones_count = 3
gcicap.cap.blue_zones = 3

-- amount of CAP groups concurrently in the air.
gcicap.cap.red_groups_count = 3
gcicap.cap.blue_groups_count = 3

-- can be "2", "4" or "randomized"
-- if "2" it consists of 2 planes, if "4" it consists of 4 planes
-- if "randomized", the CAP groups consist of either 2 or 4 planes
gcicap.cap.group_size = "2"

-- maximum number of at the same time ongoing active intercepts
gcicap.gci.max_red_gci = 2
gcicap.gci.max_blue_gci = 2

-- can be "2", "4", "randomized" or "dynamic"
-- if "2" it consists of 2 planes, if "4" it consists of 4 planes
-- if "randomized", the CAP groups consist of either 2 or 4 planes
-- if "dynamic" it has the same size as the intercepted group
gcicap.gci.group_size = "dynamic"

-- enable messages from GCI
gcicap.gci.messages = true
-- how long a GCI message will be shown in seconds
gcicap.gci.message_time = 5
-- display GCI messages with metric or imperial units.
gcicap.gci.messages_imperial = true

-- CAP units only engage if enemy units intrude their airspace
gcicap.borders = true

-- can be "parking", "takeoff" or "air" and defines the way the fighters spawn
gcicap.spawn_mode = "parking"

-- option to hide or reveal air units in the mission.
-- This setting affects both sides. Valid values are true/false to make units hidden/unhidden
gcicap.hide_groups = false

-- wether the side doe combat air patrols.
-- if set to false the side will only do GCI
gcicap.cap.blue_do_cap = true
gcicap.cap.red_do_cap = true

-- if set to true limits the amount of groups a side can spawn.
gcicap.limit_resources = false

-- amount of groups(!) for blue and red
gcicap.blue_groups_supply = 24
gcicap.red_groups_supply = 24

-- time limit, in seconds, after which a group gets removed, if a unit of it is still
-- on the ground. Consider big airfields and long taxi ways.
gcicap.stuck_limit = 1080

-- radius for cleaning up wrecks around airfields
gcicap.cleanup_radius = 3000

-- enable debug messages
gcicap.debug = true

-- name of the triggerzone which defines a CAP zone, postfixed with the number of
-- the zone. e.g. "redCAPzone3" or "blueCAPzone1".
gcicap.cap.red_zone_name = 'redCAPzone'
gcicap.cap.blue_zone_name = 'blueCAPzone'

-- name of group which waypoints define the border
gcicap.red_border_group = 'redborder'
gcicap.blue_border_group = 'blueborder'

-- i'd vouch for a better default but for the sake of backwards compatibility with
-- current missions we go with the old default.
gcicap.unit_template_prefix = '__TMP__'

-- Time interval in which ongoing intercepts are renewed, NOTE: Do not use too small a value
-- as it interrupts intercepts and resets limit on active GCIs which can cause mission to be spammed by aircraft
--gcicap.tasking_interval = 1800

-- returns airfields of given side which are marked with
-- triggerzones (triggerzone name is exactly the same as airfield name).
-- side has to be 1 (red) or 2 (blue)
function gcicap.getAirfields(side)
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

-- creates a polygon off of the waypoints of a specific
-- border group and returns this border polygon
-- function gcicap.buildBorderFromGroupPoints(group)
--     local border = mist.getGroupPoints(group)
--     if gcicap.debug and #border == 0 then
--         env.error "GCICAP: Couldn't build border polygon. There's something wrong here."
--     end
--     return border
-- end

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
    -- get all ewr units
    local active_ewr = gcicap.getAllActiveEWR(side)
    -- init some local vars
    local border = {}
    local active_ac = {}
    local intruder_count = 0
    local intruder_side = ""

    if side == "red" then
        -- set border
        border = gcicap.red_border
        -- set the side of the intruder
        intruder_side = "blue"
        -- retrieve all active aircaft of the opposing side
        active_ac = gcicap.getAllActiveAircrafts("blue")
    elseif side == "blue" then
        border = gcicap.blue_border
        intruder_side = "red"
        active_ac = gcicap.getAllActiveAircrafts("red")
    end

    -- reset the table
    gcicap.intruders[intruder_side] = {}

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
                    if gcicap.borders then
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

                        gcicap.intruders[intruder_side][#intruders[intruder_side] + 1] = {
                            name = active_ac[i].name,
                            unit = ac,
                            group = ac_group,
                            GroupID = ac_group:getID(),
                            UnitID = ac:getID(),
                            unittype = unit:getTypeName(),
                            pos = ac_pos,
                            size = ac_group:getSize(),
                            number = intruder_count
                        }

                        if gcicap.gci.messages then
                            -- show gci messages here
                        end
                    end -- if ac_intruded
                end -- if ac_detected
            end -- if ac ~= nil
        end -- for #active_ac
    end -- if active_ac > 0 and active_ewr > 0
    return gcicap.intruders[side]
end

function gcicap.getClosestAirfieldToUnit(side, unit)
    local airfields = {}
    if side == "blue" then
        airfields = gcicap.airfields_blue
    elseif side == "red" then
        airfields = gcicap.airfields_red
    end

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

function gcicap.spawnFighterGroup(side, airport, name, size, route)
    local template_unit = Unit.getByName(gcicap.unit_template_prefix..side..math.random(1, 4))
    local template_group = mist.getGroupData(template_unit:getGroup():getName())
    local template_unit_data = template_group["units"][1]
    local airport_pos = airport:getPoint()
    local group_data = {}
    local unit_data = {}
    local onboard_num = template_unit_data["onboard_num"] - 1

    for i = 1, size do
        unit_data[i] = {}
        unit_data[i]["type"] = template_unit_data["type"]
        unit_data[i]["unitName"] = name.." Pilot "..i
        unit_data[i]["x"] = airport_pos.x
        unit_data[i]["y"] = airport_pos.z
        unit_data[i]["onboard_num"] =  onboard_num + i
        unit_data[i]["groupName"] = name
        unit_data[i]["payload"] = template_unit_data["payload"]
        unit_data[i]["skill"] = template_unit_data["skill"]
        unit_data[i]["livery_id"] = template_unit_data["livery_id"]
    end

    group_data["units"] = unit_data
    group_data["groupName"] = name
    group_data["hidden"] = gcicap.hide_groups
    group_data["country"] = template_group["country"]
    group_data["category"] = template_group["category"]
    group_data["route"] = route

    if mist.groupTableCheck(group_data) then
        if gcicap.debug then
            env.info("[GCICAS] Spawning fighter group "..name.." at "..airport:getName())
            env.info(mist.utils.serialize("[GCICAS] unit 1", group_data["units"][1]))
        end
        mist.dynAdd(group_data)
    else
        if gcicap.debug then
            env.error("[GCICAS] Couldn't spawn group with following groupTable: "
                      .. mist.utils.tableShow(group_data))
        end
    end
end

function gcicap.createCAPRoute(airbase, zone, wp_count)
    -- randomize waypoint count if none given
    if wp_count == nil then
        wp_count = math.random(5,10)
    end

    local route = {}
    local airbase_id = airbase:getID()
    local airbase_pos = airbase:getPoint() -- airbase:getPosition() seems to return garbage coordinates
    local field_elevation = land.getHeight(airbase_pos)

    -- create waypoints
    for i = 1, wp_count do
        route[i] = {}
        -- check if its the first or last waypoint
        if i == 1 or i == wp_count then
            route[i]["alt"] = field_elevation
            route[i]["speed_locked"] = false
            route[i]["x"] = airbase_pos.x
            route[i]["y"] = airbase_pos.z
            route[i]["airdromeId"] = airbase_id

            -- if its the first
            if i == 1 then
                if gcicap.spawn_mode == "parking" then -- start from parking area
                    route[i]["type"] = "TakeOffParking"
                    route[i]["action"] = "From Parking Area"
                else -- or start from runway
                    route[i]["type"] = "TakeOff"
                    route[i]["action"] = "From Runway"
                end
            else -- it's the last so we'll land
                route[i]["type"] = "Landing"
                route[i]["action"] = "Landing"
            end

            -- no task
            route[i]["task"] = {
                ["id"] = "ComboTask",
                ["params"] = {
                    ["tasks"] = {
                    }
                }
            }
        -- this is a random waypoint on the CAP route
        else
            -- get a random point inside the CAP zone
            local point = mist.getRandomPointInZone(zone)
            local alt = math.random(gcicap.cap.min_alt, gcicap.cap.max_alt)
            local ground_level = land.getHeight(point)

            -- avoid crashing into hills
            if (alt - 50) < ground_level then
                alt = alt + ground_level
            end

            route[i]["alt"] = alt
            route[i]["speed_locked"] = true
            route[i]["x"] = point.x
            route[i]["y"] = point.y

            -- Add CAP task to the waypoint
            route[i]["task"] = {
                ["id"] = "ComboTask",
                ["params"] = {
                    ["tasks"] = {
                        [1] = {
                            ["number"] = 1,
                            ["key"] = "CAP",
                            ["id"] = "EngageTargets",
                            ["enabled"] = true,
                            ["auto"] = true,
                            ["params"] = {
                                ["targetTypes"] = {
                                    [1] = "Air",
                                },
                                ["priority"] = 0
                            }
                        }
                    }
                }
            }
        end

        -- this is TAS afaik
        route[i]["speed"] = 138.88888888889 -- 500 km/h
        route[i]["alt_type"] = "BARO"
        route[i]["ETA"] = 0
        route[i]["ETA_locked"] = false
        route[i]["formation_template"] = ""
        route[i]["properties"] = {
            ["vnav"] = 1,
            ["scale"] = 0,
            ["angle"] = 0,
            ["vangle"] = 0,
            ["steer"] = 2,
        }
    end
    return route
end

