--[[
    Credits
    Prism - Few little checks for clear area and method to clear projectiles/sounds
    Nowiry - The function to get aiming target
]]
util.require_natives("1663599433")
require("SoulScript_Functions")

-- Colours
local whitecolor = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}
local blackcolor = {r = 0.0, g = 0.0, b = 0.0, a = 1.0}
local pinkcolor = {r = 1.0, g = 0.0, b = 1.0, a = 1.0}

-- Settings
local Settings <const> = {}
Settings.sphere_size = 25
Settings.targetting_handle = 0
Settings.targetting_pointer = 0
Settings.targetting = false
Settings.targetting_info_script = "N/A"
Settings.targetting_info_owner = 0
Settings.targetting_info_type = "N/A"
Settings.targetting_info_hash = 0
Settings.targetting_info_name = "N/A"
Settings.targetting_info_display_name = "N/A"
Settings.targetting_info_position_x = 0
Settings.targetting_info_position_y = 0
Settings.targetting_info_position_z = 0
Settings.targetting_info_screen_x = 0
Settings.targetting_info_screen_y = 0
Settings.targetting_info_speed_mph = 0
Settings.targetting_info_speed_kph = 0
Settings.targetting_info_max_speed_mph = 0
Settings.targetting_info_max_speed_kph = 0
Settings.targetting_info_health = 0
Settings.targetting_info_max_health = 0
Settings.targetting_info_armor = 0
Settings.targetting_info_max_armor = 0

-- Tables
local vehicle_blip_esp_table = {}
local pedestrian_blip_esp_table = {}
local object_blip_esp_table = {}
local pickup_blip_esp_table = {}

-- Local List: Self
local self_list = menu.list(menu.my_root(), "Self", {}, "", function(); end)

-- Local List: Vehicle
local vehicle_list = menu.list(menu.my_root(), "Vehicle", {}, "", function(); end)

vehicle_list:toggle_loop("Vehicle Friendly Fire", {""}, "Be able to shoot people inside your current vehicle", function()
	if players.get_vehicle_model(players.user()) ~= 0 then
		local vehicle = entities.get_user_vehicle_as_handle()
		local my_group = PED.GET_PED_RELATIONSHIP_GROUP_HASH(players.user_ped())

		local seat_count = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(ENTITY.GET_ENTITY_MODEL(vehicle))
		for i = -1, seat_count do
			local ped = VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, i, false)
			local ped_group = PED.GET_PED_RELATIONSHIP_GROUP_HASH(ped)
			if ped_group ~= my_group and PED.GET_RELATIONSHIP_BETWEEN_PEDS(players.user(), ped) ~= 5 and ped ~= nil and ped_group ~= nil then
				PED.SET_RELATIONSHIP_BETWEEN_GROUPS(5, my_group, ped_group)
			end
			RemoveHandle(ped)
		end
		RemoveHandle(vehicle)
	end
end)
vehicle_list:toggle_loop("No Object Collision", {""}, "No collision with objects", function()
	if players.get_vehicle_model(players.user()) then
		local vehicle = entities.get_user_vehicle_as_handle()
		for _, object in pairs(entities.get_all_objects_as_handles()) do
			ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(object, vehicle, true)
		end
        RemoveHandle(vehicle)
	end
end)
vehicle_list:toggle_loop("Shoot Flames", {""}, "", function (toggle)
	if players.get_vehicle_model(players.user()) ~= 0 then
		entities.set_rpm(entities.get_user_vehicle_as_pointer(), 1.2)
    	util.yield(250)
	end
end)
vehicle_list:toggle_loop("Engine Lump", {""}, "", function (toggle)
	if players.get_vehicle_model(players.user()) ~= 0 then
		entities.set_rpm(entities.get_user_vehicle_as_pointer(), 1.006)
    	util.yield(600)
	end
end)

-- Local List: Online
local online_list = menu.list(menu.my_root(), "Online", {}, "", function(); end)
online_list:toggle_loop("Chat Fix", {}, "Fixes the location of chat on ultrawide monitor", function()
	local mp_chat_scaleform_handle = GRAPHICS.REQUEST_SCALEFORM_MOVIE("multiplayer_chat")
	GRAPHICS.DRAW_SCALEFORM_MOVIE(mp_chat_scaleform_handle, 0.673, 0.5, 1, 1, 255, 255, 255, 255, 1)
end)
online_list:toggle_loop("Show Talking Players", {}, "Draws a list of players talking at the top of screen", function()
	if util.is_session_started() and not util.is_session_transition_active() then
		local talking = 0
		for _, pid in pairs(players.list()) do
			if NETWORK.NETWORK_IS_PLAYER_TALKING(pid) then
				directx.draw_text(0.5, 0 + talking, players.get_name(pid).." is talking", ALIGN_TOP_CENTRE, 0.8, {r = 1.0, g = 0.0, b = 1.0, a = 1.0}, false)
				talking = talking + 0.03
			end
		end
	end
end)

-- Local List: World
local world_list = menu.list(menu.my_root(), "World", {}, "", function(); end)
local world_list_cleararea = menu.list(world_list, "Clear Area", {}, "", function(); end)
local world_list_esp = menu.list(world_list, "Entity ESP", {}, "", function(); end)
local world_list_esp_vehicles = menu.list(world_list_esp, "Vehicles", {}, "", function(); end)
local world_list_esp_peds = menu.list(world_list_esp, "Peds", {}, "", function(); end)
local world_list_esp_objects = menu.list(world_list_esp, "Objects", {}, "", function(); end)
local world_list_esp_pickups = menu.list(world_list_esp, "Pickups", {}, "", function(); end)
local world_list_spawner = menu.list(world_list, "Spawner", {}, "", function(); end)

world_list_cleararea:list_action("Clear All", {}, "", {"Vehicles", "Peds", "Objects", "Pickups", "Ropes", "Projectiles", "Sounds"}, function(index, name)
	util.toast("Clearing "..name:lower())
    local counter = 0
    switch index do

        -- Vehicles
        case 1:
            counter = ClearVehicles()
        break

        -- Peds
        case 2:
            counter = ClearPeds()
        break

        -- Objects
        case 3:
            counter = ClearObjects()
        break

        -- Pickups
        case 4:
            counter = ClearPickups()
        break

        -- Ropes
        case 5:
            count = ClearRopes()
        break

        -- Projectiles
        case 6:
            count = ClearProjectiles()
        break

        -- Sounds
        case 7:
            count = ClearSounds()
        break
    end
    
    if counter > 0 then util.toast("Cleared "..tostring(counter).." "..name:lower()) elseif counter == -1 then util.toast("Cleared no "..name:lower()) elseif count == "all" then util.toast("Cleared "..count.." "..name:lower()) end
end)
world_list_cleararea:action("Clear Area", {"superclear", "superclense", "clense"}, "", function()

    -- Vehicles
    local cleanse_entitycount = ClearVehicles()
	if cleanse_entitycount > 0 then util.toast("Cleared ".. cleanse_entitycount .." vehicles") end

    -- Peds
    local cleanse_entitycount = ClearPeds()
	if cleanse_entitycount > 0 then util.toast("Cleared " .. cleanse_entitycount .. " peds") end

    -- Objects
    local cleanse_entitycount = ClearObjects()
	if cleanse_entitycount > 0 then util.toast("Cleared " .. cleanse_entitycount .. " objects") end

    -- Pickups
    local cleanse_entitycount = ClearPickups()
	if cleanse_entitycount > 0 then util.toast("Cleared " .. cleanse_entitycount .. " pickups") end

    -- Ropes
    ClearRopes()
	util.toast("Cleared all ropes")

    -- Projectiles
    ClearProjectiles()
	util.toast("Cleared all projectiles")

    -- Sounds
    ClearSounds()
    util.toast("Cleared all sounds")
end)
world_list_cleararea:action("Clear By Model", {"clearmodel", "cleanmodel", "deletemodel"}, "Clears area of the selected model, only takes model name, not model hash", function() menu.show_command_box("clearmodel ") end, function(input)
    ClearModel(input)
end)
world_list_cleararea:action("Clear Destroyed Entities", {"cleardead"}, "Clears all nearby entities that are dead", function()

    -- Vehicles
    local cleanse_entitycount = 0
    for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
        if SafeToClearVehicle(vehicle) and ENTITY.GET_ENTITY_HEALTH(vehicle) == 0 then
			entities.delete_by_handle(vehicle)
            cleanse_entitycount = cleanse_entitycount + 1
            util.yield()
        end
    end
	if cleanse_entitycount > 0 then util.toast("Cleared ".. cleanse_entitycount .." dead vehicles") end

    -- Peds
    local cleanse_entitycount = 0
    for _, ped in pairs(entities.get_all_peds_as_handles()) do
        if SafeToClearPed(ped) and ENTITY.GET_ENTITY_HEALTH(ped) == 0 then
			entities.delete_by_handle(ped)
            cleanse_entitycount = cleanse_entitycount + 1
            util.yield()
        end
    end
	if cleanse_entitycount > 0 then util.toast("Cleared " .. cleanse_entitycount .. " dead peds") end

    -- Objects
    local cleanse_entitycount = 0
    for _, object in pairs(entities.get_all_objects_as_handles()) do
        if ENTITY.GET_ENTITY_HEALTH(object) == 0 then
            entities.delete_by_handle(object)
            cleanse_entitycount = cleanse_entitycount + 1
            util.yield()
        end
    end
	if cleanse_entitycount > 0 then util.toast("Cleared " .. cleanse_entitycount .. " dead objects") end
end)
world_list_esp_vehicles:toggle_loop("Hash", {"vehesp", "vehicleesp"}, "", function (toggle)
    local entTable = entities.get_all_vehicles_as_pointers()
    for _, ent_ptr in pairs(entTable) do
        local entPos = entities.get_position(ent_ptr)
        local modelname = entities.get_model_hash(ent_ptr)
        local sx = memory.alloc()
        local sy = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
            local ssx = memory.read_float(sx)
            local ssy = memory.read_float(sy)
            directx.draw_text(ssx, ssy - 0.1, "Hash: "..tostring(modelname), 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_vehicles:toggle_loop("Hexadecimal", {""}, "", function (toggle)
    local entTable = entities.get_all_vehicles_as_pointers()
    for _, ent_ptr in pairs(entTable) do
        local entPos = entities.get_position(ent_ptr)
        local modelname = entities.get_model_hash(ent_ptr)
        local modelname2 = string.format("0x%08X", modelname)
        local sx = memory.alloc()
        local sy = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
            local ssx = memory.read_float(sx)
            local ssy = memory.read_float(sy)
            directx.draw_text(ssx, ssy - 0.1, "Hex: "..modelname2, 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_vehicles:toggle_loop("Model Name", {""}, "", function (toggle)
    local entTable = entities.get_all_vehicles_as_pointers()
    for _, ent_ptr in pairs(entTable) do
        local entPos = entities.get_position(ent_ptr)
        local modelname = entities.get_model_hash(ent_ptr)
        local modelname2 = util.reverse_joaat(modelname)
        local sx = memory.alloc()
        local sy = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
            local ssx = memory.read_float(sx)
            local ssy = memory.read_float(sy)
            directx.draw_text(ssx, ssy - 0.1, "Model Name: "..modelname2, 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_vehicles:toggle_loop("Owner", {""}, "", function (toggle)
    local entTable = entities.get_all_vehicles_as_pointers()
    for _, ent_ptr in pairs(entTable) do
        local entPos = entities.get_position(ent_ptr)
        local owner_id = entities.get_owner(ent_ptr)
        local owner_name = players.get_name(owner_id)
        local sx = memory.alloc()
        local sy = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
            local ssx = memory.read_float(sx)
            local ssy = memory.read_float(sy)
            directx.draw_text(ssx, ssy - 0.1, "Owner: "..owner_name, 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_vehicles:toggle_loop("Blip", {""}, "", function (toggle)
    local entTable = entities.get_all_vehicles_as_handles()
    for _, ent in pairs(entTable) do
		local blip = HUD.ADD_BLIP_FOR_ENTITY(ent)
		HUD.SET_BLIP_SPRITE(blip, 56)
		table.insert(vehicle_blip_esp_table, blip)
    end
	util.yield(500)
    for _, blip in pairs(vehicle_blip_esp_table) do
        util.remove_blip(blip)
		vehicle_blip_esp_table[_] = nil
    end
end)
world_list_esp_peds:toggle_loop("Hash", {"pedesp", "pedestrianesp"}, "", function (toggle)
    local entTable = entities.get_all_peds_as_pointers()
    for _, ent_ptr in pairs(entTable) do
        local entPos = entities.get_position(ent_ptr)
        local modelname = entities.get_model_hash(ent_ptr)
        local sx = memory.alloc()
        local sy = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
            local ssx = memory.read_float(sx)
            local ssy = memory.read_float(sy)
            directx.draw_text(ssx, ssy - 0.1, "Hash: "..tostring(modelname), 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_peds:toggle_loop("Hexadecimal", {""}, "", function (toggle)
    local entTable = entities.get_all_peds_as_pointers()
    for _, ent_ptr in pairs(entTable) do
        local entPos = entities.get_position(ent_ptr)
        local modelname = entities.get_model_hash(ent_ptr)
        local modelname2 = string.format("0x%08X", modelname)
        local sx = memory.alloc()
        local sy = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
            local ssx = memory.read_float(sx)
            local ssy = memory.read_float(sy)
            directx.draw_text(ssx, ssy - 0.1, "Hex: "..modelname2, 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_peds:toggle_loop("Model Name", {""}, "", function (toggle)
    local entTable = entities.get_all_peds_as_pointers()
    for _, ent_ptr in pairs(entTable) do
        local entPos = entities.get_position(ent_ptr)
        local modelname = entities.get_model_hash(ent_ptr)
        local modelname2 = util.reverse_joaat(modelname)
        local sx = memory.alloc()
        local sy = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
            local ssx = memory.read_float(sx)
            local ssy = memory.read_float(sy)
            directx.draw_text(ssx, ssy - 0.1, "Model Name: "..modelname2, 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_peds:toggle_loop("Owner", {""}, "", function (toggle)
    local entTable = entities.get_all_peds_as_pointers()
    for _, ent_ptr in pairs(entTable) do
        local entPos = entities.get_position(ent_ptr)
        local owner_id = entities.get_owner(ent_ptr)
        local owner_name = players.get_name(owner_id)
        local sx = memory.alloc()
        local sy = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
            local ssx = memory.read_float(sx)
            local ssy = memory.read_float(sy)
            directx.draw_text(ssx, ssy - 0.1, "Owner: "..owner_name, 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_peds:toggle_loop("Blip", {""}, "", function (toggle)
    local entTable = entities.get_all_peds_as_handles()
    for _, ent in pairs(entTable) do
		local blip = HUD.ADD_BLIP_FOR_ENTITY(ent)
		HUD.SET_BLIP_SPRITE(blip, 366)
		table.insert(pedestrian_blip_esp_table, blip)
    end
	util.yield(500)
    for _, blip in pairs(pedestrian_blip_esp_table) do
        util.remove_blip(blip)
		pedestrian_blip_esp_table[_] = nil
    end
end)
world_list_esp_objects:toggle_loop("Hash", {"objesp", "objectesp"}, "", function (toggle)
    local entTable = entities.get_all_objects_as_pointers()
    for _, ent_ptr in pairs(entTable) do
        local entPos = entities.get_position(ent_ptr)
        local modelname = entities.get_model_hash(ent_ptr)
        local sx = memory.alloc()
        local sy = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
            local ssx = memory.read_float(sx)
            local ssy = memory.read_float(sy)
            directx.draw_text(ssx, ssy - 0.1, "Hash: "..tostring(modelname), 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_objects:toggle_loop("Hexadecimal", {""}, "", function (toggle)
    local entTable = entities.get_all_objects_as_pointers()
    for _, ent_ptr in pairs(entTable) do
        local entPos = entities.get_position(ent_ptr)
        local modelname = entities.get_model_hash(ent_ptr)
        local modelname2 = string.format("0x%08X", modelname)
        local sx = memory.alloc()
        local sy = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
            local ssx = memory.read_float(sx)
            local ssy = memory.read_float(sy)
            directx.draw_text(ssx, ssy - 0.1, "Hex: "..modelname2, 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_objects:toggle_loop("Model Name", {""}, "", function (toggle)
    local entTable = entities.get_all_objects_as_pointers()
    for _, ent_ptr in pairs(entTable) do
        local entPos = entities.get_position(ent_ptr)
        local modelname = entities.get_model_hash(ent_ptr)
        local modelname2 = util.reverse_joaat(modelname)
        local sx = memory.alloc()
        local sy = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
            local ssx = memory.read_float(sx)
            local ssy = memory.read_float(sy)
            directx.draw_text(ssx, ssy - 0.1, "Model Name: "..modelname2, 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_objects:toggle_loop("Owner", {""}, "", function (toggle)
    local entTable = entities.get_all_objects_as_pointers()
    for _, ent_ptr in pairs(entTable) do
        local entPos = entities.get_position(ent_ptr)
        local owner_id = entities.get_owner(ent_ptr)
        local owner_name = players.get_name(owner_id)
        local sx = memory.alloc()
        local sy = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
            local ssx = memory.read_float(sx)
            local ssy = memory.read_float(sy)
            directx.draw_text(ssx, ssy - 0.1, "Owner: "..owner_name, 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_objects:toggle_loop("Blip", {""}, "", function (toggle)
    local entTable = entities.get_all_objects_as_handles()
	util.yield()
    for _, ent in pairs(entTable) do
		local blip = HUD.ADD_BLIP_FOR_ENTITY(ent)
		HUD.SET_BLIP_SPRITE(blip, 176)
		table.insert(object_blip_esp_table, blip)
    end
	util.yield(500)
    for _, blip in pairs(object_blip_esp_table) do
        util.remove_blip(blip)
		object_blip_esp_table[_] = nil
    end
end)
world_list_esp_pickups:toggle_loop("Hash", {"pickupesp"}, "", function (toggle)
    local entTable = entities.get_all_pickups_as_pointers()
    for _, ent_ptr in pairs(entTable) do
        local entPos = entities.get_position(ent_ptr)
        local modelname = entities.get_model_hash(ent_ptr)
        local sx = memory.alloc()
        local sy = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
            local ssx = memory.read_float(sx)
            local ssy = memory.read_float(sy)
            directx.draw_text(ssx, ssy - 0.1, "Hash: "..tostring(modelname), 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_pickups:toggle_loop("Hexadecimal", {""}, "", function (toggle)
    local entTable = entities.get_all_pickups_as_pointers()
    for _, ent_ptr in pairs(entTable) do
        local entPos = entities.get_position(ent_ptr)
        local modelname = entities.get_model_hash(ent_ptr)
        local modelname2 = string.format("0x%08X", modelname)
        local sx = memory.alloc()
        local sy = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
            local ssx = memory.read_float(sx)
            local ssy = memory.read_float(sy)
            directx.draw_text(ssx, ssy - 0.1, "Hex: "..modelname2, 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_pickups:toggle_loop("Model Name", {""}, "", function (toggle)
    local entTable = entities.get_all_pickups_as_pointers()
    for _, ent_ptr in pairs(entTable) do
        local entPos = entities.get_position(ent_ptr)
        local modelname = entities.get_model_hash(ent_ptr)
        local modelname2 = util.reverse_joaat(modelname)
        local sx = memory.alloc()
        local sy = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
            local ssx = memory.read_float(sx)
            local ssy = memory.read_float(sy)
            directx.draw_text(ssx, ssy - 0.1, "Model Name: "..modelname2, 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_pickups:toggle_loop("Owner", {""}, "", function (toggle)
    local entTable = entities.get_all_pickups_as_pointers()
    for _, ent_ptr in pairs(entTable) do
        local entPos = entities.get_position(ent_ptr)
        local owner_id = entities.get_owner(ent_ptr)
        local owner_name = players.get_name(owner_id)
        local sx = memory.alloc()
        local sy = memory.alloc()
        if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
            local ssx = memory.read_float(sx)
            local ssy = memory.read_float(sy)
            directx.draw_text(ssx, ssy - 0.1, "Owner: "..owner_name, 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_pickups:toggle_loop("Blip", {""}, "", function (toggle)
    local entTable = entities.get_all_pickups_as_handles()
	util.yield()
    for _, ent in pairs(entTable) do
		local blip = HUD.ADD_BLIP_FOR_ENTITY(ent)
		HUD.SET_BLIP_SPRITE(blip, 351)
		table.insert(pickup_blip_esp_table, blip)
    end
	util.yield(500)
    for _, blip in pairs(pickup_blip_esp_table) do
        util.remove_blip(blip)
		pickup_blip_esp_table[_] = nil
    end
end)
world_list_spawner:action("Spawn Vehicle", {"vehspawn"}, "Spawns a vehicle with the selected name, only takes model name, not model hash", function() menu.show_command_box("vehspawn ") end, function(inp)
	local hash = util.joaat(inp)
	if STREAMING.IS_MODEL_VALID(hash) then
		local target_ped = players.user_ped()
		local pos1 = ENTITY.GET_ENTITY_COORDS(target_ped, false)
		pos1.x = pos1.x + 2
		RequestModel(hash)
		local entity = entities.create_vehicle(hash, pos1, 0)
		ENTITY.SET_ENTITY_COLLISION(entity, true, true)
		ENTITY.SET_ENTITY_DYNAMIC(entity, true)
		util.toast("Spawning: "..util.reverse_joaat(hash))
	else
		util.toast("Invalid Model: "..inp)
	end
end)
world_list_spawner:action("Spawn Ped", {"pedspawn"}, "Spawns a ped with the selected name, only takes model name, not model hash", function() menu.show_command_box("pedspawn ") end, function(inp)
	local hash = util.joaat(inp)
	if STREAMING.IS_MODEL_VALID(hash) then
		local target_ped = players.user_ped()
		local pos1 = ENTITY.GET_ENTITY_COORDS(target_ped, false)
		pos1.x = pos1.x + 2
		RequestModel(hash)
		local entity = entities.create_ped(0, hash, pos1, 0)
		ENTITY.SET_ENTITY_COLLISION(entity, true, true)
		ENTITY.SET_ENTITY_DYNAMIC(entity, true)
		util.toast("Spawning: "..util.reverse_joaat(hash))
	else
		util.toast("Invalid Model: "..inp)
	end
end)
world_list_spawner:action("Spawn Object", {"objspawn"}, "Spawns a object with the selected name, only takes model name, not model hash", function() menu.show_command_box("objspawn ") end, function(inp)
	local hash = util.joaat(inp)
	if STREAMING.IS_MODEL_VALID(hash) then
		local target_ped = players.user_ped()
		local pos1 = ENTITY.GET_ENTITY_COORDS(target_ped, false)
		pos1.x = pos1.x + 2
		RequestModel(hash)
		local entity = entities.create_object(hash, pos1)
		ENTITY.SET_ENTITY_COLLISION(entity, true, true)
		ENTITY.SET_ENTITY_DYNAMIC(entity, true)
		util.toast("Spawning: "..util.reverse_joaat(hash))
	else
		util.toast("Invalid Model: "..inp)
	end
end)

-- Local List: Misc
local misc_list = menu.list(menu.my_root(), "Miscellaneous", {}, "", function(); end)
local misc_list_targetting = menu.list(misc_list, "Targetting", {}, "", function(); end)
local misc_list_targetting_information = menu.list(misc_list_targetting, "Information", {}, "", function(); end)

misc_list:toggle_loop("Draw Sphere", {}, "", function(Toggle)
	local coords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
	GRAPHICS.DRAW_MARKER_SPHERE(coords.x, coords.y, coords.z, Settings.sphere_size, 255, 0, 255, 0.5)
end)
misc_list:slider("Sphere Radius", {"sphereradius"}, "", 1, 999999999, Settings.sphere_size, 1, function(s)
	Settings.sphere_size = s
end)
misc_list:toggle_loop("Auto Accept Game Warnings", {}, "", function()
	if HUD.IS_WARNING_MESSAGE_ACTIVE() then
		PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 201, 1)
		util.yield(200)
		util.toast("Auto Accepting Warning")
	end
end)
misc_list_targetting:toggle_loop("Enable", {}, "", function(toggle)
	if PED.IS_PED_SHOOTING(players.user_ped()) then
		Settings.targetting_handle = GetAimTarget()
		Settings.targetting_pointer = entities.handle_to_pointer(Settings.targetting_handle)
	end
    if Settings.targetting_pointer ~= 0 then
        Settings.targetting = true
    else
        Settings.targetting = false
    end
end)
misc_list_targetting:action("Use Current Vehicle", {}, "", function()
    if entities.get_user_vehicle_as_pointer() ~= 0 then
        Settings.targetting_handle = entities.get_user_vehicle_as_handle()
        Settings.targetting_pointer = entities.get_user_vehicle_as_pointer()
    else
        util.toast("You are not in a vehicle")
    end
end)
misc_list_targetting:action("Use Your Ped", {}, "", function()
    Settings.targetting_handle = players.user_ped()
    Settings.targetting_pointer = entities.handle_to_pointer(Settings.targetting_handle)
end)
misc_list_targetting_information:divider("Model")
local targetting_type = misc_list_targetting_information:readonly("N/A")
local targetting_name = misc_list_targetting_information:readonly("N/A")
local targetting_display_name = misc_list_targetting_information:readonly("N/A")
misc_list_targetting_information:divider("Location")
local targetting_position_x = misc_list_targetting_information:readonly("N/A")
local targetting_position_y = misc_list_targetting_information:readonly("N/A")
local targetting_position_z = misc_list_targetting_information:readonly("N/A")
local targetting_position_screen_x = misc_list_targetting_information:readonly("N/A")
local targetting_position_screen_y = misc_list_targetting_information:readonly("N/A")
misc_list_targetting_information:divider("Speed")
local targetting_speed_mph = misc_list_targetting_information:readonly("N/A")
local targetting_speed_kph = misc_list_targetting_information:readonly("N/A")
misc_list_targetting_information:divider("Health")
local targetting_health = misc_list_targetting_information:readonly("N/A")
local targetting_armor = misc_list_targetting_information:readonly("N/A")
misc_list_targetting_information:divider("Misc")
local targetting_owner = misc_list_targetting_information:readonly("N/A")
local targetting_script = misc_list_targetting_information:readonly("N/A")
local targetting_handle = misc_list_targetting_information:readonly("N/A")
local targetting_pointer = misc_list_targetting_information:readonly("N/A")

-- Local List: Settings
local settings_list = menu.list(menu.my_root(), "Settings", {}, "", function(); end)


-- Update Targetting Information
util.create_tick_handler(function()
	if Settings.targetting and Settings.targetting_handle ~= 0 and ENTITY.DOES_ENTITY_EXIST(Settings.targetting_handle) then
        local position = ENTITY.GET_ENTITY_COORDS(Settings.targetting_handle, 1)
        local speed = ENTITY.GET_ENTITY_SPEED(Settings.targetting_handle)
        local max_speed = VEHICLE.GET_VEHICLE_ESTIMATED_MAX_SPEED(Settings.targetting_handle)
        local sxa = memory.alloc()
		local sya = memory.alloc()
        local script = ""
		GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(position.x, position.y, position.z, sxa, sya)
        Settings.targetting_info_script = ENTITY.GET_ENTITY_SCRIPT(Settings.targetting_handle, script)
        Settings.targetting_info_owner = entities.get_owner(Settings.targetting_pointer)
        Settings.targetting_info_type = GetEntityType(Settings.targetting_handle)
        Settings.targetting_info_hash = entities.get_model_hash(Settings.targetting_pointer)
        Settings.targetting_info_name = util.reverse_joaat(Settings.targetting_info_hash)
        Settings.targetting_info_position_x = position.x
        Settings.targetting_info_position_y = position.y
        Settings.targetting_info_position_z = position.z
        Settings.targetting_info_screen_x = memory.read_float(sxa)
        Settings.targetting_info_screen_y = memory.read_float(sya)
        Settings.targetting_info_speed_mph = (speed * 2.236936)
        Settings.targetting_info_speed_kph = (speed * 3.6)
        Settings.targetting_info_health = ENTITY.GET_ENTITY_HEALTH(Settings.targetting_handle)
        Settings.targetting_info_max_health = ENTITY.GET_ENTITY_MAX_HEALTH(Settings.targetting_handle)
        if Settings.targetting_info_script == nil then Settings.targetting_info_script = "N/A" end

        -- Vehicle
        if Settings.targetting_info_type == "Vehicle" then
            Settings.targetting_info_display_name = util.get_label_text(VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(Settings.targetting_info_hash))
            Settings.targetting_info_max_speed_mph = (max_speed * 2.236936)
            Settings.targetting_info_max_speed_kph = (max_speed * 3.6)
            menu.set_visible(targetting_display_name, true)
        else
            Settings.targetting_info_display_name = "N/A"
            Settings.targetting_info_max_speed_mph = 0
            Settings.targetting_info_max_speed_kph = 0
            menu.set_visible(targetting_display_name, false)
        end

        -- Ped
        if Settings.targetting_info_type == "Ped" then
            Settings.targetting_info_armor = PED.GET_PED_ARMOUR(Settings.targetting_handle)
            Settings.targetting_info_max_armor = 0
            if Settings.targetting_info_type == "Player" then
                Settings.targetting_info_armor = PED.GET_PED_ARMOUR(Settings.targetting_handle)
                Settings.targetting_info_max_armor = PLAYER.GET_PLAYER_MAX_ARMOUR(Settings.targetting_info_owner)
            end
            menu.set_visible(targetting_armor, true)
        else
            Settings.targetting_info_armor = 0
            Settings.targetting_info_max_armor = 0
            menu.set_visible(targetting_armor, false)
        end

        -- Setting Menu Names
        menu.set_menu_name(targetting_owner, "Owner: "..players.get_name(Settings.targetting_info_owner))
        menu.set_menu_name(targetting_type, "Entity Type: "..Settings.targetting_info_type)
        menu.set_menu_name(targetting_name, "Name: "..Settings.targetting_info_name.." ("..Settings.targetting_info_hash..")")
        menu.set_menu_name(targetting_display_name, "Display Name: "..Settings.targetting_info_display_name)
        menu.set_menu_name(targetting_position_x, "X: "..round(Settings.targetting_info_position_x))
        menu.set_menu_name(targetting_position_y, "Y: "..round(Settings.targetting_info_position_y))
        menu.set_menu_name(targetting_position_z, "Z: "..round(Settings.targetting_info_position_z))
        if Settings.targetting_info_screen_x == -1 or Settings.targetting_info_screen_y == -1 then
			menu.set_menu_name(targetting_position_screen_x, "Screen X: Not On Screen")
			menu.set_menu_name(targetting_position_screen_y, "Screen Y: Not On Screen")
		else
			menu.set_menu_name(targetting_position_screen_x, "Screen X: "..Settings.targetting_info_screen_x)
			menu.set_menu_name(targetting_position_screen_y, "Screen Y: "..Settings.targetting_info_screen_y)
		end
        menu.set_menu_name(targetting_speed_mph, "Speed MPH: "..Settings.targetting_info_speed_mph.."("..round(Settings.targetting_info_max_speed_mph, 2)..")")
        menu.set_menu_name(targetting_speed_kph, "Speed KPH: "..Settings.targetting_info_speed_kph.."("..round(Settings.targetting_info_max_speed_kph, 2)..")")
        menu.set_menu_name(targetting_health, "Health: "..Settings.targetting_info_health.."/"..Settings.targetting_info_max_health)
        menu.set_menu_name(targetting_armor, "Armor: "..Settings.targetting_info_armor.."/"..Settings.targetting_info_max_armor)
        menu.set_menu_name(targetting_script, "Script: "..Settings.targetting_info_script)
        menu.set_menu_name(targetting_handle, "Handle: "..Settings.targetting_handle)
        menu.set_menu_name(targetting_pointer, "Pointer: "..Settings.targetting_pointer)
    else
        Settings.targetting_info_script = "N/A"
        Settings.targetting_info_owner = 0
        Settings.targetting_info_type = "N/A"
        Settings.targetting_info_hash = 0
        Settings.targetting_info_name = "N/A"
        Settings.targetting_info_display_name = "N/A"
        Settings.targetting_info_position_x = 0
        Settings.targetting_info_position_y = 0
        Settings.targetting_info_position_z = 0
        Settings.targetting_info_screen_x = 0
        Settings.targetting_info_screen_y = 0
        Settings.targetting_info_speed_mph = 0
        Settings.targetting_info_speed_kph = 0
        Settings.targetting_info_max_speed_mph = 0
        Settings.targetting_info_max_speed_kph = 0
        Settings.targetting_info_health = 0
        Settings.targetting_info_max_health = 0
        Settings.targetting_info_armor = 0
        Settings.targetting_info_max_armor = 0

        -- Setting Menu Names
        menu.set_menu_name(targetting_owner, "Owner: "..players.get_name(Settings.targetting_info_owner))
        menu.set_menu_name(targetting_type, "Entity Type: "..Settings.targetting_info_type)
        menu.set_menu_name(targetting_name, "Name: "..Settings.targetting_info_name.." ("..Settings.targetting_info_hash..")")
        menu.set_menu_name(targetting_display_name, "Display Name: "..Settings.targetting_info_display_name)
        menu.set_menu_name(targetting_position_x, "X: "..round(Settings.targetting_info_position_x))
        menu.set_menu_name(targetting_position_y, "Y: "..round(Settings.targetting_info_position_y))
        menu.set_menu_name(targetting_position_z, "Z: "..round(Settings.targetting_info_position_z))
        menu.set_menu_name(targetting_position_screen_x, "Screen X: "..Settings.targetting_info_screen_x)
        menu.set_menu_name(targetting_position_screen_y, "Screen Y: "..Settings.targetting_info_screen_y)
        menu.set_menu_name(targetting_speed_mph, "Speed MPH: "..Settings.targetting_info_speed_mph.."("..round(Settings.targetting_info_max_speed_mph)..")")
        menu.set_menu_name(targetting_speed_kph, "Speed KPH: "..Settings.targetting_info_speed_kph.."("..round(Settings.targetting_info_max_speed_kph)..")")
        menu.set_menu_name(targetting_health, "Health: "..Settings.targetting_info_health.."/"..Settings.targetting_info_max_health)
        menu.set_menu_name(targetting_armor, "Armor: "..Settings.targetting_info_armor.."/"..Settings.targetting_info_max_armor)
        menu.set_menu_name(targetting_script, "Script: "..Settings.targetting_info_script)
        menu.set_menu_name(targetting_handle, "Handle: "..Settings.targetting_handle)
        menu.set_menu_name(targetting_pointer, "Pointer: "..Settings.targetting_pointer)
    end
end)

util.keep_running()