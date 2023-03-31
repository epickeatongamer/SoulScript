--[[
    Credits
    Prism - Few little checks for clear area and method to clear projectiles/sounds
    Nowiry - The function to get aiming target
    Sapphire - Helping with dlc stuff
    Aaron - Instant respawn feature
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
Settings.targetting_info_dlc = "N/A"
Settings.targetting_info_owner = 0
Settings.targetting_info_type = "N/A"
Settings.targetting_info_hash = 0
Settings.targetting_info_name = "N/A"
Settings.targetting_info_display_name = "N/A"
Settings.targetting_info_manufacturer = "N/A"
Settings.targetting_info_vehicle_class = "N/A"
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
Settings.steering_type = 0
Settings.drive_type = 0
Settings.instant_respawn = false
Settings.folder_open_self = false
Settings.folder_open_vehicle = false
Settings.join_timer = false

-- Tables
local vehicle_blip_esp_table = {}
local pedestrian_blip_esp_table = {}
local object_blip_esp_table = {}
local pickup_blip_esp_table = {}
local player_blip_table = {}
local join_timer_offsets = {}

-- Local List: Self
local self_list = menu.list(menu.my_root(), "Self", {}, "", function() Settings.folder_open_self = true end, function() Settings.folder_open_self = false end)

self_list:toggle_loop("No Object Collision", {""}, "No collision with objects", function()
	local ped = players.user_ped()
	for _, object in pairs(entities.get_all_objects_as_handles()) do
		ENTITY.SET_ENTITY_NO_COLLISION_ENTITY(object, ped, true)
	end
    RemoveHandle(ped)
end)
menu.toggle(self_list, "Instant Respawn", {"instantrespawn", "instantspawn", "instarespawn", "instaspawn"}, "", function(state)
	Settings.instant_respawn = state
end, Settings.instant_respawn)

-- Local List: Vehicle
local vehicle_list = menu.list(menu.my_root(), "Vehicle", {}, "", function() Settings.folder_open_vehicle = true end, function() Settings.folder_open_vehicle = false end)
local vehicle_list_handling = menu.list(vehicle_list, "Handling", {}, "", function(); end)

vehicle_list:toggle_loop("Vehicle Friendly Fire", {""}, "Be able to shoot people inside your current vehicle", function()
	if players.get_vehicle_model(players.user()) then
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
	if players.get_vehicle_model(players.user()) then
		entities.set_rpm(entities.get_user_vehicle_as_pointer(), 1.2)
    	util.yield(250)
	end
end)
vehicle_list:toggle_loop("Engine Lump", {""}, "", function (toggle)
	if players.get_vehicle_model(players.user()) then
		entities.set_rpm(entities.get_user_vehicle_as_pointer(), 1.006)
    	util.yield(600)
	end
end)
vehicle_list_handling:toggle_loop("Enable F1 Boost", {""}, "Need to respawn vehicle for it to take effect", function (toggle)
	if players.get_vehicle_model(players.user()) then
		MISC.SET_BIT(entities.vehicle_get_handling(entities.get_user_vehicle_as_pointer()) + 0x128, 2)
        util.yield(100)
	end
end, function() MISC.CLEAR_BIT(entities.vehicle_get_handling(entities.get_user_vehicle_as_pointer()) + 0x128, 2) end)
vehicle_list_handling:toggle_loop("Offroad Mode", {""}, "Need to respawn vehicle for it to take effect", function (toggle)
	if players.get_vehicle_model(players.user()) then
		MISC.SET_BIT(entities.vehicle_get_handling(entities.get_user_vehicle_as_pointer()) + 0x128, 21)
        util.yield(100)
	end
end, function() MISC.CLEAR_BIT(entities.vehicle_get_handling(entities.get_user_vehicle_as_pointer()) + 0x128, 21) end)
vehicle_list_handling:list_select("Steering Type", {}, "", {"Front", "All", "Rear"}, 1, function(index, value)
	switch index do
		case 1:
			Settings.steering_type = 0
		break
		case 2:
            Settings.steering_type = 1
		break
		case 3:
            Settings.steering_type = 2
		break
	end
end)
vehicle_list_handling:toggle_loop("Apply Steering Type", {""}, "Need to respawn vehicle for it to take effect", function (toggle)
	if players.get_vehicle_model(players.user()) then
        if Settings.steering_type == 0 then
		    MISC.CLEAR_BIT(entities.vehicle_get_handling(entities.get_user_vehicle_as_pointer()) + 0x128, 5)
		    MISC.CLEAR_BIT(entities.vehicle_get_handling(entities.get_user_vehicle_as_pointer()) + 0x128, 7)
        elseif Settings.steering_type == 1 then
		    MISC.CLEAR_BIT(entities.vehicle_get_handling(entities.get_user_vehicle_as_pointer()) + 0x128, 5)
            MISC.SET_BIT(entities.vehicle_get_handling(entities.get_user_vehicle_as_pointer()) + 0x128, 7)
        elseif Settings.steering_type == 2 then
            MISC.SET_BIT(entities.vehicle_get_handling(entities.get_user_vehicle_as_pointer()) + 0x128, 5)
		    MISC.CLEAR_BIT(entities.vehicle_get_handling(entities.get_user_vehicle_as_pointer()) + 0x128, 7)
        end
        util.yield(100)
	end
end, function() 
    MISC.CLEAR_BIT(entities.vehicle_get_handling(entities.get_user_vehicle_as_pointer()) + 0x128, 5) 
    MISC.CLEAR_BIT(entities.vehicle_get_handling(entities.get_user_vehicle_as_pointer()) + 0x128, 7)
end)
vehicle_list_handling:list_select("Drive Type", {}, "", {"RWD", "AWD (30:70)", "AWD (50:50)", "AWD (70:30)", "FWD", "Full AWD"}, 1, function(index, value)
	switch index do
		case 1:
			Settings.drive_type = 0
		break
		case 2:
            Settings.drive_type = 1
		break
		case 3:
            Settings.drive_type = 2
		break
		case 4:
            Settings.drive_type = 3
		break
		case 5:
            Settings.drive_type = 4
		break
		case 6:
            Settings.drive_type = 5
		break
	end
end)
vehicle_list_handling:toggle_loop("Apply Drive Type", {""}, "These notes need to be read\n\nfwd is very temperamental\n\nfull awd is temperamental aswell, but needs the vehicle to be respawned to apply most of the time", function (toggle)
	if players.get_vehicle_model(players.user()) then
        local CHandlingData = entities.vehicle_get_handling(entities.get_user_vehicle_as_pointer())
        if Settings.drive_type == 0 then
		    memory.write_float(CHandlingData + 0x0044, "1.000000") -- rear
		    memory.write_float(CHandlingData + 0x0048, "0.000000") -- front
        elseif Settings.drive_type == 1 then
		    memory.write_float(CHandlingData + 0x0044, "0.750000") -- rear
		    memory.write_float(CHandlingData + 0x0048, "0.350000") -- front
        elseif Settings.drive_type == 2 then
		    memory.write_float(CHandlingData + 0x0044, "0.500000") -- rear
		    memory.write_float(CHandlingData + 0x0048, "0.500000") -- front
        elseif Settings.drive_type == 3 then
		    memory.write_float(CHandlingData + 0x0044, "0.350000") -- rear
		    memory.write_float(CHandlingData + 0x0048, "0.750000") -- front
        elseif Settings.drive_type == 4 then
		    memory.write_float(CHandlingData + 0x0044, "0.000000") -- rear
		    memory.write_float(CHandlingData + 0x0048, "1.000000") -- front
        elseif Settings.drive_type == 5 then
		    memory.write_float(CHandlingData + 0x0044, "1.000000") -- rear
		    memory.write_float(CHandlingData + 0x0048, "1.000000") -- front
        end
        util.yield(100)
	end
end)

-- Local List: Online
local online_list = menu.list(menu.my_root(), "Online", {}, "", function(); end)
online_list:toggle_loop("Chat Fix", {}, "Fixes the location of chat on ultrawide monitor", function()
	local mp_chat_scaleform_handle = GRAPHICS.REQUEST_SCALEFORM_MOVIE("multiplayer_chat")
	GRAPHICS.DRAW_SCALEFORM_MOVIE(mp_chat_scaleform_handle, 0.673, 0.5, 1, 1, 255, 255, 255, 255, 1)
end)
online_list:toggle_loop("Show Talking Players", {}, "Draws a list of players talking at the top of the screen", function()
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
online_list:toggle("Show Joining Players", {}, "Draws a list of players currently joining at the top of the screen", function(Toggle)
	Settings.join_timer = Toggle
end)
online_list:action("Cancel Join", {"stopjoin"}, "", function()
    NETWORK.NETWORK_SESSION_FORCE_CANCEL_INVITE()
end)

-- Local List: World
local world_list = menu.list(menu.my_root(), "World", {}, "", function(); end)
local world_list_cleararea = menu.list(world_list, "Clear Area", {}, "", function(); end)
local world_list_esp = menu.list(world_list, "Entity ESP", {}, "", function(); end)
local world_list_esp_vehicles = menu.list(world_list_esp, "Vehicles", {}, "", function(); end)
local world_list_esp_peds = menu.list(world_list_esp, "Peds", {}, "", function(); end)
local world_list_esp_objects = menu.list(world_list_esp, "Objects", {}, "", function(); end)
local world_list_esp_pickups = menu.list(world_list_esp, "Pickups", {}, "", function(); end)
--local world_list_esp_enemys = menu.list(world_list_esp, "Enemys", {}, "", function(); end)
local world_list_spawner = menu.list(world_list, "Spawner", {}, "", function(); end)
local world_list_blips = menu.list(world_list, "Blip Options", {}, "", function(); end)

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
			if ssx == -1 or ssy == -1 then return end
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
			if ssx == -1 or ssy == -1 then return end
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
			if ssx == -1 or ssy == -1 then return end
            directx.draw_text(ssx, ssy - 0.1, "Owner: "..owner_name, 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_vehicles:toggle_loop("Boundary Box", {""}, "May experience frame drops with this on", function (toggle)
	local entTable = entities.get_all_vehicles_as_pointers()
	for _, ent_ptr in pairs(entTable) do
		local entPos = entities.get_position(ent_ptr)
		local sx = memory.alloc()
		local sy = memory.alloc()
		if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
			local ssx = memory.read_float(sx)
			local ssy = memory.read_float(sy)
			if ssx ~= -1 or ssy ~= -1 then 
				DrawBoundaryBox(ent_ptr, entPos)
			end
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
			if ssx == -1 or ssy == -1 then return end
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
			if ssx == -1 or ssy == -1 then return end
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
			if ssx == -1 or ssy == -1 then return end
            directx.draw_text(ssx, ssy - 0.1, "Owner: "..owner_name, 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_peds:toggle_loop("Boundary Box", {""}, "May experience frame drops with this on", function (toggle)
	local entTable = entities.get_all_peds_as_pointers()
	for _, ent_ptr in pairs(entTable) do
		local entPos = entities.get_position(ent_ptr)
		local sx = memory.alloc()
		local sy = memory.alloc()
		if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
			local ssx = memory.read_float(sx)
			local ssy = memory.read_float(sy)
			if ssx ~= -1 or ssy ~= -1 then 
				DrawBoundaryBox(ent_ptr, entPos)
			end
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
			if ssx == -1 or ssy == -1 then return end
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
			if ssx == -1 or ssy == -1 then return end
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
			if ssx == -1 or ssy == -1 then return end
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
			if ssx == -1 or ssy == -1 then return end
            directx.draw_text(ssx, ssy - 0.1, "Owner: "..owner_name, 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_objects:toggle_loop("Boundary Box", {""}, "May experience frame drops with this on", function (toggle)
	local entTable = entities.get_all_objects_as_pointers()
	for _, ent_ptr in pairs(entTable) do
		local entPos = entities.get_position(ent_ptr)
		local sx = memory.alloc()
		local sy = memory.alloc()
		if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
			local ssx = memory.read_float(sx)
			local ssy = memory.read_float(sy)
			if ssx ~= -1 or ssy ~= -1 then 
				DrawBoundaryBox(ent_ptr, entPos)
			end
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
			if ssx == -1 or ssy == -1 then return end
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
			if ssx == -1 or ssy == -1 then return end
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
			if ssx == -1 or ssy == -1 then return end
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
			if ssx == -1 or ssy == -1 then return end
            directx.draw_text(ssx, ssy - 0.1, "Owner: "..owner_name, 1, 0.5, pinkcolor, false)
        end
    end
end)
world_list_esp_pickups:toggle_loop("Boundary Box", {""}, "May experience frame drops with this on", function (toggle)
	local entTable = entities.get_all_pickups_as_pointers()
	for _, ent_ptr in pairs(entTable) do
		local entPos = entities.get_position(ent_ptr)
		local sx = memory.alloc()
		local sy = memory.alloc()
		if GRAPHICS.GET_SCREEN_COORD_FROM_WORLD_COORD(entPos.x, entPos.y, entPos.z, sx, sy) then
			local ssx = memory.read_float(sx)
			local ssy = memory.read_float(sy)
			if ssx ~= -1 or ssy ~= -1 then 
				DrawBoundaryBox(ent_ptr, entPos)
			end
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

world_list_blips:toggle_loop("Draw Player Cones", {}, "", function()
	for _, pid in ipairs(players.list()) do
		local blip = HUD.GET_BLIP_FROM_ENTITY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
		player_blip_table[#player_blip_table + 1] = blip
		if pid ~= players.user() and HUD.IS_BLIP_ON_MINIMAP(blip) then
    		HUD.SET_BLIP_SHOW_CONE(blip, true, 1)
		end
	end
end, function() 
	for pos, blip in ipairs(player_blip_table) do
		HUD.SET_BLIP_SHOW_CONE(blip, false, 1)
		table.remove(player_blip_table, pos)
	end
end)
world_list_blips:toggle_loop("Ignore Police Cones", {}, "", function()
    if players.get_vehicle_model(players.user()) then
		VEHICLE.SET_DISABLE_WANTED_CONES_RESPONSE(entities.get_user_vehicle_as_handle(), true)
	end
end, function() 
    if players.get_vehicle_model(players.user()) then
		VEHICLE.SET_DISABLE_WANTED_CONES_RESPONSE(entities.get_user_vehicle_as_handle(), false)
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
local targetting_manufacturer = misc_list_targetting_information:readonly("N/A")
local targetting_vehicle_class = misc_list_targetting_information:readonly("N/A")
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
local settings_list_bounding_box = menu.list(settings_list, "Boundary Box", {}, "", function(); end)

settings_list_bounding_box:toggle_loop("Draw in self options", {}, "", function()
    if menu.is_open() then
	    if Settings.folder_open_self or IsInParent(menu.get_current_menu_list(), menu.ref_by_path("Self")) then
            local ped = entities.handle_to_pointer(players.user_ped())
            local position = entities.get_position(ped)
	    	DrawBoundaryBox(ped, position)
	    end
    end
end)
settings_list_bounding_box:toggle_loop("Draw in vehicle options", {}, "", function()
    if menu.is_open() then
	    if Settings.folder_open_vehicle or IsInParent(menu.get_current_menu_list(), menu.ref_by_path("Vehicle")) then
	    	if players.get_vehicle_model(players.user()) then
                local vehicle = entities.get_user_vehicle_as_pointer()
                local position = entities.get_position(vehicle)
	    		DrawBoundaryBox(vehicle, position)
	    	end
	    end
    end
end)

-- Update Targetting Information
util.create_tick_handler(function()
	if Settings.targetting and Settings.targetting_handle ~= 0 and ENTITY.DOES_ENTITY_EXIST(Settings.targetting_handle) then
        local position = ENTITY.GET_ENTITY_COORDS(Settings.targetting_handle, 1)
        local speed = ENTITY.GET_ENTITY_SPEED(Settings.targetting_handle)
        local max_speed = VEHICLE.GET_VEHICLE_ESTIMATED_MAX_SPEED(Settings.targetting_handle)
        local sxa = memory.alloc()
		local sya = memory.alloc()
        local script = ""
        local CAutomobile = Settings.targetting_pointer
        local CVehicleModelInfo = 0x20
        local m_manufacturer = memory.read_string(memory.read_long(CAutomobile + CVehicleModelInfo) + 0x02A4)
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
            Settings.targetting_info_manufacturer = m_manufacturer:lower()
            Settings.targetting_info_vehicle_class = GetClass(Settings.targetting_handle)
            Settings.targetting_info_max_speed_mph = (max_speed * 2.236936)
            Settings.targetting_info_max_speed_kph = (max_speed * 3.6)
            menu.set_visible(targetting_display_name, true)
            menu.set_visible(targetting_manufacturer, true)
            menu.set_visible(targetting_vehicle_class, true)
        else
            Settings.targetting_info_display_name = "N/A"
            Settings.targetting_info_manufacturer = "N/A"
            Settings.targetting_info_vehicle_class = "N/A"
            Settings.targetting_info_max_speed_mph = 0
            Settings.targetting_info_max_speed_kph = 0
            menu.set_visible(targetting_display_name, false)
            menu.set_visible(targetting_manufacturer, false)
            menu.set_visible(targetting_vehicle_class, false)
        end

        -- Ped
        if Settings.targetting_info_type == "Ped" then

        else

        end

        -- Player
        if Settings.targetting_info_type == "Player" then
            Settings.targetting_info_armor = PED.GET_PED_ARMOUR(Settings.targetting_handle)
            Settings.targetting_info_max_armor = PLAYER.GET_PLAYER_MAX_ARMOUR(Settings.targetting_info_owner)
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
        menu.set_menu_name(targetting_manufacturer, "Manufacturer: "..Settings.targetting_info_manufacturer)
        menu.set_menu_name(targetting_vehicle_class, "Vehicle Class: "..Settings.targetting_info_vehicle_class)
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
        menu.set_menu_name(targetting_speed_mph, "Speed MPH: "..math.floor(Settings.targetting_info_speed_mph).."("..math.floor(Settings.targetting_info_max_speed_mph)..")")
        menu.set_menu_name(targetting_speed_kph, "Speed KPH: "..math.floor(Settings.targetting_info_speed_kph).."("..math.floor(Settings.targetting_info_max_speed_kph)..")")
        menu.set_menu_name(targetting_health, "Health: "..Settings.targetting_info_health.."/"..Settings.targetting_info_max_health)
        menu.set_menu_name(targetting_armor, "Armor: "..Settings.targetting_info_armor.."/"..Settings.targetting_info_max_armor)
        menu.set_menu_name(targetting_script, "Script: "..Settings.targetting_info_script)
        menu.set_menu_name(targetting_script, "DLC: "..Settings.targetting_info_dlc)
        menu.set_menu_name(targetting_handle, "Handle: "..Settings.targetting_handle)
        menu.set_menu_name(targetting_pointer, "Pointer: "..Settings.targetting_pointer)
    else
        Settings.targetting_info_script = "N/A"
        Settings.targetting_info_owner = 0
        Settings.targetting_info_type = "N/A"
        Settings.targetting_info_hash = 0
        Settings.targetting_info_name = "N/A"
        Settings.targetting_info_display_name = "N/A"
        Settings.targetting_info_manufacturersss = "N/A"
        Settings.targetting_info_vehicle_class = "N/A"
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
        Settings.targetting_info_dlc = "N/A"

        -- Setting Menu Names
        menu.set_menu_name(targetting_owner, "Owner: "..players.get_name(Settings.targetting_info_owner))
        menu.set_menu_name(targetting_type, "Entity Type: "..Settings.targetting_info_type)
        menu.set_menu_name(targetting_name, "Name: "..Settings.targetting_info_name.." ("..Settings.targetting_info_hash..")")
        menu.set_menu_name(targetting_display_name, "Display Name: "..Settings.targetting_info_display_name)
        menu.set_menu_name(targetting_manufacturer, "Manufacturer: "..Settings.targetting_info_manufacturer)
        menu.set_menu_name(targetting_vehicle_class, "Vehicle Class: "..Settings.targetting_info_vehicle_class)
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
        menu.set_menu_name(targetting_script, "DLC: "..Settings.targetting_info_dlc)
        menu.set_menu_name(targetting_handle, "Handle: "..Settings.targetting_handle)
        menu.set_menu_name(targetting_pointer, "Pointer: "..Settings.targetting_pointer)
    end
end)

--instant respawn tick handler
util.create_tick_handler(function()
	if Settings.instant_respawn then
		local player = players.user()
		if not PLAYER.IS_PLAYER_CONTROL_ON(player) then return end
		local ped = players.user_ped()
		local ped_ptr = entities.handle_to_pointer(ped)
		if entities.get_health(ped_ptr) < 100 then
			local ped_coord = ENTITY.GET_ENTITY_COORDS(ped)
			local ped_rot = ENTITY.GET_ENTITY_HEADING(ped)
			local ped_weapon = WEAPON.GET_SELECTED_PED_WEAPON(ped)
			local cam_rot = CAM.GET_FINAL_RENDERED_CAM_ROT(2)
			local veh, seat
			veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
			if veh ~= 0 then
				seat = GetPedSeat(veh, ped)
			end
			NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(ped_coord.x, ped_coord.y, ped_coord.z, ped_rot, false, false, 0)
			WEAPON.GIVE_WEAPON_TO_PED(ped, ped_weapon, 0, false, true)
			CAM.SET_GAMEPLAY_CAM_RELATIVE_PITCH(cam_rot.x, 1)
			CAM.SET_GAMEPLAY_CAM_RELATIVE_HEADING(cam_rot.z - ped_rot)
			if seat then
				TASK.TASK_WARP_PED_INTO_VEHICLE(ped, veh, seat)
			end
			util.yield(200)
			if not seat and PED.IS_PED_RAGDOLL(ped) then
				TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
			end
		end
	end
end)

-- tick handler for other stuff
util.create_tick_handler(function()
    -- Join Timers
    local joining_offset = 0
    for pos, pid in ipairs(players.list()) do
        if Settings.join_timer and memory.read_byte(memory.script_global(2657589 + 1 + (pid * 466) + 232)) == 0 and players.get_name(pid) ~= nil then
            join_timer_offsets[pid] = joining_offset
            joining_offset = joining_offset + 1
        end
    end
end)

-- On Join function
players.on_join(function(pid)
	if Settings.join_timer and players.get_name(pid) ~= nil then
		local timer = 0
		repeat
			timer = timer + 1
			directx.draw_text(0, 0 + (join_timer_offsets[pid] * 0.02), players.get_name(pid).." ("..pid.."): "..(timer/100).."s", ALIGN_TOP_LEFT, 0.5, pinkcolor, false)
			util.yield()
		until memory.read_byte(memory.script_global(2657589 + 1 + (pid * 466) + 232)) == 99
        join_timer_offsets[pid] = 0
	end
end)

-- On Leave function
players.on_leave(function(pid, username)
    --code
end)

util.keep_running()