-- main.lua
-- ALL-IN-ONE SYSTEM INTEGRITY LOG CHECKER & INTERNAL FILE TREE EXPORTER

-- Helper function to safely read file sizes in bytes
local function get_file_size(filename)
    local file = io.open(filename, "rb")
    if not file then return nil end
    local size = file:seek("end")
    file:close()
    return size
end

-- Universal cross-platform system checker (Logs integrity checks directly to UE4SS.log)
local function run_log_check()
    print("\n========== BEGINNING STEAM INTEGRITY SCAN ==========\n")

    local isPirate = false
    local foundIni = false
    local foundRne = false

    local status, directories = pcall(IterateGameDirectories)
    if status and directories then
        local function scan_folders(dir_obj)
            if dir_obj.__files then
                for _, file in pairs(dir_obj.__files) do
                    local fileName = string.lower(file.__name or "")
                    if fileName == "steam_emu.ini" then
                        foundIni = true
                    elseif fileName == "steam_api64.rne" then
                        foundRne = true
                    end
                end
            end
            for key, sub_dir in pairs(dir_obj) do
                if type(sub_dir) == "table" and string.sub(key, 1, 2) ~= "__" then
                    scan_folders(sub_dir)
                end
            end
        end
        for _, RootDir in pairs(directories) do scan_folders(RootDir) end
    end

    if foundIni then 
        print("[ALERT] Unexpected configuration file found: steam_emu.ini\n") 
        isPirate = true 
    else
        print("[INFO] No steam_emu.ini detected.\n")
    end
    
    if foundRne then 
        print("[ALERT] Renamed Steam library detected: steam_api64.rne\n") 
        isPirate = true 
    else
        print("[INFO] No steam_api64.rne detected.\n")
    end

    local officialPath = "../../../Engine/Binaries/ThirdParty/Steamworks/Steamv157/Win64/steam_api64.dll"
    local dllSize = get_file_size(officialPath) or get_file_size("steam_api64.dll")

    if dllSize then
        print(string.format("[INFO] Active steam_api64.dll size: %d bytes\n", dllSize))
        if dllSize == 1098392 then
            print("[ALERT] Cracked steam_api64.dll size signature matched!\n")
            isPirate = true
        elseif dllSize ~= 295336 then
            print("[ALERT] Non-standard active steam_api64.dll size detected!\n")
            isPirate = true
        else
            print("[INFO] Active steam_api64.dll matches standard official size.\n")
        end
    else
        print("[ERROR] Could not look up or read the Steam API binary file size.\n")
        isPirate = true
    end

    if isPirate then
        print("[STATUS] Arg Mate Pirate Ye Be!\n")
    else
        print("[STATUS] Steam API integrity verified successfully.\n")
    end

    print("\n========== END OF STEAM INTEGRITY SCAN ==========\n")
end

-- Generates the cross-platform complete folder layout and dumps it directly into UE4SS.log
local function run_directory_tree_dump()
    print("\n========== BEGINNING UE4SS COMPLETE TREE DUMP ==========\n")
    
    local function get_target_role(dir_obj)
        if dir_obj.__files then
            for _, f in pairs(dir_obj.__files) do
                if f.__name then
                    local fName = string.lower(f.__name)
                    if fName == "subnautica2-win64-shipping.exe" then return "Subnautica2/Binaries/Win64" end
                    if fName == "steam_api64.dll" or fName == "onnxruntime.dll" then
                        if string.lower(dir_obj.__name or "") == "win64" then
                            return "Engine/Binaries/ThirdParty/Steamworks/Steamv157/Win64"
                        end
                    end
                    if fName == "mods.txt" or fName == "mods.json" then return "UE4SS Mods Directory" end
                end
            end
        end
        return nil
    end

    local function dump_complete_tree(dir_obj, indent)
        indent = indent or ""
        local folderName = dir_obj.__name or ""
        if folderName == "" then return end

        local targetRole = get_target_role(dir_obj)
        if targetRole then
            print(string.format("%s|-- [TARGET DIR] %s (%s)\n", indent, folderName, targetRole))
            if dir_obj.__files then
                for _, f in pairs(dir_obj.__files) do
                    if f.__name then 
                        local fName = string.lower(f.__name)
                        -- Filter out logs, configs, and CSV table data inside the targets
                        if not string.find(fName, "%.csv$") and not string.find(fName, "%.log$") then
                            print(indent .. "|   |-- " .. f.__name .. "\n") 
                        end
                    end
                end
            end
        else
            print(indent .. "|-- [DIR] " .. folderName .. "\n")
        end

        for key, sub_dir in pairs(dir_obj) do
            if type(sub_dir) == "table" and string.sub(key, 1, 2) ~= "__" then
                dump_complete_tree(sub_dir, indent .. "|   ")
            end
        end
    end

    local status, directories = pcall(IterateGameDirectories)
    if status and directories then
        for _, RootDir in pairs(directories) do dump_complete_tree(RootDir, "") end
    else
        print("[ERROR] Failed to fetch directory structure.\n")
    end

    print("\n========== END OF UE4SS COMPLETE TREE DUMP ==========\n")
end

-- ============================================================================
-- MAIN PIPELINE EXECUTION
-- ============================================================================

-- 1. Execute system integrity logging loop (writes to UE4SS.log)
run_log_check()

-- 2. Execute full directory mapping sequence (writes directly to UE4SS.log)
run_directory_tree_dump()

