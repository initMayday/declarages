local RelativeScriptPath = debug.getinfo(1, "S").source:sub(2):match("(.*/)") or "./"
package.path = package.path .. ";" ..  RelativeScriptPath .. "?.lua";
local Common = require("common");

local TotalStartTime = Common.execute_command(Common.DateCommand);

--> Decipher argument path
local FileName = "packages";
if arg[1] ~= nil then
    FileName = arg[1]:match("([^/]+)$"):gsub("%.lua$", "")
    local Directory = arg[1]:match("^(.*)/").. "/"
    package.path = package.path .. ";" .. Directory .. "/?.lua"
else
    print("[ERROR] You must specify the path of the configuration file")
    os.exit(-1)
end

local Configuration = require(FileName);
local Colours = require("colours")

if Configuration.Settings.SuperuserCommand ~= "" then Configuration.Settings.SuperuserCommand = Configuration.Settings.SuperuserCommand.. " "; end

--<> Activation Message
if Configuration.Settings.RandomActivationMessage == true and Configuration.Settings.Licensed == false then
    if math.random(0, 6) == 1 then -- 1 in 6 chance of showing
        print(Colours.Cyan .."[ACTIVATION] If you find this product useful, please purchase a license from: https://ko-fi.com/s/f7ac787074, it really helps!".. Colours.Reset);
    end
end

print(Colours.Blue.. "[ENTER] Beginning".. Colours.Reset);
for Index, Value in pairs(Configuration["Settings"]["Cores"]) do
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
