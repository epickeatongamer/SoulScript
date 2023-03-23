--removes a handle
function RemoveHandle(entity_handle)
	if entities.handle_to_pointer(entity_handle) ~= 0 then
		SHAPETEST.RELEASE_SCRIPT_GUID_FROM_ENTITY(entity_handle)
        return true
    else
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