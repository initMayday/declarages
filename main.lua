local RelativeScriptPath = debug.getinfo(1, "S").source:sub(2):match("(.*/)") or "./"
package.path = package.path .. ";" ..  RelativeScriptPath .. "?.lua";
local Common = require("common");

local TotalStartTime = Common.execute_command(Common.DateCommand);

local Configuration = dofile(arg[1] or "packages.lua");
local Colours = require("colours")

if Configuration.Settings.SuperuserCommand ~= "" then Configuration.Settings.SuperuserCommand = Configuration.Settings.SuperuserCommand.. " "; end

print(Colours.Blue.. "[ENTER] Beginning".. Colours.Reset);
for _, Value in pairs(Configuration["Settings"]["Cores"]) do
    local StartTime = Common.execute_command(Common.DateCommand);
    Value = string.lower(Value);
    local Core = require("cores/"..Value.."/"..Value);
    Value = Value:gsub("^%l", string.upper)
    print(Colours.Magenta.. Colours.Bold.. "[LOG] Executing: ".. Value.. " Core".. Colours.Reset)
    Core.execute(Configuration);
    local EndTime = Common.execute_command(Common.DateCommand);
    print(Colours.Magenta.. Colours.Bold.. "[LOG] Completed: ".. Value.. " Core (".. Common.round_to_2dp((EndTime - StartTime) / 1000).. "s)" .. Colours.Reset)
end
local TotalEndTime = Common.execute_command(Common.DateCommand);
print(Colours.Blue.. "[EXIT] Finished: (" ..Common.round_to_2dp((TotalEndTime - TotalStartTime) / 1000).."s)".. Colours.Reset);
