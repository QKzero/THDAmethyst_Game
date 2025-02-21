--------------------
--LAB模式的测试内容--
--------------------
-- ability_starwberryability_buff = {}
-- function ability_starwberryability_buff:GetIntrinsicModifierName()
-- 	local caster = self:GetCaster()
-- 	if caster:GetClassname() == "npc_dota_hero_slark" then return "modifier_starwberry_aya" end --射命丸文
-- end
-- --射命丸文部分
-- modifier_starwberry_aya = {}
-- LinkLuaModifier("modifier_starwberry_aya", "scripts/vscripts/util/starwberry.lua", LUA_MODIFIER_MOTION_NONE)
-- function modifier_starwberry_aya:IsHidden() return false end
-- function modifier_starwberry_aya:IsPurgable() return false end
-- function modifier_starwberry_aya:RemoveOnDeath() return false end
-- function modifier_starwberry_aya:IsDebuff() return false end
-- function modifier_starwberry_aya:AllowIllusionDuplicate() return true end
-- function modifier_starwberry_aya:DeclareFunctions() return
--     {
--         MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
--         MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
--     }
-- end
-- function modifier_starwberry_aya:GetModifierBonusStats_Strength()   
--     local parent = self:GetParent()  
--     return parent:GetLevel()*0.4-0.4 end
-- function modifier_starwberry_aya:GetModifierBonusStats_Agility()    
--     local parent = self:GetParent()  
--     return parent:GetLevel()*0.5-0.5 end




