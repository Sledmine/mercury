
-- Universal AI synchronization client script V.1.2 (Release/DELTA 1.7, compatible with server BETA 1.7), by IceCrow14.

-- Text tags for important stuff: "TESTING", "PENDING", "REMINDER", "DEBUGGED".

-- List of new features:
	-- Now named bipeds, those placed from the "Bipeds" section in Sapien and AI major variants will synchronize.
	-- AI actors that use the player biped tag will be synchronized too. This means that these scripts should now be compatible with any multi-team bipeds script.
	-- Lots of potential (and actual) glitch sources patched.
	-- Packet data is now compressed using base-41, and hexadecimal (base-16) numeral systems.
	-- Angular velocities are now synchronized. This makes bipeds' movement look as smooth as if they were client sided.
	-- Introduced a menu and file to adjust performance settings and show debugging information when desired.

-- List of possible features to add/things to do:
	-- AI synchronization in vehicles.
	-- AI firing effects.
	-- Restore safe mode.
	-- Eternal projectiles, make a timer or manual reset command to delete them.
	-- Code to ensure bipeds play their complete death animations.

-- Notes:
	-- Doesn't work for protected maps.

clua_version = 2.042

-- Callbacks
set_callback("map load", "OnGameStart")
set_callback("pretick", "OnTick")
set_callback("rcon message", "OnRcon")
set_callback("command", "OnCommand")

-- Globals (and default values)
char_table = {}
settings = nil
settings_initialized = nil

uais_max_expected_bipeds_by_match = 2048 -- Max: 65535
uais_alpha_period = 3
uais_debug = false
uais_show_packets = false
uais_excluded_maps = {}

-- Object, data tables and match exclusive variables.
biped_tag_paths = {}
weapon_tag_paths = {}
bipeds = {} -- Every biped is an array of its properties, including the object ID. Structure subject to change, using string keys temporally.
weapons = {}
ticks = 0
map_is_ready = false

function OnGameStart()
	map_is_ready = false
	ticks = 0
	bipeds = {}
	weapons = {}
	biped_tag_paths = {}
	weapon_tag_paths = {}

	if server_type == "dedicated" then
		MakeBase41Table()
		InitializeSettings()
		Startup()
		map_is_ready = true
	end
end

function OnRcon(Message)
	if map_is_ready == true then
		if string.sub(Message, 1, 2) == "@b" then
			if string.sub(Message, 3, 3) == "u" then
				UpdateBiped(Message)
				return uais_show_packets
			elseif string.sub(Message, 3, 3) == "d" then
				DeleteBiped(Message)
				return uais_show_packets
			else
				console_out("WARNING: Unespecified biped instruction")
			end
		end
	end
end

function OnCommand(Command)
	if string.sub(Command, 1, 4) == "uais" then
		return PrimaryMenu(Command)
	end
end

function OnTick()
	if server_type == "dedicated" then
		UpdateAllBipedsOnTick()
	end
end

-- >>> Sub-level functions: Used by the functions above. <<<

-- REMOTE CONSOLE FUNCTIONS

-- Read and store meaningful information from remote console packets.

function UpdateBiped(Message) -- S.L. 1.
	if string.len(Message) >= 80 then
		console_out("WARNING: Number of characters exceeded. ("..string.len(Message)..")")
	else
		local data = GetRConPacketValues(Message, 16, 2, 2, 2) -- Format specified in the server script.
		local biped_index = Hex4ToWord16(data[17])

		if bipeds[biped_index] == nil then
			bipeds[biped_index] = {}
			bipeds[biped_index]["last_update_time"] = ticks
		else
			bipeds[biped_index]["x"] = Integer41ToFloat16(data[1])
			bipeds[biped_index]["y"] = Integer41ToFloat16(data[2])
			bipeds[biped_index]["z"] = Integer41ToFloat16(data[3])
			bipeds[biped_index]["x_vel"] = Integer41ToFloat16(data[4])
			bipeds[biped_index]["y_vel"] = Integer41ToFloat16(data[5])
			bipeds[biped_index]["z_vel"] = Integer41ToFloat16(data[6])
			bipeds[biped_index]["pitch"] = Integer41ToFloat16(data[7])
			bipeds[biped_index]["yaw"] = Integer41ToFloat16(data[8])
			bipeds[biped_index]["pitch_vel"] = Integer41ToFloat16(data[9])
			bipeds[biped_index]["yaw_vel"] = Integer41ToFloat16(data[10])
			bipeds[biped_index]["x_aim"] = Integer41ToFloat16(data[11])
			bipeds[biped_index]["y_aim"] = Integer41ToFloat16(data[12])
			bipeds[biped_index]["z_aim"] = Integer41ToFloat16(data[13])
			bipeds[biped_index]["x_aim_vel"] = Integer41ToFloat16(data[14])
			bipeds[biped_index]["y_aim_vel"] = Integer41ToFloat16(data[15])
			bipeds[biped_index]["z_aim_vel"] = Integer41ToFloat16(data[16])

			bipeds[biped_index]["animation"] = Hex4ToWord16(data[18]) -- REMINDER: Get rid of those obsolete hex functions and replace for base 41.

			bipeds[biped_index]["biped_type"] = Hex2ToByte8(data[19])
			bipeds[biped_index]["weapon_type"] = Hex2ToByte8(data[20])

			bipeds[biped_index]["health"] = tonumber(data[21])
			bipeds[biped_index]["shield"] = tonumber(data[22])

			bipeds[biped_index]["update_time"] = ticks
		end
	end
end

function DeleteBiped(Message)
	local data = GetRConPacketValues(Message, 0, 1, 0, 0)
	local biped_index = Hex4ToWord16(data[1])
	if bipeds[biped_index] ~= nil then
		bipeds[biped_index]["delete"] = true
	end
end

function GetRConPacketValues(Message, Integer41s, Words, Bytes, Bits) -- S.L. 2.
	local data_table = {}
	local data_start = 4
	local c_data_start = data_start
	if Integer41s > 0 then
		for i = 1, Integer41s do
			local c_value = string.sub(Message, c_data_start, c_data_start + 2)
			table.insert(data_table, c_value)
			c_data_start = c_data_start + 3
		end
	end
	if Words > 0 then
		for i = 1, Words do
			local c_value = string.sub(Message, c_data_start, c_data_start + 3)
			table.insert(data_table, c_value)
			c_data_start = c_data_start + 4
		end
	end
	if Bytes > 0 then
		for i = 1, Bytes do
			local c_value = string.sub(Message, c_data_start, c_data_start + 1)
			table.insert(data_table, c_value)
			c_data_start = c_data_start + 2
		end
	end
	if Bits > 0 then
		for i = 1, Bits do
			local c_value = string.sub(Message, c_data_start, c_data_start)
			table.insert(data_table, c_value)
			c_data_start = c_data_start + 1
		end
	end
	return data_table
end

-- FILE I/O FUNCTIONS

-- For the settings file. Only executed once, right after joining a dedicated server.

function InitializeSettings() -- S.L. 1.
	if settings_initialized ~= true then
		settings = io.open("uais_settings_client.txt", "r")
		DebugConsoleOut("ATTENTION: Reading settings file...")
		if settings == nil then -- Create file. 
			DebugConsoleOut("WARNING: Settings file doesn't exist. Creating...")

			settings = io.open("uais_settings_client.txt", "w") -- Write default values for global variables.
			WriteDefaultSettings()
			io.close(settings)

			DebugConsoleOut("ATTENTION: Settings file created.")
			settings = io.open("uais_settings_client.txt", "r")
		end
		ReadSettingsFile() -- Read file and assign values for global variables.
		io.close(settings)

		DebugConsoleOut("ATTENTION: Settings file closed.")
		settings_initialized = true
	end
end

function WriteDefaultSettings() -- S.L. 2.
	io.output(settings)
	io.write("@ You can specify new values for the following settings manually as long as you don't modify the format or specify invalid ones. To add a new excluded map, just write its file name (without the .map extension) below the EXCLUDED MAPS section, specify only one map per line.\n")
	io.write("@ If for some reason you break the file (GG), just delete it, restart your game, join a dedicated server and a new file will be created automatically for you.\n")
	io.write("@ Read the in-game menu for more information about what you can write here safely. For questions or help, you can find me on YouTube or Discord. -IceCrow14\n")
	io.write("MAX. EXPECTED BIPEDS PER MATCH (Must be a positive integer, you can lower this value for better performance, just don't set it too low or some bipeds will not synchronize. Above 2000 should be fine for most cases).\n2048\n")
	io.write("ALPHA PERIOD (Positive integer, in seconds)\n3\n")
	io.write("EXCLUDED MAPS\n") -- Stock maps will be added by default.
	io.write("beavercreek\nsidewinder\ndamnation\nratrace\nprisoner\nhangemhigh\nchillout\ncarousel\nboardingaction\nbloodgulch\nwizard\nputput\nlongest\nicefields\ndeathisland\ndangercanyon\ninfinity\ntimberland\ngephyrophobia\n")
end

function ReadSettingsFile()
	io.input(settings)
	local valid_lines = {}
	for line in settings:lines() do
		if string.sub(line, 1, 1) ~= "@" then
			table.insert(valid_lines, line)
		end	
	end

	uais_max_expected_bipeds_by_match = tonumber(valid_lines[2])
	uais_alpha_period = tonumber(valid_lines[4])

	if #uais_excluded_maps == 0 then
		for map = 6, #valid_lines do
			table.insert(uais_excluded_maps, valid_lines[map])
		end
	end
end

-- MEMORY READING/WRITING FUNCTIONS

-- Used to apply changes to the game's real-time memory.

function UpdateAllBipedsOnTick() -- S.L. 1.
	-- UPDATE BIPED INSTRUCTIONS
	for biped_index = 1, uais_max_expected_bipeds_by_match do
		if bipeds[biped_index] ~= nil then

			if bipeds[biped_index]["object_id"] ~= nil then
				local m_address = get_object(bipeds[biped_index]["object_id"])
				if m_address ~= nil then -- Let's assume there are no object ID mismatches or anything like that...

					local local_health_empty = read_bit(m_address + 0x106, 2)

					-- CONSTANT UPDATES, velocities and maybe (just maybe, PENDING in such case) shield. Here is where quality settings would be used.
					write_float(m_address + 0x68, bipeds[biped_index]["x_vel"])
					write_float(m_address + 0x6C, bipeds[biped_index]["y_vel"])
					write_float(m_address + 0x70, bipeds[biped_index]["z_vel"])
					write_float(m_address + 0x8C, bipeds[biped_index]["pitch_vel"])
					write_float(m_address + 0x90, bipeds[biped_index]["yaw_vel"])
					
					if local_health_empty == 0 then
						write_float(m_address + 0x248, bipeds[biped_index]["x_aim_vel"])
						write_float(m_address + 0x24C, bipeds[biped_index]["y_aim_vel"])
						write_float(m_address + 0x250, bipeds[biped_index]["z_aim_vel"])
					end

					-- DELAYED UPDATES
					if bipeds[biped_index]["update_time"] ~= bipeds[biped_index]["last_update_time"] then
						write_float(m_address + 0x5C, bipeds[biped_index]["x"])
						write_float(m_address + 0x60, bipeds[biped_index]["y"])
						write_float(m_address + 0x64, bipeds[biped_index]["z"])
						write_float(m_address + 0x74, bipeds[biped_index]["pitch"])
						write_float(m_address + 0x78, bipeds[biped_index]["yaw"])

						local local_animation = read_word(m_address + 0xD0)
						
						local local_shield_empty = read_bit(m_address + 0x106, 3)

						if bipeds[biped_index]["animation"] ~= local_animation then
							write_word(m_address + 0xD2, 0)
							if bipeds[biped_index]["animation"] ~= 65535 then
								write_word(m_address + 0xD0, bipeds[biped_index]["animation"]) -- REMINDER.
							end
						end

						if bipeds[biped_index]["shield"] == local_shield_empty then
							if bipeds[biped_index]["shield"] == 1 then
								write_float(m_address + 0xE4, 1)
								write_bit(m_address + 0x106, 3, 0)
							else
								-- PENDING: Write to addresses that stop shield regeneration and do the shield sapping effect.
								write_float(m_address + 0xE4, 0)
								write_bit(m_address + 0x106, 3, 1)
							end
						end

						if bipeds[biped_index]["health"] == local_health_empty then
							if bipeds[biped_index]["health"] <= 0 then
								DeleteBipedWeapon(biped_index)
								write_float(m_address + 0xE0, 0)
								write_bit(m_address + 0x106, 11, 0)
								write_bit(m_address + 0x106, 2, 1)
							else
								write_float(m_address + 0x23C, bipeds[biped_index]["x_aim"])
								write_float(m_address + 0x240, bipeds[biped_index]["y_aim"])
								write_float(m_address + 0x244, bipeds[biped_index]["z_aim"])
							end
						end
						bipeds[biped_index]["last_update_time"] = bipeds[biped_index]["update_time"]
					end
				else -- DEBUGGED: Enabled, the memory leak is gone. 
					bipeds[biped_index] = nil
				end
			else
				if bipeds[biped_index]["update_time"] ~= nil then -- Make sure all the data has been collected.
					local biped_tag_path = biped_tag_paths[bipeds[biped_index]["biped_type"]]
					local weapon_tag_path = weapon_tag_paths[bipeds[biped_index]["weapon_type"]]
					if bipeds[biped_index]["health"] > 0 then

						bipeds[biped_index]["object_id"] = spawn_object("bipd", biped_tag_path, bipeds[biped_index]["x"], bipeds[biped_index]["y"], bipeds[biped_index]["z"])

						local m_address = get_object(bipeds[biped_index]["object_id"])
						write_bit(m_address + 0x106, 11, 1) -- 'Undamageable'

						if weapon_tag_path ~= nil then
							weapons[biped_index] = spawn_object("weap", weapon_tag_path, bipeds[biped_index]["x"], bipeds[biped_index]["y"], bipeds[biped_index]["z"])

							local m_address_weapon = get_object(weapons[biped_index])
							write_dword(m_address + 0x2F8, weapons[biped_index]) -- 'Unit primary weapon object ID', writing to these two is more than enough.
							write_bit(m_address_weapon + 0x1F4, 0, 1) -- 'Item is in inventory'
							-- PENDING: Add support for multiple weapons for a single biped? That'd require writing to the weapon slot m_address too.
						end

						DebugConsoleOut("Biped created #"..biped_index)

					end
				end

			end

		end

		-- DELETE BIPED INSTRUCTIONS
		if bipeds[biped_index] ~= nil then
			if bipeds[biped_index]["delete"] == true then -- DEBUGGED: Repeated for cycle, I forgot to fix this on the first release.
				if bipeds[biped_index]["object_id"] ~= nil then
					local m_address = get_object(bipeds[biped_index]["object_id"])
					if m_address ~= nil then
						DeleteBipedWeapon(biped_index)
						delete_object(bipeds[biped_index]["object_id"])
					end
				end
				bipeds[biped_index] = nil
				DebugConsoleOut("Biped #"..biped_index.." deleted.")
			end
		end

	end
	-- HIDE SERVER BIPEDS INSTRUCTIONS
	AlphaFunction()
	-- RESET AI BIPEDS/DELETION DUE TO LACK OF UPDATES/ETERNAL PROJECTILES RESET INSTRUCTIONS
	-- PENDING.
end

function DeleteBipedWeapon(BipedIndex) -- S.L. 2.
	local weapon_object_id = weapons[BipedIndex]
	if weapon_object_id ~= nil then
		if get_object(weapon_object_id) ~= nil then
			-- DEBUGGED: Seems that biped weapon drop is performed automatically after the weapon object is deleted. So this should be enough.
			-- REMINDER: Using ai_erase_all can sometimes crash the game. I still don't know what might cause it but I suspect it does when there are lots of bipeds.
			delete_object(weapon_object_id)
		end
		weapons[BipedIndex] = nil
	end
end

function AlphaFunction()
	ticks = ticks + 1
	local seconds = ticks/30 -- REMINDER: Hard-coded tick rate.
	if seconds % uais_alpha_period == 0 then
		local local_bipeds = 0
		local server_bipeds = 0
		local npc_bipeds_object_id = GetCurrentBipeds()[1]
		local npc_bipeds_memory = GetCurrentBipeds()[2]
		if #npc_bipeds_object_id > 0 then
			for i = 1, #npc_bipeds_object_id do
				local biped = npc_bipeds_object_id[i]
				local biped_address = npc_bipeds_memory[i]
				local is_server_biped = true
				for biped_index = 1, uais_max_expected_bipeds_by_match do
					if bipeds[biped_index] ~= nil then
						local c_rcon_biped = bipeds[biped_index]["object_id"]
						if biped == c_rcon_biped then
							is_server_biped = false
							break
						end
					end
				end
				local ghost_mode = read_bit(biped_address + 0x10, 0)
				if is_server_biped == true then
					server_bipeds = server_bipeds + 1
					if ghost_mode == 0 then
						write_bit(biped_address + 0x10, 0, 1) -- 'Ghost mode'
						write_bit(biped_address + 0x10, 24, 1) -- 'Collision disabled'
					end
				else
					local_bipeds = local_bipeds + 1
					if ghost_mode == 1 then
						write_bit(biped_address + 0x10, 0, 0)
						write_bit(biped_address + 0x10, 24, 0)
					end
				end
			end
		end
		DebugConsoleOut("Server: "..server_bipeds..", local: "..local_bipeds..", total: "..#npc_bipeds_object_id)
	end
end

function GetCurrentBipeds() -- S.L. 3. Adds any non-player biped's object ID and memory address to the return table. Credits to Devieth for the object table addresses. 
	local current_bipeds = {{}, {}}
	local object_table = 0x400506B4
	local object_count = read_word(object_table + 0x2E)
	local object_base = read_dword(object_table + 0x34)
	for i = 0, (object_count - 1) do
		local object_table_address = object_base + (i * 0xC) + 0x8
		local object_address = read_dword(object_table_address)
		local object_id = read_word(object_base + i * 12) * 0x10000 + i
		if object_address ~= 0 then
			local object_type = read_word(object_address + 0xB4)
			if object_type == 0 then
				local player_id = read_dword(object_address + 0xC0)
				if player_id == 0xFFFFFFFF then
					table.insert(current_bipeds[1], object_id)
					table.insert(current_bipeds[2], object_address)
				end
			end
		end
	end
	return current_bipeds
end

-- CUSTOMIZATION MENU FUNCTIONS

-- These define what should be done when you enter a UAIS command.

function PrimaryMenu(Command) -- S.L. 1.
	local valid_command = false
	if Command == "uais" then -- Display help menus.
		valid_command = ValidCommandResult()
		console_out("Universal AI synchronization client script V.1.2 (Release/DELTA 1.7) by IceCrow14")
		console_out("  List of commands:")
		console_out("    >> uais")
		console_out("    >> uais_mebpm")
		console_out("    >> uais_alpha_period")
		console_out("    >> uais_debug")
		console_out("    >> uais_show_packets")
		console_out("Enter a command for usage details.")
	elseif Command == "uais_mebpm" then
		valid_command = ValidCommandResult()
		console_out("UAIS max. expected bipeds by match (Current: "..uais_max_expected_bipeds_by_match..")")
		console_out("Sets a new value for this parameter, lower values improve performance (default: 2048).")
		console_out("WARNING I: Do not change this value in-game (other than in the UI), errors may occur.")
		console_out("WARNING II: Very low values will cause desynchronization issues.")
		console_out("Usage: uais_mebpm <value>")
	elseif Command == "uais_alpha_period" then
		valid_command = ValidCommandResult()
		console_out("UAIS alpha period (Current: "..uais_alpha_period..")")
		console_out("Sets a new period for the Alpha function timer, in seconds (default: 3).")
		console_out("Greater values improve performance; lower ones hide the server-side bipeds quicker.")
		console_out("Usage: uais_alpha_period <period>")
	elseif Command == "uais_debug" then
		valid_command = ValidCommandResult()
		console_out("UAIS debug (Current: "..tostring(uais_debug)..")")
		console_out("Prints additional information to the console, disabled by default.")
		console_out("Usage: uais_debug <true/false>")
	elseif Command == "uais_show_packets" then
		valid_command = ValidCommandResult()
		console_out("UAIS show packets (Current: "..tostring(uais_show_packets)..")")
		console_out("Usage: uais_show_packets <true/false>")
	elseif Command == "uais_safe_mode" then
		valid_command = ValidCommandResult()
		console_out("UAIS safe mode (Current: "..tostring(uais_safe_mode)..")")
		console_out("Disables garbage collection handled by the server. This will affect some visuals.")
		console_out("Turn on if your game crashes, or invisible bipeds are a frequent issue (default: true)")
		console_out("Usage: uais_safe_mode <true/false>")
	end
	if string.sub(Command, 1, 5) == "uais_" then -- Execute commands.
		if string.sub(Command, 6, 11) == "mebpm " then
			local value = tonumber(string.sub(Command, 12, -1))
			if value ~= nil and value > 0 then
				valid_command = ValidCommandResult()
				uais_max_expected_bipeds_by_match = value
				SaveSettingToFile("MAX. EXPECTED BIPEDS PER MATCH (Must be a positive integer, you can lower this value for better performance, just don't set it too low or some bipeds will not synchronize. Above 2000 should be fine for most cases).\n", value, "UAIS Max. expected bipeds by match, changed to: "..value)
			end
		elseif string.sub(Command, 6, 18) == "alpha_period " then
			local period = tonumber(string.sub(Command, 19, -1))
			if period ~= nil and period > 0 then
				valid_command = ValidCommandResult()
				uais_alpha_period = period
				SaveSettingToFile("ALPHA PERIOD (Positive integer, in seconds)\n", period, "UAIS Alpha period, changed to: "..period)
			end
		elseif string.sub(Command, 6, 11) == "debug " then
			if string.sub(Command, 12, 15) == "true" then
				valid_command = ValidCommandResult()
				uais_debug = true
			elseif string.sub(Command, 12, 16) == "false" then
				valid_command = ValidCommandResult()
				uais_debug = false
			end
		elseif string.sub(Command, 6, 18) == "show_packets " then
			if string.sub(Command, 19, 22) == "true" then
				valid_command = ValidCommandResult()
				uais_show_packets = true
			elseif string.sub(Command, 19, 23) == "false" then
				valid_command = ValidCommandResult()
				uais_show_packets = false
			end
		end
	end
	if valid_command == true then -- Cancel error message.
		return false
	end
end

function ValidCommandResult() -- S.L. 2.
	execute_script("cls")
	return true
end

function SaveSettingToFile(FileValueTitle, NewValue, ConsoleMessage)
	if settings_initialized == true then -- Allow file output.
		local p_file_content = {} -- Read file and get line position.
		local l_file_content = {}
		local switch = false
		settings = io.open("uais_settings_client.txt", "r")
		for line in settings:lines("L") do
			if switch == false then
				table.insert(p_file_content, line)
			else
				table.insert(l_file_content, line)
			end
			if line == FileValueTitle then
				switch = true
			end
		end
		io.close(settings)
		settings = io.open("uais_settings_client.txt", "w") -- Write original content and new value.
		for i = 1, #p_file_content do
			settings:write(p_file_content[i])
		end
		settings:write(NewValue, "\n")
		for i = 2, #l_file_content do -- Skip original line.
			settings:write(l_file_content[i])
		end
		io.close(settings)
		if ConsoleMessage ~= nil then
			console_out(ConsoleMessage)
		end
	else
		console_out("WARNING: Settings have not been initialized yet. Changes will not be saved.")
	end
end

-- GENERIC/MISCELLANEOUS FUNCTIONS

-- Functions that wouldn't fit anywhere else.

function Startup() -- S.L. 1.
	local map_is_valid = true
	for i = 1, #uais_excluded_maps do
		if uais_excluded_maps[i] == map then
			map_is_valid = false
			DebugConsoleOut("Excluded map: "..map..". AI will not synchronize.")
			break
		end
	end
	if map_is_valid == true then
		TagManipulationClient(GetScenarioPath())
		DebugConsoleOut("AI synchronization ready!")
	end
end

function DebugConsoleOut(String) -- S.L. 2 (1 & 2).
	if uais_debug == true then
		console_out(String)
	end
end

function AddProjectileCreationEffects() -- Sub-level not defined, unused. Should be run after weapon paths have been declared.
	for i = 1, #weapon_tag_paths do
		local weapon_tag_path = weapon_tag_paths[i]
		local weapon_tag_address = get_tag("weap", weapon_tag_path)
		local weapon_tag_data = read_dword(weapon_tag_address + 0x14)
		local triggers_struct_count = read_dword(weapon_tag_data + 0x4FC)
		local triggers_struct_address = read_dword(weapon_tag_data + 0x4FC + 4)
		for j = 0, triggers_struct_count - 1 do
			local trigger = triggers_struct_address + j * 276
			local firing_effects_struct_address = read_dword(trigger + 0x108 + 4) -- There's spot for only one creation effect. Therefore, only the first firing effect will be used.
			local firing_effect_tag_id = read_dword(firing_effects_struct_address + 0x24 + 0xC)
			local projectile_tag_path = read_string(read_dword(trigger + 0x94 + 0x4))
			local projectile_tag_address = get_tag("proj", projectile_tag_path)
			local projectile_tag_data = read_dword(projectile_tag_address + 0x14)
			local projectile_creation_effect_tag_id_address = projectile_tag_data + 0xA0 + 0xC
			write_dword(projectile_creation_effect_tag_id_address, firing_effect_tag_id) -- Will not work unless the effect tag doesn't have any marker information. Which I'm not going to touch yet.
		end
	end
end

-- DATA DECOMPRESSION FUNCTIONS

-- Used to decompress the data extracted from remote console packets.

function MakeBase41Table() -- S.L. 1.
	if #char_table == 0 then -- REMINDER: Run just once.
		local char_list = "0123456789abcdefghijklmnopqrstuvwxyzABCDE"
		for char = 1, 41 do
			local c_char = string.sub(char_list, char, char)
			char_table[c_char] = char - 1
		end
		DebugConsoleOut("Base-41 character table ready.")
	end
end

function Hex4ToWord16(String) -- S.L. 2.
	local bits = {}
	local word
	for i = 1, 4 do
		local c_4_bits = DecimalToBinary(tonumber(string.sub(String, i, i), 16), 4)
		table.insert(bits, c_4_bits)
	end
	word = tonumber(table.concat(bits), 2)
	return word
end

function Hex2ToByte8(String)
	local bits = {}
	local byte
	for i = 1, 2 do
		local c_4_bits = DecimalToBinary(tonumber(string.sub(String, i, i), 16), 4)
		table.insert(bits, c_4_bits)
	end
	byte = tonumber(table.concat(bits), 2)
	return byte
end

function Integer41ToFloat16(String)
	local cens = char_table[string.sub(String, 1, 1)] * 1681
	local decs = char_table[string.sub(String, 2, 2)] * 41
	local unts = char_table[string.sub(String, 3, 3)] * 1
	local decimal = cens + decs + unts
	local binary = DecimalToBinary(decimal, 16)
	local binary_sign
	local binary_exponent = {}
	local binary_mantissa = {}
	local binary_exponent_sum = 0
	local binary_mantissa_sum = 0
	local float

	if decimal >= 65535 then
		console_out("WARNING: Integer 41 max. value exceeded ("..decimal..")")
		decimal = 65535
	elseif decimal < 0 then
		decimal = 0
	end

	for i = 1, 16 do
		local c_bit = tonumber(string.sub(binary, i, i), 2)
		local c_bit_index = i - 1
		if c_bit_index == 0 then
			binary_sign = c_bit
		elseif c_bit_index > 0 and c_bit_index < 6 then
			table.insert(binary_exponent, c_bit)
		else
			table.insert(binary_mantissa, c_bit)
		end
	end

	for i = 1, #binary_exponent do -- Convert binary to float (half precision format).
		local c_bit = binary_exponent[i]
		local c_bit_value = c_bit * 2 ^ (#binary_exponent - i)
		binary_exponent_sum = binary_exponent_sum + c_bit_value
	end

	for i = 1, #binary_mantissa + 1 do
		local c_bit_value
		if i == 1 then
			c_bit_value = 1 * 2 ^ (1 - i)
		else
			c_bit_value = binary_mantissa[i - 1] * 2 ^ (1 - i)
		end
		binary_mantissa_sum = binary_mantissa_sum + c_bit_value
	end

	float = (-1) ^ binary_sign * 2 ^ (binary_exponent_sum - 15) * binary_mantissa_sum

	return float
end

function DecimalToBinary(Value, Digits) -- S.L. 3.
	local binary_number = {}
	local quotient = tonumber(Value)
	local modulo
	local bits = {}
	while quotient > 0 do
		modulo = quotient % 2
		quotient = math.floor(quotient/2)
		table.insert(bits, modulo)
	end
	for i = 1, Digits do
		table.insert(binary_number, 0)
	end
	for i = 1, #bits do
		local c_bit = bits[#bits - (i - 1)]
		table.insert(binary_number, c_bit)
	end
	binary_number = string.sub(table.concat(binary_number), -Digits, -1)
	return binary_number -- String
end

-- TAG MANIPULATION FUNCTIONS

-- These functions are run only once, every time a new map is loaded. Only fully finished functions are placed inside this section and each one has its own sub-level ID.

function TagManipulationClient(ScenarioPath) -- S.L. 2.
	local scnr_tag_address = get_tag("scnr",ScenarioPath)
	local scnr_tag_data = read_dword(scnr_tag_address + 0x14)
	local actors_count = read_dword(scnr_tag_data + 0x420) -- Taken from the "Actor Palette" struct.
	local actors_address = read_dword(scnr_tag_data + 0x420 + 4)
	if actors_count > 0 then -- Safety check.
		for i = 0,actors_count - 1 do
			local c_actor_address = actors_address + i * 16
			local c_actor_dpdc_path = read_string(read_dword(c_actor_address + 0x4))
			DeclareBipedType(c_actor_dpdc_path)
		end 
		local encounters_count = read_dword(scnr_tag_data + 0x42C) -- Disable encounters' respawn and spawn by default.
		local encounters_address = read_dword(scnr_tag_data + 0x42C + 4)
		if encounters_count > 0 then
			for i = 0,(encounters_count - 1) do
				local c_encounter_address = encounters_address + i * 176
				local c_encounter_dpdc_path = read_string(c_encounter_address + 0x00)
				local c_encounter_bitmask = c_encounter_address + 0x20
				write_bit(c_encounter_bitmask, 0, 1) -- "Not Initially Created" set to true.
				write_bit(c_encounter_bitmask, 1, 0) -- "Respawn Enabled" set to false.
			end
		end
	end
	local bipeds_struct_count = read_dword(scnr_tag_data + 0x234) -- Taken from the "Biped Palette" struct. Registers bipeds from the biped palette too.
	local bipeds_struct_address = read_dword(scnr_tag_data + 0x234 + 4)
	if bipeds_struct_count > 0 then
		for i = 0, bipeds_struct_count - 1 do
			local c_biped_address = bipeds_struct_address + i * 48
			local c_biped_dpdc_path = read_string(read_dword(c_biped_address + 0x4))
			local new_biped_type = TryToAddBipedType(c_biped_dpdc_path)
			if new_biped_type == true then
				local tag_address = get_tag("bipd", c_biped_dpdc_path)
				local tag_data = read_dword(tag_address + 0x14)
				local biped_weapons_count = read_dword(tag_data + 0x2D8) -- Weapons used by the bipeds should be tested and added to the weapon tag path tables (if not there).
				local biped_weapons_address = read_dword(tag_data + 0x2D8 + 4)
				if biped_weapons_count > 0 then
					for i = 0,biped_weapons_count - 1 do
						local c_biped_weapon_address = biped_weapons_address + i * 36
						local c_biped_weapon_path = read_string(read_dword(c_biped_weapon_address + 0x4))
						DeclareWeaponType(c_biped_weapon_path)
					end
				end
			end	
		end
		local bipeds_count = read_dword(scnr_tag_data + 0x228) -- Taken from the "Bipeds" struct. Prevents from any "initially created" client-side bipeds.
		local bipeds_address = read_dword(scnr_tag_data + 0x228 + 4)
		if bipeds_count > 0 then
			for i = 0,(bipeds_count - 1) do
				local c_biped_address = bipeds_address + i * 120
				local c_biped_not_placed_bitmask = c_biped_address + 0x4
				if read_bit(c_biped_not_placed_bitmask, 0) == 0 then
					write_bit(c_biped_not_placed_bitmask, 0, 1) -- "Not placed: automatically" set to true.
				end
			end
		end
	end
end

function GetScenarioPath() -- S.L. 2.
	local scnr_tag_name_address = read_dword(0x40440028 + 0x10) -- REMINDER: Doesn't work for protected maps.
	local scnr_tag_name = read_string(scnr_tag_name_address)
	return scnr_tag_name
end

function DeclareBipedType(ActorPath) -- S.L. 3.
	local actv_tag_address = get_tag("actv",ActorPath)
	local actv_tag_data = read_dword(actv_tag_address + 0x14)
	local unit_dpdc = read_dword(actv_tag_data + 0x14)
	local unit_dpdc_path = read_string(read_dword(actv_tag_data + 0x14 + 0x4))
	TryToAddBipedType(unit_dpdc_path)
	local actv_weap_dpdc = read_dword(actv_tag_data + 0x64) -- Declare actv's weapon.
	local actv_weap_dpdc_path = read_string(read_dword(actv_tag_data + 0x64 + 0x4))
	DeclareWeaponType(actv_weap_dpdc_path)
	local major_variant_dpdc = read_dword(actv_tag_data + 0x24) -- Declare "Major variant" of this actv (runs this function recursively).
	local major_variant_dpdc_path = read_string(read_dword(actv_tag_data + 0x24 + 0x4))
	if major_variant_dpdc_path ~= nil then
		DeclareBipedType(major_variant_dpdc_path)
	end
end

function DeclareWeaponType(WeaponPath) -- S.L. 4 (3 & 4).
	if WeaponPath ~= nil then -- If this "actv" or "bipd" has a weapon.
		local new = true
		for i = 1,#weapon_tag_paths do -- To avoid registering the same weapon multiple times.
			if weapon_tag_paths[i] == WeaponPath then
				new = false
			end
		end
		if new == true then
			table.insert(weapon_tag_paths,WeaponPath)
		end
	end
end

function TryToAddBipedType(Path)
	local new = true
	for i = 1,#biped_tag_paths do -- To avoid registering the same biped type multiple times.
		if biped_tag_paths[i] == Path then
			new = false
		end
	end
	if new == true then
		table.insert(biped_tag_paths, Path)
		local biped_tag_address = get_tag("bipd", Path) -- Fixes death animations' loop frame index, and destroyable collision model regions.
		local biped_tag_data = read_dword(biped_tag_address + 0x14)
		local biped_animations_dpdc = read_dword(biped_tag_data + 0x38)
		local biped_animations_path = read_string(read_dword(biped_tag_data + 0x38 + 0x4))
		local biped_collision_model_dpdc = read_dword(biped_tag_data + 0x70)
		local biped_collision_model_path = read_string(read_dword(biped_tag_data + 0x70 + 0x4))
		FixDeathAnimations(biped_animations_path)
		FixCollisionModel(biped_collision_model_path)
	end
	return new
end

function FixDeathAnimations(AnimationsPath) -- S.L. 5.
	local animations_tag_address = get_tag("antr", AnimationsPath)
	local animations_tag_data = read_dword(animations_tag_address + 0x14)
	local animations_count = read_dword(animations_tag_data + 0x74)
	local animations_address = read_dword(animations_tag_data + 0x74 + 4)
	for animation = 0,(animations_count - 1) do
		local c_animation_address = animations_address + animation * 180
		local animation_name = read_string(c_animation_address + 0x00)
		local animation_frame_count = read_short(c_animation_address + 0x22)
		local animation_loop_frame_index = read_short(c_animation_address + 0x2E)
		if string.match(animation_name,"dead") or string.match(animation_name,"kill") then -- In order for this to work, the animations must have the default labels. "stand-idle", "h-kill", "airborne-dead", etc...
			if not string.match(animation_name,"airborne") then
				write_short(c_animation_address + 0x2E, animation_frame_count)
			end
		end
	end
end

function FixCollisionModel(CollisionModelPath)
	local coll_model_tag_address = get_tag("coll", CollisionModelPath)
	local coll_model_tag_data = read_dword(coll_model_tag_address + 0x14)
	local regions_count = read_dword(coll_model_tag_data + 0x240)
	local regions_address = read_dword(coll_model_tag_data + 0x240 + 4)
	for region = 0, (regions_count - 1) do
		local c_region_address = regions_address + region * 84
		local bitmask_address = c_region_address + 0x20
		local forces_drop_weapon_bit = read_bit(bitmask_address + 1, 0)
		local damage_threshold_address = c_region_address + 0x28
		local damage_threshold = read_float(damage_threshold_address)
		if forces_drop_weapon_bit == 1 and damage_threshold ~= 0 then -- This avoids some issues on bipeds that can wield weapons but have destroyable parts (Flood combat forms, for example).
			write_float(damage_threshold_address, 0)
		end
	end
end