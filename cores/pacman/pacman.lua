local Luv = require("luv")
local Json = require("lunajson")
local Common = require("common")
local Colours = require("colours")
local PrintTable = require("print_table")
local Run = {};

local function get_sub_packages(input)
    if type(input) == "table" then
        return input.Sub
    else
        return input
    end
end

local function get_base_packages(input)
    if type(input) == "table" then
        return input.Base
    else
        return input
    end
end

local function convert_to_base_package_names(Array)
    local NamedPackages = {}
    for _, Value in ipairs(Array) do
        local RealPackage = get_base_packages(Value);
        table.insert(NamedPackages, RealPackage);
    end
    return NamedPackages;
end

local function convert_to_sub_package_names(Array)
    local NamedPackages = {}
    for _, Value in ipairs(Array) do
        local RealPackage = get_sub_packages(Value);
        if type(RealPackage) == "table" then
            NamedPackages = Common.merge_arrays(NamedPackages, RealPackage);
        else
            table.insert(NamedPackages, RealPackage);
        end
    end
    return NamedPackages;
end

local function install_custom_package(SuperuserCommand, Location, Package)
    local ChDir = "cd ".. Location.."/".. Package.Base.. " && ";
    local _Ok, _Type, Code = os.execute(ChDir.. Package.BuildCmd)
     if Code == 0 then
        print("[LOG] Built: ".. Package.Base)
    else
        print("[LOG] Failed to build: ".. Package.Base)
        return
    end

    local BuiltFiles = Common.get_entries_in_path(Location.. "/".. Package.Base)
    local SubPackagesToInstall = {}

    for _Index, Sub in ipairs(Package.Sub) do
        local Matches = {}
        for _Index, Value in ipairs(BuiltFiles) do
            print(Value, Sub)
            if string.find(Value, Sub, 1, true) and string.find(Value, "pkg.tar", 1, true) then
                table.insert(Matches, Value)
            end
        end
        
        if #Matches == 0 then
            print(Colours.Red.. "[FAIL] Could not find matching sub-package for: ".. Sub.. Colours.Reset)
        else
            local SmallestName = ""
            local SmallestLength = math.huge
            for _Index, Value in ipairs(Matches) do
                if #Value < SmallestLength then
                    SmallestLength = #Value
                    SmallestName = Value
                end
            end
            table.insert(SubPackagesToInstall, SmallestName)
        end
    end

    local FinalString = ""
    for _Index, Value in ipairs(SubPackagesToInstall) do
        FinalString = FinalString.. string.format("'%s'", Value)
    end

    local _Ok, _Type, Code = os.execute(ChDir.. SuperuserCommand.. "pacman -U ".. FinalString)
    if Code == 0 then
        print(Colours.Bold.. Colours.Green.. "[LOG] Completed: ".. Package.Base.. Colours.Reset)
    else
        print(Colours.Reset.. "[LOG] Failed: ".. Package.Base.. Colours.Reset)
    end
end

function Run.execute(Configuration)

    --> Remove Unused Dependencies
    local UnusedDeps = Common.raw_list_to_table(Common.execute_command("pacman -Qtdq"));
    local Continue = Common.check_package_warn_limit(UnusedDeps, Configuration.Settings.WarnOnPackageRemovalAbove);
    if Continue and #UnusedDeps > 0 then
        local RemovalString = "pacman -Rns --noconfirm";
        io.write(Colours.Bold.. "[LOG] Removing Unused Dependencies: ".. Colours.Reset)
        for _, Value in ipairs(UnusedDeps) do
            io.write(Value.. " ");
            RemovalString = RemovalString.. " " ..Value;
        end
        print("");
        Common.execute_command(Configuration.Settings.SuperuserCommand.. RemovalString);
        io.write(Colours.Green.. Colours.Bold.. "[LOG] Removed Packages: ");
        for _, Value in ipairs(UnusedDeps) do
            io.write(Value.. " ");
        end
        io.write(Colours.Reset.. "\n");
    end

    --> Get installed packages
    local InstalledPackages = Common.raw_list_to_table(Common.execute_command("pacman -Qeq"));

    --> Remove installed packages that are no longer required
    local CombinedNameOnlyPackages = convert_to_sub_package_names(Common.merge_arrays(Configuration.Pacman.Primary, Configuration.Pacman.Custom))
    local PackagesToRemove = Common.subtract_arrays(Common.subtract_arrays(InstalledPackages, CombinedNameOnlyPackages), Configuration.Pacman.Ignore);
    local Confirmation = Common.check_package_warn_limit(PackagesToRemove, Configuration.Settings.WarnOnPackageRemovalAbove);

    if Confirmation == true and #PackagesToRemove > 0 then
        --> Need to check if the packages are dependencies of other packages before attempting removal
        for Index, Value in ipairs(PackagesToRemove) do
            local DependenciesRaw = Common.execute_command("pactree -r --optional=0 --depth=1 -l ".. Value);

            local CanBeRemoved = true;
            for Package in DependenciesRaw:gmatch("([^\n]+)") do
                if Package ~= "" then
                    --> Check if the package that depends on this package is part of the packages we are removing
                    local Hit = false;
                    for _, Value2 in ipairs(PackagesToRemove) do
                        if Package == Value2 then
                            Hit = true;
                        end
                    end
                   if Hit == false then
                        CanBeRemoved = false;
                        break;
                   end
                end
            end

            if CanBeRemoved == false then
                table.remove(PackagesToRemove, Index);
                print(Colours.Bold.. Colours.Yellow.. "[WARNING]".. Colours.Reset .. Colours.Bold.." Unable to remove ".. Value .." as the following depend upon it:" .. Colours.Reset);
                io.write(DependenciesRaw);
                print(Colours.Bold.. "[LOG] Marking ".. Value .." install reason as dependency".. Colours.Reset);
                Common.execute_command(Configuration.Settings.SuperuserCommand.. "pacman -D --asdep ".. Value);
                print("");
            end
        end

        if #PackagesToRemove > 0 then
            local RemovalString = "pacman -Rns --noconfirm";
            io.write(Colours.Bold.. "[LOG] Removing: ".. Colours.Reset)
            for _, Value in ipairs(PackagesToRemove) do
                io.write(Value.. " ");
                RemovalString = RemovalString.. " " ..Value;
            end
            print("");
            os.execute(Configuration.Settings.SuperuserCommand.. RemovalString);
            io.write(Colours.Green.. Colours.Bold.. "[LOG] Removed Packages: ");
            for _, Value in ipairs(PackagesToRemove) do
                io.write(Value.. " ");
            end
            io.write(Colours.Reset.. "\n");
        end
    end

    --> Delete Old Custom Package directories
    local InstalledCustomPackages = Common.raw_list_to_table(Common.execute_command(Configuration.Settings.SuperuserCommand.. "ls ".. Configuration.Pacman.Settings.CustomLocation));
    local UnrequiredCustom = Common.subtract_arrays(InstalledCustomPackages, convert_to_base_package_names(Configuration.Pacman.Custom))
    for _, Value in ipairs(UnrequiredCustom) do
        Common.remove_path(Configuration.Pacman.Settings.CustomLocation.."/"..Value, Configuration.Settings.SuperuserCommand, Configuration.Settings.AddPathConfirmation);
    end

    --> Install packages we don't have
    local PrimaryNameOnlyPackages = convert_to_base_package_names(Configuration.Pacman.Primary);
    local PackagesToInstallPrimary = Common.subtract_arrays(PrimaryNameOnlyPackages, InstalledPackages);

    for Index, Package in ipairs(PackagesToInstallPrimary) do
        --> Check if the package is already on our system
        if Common.execute_command("pacman -Qq | grep -w ".. Package) ~= "" then --> Grep the full word!
            print(Colours.Bold.. "[LOG] Marking ".. Package .. " install reason as explicit".. Colours.Reset);
            Common.execute_command(Configuration.Settings.SuperuserCommand.. "pacman -D --asexplicit ".. Package);
            table.remove(PackagesToInstallPrimary, Index);
        end
    end

    local InstallString = "pacman -Syu --noconfirm";
    if #PackagesToInstallPrimary > 0 then
        io.write(Colours.Bold.. Colours.Cyan.. "[LOG] Upgrading System & Attempting to install: ".. Colours.Reset);
        for _, Value in ipairs(PackagesToInstallPrimary) do
            io.write(Value.. " ");
            InstallString = InstallString .." ".. Value;
        end
        print("");
    else
        print(Colours.Bold.. Colours.Cyan.."[LOG] Upgrading System".. Colours.Reset);
    end

    os.execute(Configuration.Settings.SuperuserCommand.. InstallString);
    print(Colours.Bold.. Colours.Green.. "[LOG] Completed Installations".. Colours.Reset);

    --[[ 
        START CUSTOM 
    ]]--
    print(Colours.Bold.. Colours.Cyan.. "[LOG] Upgrading Custom Packages".. Colours.Reset);
    Common.create_path(Configuration.Pacman.Settings.CustomLocation, "", Configuration.Settings.AddPathConfirmation);
 
    --> Convert Custom Packages ALL to the same format
    local NewTable = {}
    for Index, Value in ipairs(Configuration.Pacman.Custom) do
        if type(Value) ~= "table" then
            Value = { Base = Value, Sub = { Value } }
        end

        --> If any special update commands are specified, disable RPC by default. Else, enable RPC
        if Value.CloneCmd == nil and Value.UpdateRemoteCmd == nil and Value.VersionCmd == nil and Value.PrepareCmd == nil then
            Value.RPC = Common.default_value(Value.RPC, true)
        else
            Value.RPC = Common.default_value(Value.RPC, false)
        end
        Value.CloneCmd = Common.default_value(Value.CloneCmd, "git clone ".. "https://aur.archlinux.org/"..Value.Base..".git")
        Value.VersionCmd = Common.default_value(Value.VersionCmd,
            "makepkg --printsrcinfo | awk -F ' = ' '/pkgver/ {print $2}' || { echo \"FAIL\"; exit 1; }")
        Value.UpdateRemoteCmd = Common.default_value(Value.UpdateRemoteCmd, "git reset --hard && git pull")
        Value.PrepareCmd = Common.default_value(Value.PrepareCmd, "makepkg -o")
        Value.BuildCmd = Common.default_value(Value.BuildCmd, "makepkg -sf --noconfirm")
        table.insert(NewTable, Value)
    end
    Configuration.Pacman.Custom = NewTable

    --> Updating existing AUR packages
    local CustomOrderedList = Common.get_entries_in_path(Configuration.Pacman.Settings.CustomLocation);
    local CustomList = {}

    for Index, Value in ipairs(CustomOrderedList) do
        for Index2, Value2 in ipairs(Configuration.Pacman.Custom) do
            if Value == Value2.Base then
                table.insert(CustomList, Value2)
                break
            end
        end
    end

    --> Change directory, but save the directory so we can move back later..
    local OriginalDir = Luv.cwd()
    Luv.chdir(Configuration.Pacman.Settings.CustomLocation);

    print("[LOG] Checking Updates")
    local PackagesToUpdate = {}

    for Index, Value in ipairs(CustomList) do
        local ChDir = "cd ".. Value.Base.. " && ";
        Common.luv_execute_command(Luv, ChDir ..Value.VersionCmd, function(Code, Signal, Output)
            if Code == 0 then
                local OriginalVersion = Output:sub(1, -2) --> Remove trailing \n

                --> If RPC is enabled, make query to AUR
                if Value.RPC == true then
                    Common.luv_execute_command(Luv, string.format("curl -s 'https://aur.archlinux.org/rpc/v5/info?arg[]=%s'", Value.Base), function(Code, Signal, Output)
                        if Code ~= 0 then
                            print(Colours.Red.. "[FAIL : Code ".. Code .." ] Failed to curl RPC: ".. Value.Base, Output ..Colours.Reset)
                            return
                        end

                        local Decoded = Json.decode(Output)
                        if Decoded == nil then
                            print(Colours.Red.. "[FAIL] Failed to decode RPC JSON: ".. Value.Base, Output .. Colours.Reset);
                            return
                        end

                        if Decoded.resultcount == 0 then
                            print(Colours.Red.. "[FAIL] Could not retrieve version from RPC: ".. Value.Base ..Colours.Reset);
                            return
                        end
                        --PrintTable(Decoded)
                        local Version = Decoded.results[1].Version:gsub("^%d+:", ""):gsub("%-[^-]+$", "")

                        Common.luv_execute_command(Luv, "vercmp ".. OriginalVersion .." ".. Version, function(Code, Signal, Output)
                            if Code ~= 0 then
                                print(Colours.Red.. "[FAIL : Code ".. Code .." ] Failed to use vercmp to compare versions:", Value.Base, OriginalVersion, Version)
                                return
                            end
                            Output = Output:sub(1, -2) --> Remove trailing \n
                            if Output == "0" then
                                print("[LOG] (RPC) Up to Date: ".. Value.Base)
                            elseif Output == "1" then
                                print(Colours.Yellow .."[WARNING] (RPC ".. OriginalVersion.. " : "..
                                    Version.. ") Local Version is ahead of Remote: ".. Value.Base.. Colours.Reset)
                            else
                                print("[LOG] (RPC ".. OriginalVersion.. " : " ..Version..") Needs Update: ".. Value.Base)
                                table.insert(PackagesToUpdate, Value)
                            end
                        end)
                    end)
                else
                    --> If RPC is disabled, use manual versioning. This will be slower
                    Common.luv_execute_command(Luv, ChDir ..Value.UpdateRemoteCmd, function(Code)
                        if Code ~= 0 then
                            print(Colours.Red .."[FAIL : Code ".. Code .."] Failed to update source from remote: ".. Value.Base.. Colours.Reset)
                            return
                        end
                        Common.luv_execute_command(Luv, ChDir ..Value.PrepareCmd, function(Code)
                            if Code ~= 0 then
                                print(Colours.Red.. "[FAIL : Code ".. Code .."] Failed to prepare pacakge: ".. Value.Base.. Colours.Reset)
                                return
                            end
                            Common.luv_execute_command(Luv, ChDir.. Value.VersionCmd, function(Code, Signal, Output)
                                if Code ~= 0 then
                                    print(Colours.Red.. "[FAIL : Code ".. Code .."] Could not determine new Version of: ".. Value.Base.. Colours.Reset)
                                    return
                                end
                                local Version = Output:sub(1, -2) --> Remove trailing \n
                                if OriginalVersion == Version then
                                    print("[LOG] (Manual) Up to Date: ".. Value.Base)
                                else
                                    print("[LOG] (Manual ".. OriginalVersion.. " : " ..Version..") Needs Update: ".. Value.Base)
                                    table.insert(PackagesToUpdate, Value)
                                end
                            end)
                        end, false, false)
                    end)
                end
            else
                print(Colours.Red .."[FAIL : Code ".. Code .."] Could not determine original Version of ".. Value.Base.. Colours.Reset)
            end
        end)
    end
    Luv.run()

    --> Change back to original working dir
    Luv.chdir(OriginalDir)

    for Index, Value in ipairs(PackagesToUpdate) do
        print("[LOG] Updating: ".. Value.Base)
        install_custom_package(Configuration.Settings.SuperuserCommand, Configuration.Pacman.Settings.CustomLocation, Value)
    end

    --> Install AUR packages we don't have
    for _, Value in ipairs(Configuration.Pacman.Custom) do
        local Hits = 0;
        for _, Value2 in ipairs(Value.Sub) do
            for _, Value3 in ipairs(InstalledPackages) do
                if Value2 == Value3 then
                    Hits = Hits + 1;
                    break;
                end
            end
        end
        if Hits ~= #Value.Sub then --> We don't have (all) the package(s) installed, install the package
            local DirName = Value.Base;
            print(Colours.Green.. Colours.Bold.. "[LOG] Installing: ".. DirName.. Colours.Reset);

            Common.remove_path(Configuration.Pacman.Settings.CustomLocation.."/"..DirName,
                Configuration.Settings.SuperuserCommand, Configuration.Settings.RemovePathConfirmation);
            Common.execute_command("cd ".. Configuration.Pacman.Settings.CustomLocation.." && ".. Value.CloneCmd);
            install_custom_package(Configuration.Settings.SuperuserCommand, Configuration.Pacman.Settings.CustomLocation, Value)
        end
    end
    print(Colours.Bold.. Colours.Green.. "[LOG] Completed Custom Installations".. Colours.Reset);
end

return Run
