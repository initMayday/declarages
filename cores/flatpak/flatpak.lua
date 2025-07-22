local Common = require("common")
local Colours = require("colours")
local Run = {};

function Run.execute(Configuration)
    local RemoveUnused = "flatpak uninstall --unused --assumeyes";
    Common.execute_command(RemoveUnused);

    local InstalledPackages = Common.raw_list_to_table(Common.execute_command("flatpak list --app --columns=application"));

    for Index, Value in ipairs(InstalledPackages) do --> Sometimes the "Application ID" header pops up
        if Value == "Application ID" then
            table.remove(InstalledPackages);
            break;
        end
    end

    local PackagesToRemove = Common.subtract_arrays(InstalledPackages, Configuration.Flatpak);
    local Confirmation = Common.check_package_warn_limit(PackagesToRemove, Configuration.Settings.WarnOnPackageRemovalAbove);

    if Confirmation == true and #PackagesToRemove > 0 then
        local RemovalString = "flatpak uninstall --assumeyes";
        io.write(Colours.Bold.. "[LOG] Removing: ".. Colours.Reset)
        for Index, Value in ipairs(PackagesToRemove) do
            io.write(Value.. " ");
            RemovalString = RemovalString.. " " ..Value;
        end
        print("")
        Common.execute_command(RemovalString);
        io.write(Colours.Green.. Colours.Bold.. "[LOG] Removed Packages: ");
        for Index, Value in ipairs(PackagesToRemove) do
            io.write(Value.. " ");
        end
        io.write(Colours.Reset.. "\n"); 
    end

    print(Colours.Bold.. Colours.Cyan.."[LOG] Upgrading System".. Colours.Reset);
    os.execute("flatpak update --assumeyes");

    local PackagesToInstall = Common.subtract_arrays(Configuration.Flatpak, InstalledPackages);
    local InstallString = "flatpak install --assumeyes";
    if #PackagesToInstall > 0 then
        io.write(Colours.Bold.. Colours.Cyan.. "[LOG] Attempting to install: ".. Colours.Reset);
        for Index, Value in ipairs(PackagesToInstall) do
            io.write(Value.. " ");
            InstallString = InstallString .." ".. Value;
        end
        print(""); 
        os.execute(InstallString);
    end

    print(Colours.Bold.. Colours.Green.. "[LOG] Completed Installations".. Colours.Reset);
end

return Run;
