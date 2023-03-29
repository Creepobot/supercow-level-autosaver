local imgui = require("imgui")
local config = require("config")
local memory = require("memory")
local timers = require("timers")
local ffi = require("ffi")

local baseScene = memory.at("81 3D ? ? ? ? ? ? ? ? 0F 95 C0"):add(2):readOffset()
local editorScene = memory.at("68 ? ? ? ? 8B 4D ? E8 ? ? ? ? 8B 4D ? 8B 55"):add(1):readInt()
local isPaused = memory.at("C6 05 ? ? ? ? ? 0F B6 0D ? ? ? ? 85 C9 75 ? 6A"):add(2):readOffset()
local gameSaveFunc = memory.at("55 8B EC D9 05 ? ? ? ? D8 1D ? ? ? ? DF E0 F6 C4 ? 75 ? EB ? E8"):getFunction("void (*)()")
local saveFunc = function() if baseScene:readInt() == editorScene then gameSaveFunc() end end

local buf
if config.mod:has("saveInterval") then
    buf = ffi.new("int[1]", config.mod:getNumber("saveInterval"))
else buf = ffi.new("int[1]", 60) end
local timerId = timers.setInterval(saveFunc, 60000)

function HelpMarker(text)
    imgui.SameLine()
    imgui.TextDisabled(" ?");
    if imgui.IsItemHovered(imgui.ImGuiHoveredFlags_DelayShort) then
        imgui.BeginTooltip();
        imgui.PushTextWrapPos(imgui.GetFontSize() * 35);
        imgui.TextUnformatted(text);
        imgui.PopTextWrapPos();
        imgui.EndTooltip();
    end
end

-- camera freeze fix
function render()
    if isPaused:readBool() then
        if baseScene:readInt() == editorScene then
            isPaused:writeByte(0)
        end
    end
end

function renderUi()
    if imgui.Button("GitHub") then
        os.execute('start "" "https://github.com/Creepobot/supercow-level-autosaver"')
    end
    
    imgui.Text("Частота автосохранения")
    HelpMarker("Частота в секундах, с которой игра\n автоматически сохраняет уровень.")
    imgui.SliderInt(" ", buf, 15, 900, "%0i сек")
    imgui.SameLine()
    imgui.Text("("..(math.floor(buf[0] / 60 * 10) / 10).." минут)")
    if imgui.Button("Применить") then
        timers.clearTimer(timerId)
        timerId = timers.setInterval(saveFunc, buf[0] * 1000)
        config.mod:set("saveInterval", buf[0])
        config.save()
    end
end
