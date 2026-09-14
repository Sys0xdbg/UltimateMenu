-- Mock-runtime inventory check for the unmodified YimMenu script.
local next_ref, counters = 0, {list = 0, action = 0, toggle = 0, text = 0}
local actions, toggles, inputs, sliders, native_calls, list_names = {}, {}, {}, {}, {}, {}
local threads_created = 0
local thread_callbacks = {}
local thread_origins = {}
local menu_back_calls = 0
local memory_values = {}
local last_pointer
local function ref()
    next_ref = next_ref + 1
    return {id = next_ref}
end
menu = {
    my_root = ref,
    list = function(_, label)
        counters.list = counters.list + 1
        list_names[label] = true
        return ref()
    end,
    action = function(_, label, _, _, callback)
        counters.action = counters.action + 1
        actions[#actions + 1] = {label = label, callback = callback}
        return ref()
    end,
    toggle = function(_, label, _, _, callback, default)
        counters.toggle = counters.toggle + 1
        toggles[#toggles + 1] = {label = label, callback = callback, default = default}
        return ref()
    end,
    slider = function(_, label, _, _, _, _, _, _, callback)
        sliders[#sliders + 1] = {label = label, callback = callback}
        return ref()
    end,
    readonly = function() counters.text = counters.text + 1; return ref() end,
    divider = function() return ref() end,
    get_value = function() return false end,
    set_value = function() end,
    get_menu_name = function() return "" end,
    set_menu_name = function() end,
    set_help_text = function() end,
    go_back = function() menu_back_calls = menu_back_calls + 1 end,
}
__smenu = {
    text_input = function(_, label, _, _, callback)
        inputs[#inputs + 1] = {label = label, callback = callback}
        return ref().id
    end,
    node_in_viewport = function() return true end,
}
util = {
    joaat = function(name) return #tostring(name) end,
    toast = function() end,
    yield = function()
        local _, is_main = coroutine.running()
        if not is_main then coroutine.yield() end
    end,
    create_thread = function(callback)
        threads_created = threads_created + 1
        thread_callbacks[#thread_callbacks + 1] = callback
        thread_origins[#thread_origins + 1] = debug.traceback("", 2)
        return {}
    end,
}
__ny_execute_as_script = function(_, callback) callback(); return true end
__ny_request_script_host = function() return true end
memory = {
    alloc_int = function() return 1 end,
    alloc_float = function() return 2 end,
    read_int = function(address) return memory_values[address] or 0 end,
    write_int = function(address, value) memory_values[address] = value end,
    read_float = function() return 0 end,
    read_bool = function() return false end,
    script_global = function() return 0 end,
    script_local = function() return nil end,
    tunable = function() return 0 end,
}
local last_hash
local session_started = os.getenv("UM_START_OFFLINE") == nil
local owned_stats = os.getenv("UM_OWNED_STATS") == "1"
native_invoker = {
    begin_call = function() end,
    push_arg_int = function() end,
    push_arg_float = function() end,
    push_arg_bool = function() end,
    push_arg_pointer = function(address) last_pointer = address end,
    end_call = function(hash)
        last_hash = hash
        native_calls[#native_calls + 1] = hash
        if hash == "3C5FD37B5499582E" then memory_values[last_pointer] = 42 end
        if hash == "767FBC2AC802EF3D" and owned_stats then
            memory_values[last_pointer] = 1
        end
    end,
    get_return_value_bool = function()
        return (last_hash == "9DE624D2FC4B603F" and session_started)
            or last_hash == "3C5FD37B5499582E"
            or (last_hash == "767FBC2AC802EF3D" and owned_stats)
            or last_hash == "7239B21A38F536BA"
    end,
    get_return_value_int = function() return 0 end,
    get_return_value_float = function() return 0 end,
    get_return_value_vector3 = function() return {x = 1, y = 2, z = 3} end,
}
local direct_native_calls = {}
local load_phase = true
for _, group in ipairs({"CLOCK", "CUTSCENE", "ENTITY", "HUD", "INTERIOR", "NETSHOPPING", "PAD", "PED", "PLAYER", "SCRIPT", "STREAMING", "SYSTEM", "TASK"}) do
    _G[group] = setmetatable({}, {__index = function(_, name)
        return function()
            if load_phase then direct_native_calls[group .. "." .. name] = true end
            return 0
        end
    end})
end
ENTITY.DOES_ENTITY_EXIST = function() return true end
__stand_get_all = function() return {} end
__stand_get_weapons = function() return {{n = "WEAPON_PISTOL", d = "Pistol"}} end
vec3 = {new = function(_, x, y, z) return {x = x, y = y, z = z} end}
ImGuiWindowFlags = {Modal = 0, NoCollapse = 0, NoMove = 0, NoResize = 0}
log = {info = function() end, warning = function() end, debug = function() end}

local fake_files = {}
local original_io_open = io.open
io.open = function(name, mode)
    if mode == "r" and not fake_files[name] then return nil end
    return {
        write = function(_, body) fake_files[name] = body end,
        read = function() return fake_files[name] end,
        close = function() end,
    }
end

local before_load = #native_calls
local executed_lines = {}
if os.getenv("UM_SCAN_COVERAGE") then
    debug.sethook(function(_, line)
        local info = debug.getinfo(2, "S")
        if info.source and info.source:find("Ultimate_Menu_Legacy.lua", 1, true) then
            executed_lines[line] = true
        end
    end, "l")
end
local compat = dofile("Nenyoo/Ultimate_Menu.lua")
debug.sethook()
load_phase = false
assert(fake_files["Nenyoo/YimResupplier.json"], "Resupplier config was not kept inside its package")
assert(not fake_files["YimResupplier.json"], "Resupplier config leaked into the game directory")
assert(rawget(_G, "stats") == nil, "Package leaked Yim stats into other scripts")
assert(rawget(memory, "scan_pattern") == nil, "Package changed the global memory API")
if os.getenv("UM_SCAN_COVERAGE") then
    local file = assert(original_io_open("Nenyoo/lib/Ultimate_Menu_Legacy.lua", "r"))
    local line_number = 0
    for line in file:lines() do
        line_number = line_number + 1
        if line:find("ImGui%.[A-Za-z_]+%(") and not executed_lines[line_number] then
            print("Unmaterialized UI line " .. line_number .. ": " .. line)
        end
    end
    file:close()
end
local permitted_load_natives = {
    ["SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH"] = true,
    ["CLOCK.GET_CLOCK_MINUTES"] = true,
    ["CLOCK.GET_CLOCK_HOURS"] = true,
    ["INTERIOR.GET_INTERIOR_FROM_ENTITY"] = true,
    ["PLAYER.PLAYER_PED_ID"] = true,
}
for name in pairs(direct_native_calls) do
    assert(permitted_load_natives[name], "Menu materialization called unexpected native: " .. name)
end
if os.getenv("UM_SHOW_LOAD_NATIVES") then
    for name in pairs(direct_native_calls) do print(name) end
end
for i = before_load + 1, #native_calls do
    assert(native_calls[i] ~= "B3271D7AB655B441", "Menu materialization wrote a stat")
end
assert(counters.list >= 60, "Missing tab hierarchy: " .. counters.list)
assert(counters.action >= 945, "Missing initial actions: " .. counters.action)
assert(#compat.imgui_sections >= 43, "Missing ImGui sections: " .. #compat.imgui_sections)
for _, name in ipairs({"Self Menu", "Story Mode", "Recovery Menu", "Online Services Menu",
    "Collectibles", "Events Menu", "YimResupplier", "Heists Data Editor Menu", "Kortz Center Heist"}) do
    assert(list_names[name], "Missing original menu section: " .. name)
end
local rank_action
for _, action in ipairs(actions) do
    if action.label == "Set Rank" then rank_action = action.callback; break end
end
assert(rank_action, "Missing ImGui rank action")
session_started = false
local offline_before = #native_calls
rank_action()
for i = offline_before + 1, #native_calls do
    assert(native_calls[i] ~= "B3271D7AB655B441", "Online action changed stats in Story Mode")
end
session_started = true
local before = #native_calls
rank_action()
local stat_writes = 0
for i = before + 1, #native_calls do
    if native_calls[i] == "B3271D7AB655B441" then stat_writes = stat_writes + 1 end
end
assert(stat_writes == 2, "Rank action did not write both stats: " .. stat_writes)
local story_cash_action
for _, action in ipairs(actions) do
    if action.label == "Add 1 Mil Cash $" then story_cash_action = action.callback; break end
end
assert(story_cash_action, "Missing Story Mode cash action")
before = #native_calls
story_cash_action()
for i = before + 1, #native_calls do
    assert(native_calls[i] ~= "B3271D7AB655B441", "Story Mode action changed stats online")
end
session_started = false
before = #native_calls
story_cash_action()
local story_wrote = false
for i = before + 1, #native_calls do
    if native_calls[i] == "B3271D7AB655B441" then story_wrote = true end
end
assert(story_wrote, "Story Mode action did not reach the stat bridge offline")
session_started = true
local panther_action
for _, action in ipairs(actions) do
    if action.label == "Panther Statue" then panther_action = action.callback; break end
end
assert(panther_action, "Missing Cayo primary target option")
before = #native_calls
panther_action()
local target_written = false
for i = before + 1, #native_calls do
    if native_calls[i] == "B3271D7AB655B441" then target_written = true end
end
assert(target_written, "Cayo target option did not reach the stat bridge")
local office_action
for _, action in ipairs(actions) do
    if action.label == "Teleport To Office" then office_action = action.callback; break end
end
assert(office_action, "Missing nested YimResupplier action")
before = threads_created
office_action()
assert(threads_created > before, "Nested tab action did not reach its callback")
local native_table = setmetatable({}, {__index = NETSHOPPING})
local wrapper_environment = setmetatable({
    NETSHOPPING = native_table,
    HUD = setmetatable({}, {__index = HUD}),
    ENTITY = setmetatable({}, {__index = ENTITY}),
    CUTSCENE = setmetatable({}, {__index = CUTSCENE}),
    memory = setmetatable({}, {__index = memory}),
}, {__index = _G})
assert(loadfile("Nenyoo/lib/yim_compat.lua", "t", wrapper_environment))()
local service_ok, transaction = native_table.NET_GAMESERVER_BEGIN_SERVICE(-1, 1, 2, 3, 4, 5)
assert(service_ok and transaction == 42, "Weapon unlock service lost the output transaction ID")
assert(rawget(NETSHOPPING, "NET_GAMESERVER_BEGIN_SERVICE") == nil, "Package changed global native wrappers")
local blip_position = wrapper_environment.HUD.GET_BLIP_COORDS(1)
assert(blip_position.x == 1 and blip_position.z == 3, "Blip coordinates lost their vector result")
assert(wrapper_environment.HUD.DOES_BLIP_EXIST(1) == false, "Missing blip must be false, not numeric zero")
assert(wrapper_environment.NETSHOPPING.NET_GAMESERVER_BASKET_IS_ACTIVE() == false, "Inactive basket must be false")
assert(wrapper_environment.CUTSCENE.IS_CUTSCENE_PLAYING() == false, "Inactive cutscene must be false")
assert(wrapper_environment.weapons.get_weapon_display_name("WEAPON_PISTOL") == "Pistol", "Weapon editor lost catalog names")
assert(wrapper_environment.weapons.get_weapon_display_name(util.joaat("WEAPON_PISTOL")) == "Pistol", "Gun Van hash did not resolve")
local failures = {}
local initial_action_count = #actions
local initial_toggle_count, initial_input_count, initial_slider_count = #toggles, #inputs, #sliders
for _, action in ipairs(actions) do
    local ok, message = pcall(action.callback)
    if not ok then failures[#failures + 1] = action.label .. ": " .. tostring(message) end
end
for _, toggle in ipairs(toggles) do
    local ok, message = pcall(toggle.callback, not toggle.default)
    if not ok then failures[#failures + 1] = toggle.label .. ": " .. tostring(message) end
end
for _, input in ipairs(inputs) do
    local ok, message = pcall(input.callback, "1")
    if not ok then failures[#failures + 1] = input.label .. ": " .. tostring(message) end
end
for _, slider in ipairs(sliders) do
    local ok, message = pcall(slider.callback, 1)
    if not ok then failures[#failures + 1] = slider.label .. ": " .. tostring(message) end
end
local scheduled = #thread_callbacks
if os.getenv("UM_OWNED_STATS") == "late" then owned_stats = true end
for i = 1, scheduled do
    local thread = coroutine.create(thread_callbacks[i])
    debug.sethook(thread, function() error("Mock thread exceeded one-tick instruction budget") end, "", 1000000)
    for tick = 1, 2 do
        if coroutine.status(thread) == "dead" then break end
        local ok, message = coroutine.resume(thread)
        if not ok then failures[#failures + 1] = "thread " .. i .. " tick " .. tick .. ": " .. tostring(message) .. thread_origins[i]; break end
    end
end
assert(counters.action >= 1046, "Dynamic Gun Van editor controls did not materialize")
if os.getenv("UM_OWNED_STATS") then
    assert(counters.action >= 1069, "Owned-business controls did not materialize")
end
for i = initial_action_count + 1, #actions do
    local ok, message = pcall(actions[i].callback)
    if not ok then failures[#failures + 1] = actions[i].label .. ": " .. tostring(message) end
end
for i = initial_toggle_count + 1, #toggles do
    local ok, message = pcall(toggles[i].callback, not toggles[i].default)
    if not ok then failures[#failures + 1] = toggles[i].label .. ": " .. tostring(message) end
end
for i = initial_input_count + 1, #inputs do
    local ok, message = pcall(inputs[i].callback, "1")
    if not ok then failures[#failures + 1] = inputs[i].label .. ": " .. tostring(message) end
end
for i = initial_slider_count + 1, #sliders do
    local ok, message = pcall(sliders[i].callback, 1)
    if not ok then failures[#failures + 1] = sliders[i].label .. ": " .. tostring(message) end
end
for _, failure in ipairs(failures) do print(failure) end
assert(#failures == 0, string.format("%d action callbacks failed", #failures))
assert(menu_back_calls > 0, "Gun Van Close action did not leave its submenu")
-- A filtered list changes ordinal positions. An action must still select its
-- original weapon rather than whatever weapon moved into that position.
local weapon_filter, pistol_action, set_weapon_action
for _, input in ipairs(inputs) do
    if input.label == "Weapon Name" then weapon_filter = input.callback end
end
for _, action in ipairs(actions) do
    if action.label == "Pistol" then pistol_action = action.callback end
    if action.label == "Set Weapon" then set_weapon_action = action.callback end
end
assert(weapon_filter and pistol_action and set_weapon_action, "Missing Gun Van editor controls")
memory.tunable = function() return 123456 end
weapon_filter("Pistol")
pistol_action()
set_weapon_action()
assert(memory_values[123456] == util.joaat("WEAPON_PISTOL"), "Filtered Gun Van row selected another weapon")
print(string.format("Ultimate Menu loaded: %d nodes, %d lists, %d actions, %d ImGui sections",
    next_ref, counters.list, counters.action, #compat.imgui_sections))
