-- Loads the whole modded c0000.hks with a fake engine and runs deflect/skill scenarios through
-- the real ExecGuard / ExecDamage / Update code. It checks the script's logic only; how the game
-- reacts (animations, effects, stance damage) still needs testing in game.
-- usage: lua5.1 tests/script_test.lua mod/action/script/c0000.hks
TRUE, FALSE = 1, 0

-- constants the define files would provide
DAMAGE_TYPE_INVALID, DAMAGE_TYPE_WEAK_POINT, DAMAGE_TYPE_PARRY = 0, 1, 2
DAMAGE_TYPE_GUARDED, DAMAGE_TYPE_WALL_LEFT = 10, 99
DAMAGE_TYPE_GUARD = 5 -- handled after the GUARDED..WALL_LEFT range
DAMAGE_LEVEL_NONE, DAMAGE_LEVEL_MINIMUM, DAMAGE_LEVEL_SMALL, DAMAGE_LEVEL_MIDDLE, DAMAGE_LEVEL_LARGE = 0, 1, 2, 3, 4
local next_const, next_damage_type, next_level = 100000, 11, 5
local stubs_called = {}

-- world state
W = {}
function reset_world()
    W = {
        hero = "HERO_TECHNICAL", sp = {}, stamina = 100, pressed = {}, held = {},
        category = { }, guard_level = 1, damage_type = 0, damage_level = DAMAGE_LEVEL_SMALL,
        damaged = TRUE, vars = {}, events = {}, acts = {}, nodes = {}, frame = 0,
        hp = 500, max_hp = 1000,
    }
end
reset_world()

local engine = {}
function engine.env(id, a, ...)
    if id == 371 then return _G[W.hero] end
    if id == 1116 then return W.sp[a] and TRUE or FALSE end
    if id == 1106 then return W.pressed[a] and TRUE or FALSE end
    if id == 1108 then return W.held[a] and 1 or 0 end
    if id == 225 then return W.category[a] or _G.WEAPON_CATEGORY_KATANA end
    if id == 1001 then return W.stamina end
    if id == 237 then return W.guard_level end
    if id == 202 then return W.damage_type end
    if id == 236 then return W.damage_level end
    if id == 256 then return W.damaged end
    if id == 1000 then return W.hp end
    if id == 2013 then return W.max_hp end
    if id == 333 then return 33 end -- frame time in ms (GetDeltaTime)
    return 0
end
function engine.act(id, a, b)
    table.insert(W.acts, { id, a })
    if id == 148 then W.vars[a] = b
    elseif id == 2002 then
        W.sp[a] = true
        -- the rework's instant HP change effects: 707300 + n / 707310 + n = -/+ 2^(n-1) % of max HP
        if a > 707300 and a <= 707307 then W.hp = W.hp - W.max_hp * 2 ^ (a - 707301) / 100 end
        if a > 707310 and a <= 707317 then W.hp = W.hp + W.max_hp * 2 ^ (a - 707311) / 100 end
    elseif id == 9001 then W.sp[a] = nil
    elseif id == 1001 then W.stamina = W.stamina + a end
end
function engine.DebugPrint() end
engine.hkVector4 = { new = function(...) return { ... } end }
engine.hkQuaternion = { new = function(...) return { ... } end }
function engine.hkbFireEvent(e) table.insert(W.events, e) end
function engine.hkbGetVariable(k) return W.vars[k] or 0 end
function engine.hkbIsNodeActive(n) return W.nodes[n] == true end

local harness_mt = { __index = function(t, k)
    if engine[k] then return engine[k] end
    if type(k) ~= "string" then return nil end
    if k:match("^DAMAGE_TYPE_") then rawset(t, k, next_damage_type); next_damage_type = next_damage_type + 1; return rawget(t, k) end
    if k:match("^DAMAGE_LEVEL_") then rawset(t, k, next_level); next_level = next_level + 1; return rawget(t, k) end
    if k:match("^[A-Z][A-Z0-9_]*$") then rawset(t, k, next_const); next_const = next_const + 1; return rawget(t, k) end
    if k:match("^[cg]_") or k:match("^f%d+_local") then return 0 end
    -- any other engine function: record and return 0
    return function(...) stubs_called[k] = (stubs_called[k] or 0) + 1; return 0 end
end }
setmetatable(_G, harness_mt)

dofile(arg[1])
-- the script ends by installing its own fallback for missing globals; put the fake engine back
setmetatable(_G, harness_mt)
-- vanilla guard eligibility (weapon tables from the define files) isn't part of the rework
IsEnableGuard = function() return TRUE end

-- the script's own constants now exist; pin the ones the fake engine answers with
HAND_LEFT, HAND_RIGHT = HAND_LEFT, HAND_RIGHT
g_FrameCount = 0

local pass, fail = 0, 0
local function check(c, msg)
    if c then pass = pass + 1; print("ok    " .. msg) else fail = fail + 1; print("FAIL  " .. msg) end
end
local function has(list, x) for _, v in ipairs(list) do if v == x then return true end end return false end
local function count_act(id, a) local n = 0 for _, v in ipairs(W.acts) do if v[1] == id and (a == nil or v[2] == a) then n = n + 1 end end return n end
local function frame() W.frame = W.frame + 1; g_FrameCount = W.frame; Update() end

-- helpers
local function press_guard()
    W.pressed[ACTION_ARM_L1] = true; W.held[ACTION_ARM_L1] = true
    ExecGuard({ "W_GuardStart" }, UPPER, FALSE)
    W.pressed[ACTION_ARM_L1] = false
end
local function release_guard() W.held[ACTION_ARM_L1] = false end
-- the engine blocks the hit (charging `cost` stamina) and then the script handles it
local function hit(dtype, cost, charge_late)
    W.damage_type = dtype
    if not charge_late then W.stamina = W.stamina - cost end
    W.events = {}
    ExecDamage(FALSE, FALSE)
    if charge_late then W.stamina = W.stamina - cost end
end
local function expire_window() W.sp[707001] = nil; W.sp[707002] = nil; W.sp[707003] = nil end

print("== deflect with a katana")
reset_world(); W.category[HAND_LEFT] = WEAPON_CATEGORY_KATANA
press_guard()
check(W.sp[707001] and W.sp[707004], "fresh press opens the 100% window and the spam recovery")
frame(); W.stamina = 101; frame()
hit(DAMAGE_TYPE_GUARD, 30)
check(W.stamina == 101 - 30 + 27, "deflect costs 10% of the block (30 -> 3), stamina " .. W.stamina)
check(EXECUTOR_DEFLECT_COUNT == 1, "deflect counted toward the awakening")
check(not W.sp[707004], "deflect ends the spam recovery")
check(W.vars.IndexGuard ~= 4, "weapon's own guard animation set (IndexGuard " .. tostring(W.vars.IndexGuard) .. ")")
check(has(W.events, "W_GuardDamageSmall"), "light guard hit plays the weapon's small guard reaction")
check(has(W.events, "W_AddDamageGuardStartDemonSword") and W.vars.AddDamageGuardBlend == 1, "Cursed Sword deflect flinch layered on top")
local s = W.stamina; frame(); frame()
check(W.stamina == s, "no second refund on the following frames")

print("== engine charges the stamina one frame after the script sees the hit")
reset_world(); EXECUTOR_DEFLECT_COUNT = 0
press_guard(); frame()
hit(DAMAGE_TYPE_GUARD, 40, true)
check(W.stamina == 60, "nothing refunded before the charge")
frame()
check(W.stamina == 60 + 36, "refund on the next frame (40 -> 4), stamina " .. W.stamina)

print("== hit on the first frame of the window, before any Update()")
reset_world(); EXECUTOR_DEFLECT_COUNT = 0; EXECUTOR_DEFLECT_STAMINA_BEFORE = -1
press_guard()
hit(DAMAGE_TYPE_GUARD, 50)
check(W.stamina == 95, "stamina from the guard press is used (50 -> 5), stamina " .. W.stamina)

print("== two hits in one window")
reset_world(); EXECUTOR_DEFLECT_COUNT = 0
press_guard(); frame()
hit(DAMAGE_TYPE_GUARD, 20); frame()
local after_first = W.stamina
hit(DAMAGE_TYPE_GUARD, 20); frame()
check(after_first == 98 and W.stamina == 96, "each hit costs 10% of its own block cost (" .. after_first .. ", " .. W.stamina .. ")")

print("== normal block (no window)")
reset_world(); EXECUTOR_DEFLECT_COUNT = 0
W.held[ACTION_ARM_L1] = true; frame()
hit(DAMAGE_TYPE_GUARD, 30); frame(); frame()
check(W.stamina == 70, "full block cost without a deflect")
check(EXECUTOR_DEFLECT_COUNT == 0 and not has(W.events, "W_AddDamageGuardStartDemonSword"), "no deflect count, no deflect flinch")

print("== deflected hit too weak for a guard reaction")
reset_world(); EXECUTOR_DEFLECT_COUNT = 0
press_guard(); frame(); W.guard_level = 0
hit(DAMAGE_TYPE_GUARD, 10)
check(W.events[1] == "W_AddDamageGuardStartDemonSword" and #W.events == 1, "only the Cursed Sword deflect flinch (" .. table.concat(W.events, ",") .. ")")

print("== deflected guard break")
reset_world(); EXECUTOR_DEFLECT_COUNT = 0
press_guard(); frame(); W.guard_level = 3
hit(DAMAGE_TYPE_GUARDBREAK, 100)
check(has(W.events, "W_GuardDamageSmall") and not has(W.events, "W_GuardDamageLarge"), "no guard break, light guard reaction (" .. table.concat(W.events, ",") .. ")")
check(W.stamina == 90, "stamina back to 90% after a guard break was deflected, stamina " .. W.stamina)
check(EXECUTOR_DEFLECT_COUNT == 1, "counted")

print("== vanilla stance deflect unchanged")
reset_world(); EXECUTOR_DEFLECT_COUNT = 0
W.sp[707060] = true; W.sp[707000] = true; W.guard_level = 3
hit(DAMAGE_TYPE_GUARDBREAK, 10)
check(has(W.events, "W_GuardDamageLarge") and W.vars.IndexGuard == 4, "stance deflect of a guard break keeps its Cursed Sword reaction")
check(EXECUTOR_DEFLECT_COUNT == 0 and W.stamina == 90, "no passive count or refund in the stance")

print("== spam protection")
reset_world(); EXECUTOR_DEFLECT_COUNT = 0
press_guard(); expire_window(); release_guard()
press_guard()
check(not W.sp[707001] and W.sp[707004], "second press during the recovery opens no window")
W.sp[707004] = nil; release_guard(); press_guard()
check(W.sp[707001], "press after the recovery opens a window again")
frame(); hit(DAMAGE_TYPE_GUARD, 10); release_guard(); press_guard()
check(W.sp[707001], "after a deflect the next press opens a window right away (combos)")

print("== deflect sparks go to the guarding weapon")
reset_world(); press_guard()
check(W.sp[707009] and not W.sp[707008], "one-handed: left-weapon sparks marker with the window")
reset_world(); c_Style = HAND_RIGHT_BOTH; W.category[HAND_RIGHT] = WEAPON_CATEGORY_KATANA; press_guard(); c_Style = nil
check(W.sp[707008] and not W.sp[707009] and W.sp[707001], "two-handed right: right-weapon sparks marker")
reset_world(); W.sp[707004] = true; press_guard()
check(not W.sp[707008] and not W.sp[707009], "no marker when the spam protection blocks the window")
for _, cat in ipairs({ "CLAW", "FIST" }) do
    reset_world(); c_Style = HAND_RIGHT_BOTH; W.category[HAND_RIGHT] = _G["WEAPON_CATEGORY_" .. cat]; press_guard(); c_Style = nil
    check(W.sp[707012] and not W.sp[707008] and not W.sp[707009], cat .. " two-handed: sparks on the left hand, which blocks (707012)")
end
reset_world(); c_Style = HAND_RIGHT_BOTH; W.category[HAND_RIGHT] = WEAPON_CATEGORY_FLAIL; press_guard(); c_Style = nil
check(W.sp[707008] and not W.sp[707012], "flail two-handed: sparks on the right weapon")
reset_world(); W.category[HAND_LEFT] = WEAPON_CATEGORY_SHORT_SWORD; press_guard()
check(W.sp[707012] and not W.sp[707009], "dagger in the left hand: sparks at the left hand (707012)")
reset_world(); c_Style = HAND_RIGHT_BOTH; W.category[HAND_RIGHT] = WEAPON_CATEGORY_SHORT_SWORD; press_guard(); c_Style = nil
check(W.sp[707013] and not W.sp[707008], "dagger two-handed: sparks at the right hand (707013)")

print("== the deflect flinch always plays")
reset_world(); EXECUTOR_DEFLECT_COUNT = 0; W.category[HAND_LEFT] = WEAPON_CATEGORY_SHORT_SWORD
press_guard(); frame(); W.damaged = FALSE; W.guard_level = 3
hit(DAMAGE_TYPE_GUARD, 10)
check(has(W.events, "W_AddDamageGuardStartDemonSword") and W.vars.AddDamageGuardBlend == 1, "flinch plays even when the hit counts as not damaged (" .. table.concat(W.events, ",") .. ")")
check(has(W.events, "W_GuardDamageSmall") and not has(W.events, "W_GuardDamageMiddle"), "heavy deflected hit still gets the light guard reaction")
reset_world(); W.held[ACTION_ARM_L1] = true; frame(); W.guard_level = 3
hit(DAMAGE_TYPE_GUARD, 10)
check(has(W.events, "W_GuardDamageMiddle") and not has(W.events, "W_AddDamageGuardStartDemonSword"), "normal block keeps its own reaction level and no flinch")

print("== deflect stops knock-backs through the guard")
for _, t in ipairs({ "GUARDBREAK_BLAST", "GUARDBREAK_FLING" }) do
    reset_world(); EXECUTOR_DEFLECT_COUNT = 0; W.category[HAND_LEFT] = WEAPON_CATEGORY_SHORT_SWORD
    press_guard(); frame(); W.guard_level = 1
    hit(_G["DAMAGE_TYPE_" .. t], 20)
    check(EXECUTOR_DEFLECT_COUNT == 1 and has(W.events, "W_GuardDamageSmall") and not has(W.events, "W_DamageLv7_SmallBlow") and not has(W.events, "W_DamageLv6_Fling"), t .. " deflected like a normal hit (" .. table.concat(W.events, ",") .. ")")
    reset_world(); W.held[ACTION_ARM_L1] = true; frame()
    hit(_G["DAMAGE_TYPE_" .. t], 20)
    check(not has(W.events, "W_GuardDamageSmall"), t .. " without a deflect still knocks back (" .. table.concat(W.events, ",") .. ")")
end

print("== deflect groups")
local function window_for(cat) reset_world(); W.category[HAND_LEFT] = cat; press_guard(); return (W.sp[707001] and 1) or (W.sp[707002] and 2) or (W.sp[707003] and 3) or 0 end
check(window_for(WEAPON_CATEGORY_KATANA) == 1 and window_for(WEAPON_CATEGORY_FIST) == 1, "katana / fist 100%")
check(window_for(WEAPON_CATEGORY_SHORT_SWORD) == 1 and window_for(WEAPON_CATEGORY_CLAW) == 1 and window_for(WEAPON_CATEGORY_RAPIER) == 1 and window_for(WEAPON_CATEGORY_CURVEDSWORD) == 1, "dagger / claw / thrusting sword / curved sword 100%")
check(window_for(WEAPON_CATEGORY_LARGE_SWORD) == 2 and window_for(WEAPON_CATEGORY_FLAIL) == 2, "greatsword / flail 65%")
check(window_for(WEAPON_CATEGORY_EXTRALARGE_SWORD) == 3, "colossal sword 30%")
check(window_for(WEAPON_CATEGORY_WHIP) == 0 and window_for(WEAPON_CATEGORY_MIDDLE_SHIELD) == 0, "whip / shield none")

print("== 4 deflects awaken the sword")
reset_world(); EXECUTOR_DEFLECT_COUNT = 0
for i = 1, 4 do press_guard(); frame(); hit(DAMAGE_TYPE_GUARD, 10); frame(); release_guard() end
check(W.sp[707051] and EXECUTOR_DEFLECT_COUNT == 0, "awakened after 4 deflects")

print("== other heroes")
reset_world(); W.hero = "HERO_MAGIC"; W.held[ACTION_ARM_L1] = true
W.pressed[ACTION_ARM_L1] = true; ExecGuard({ "W_GuardStart" }, UPPER, FALSE)
frame(); hit(DAMAGE_TYPE_GUARD, 30); frame()
check(not W.sp[707001] and W.stamina == 70 and not has(W.events, "W_AddDamageGuardStartDemonSword"), "no window, refund or flinch for other heroes")

print("== skill")
reset_world(); EXECUTOR_SKILL_STATE = EXECUTOR_SKILL_NONE
StartExecutorSkill()
check(W.events[1] == "W_DemonSwordArts" and W.vars.AddDemonSwordModeBlend == 1, "dash slash with the Cursed Sword layer")
W.nodes["DemonSwordArts Selector"] = true; frame(); frame()
W.nodes["DemonSwordArts Selector"] = false; frame()
check(W.vars.AddDemonSwordModeBlend == 0, "layer off after the slash")

print("== no Cursed Sword moveset right after the skill")
local function r1_request() W.pressed[ACTION_ARM_R1] = true; local r = GetAttackRequest(FALSE); W.pressed[ACTION_ARM_R1] = false; return r end
reset_world(); EXECUTOR_SKILL_STATE = EXECUTOR_SKILL_NONE; EXECUTOR_SKILL_ATTACK_LOCK_LEFT = 0
check(r1_request() ~= ATTACK_REQUEST_INVALID, "R1 works normally before the skill")
StartExecutorSkill()
check(r1_request() == ATTACK_REQUEST_INVALID, "no R1 cancel while the dash slash plays")
W.nodes["DemonSwordArts Selector"] = true; frame()
W.nodes["DemonSwordArts Selector"] = false; frame()
check(W.vars.AddDemonSwordModeBlend == 0 and r1_request() == ATTACK_REQUEST_INVALID, "still no R1 right after the slash (layer fading out)")
W.sp[707060] = true; for i = 1, 10 do frame() end
check(r1_request() == ATTACK_REQUEST_INVALID, "no R1 while the stance state from the layer lingers")
W.sp[707060] = nil; frame()
check(r1_request() ~= ATTACK_REQUEST_INVALID, "R1 works again once the layer is gone (after about 0.2 s)")
reset_world(); W.hero = "HERO_MAGIC"; EXECUTOR_SKILL_ATTACK_LOCK_LEFT = 1
check(r1_request() ~= ATTACK_REQUEST_INVALID, "no attack lock for other heroes")
EXECUTOR_SKILL_ATTACK_LOCK_LEFT = 0

print("== Beast HP: setup, the Beast falling, the form ending")
local function act_index(id, a) for i, v in ipairs(W.acts) do if v[1] == id and v[2] == a then return i end end return nil end
local function start_beast(hp)
    reset_world(); W.hp = hp; EXECUTOR_BEAST_STATE = EXECUTOR_BEAST_NONE; EXECUTOR_BEAST_PROTECTION_LEFT = 0
    SaveExecutorPreBeastHp()
    W.sp[707115] = true; W.max_hp = 2000; W.hp = 2000 -- Beast form on, vanilla full heal
end
start_beast(300)
SetupExecutorBeastHp()
check(EXECUTOR_BEAST_STATE == EXECUTOR_BEAST_ACTIVE and W.hp == 600, "Beast gets the Executor's 30% (" .. W.hp .. " of 2000)")
-- the Beast falls: noDead holds it at 1 HP
W.hp = 1; W.acts = {}; frame()
local prot, clear = act_index(2002, EXECUTOR_BEAST_EXIT_PROTECTION), act_index(9001, 707115)
check(prot and clear and prot < clear, "exit protection goes on before the Beast form is cleared")
check(EXECUTOR_BEAST_STATE == EXECUTOR_BEAST_ENDED and not W.sp[707115], "form ended instead of the Beast dying")
W.max_hp = 1000; frame()
check(math.abs(W.hp - 300) <= 10 and EXECUTOR_BEAST_STATE == EXECUTOR_BEAST_NONE, "Executor back at 30% (" .. W.hp .. " of 1000, 1% steps from 1 HP)")

print("== attacking straight out of the transformation (no Beast idle)")
start_beast(800)
for i = 1, 30 do frame() end
check(EXECUTOR_BEAST_STATE == EXECUTOR_BEAST_TRANSFORMING, "no setup during the first second without the idle")
for i = 1, 80 do frame() end
check(EXECUTOR_BEAST_STATE == EXECUTOR_BEAST_ACTIVE and W.hp == 1600, "HP setup runs by the 3 s fallback (" .. W.hp .. " of 2000)")

print("== form ends before the HP setup ran")
start_beast(250)
frame(); frame()
W.sp[707115] = nil; W.max_hp = 1000; W.hp = 1; W.acts = {}; frame()
check(count_act(2002, EXECUTOR_BEAST_EXIT_PROTECTION) == 1 and EXECUTOR_BEAST_STATE == EXECUTOR_BEAST_ENDED, "exit protection and HP restore start even though the setup never ran")
frame()
check(math.abs(W.hp - 250) <= 10 and EXECUTOR_BEAST_STATE == EXECUTOR_BEAST_NONE, "Executor back at 25% instead of 1 HP (" .. W.hp .. ")")

print("== gauge runs out")
start_beast(700)
SetupExecutorBeastHp(); W.hp = 900
W.sp[707115] = nil; W.max_hp = 1000; W.hp = 450; W.acts = {}; frame()
check(count_act(2002, EXECUTOR_BEAST_EXIT_PROTECTION) == 1, "exit protection when the form ends normally")
frame()
check(W.hp == 700, "Executor back at 70% (" .. W.hp .. ")")
W.acts = {}; frame(); frame()
check(EXECUTOR_BEAST_STATE == EXECUTOR_BEAST_NONE and W.hp == 700, "nothing more after the restore")

print("== exit protection holds until the Executor can act again")
start_beast(600); SetupExecutorBeastHp()
W.hp = 1; frame()                                   -- the Beast falls
W.max_hp = 1000
W.acts = {}; for i = 1, 20 do frame() end
check(count_act(2002, EXECUTOR_BEAST_EXIT_PROTECTION) == 20, "protection refreshed every frame while not back in control (" .. count_act(2002, EXECUTOR_BEAST_EXIT_PROTECTION) .. " of 20)")
pcall(Idle_onUpdate)                                 -- back in the idle state
W.acts = {}; for i = 1, 5 do frame() end
check(count_act(2002, EXECUTOR_BEAST_EXIT_PROTECTION) == 0, "no more refreshing once idle (the last one runs out 1 s later)")
start_beast(600); SetupExecutorBeastHp()
W.sp[707115] = nil; W.max_hp = 1000; frame()        -- gauge runs out
pcall(Move_onUpdate)                                 -- already moving
W.acts = {}; frame()
check(count_act(2002, EXECUTOR_BEAST_EXIT_PROTECTION) == 0, "moving also counts as back in control")
start_beast(600); SetupExecutorBeastHp()
W.hp = 1; frame(); W.max_hp = 1000
for i = 1, 160 do frame() end                        -- 5.3 s, never idle
W.acts = {}; frame()
check(count_act(2002, EXECUTOR_BEAST_EXIT_PROTECTION) == 0, "refreshing stops after 5 s at the latest")

print("== Ultimate Art cancelled before the Beast form came on")
start_beast(500); W.sp[707115] = nil; W.max_hp = 1000; W.hp = 500; W.acts = {}
for i = 1, 5 do frame() end
check(count_act(2002, EXECUTOR_BEAST_EXIT_PROTECTION) == 0 and W.hp == 500, "no protection or HP change without a Beast form")

print(string.format("\n%d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
