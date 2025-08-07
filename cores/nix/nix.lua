local Common = require("common")
local Colours = require("colours")

local Run = {};

function Run.execute(Configuration)
    local GetPackagesCommand = [[nix profile list | grep Name | cut -d':' -f2- | sed 's/^ *//' | sed 's/\x1b\[[0-9;]*m//g']]
    local InstalledPackages = Common.raw_list_to_table(Common.execute_command(GetPackagesCommand));

    --> Values that are a table have two string values, the Base and Sub values.
    --> Eg. {Base = "kdePackages.konsole", Sub  = "konsole"}, the former name is needed to install the package
    --> and once installed, the latter name is the name of the package on the system
    --> Hence, we just get the name of the package on the system
    local ConfigurationProperNames = {};
    for _, Value in pairs(Configuration.Nix.Primary) do
        if type(Value) == "table" then
            table.insert(ConfigurationProperNames, Value.Sub);
        else
            table.insert(ConfigurationProperNames, Value);
        end
    end

    --for index, value in pairs(ConfigurationProperNames) do print("Wants: "..value) end

    local PackagesToRemove = Common.subtract_arrays(InstalledPackages, ConfigurationProperNames);
    local Confirmation = Common.check_package_warn_limit(PackagesToRemove, Configuration.Settings.WarnOnPackageRemovalAbove);

    if Confirmation == true and #PackagesToRemove > 0 then
        local RemoveString = "nix profile remove";
        for _, Value in pairs(PackagesToRemove) do
            RemoveString = RemoveString.. " ".. Value;
        end
        Common.execute_command(RemoveString);

        io.write(Colours.Green.. Colours.Bold.. "[LOG] Removed Packages: ");
        for _, Value in ipairs(PackagesToRemove) do
            io.write(Value.. " ");
        end
        print("")

        Common.execute_command("nix profile wipe-history");
        io.write(Colours.Green.. Colours.Bold.. "[LOG] Wiped History")
        io.write(Colours.Reset.. "\n");
    end

    --> Only upgrade system, if there are still packages on the system
    --> Note that we do not use the initial installedpackages variable, as we have removed packages since then
    --> and hence there may still be now 0 packages on the system
    if #Common.raw_list_to_table(Common.execute_command(GetPackagesCommand)) > 0 then
        print(Colours.Bold.. Colours.Cyan.."[LOG] Upgrading System".. Colours.Reset);
        Common.execute_command("nix profile upgrade --all");
    end

    local PackagesToInstall = Common.subtract_arrays(ConfigurationProperNames, InstalledPackages);

    --for index, value in pairs(InstalledPackages) do print("Already Installed: ".. value); end
    --for index, value in pairs(PackagesToInstall) do print("NEEDS: ".. value); end

    local InstallString = "nix profile add";
    if #PackagesToInstall > 0 then
        io.write(Colours.Bold.. Colours.Cyan.. "[LOG] Attempting to install: ".. Colours.Reset);
        for _, Value in ipairs(PackagesToInstall) do
            local OriginalIndex = Common.index_of(ConfigurationProperNames, Value)
            --> Convert the package on system name back to the install name. The works because we the indexes of the ConfigurationProperNames and Nix table line up
            if type(Configuration.Nix.Primary[OriginalIndex]) == "table" then
                Value = Configuration.Nix.Primary[OriginalIndex].Base;
            end
            io.write(Value.. " ");
            InstallString = InstallString .." nixpkgs#".. Value;
        end
        print("");
        Common.execute_command(InstallString);
    end

    print(Colours.Bold.. Colours.Green.. "[LOG] Completed Installations".. Colours.Reset);

end

return Run;
