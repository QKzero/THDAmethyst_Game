local modifiersName = {
    "modifier_event_proxy",
}

for i, modifier_name in pairs(modifiersName) do
	LinkLuaModifier(modifier_name, "components/modifiers/" .. modifier_name, LUA_MODIFIER_MOTION_NONE)
    print(string.format("LinkLuaModifier(%s, components/modifiers/%s, LUA_MODIFIER_MOTION_NONE)", modifier_name, modifier_name))
end
