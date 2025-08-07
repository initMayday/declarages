local Common = require("common")
local Colours = require("colours")
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
        if Common.execute_command("pacman -Qq | grep -w".. Package) ~= "" then --> Grep the full word!
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
    print(Colours.Bold.. Colours.Cyan.. "[LOG] Upgrading Custom Packages".. Colours.Reset);

    Common.create_path(Configuration.Pacman.Settings.CustomLocation, "", Configuration.Settings.AddPathConfirmation);

    --> Updating existing AUR packages via Rust Program (parallel running)
    os.execute(Common.get_script_dir().. "/cores/pacman/custom_parallel/target/release/custom_parallel ".. Configuration.Pacman.Settings.CustomLocation);

    --> Install AUR packages we don't have
    for _, Value in ipairs(Configuration.Pacman.Custom) do
        local SubPackages = get_sub_packages(Value);
        if type(SubPackages) ~= "table" then
            SubPackages = { SubPackages };
        end

        local Hits = 0;
        for _, Value2 in ipairs(SubPackages) do
            for _, Value3 in ipairs(InstalledPackages) do
                if Value2 == Value3 then
                    Hits = Hits + 1;
                    break;
                end
            end
        end
        if Hits ~= #SubPackages then --> We don't have (all) the package(s) installed, install the package
            local DirName = get_base_packages(Value);
            print(Colours.Green.. Colours.Bold.. "[LOG] Installing: ".. DirName.. Colours.Reset);

            --> Get the url, and extract it from the table if the package is a table
            local Url = "https://aur.archlinux.org/"..DirName..".git";
            if type(Value) == "table" then
                if Value.Url ~= nil then
                    Url = Value.Url;
                end
            end

            Common.remove_path(Configuration.Pacman.Settings.CustomLocation.."/"..DirName, Configuration.Settings.SuperuserCommand, Configuration.Settings.RemovePathConfirmation);
            Common.execute_command("cd ".. Configuration.Pacman.Settings.CustomLocation.." && git clone ".. Url);
            Common.execute_command("cd ".. Configuration.Pacman.Settings.CustomLocation.."/"..DirName.."/".."&& makepkg -si --noconfirm");
            print(Colours.Green.. Colours.Bold.. "[LOG] Completed: ".. DirName.. Colours.Reset);
        end
    end
    print(Colours.Bold.. Colours.Green.. "[LOG] Completed Custom Installations".. Colours.Reset);
end

return Run
