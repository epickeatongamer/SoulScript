--tables
local vehicle_classes = {
    "Compact",
    "Sedan",
    "SUV",
    "Coupe",
    "Muscle",
    "Sport Classic",
    "Sport",
    "Super",
    "Motorcycle",
    "Off-road",
    "Industrial",
    "Utility",
    "Van",
    "Cycle",
    "Boat",
    "Helicopter",
    "Plane",
    "Service",
    "Emergency",
    "Military",
    "Commercial",
    "Train",
}

--get vehicle class
function GetClass(vehicle)
    return vehicle_classes[VEHICLE.GET_VEHICLE_CLASS(vehicle) + 1]
end

--removes a handle
function RemoveHandle(entity_handle)
	if entities.handle_to_pointer(entity_handle) ~= 0 then
		SHAPETEST.RELEASE_SCRIPT_GUID_FROM_ENTITY(entity_handle)
        return true
    else
        return false
    end
end

--checks if it is a handle
function is_handle(entity)
    if entities.handle_to_pointer(entity) ~= 0 then
		return true
	elseif entities.handle_to_pointer(entity) == 0 then
		return false
	end
end

--check if entity is safe to clear
function SafeToClearVehicle(vehicle)
    if vehicle ~= PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false) and DECORATOR.DECOR_GET_INT(vehicle, "Player_Vehicle") == 0 and NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
        return true
    else
        return false
    end
end
function SafeToClearPed(ped)
    if ped ~= players.user_ped() and not PED.IS_PED_A_PLAYER(ped) and NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(ped) and (not NETWORK.NETWORK_IS_ACTIVITY_SESSION() or NETWORK.NETWORK_IS_ACTIVITY_SESSION() and not ENTITY.IS_ENTITY_A_MISSION_ENTITY(ped)) then
        return true
    else
        return false
    end
end

--clear area
function ClearModel(model)
	local deleted_model_count = 0
	local hash = util.joaat(model)
	if STREAMING.IS_MODEL_VALID(hash) then
        -- Vehicles
		if STREAMING.IS_MODEL_A_VEHICLE(hash) then
			for k, vehicle in pairs(entities.get_all_vehicles_as_handles()) do
				if ENTITY.GET_ENTITY_MODEL(vehicle) == hash then
					entities.delete_by_handle(vehicle)
					deleted_model_count = deleted_model_count + 1
				end
			end
			if deleted_model_count > 0 then
				return deleted_model_count
			else
				return 0
			end
		end

        -- Peds
		if STREAMING.IS_MODEL_A_PED(hash) then
			for k, ped in pairs(entities.get_all_peds_as_handles()) do
				if ENTITY.GET_ENTITY_MODEL(ped) == hash then
					if not PED.IS_PED_A_PLAYER(ped) then
						entities.delete_by_handle(ped)
						deleted_model_count = deleted_model_count + 1
					end
				end
			end
			if deleted_model_count > 0 then
				return deleted_model_count
			else
				return 0
			end
		end
        
        -- Objects
		for k, object in pairs(entities.get_all_objects_as_handles()) do
			if ENTITY.GET_ENTITY_MODEL(object) == hash then
				entities.delete_by_handle(object)
				deleted_model_count = deleted_model_count + 1
			end
		end
		if deleted_model_count > 0 then
			return deleted_model_count
		else
			return 0
		end
	else
		return -1
	end
end
function ClearVehicles()
    local counter = 0
    for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
        if SafeToClearVehicle(vehicle) then
            entities.delete_by_handle(vehicle)
            counter = counter + 1
        end
        util.yield()
    end
    if counter > 0 then counter = counter else counter = -1 end
    return counter
end
function ClearPeds()
    local counter = 0
    for _, ped in ipairs(entities.get_all_peds_as_handles()) do
        if SafeToClearPed(ped) then
            entities.delete_by_handle(ped)
            counter = counter + 1
            util.yield()
        end
    end
    if counter > 0 then counter = counter else counter = -1 end
    return counter
end
function ClearObjects()
    local counter = 0
    for _, object in ipairs(entities.get_all_objects_as_handles()) do
        entities.delete_by_handle(object)
        counter = counter + 1
        util.yield()
    end
    if counter > 0 then counter = counter else counter = -1 end
    return counter
end
function ClearPickups()
    local counter = 0
    for _, pickup in ipairs(entities.get_all_pickups_as_handles()) do
        entities.delete_by_handle(pickup)
        counter = counter + 1
        util.yield()
    end
    if counter > 0 then counter = counter else counter = -1 end
    return counter
end
function ClearRopes()
    local temp = memory.alloc(4)
    for i = 0, 100 do
        memory.write_int(temp, i)
        if PHYSICS.DOES_ROPE_EXIST(temp) then
            PHYSICS.DELETE_ROPE(temp)
            counter = counter + 1
        end
        util.yield()
    end
    return "all"
end
function ClearProjectiles()
    local coords = players.get_position(players.user())
    MISC.CLEAR_AREA_OF_PROJECTILES(coords.x, coords.y, coords.z, 1000, 0)
    return "all"
end
function ClearSounds()
    for i = 0, 100 do
        AUDIO.STOP_SOUND(i)
        util.yield()
    end
    return "all"
end

--request for the model to be loaded
function RequestModel(hash)
	while not STREAMING.HAS_MODEL_LOADED(hash) do
		STREAMING.REQUEST_MODEL(hash)
		util.yield(10)
	end
    if STREAMING.HAS_MODEL_LOADED(hash) then
        return true
    end
end

--weapon aiming
function GetAimTarget()
    local entity = 0
    if PLAYER.IS_PLAYER_FREE_AIMING(players.user()) then
        local pEntity = memory.alloc_int()
        if PLAYER.GET_ENTITY_PLAYER_IS_FREE_AIMING_AT(players.user(), pEntity) then
            entity = memory.read_int(pEntity)
        end
        if ENTITY.IS_ENTITY_A_PED(entity) and PED.IS_PED_IN_ANY_VEHICLE(entity) then
            local vehicle = PED.GET_VEHICLE_PED_IS_IN(entity, false)
            entity = vehicle
        end
    end
    return entity
end

--get entity information
function GetEntityType(entity)
    if ENTITY.IS_ENTITY_A_PED(entity) then
        if PED.IS_PED_A_PLAYER(entity) then
            return "Player"
        else
            return "Ped"
        end
    elseif ENTITY.IS_ENTITY_A_VEHICLE(entity) then
        return "Vehicle"
    elseif ENTITY.IS_ENTITY_AN_OBJECT(entity) then
        return "Object"
    else
        return "N/A"
    end
end

--math functions
function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

--esp bounding box (thanks ren for an improvement to it)
function DrawLine(start, to, colour)
	GRAPHICS.DRAW_LINE(start.x, start.y, start.z, to.x, to.y, to.z, math.floor(colour.r*255), math.floor(colour.g*255), math.floor(colour.b*255), math.floor(colour.a*255))
end
local memory_pos, memory_pos2 = memory.alloc(24), memory.alloc(24)
function DrawBoundaryBox(entity_ptr, max_distance, ent_pos, colour)
    if entity_ptr ~= nil then
        if is_handle(entity_ptr) then
            util.toast("[SoulScript] You need to pass a pointer to bounding box")
            return end
        local colour = colour or {r = 255, g = 0, b = 255, a = 255}
        local entity = entities.pointer_to_handle(entity_ptr)
        local hash = ENTITY.GET_ENTITY_MODEL(entity)

        local dimensions_min, dimensions_max = v3.new(), v3.new()
        MISC.GET_MODEL_DIMENSIONS(hash, dimensions_min, dimensions_max)

        local top_front_right = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, dimensions_max.x, dimensions_max.y, dimensions_max.z)
        local top_front_left =  ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, dimensions_min.x, dimensions_max.y, dimensions_max.z)
        local top_rear_left =   ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, dimensions_min.x, dimensions_min.y, dimensions_max.z)
        local top_rear_right =  ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, dimensions_max.x, dimensions_min.y, dimensions_max.z)

        local bot_front_right = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, dimensions_max.x, dimensions_max.y, dimensions_min.z)
        local bot_front_left =  ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, dimensions_min.x, dimensions_max.y, dimensions_min.z)
        local bot_rear_left =   ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, dimensions_min.x, dimensions_min.y, dimensions_min.z)
        local bot_rear_right =  ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, dimensions_max.x, dimensions_min.y, dimensions_min.z)

        DrawLine(top_front_right,   top_front_left,     colour)
        DrawLine(top_front_left,    top_rear_left,      colour)
        DrawLine(top_rear_left,     top_rear_right,     colour)
        DrawLine(top_rear_right,    top_front_right,    colour)

        DrawLine(top_front_right,   bot_front_right,    colour)
        DrawLine(top_front_left,    bot_front_left,     colour)
        DrawLine(top_rear_right,    bot_rear_right,     colour)
        DrawLine(top_rear_left,     bot_rear_left,      colour)

        DrawLine(bot_front_right,   bot_front_left,     colour)
        DrawLine(bot_front_left,    bot_rear_left,      colour)
        DrawLine(bot_rear_left,     bot_rear_right,     colour)
        DrawLine(bot_rear_right,    bot_front_right,    colour)
        if not ENTITY.IS_ENTITY_A_MISSION_ENTITY(entity) or ENTITY.GET_ENTITY_SCRIPT(entity, 0) == "" then
            SHAPETEST.RELEASE_SCRIPT_GUID_FROM_ENTITY(entity)
        end
    end
end

--check if a ped is an enemy (WIP)
function IsPedEnemy(ped)
    local relationship = PED.GET_RELATIONSHIP_BETWEEN_PEDS(players.user_ped(), ped)
    if relationship == 4 or relationship == 5 then
        return true
    else
        return false
    end
end

--get seat ped is using
function GetPedSeat(vehicle, ped)
    for i=-1,14 do
        local ped_in_seat = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, i, false)
        if ped_in_seat == ped then
            return i
        end
    end
end

--check if it is inside of a certain list
function IsInParent(commandRef, parent)
    repeat
        if commandRef:equals(parent) then return true end
        commandRef = commandRef:getParent()
    until not commandRef:isValid()
    return false
end

--edited get_name function
function PlayerNameValid(pid, name)
    if (name == players.get_name(pid)) ~= "UndiscoveredPlayer" then
        return true
    end
    return false
end