
STARTING_GOLD = 500--650
DEBUG = true
GameMode = nil

TRUE = 1
FALSE = 0

function Toolsprint(string)
	if IsInToolsMode() then
		print(string)
	end
end

function GetDistanceBetweenTwoVec2D(a, b)
    local xx = (a.x-b.x)
    local yy = (a.y-b.y)
    return math.sqrt(xx*xx + yy*yy)
end

function GetRadBetweenTwoVec2D(a,b)
	local y = b.y - a.y
	local x = b.x - a.x
	return math.atan2(y,x)
end
--aVec:原点向量
--rectOrigin：单位原点向量
--rectWidth：矩形宽度
--rectLenth：矩形长度
--rectRad：矩形相对Y轴旋转角度
function IsRadInRect(aVec,rectOrigin,rectWidth,rectLenth,rectRad)
	local aRad = GetRadBetweenTwoVec2D(rectOrigin,aVec)
	local turnRad = aRad + (math.pi/2 - rectRad)
	local aRadius = GetDistanceBetweenTwoVec2D(rectOrigin,aVec)
	local turnX = aRadius*math.cos(turnRad)
	local turnY = aRadius*math.sin(turnRad)
	local maxX = rectWidth/2
	local minX = -rectWidth/2
	local maxY = rectLenth
	local minY = 0
	if(turnX<maxX and turnX>minX and turnY>minY and turnY<maxY)then
		return true
	else
	    return false
	end
	return false
end

function IsRadBetweenTwoRad2D(a,rada,radb)
    local maxrad = math.max(rada,radb)
    local minrad = math.min(rada,radb)
    
    if rada >= 0 and radb >= 0 then
        if(a<=maxrad and a>=minrad)then
            print("true")
            return true
        end
    elseif rada >=0 and radb < 0 then

    elseif rada < 0 and radb >= 0 then
        if(a<maxrad and a>minrad)then
            print("true")
            return true
        end
    elseif rada < 0 and radb < 0 then
        if(a<maxrad and a>minrad)then
            print("true")
            return true
        end
    end

	return false
end


-- cx = 目标的x
-- cy = 目标的y
-- ux = math.cos(theta)   (rad是caster和target的夹角的弧度制表示)
-- uy = math.sin(theta)
-- r = 目标和原点之间的距离
-- theta = 夹角的弧度制
-- px = 原点的x
-- py = 原点的y
-- 返回 true or false(目标是否在扇形内，在的话=true，不在=false)

function IsPointInCircularSector(cx,cy,ux,uy,r,theta,px,py)
    local dx = px - cx
    local dy = py - cy

    local length = math.sqrt(dx * dx + dy * dy)

    if (length > r) then
        return false
    end

    local vec = Vector(dx,dy,0):Normalized()
    return math.acos(vec.x * ux + vec.y * uy) < theta
 end 


function SetTargetToTraversable(target)
    local vecTarget = target:GetOrigin() 
    local vecGround = GetGroundPosition(vecTarget, nil)

    UnitNoCollision(target,vecTarget)
end

function CDOTA_BaseNPC:GetFountainHandle()
	local handle
	for i, fountain in pairs(Entities:FindAllByClassname("ent_dota_fountain")) do
		if fountain:GetTeamNumber() == self:GetTeamNumber() then
			handle = fountain
			break
		end
	end

    return handle
end

function CDOTA_BaseNPC:GetFountainAbsOrigin()
	local absorigin
	for i, fountain in pairs(Entities:FindAllByClassname("ent_dota_fountain")) do
		if fountain:GetTeamNumber() == self:GetTeamNumber() then
			absorigin = fountain:GetAbsOrigin()
			break
		end
	end

    return absorigin
end

function CDOTA_BaseNPC:SetUnitOnClearGround()       --学习imba的方法，延迟 1 FrameTime
	Timer.Wait 'SetOnClearGround' (FrameTime(), function()
		self:SetAbsOrigin(Vector(self:GetAbsOrigin().x, self:GetAbsOrigin().y, GetGroundPosition(self:GetAbsOrigin(), self).z))		
		FindClearSpaceForUnit(self, self:GetAbsOrigin(), true)
		ResolveNPCPositions(self:GetAbsOrigin(), 64)
	end)
end

function CDOTA_BaseNPC:EmitCasterSound(sCasterName, tSoundNames, fChancePct, flags, fCooldown, sCooldownindex)  -- from imba
	flags = flags or 0
	if self:GetName() ~= sCasterName then
		return true
	end

	if fCooldown then
		if self["VoiceCooldown"..sCooldownindex] then
			return true
		else
			self["VoiceCooldown"..sCooldownindex] = true
			Timers:CreateTimer(fCooldown, function()
				self["VoiceCooldown"..sCooldownindex] = nil
			end)
		end
	end

	if fChancePct then
		if fChancePct <= math.random(1,100) then
			return false -- Only return false if chance was missed
		end
	end
	if (bit.band(flags, DOTA_CAST_SOUND_FLAG_WHILE_DEAD) > 0) or self:IsAlive() then
		local sound = tSoundNames[math.random(1,#tSoundNames)]
		if bit.band(flags, DOTA_CAST_SOUND_FLAG_BOTH_TEAMS) > 0 then
			self:EmitSound(sound)
		--elseif bit.band(flags, DOTA_CAST_SOUND_FLAG_GLOBAL) > 0 then
			-- Iterate through players, added later
		else
			StartSoundEventReliable(sound, self)
		end
	end
	return true
end

function CDOTA_BaseNPC:CasterSoundCooldown(sCasterName, fCooldown, sCooldownindex)  -- 使语音冷却进入cd
	if self:GetName() ~= sCasterName then
		return true
	end

	if fCooldown then
		if self["VoiceCooldown"..sCooldownindex] then
			return true
		else
			self["VoiceCooldown"..sCooldownindex] = true
			Timers:CreateTimer(fCooldown, function()
				self["VoiceCooldown"..sCooldownindex] = nil
			end)
		end
	end

	return true
end

function CDOTA_BaseNPC:GetUsedAbilitySlotCount()
	local count = 0
	for i = 0, self:GetAbilityCount() - 1 do
		if self:GetAbilityByIndex(i) then
			count = count + 1
		end
	end

	return count
end

function ParticleManager:DestroyParticleSystem(effectIndex,bool)
    if(bool)then
        if effectIndex ~= nil then
            ParticleManager:DestroyParticle(effectIndex,true)
            ParticleManager:ReleaseParticleIndex(effectIndex) 
        end
    else
        Timer.Wait 'Effect_Destroy_Particle' (4,
            function()
                if effectIndex ~= nil then
                    ParticleManager:DestroyParticle(effectIndex,true)
                    ParticleManager:ReleaseParticleIndex(effectIndex) 
                end
            end
        )
    end
end

function ParticleManager:DestroyParticleSystemTime(effectIndex,time)
    Timer.Wait 'Effect_Destroy_Particle_Time' (time,
        function()
            ParticleManager:DestroyParticle(effectIndex,true)
            ParticleManager:ReleaseParticleIndex(effectIndex) 
        end
    )
end

function is_spell_blocked(target,caster)
    if caster ~= nil then 
        if caster:GetTeam() == target:GetTeam() then
            return false
        end
    end
	if target:HasModifier("modifier_item_sphere_target") then
		target:RemoveModifierByName("modifier_item_sphere_target")  --The particle effect is played automatically when this modifier is removed (but the sound isn't).
		target:EmitSound("DOTA_Item.LinkensSphere.Activate")
		return true
	end
	return false
end

function THDReduceCooldown(ability,value)
    if value == 0 then return end
    local cooldown=(ability:GetCooldown(ability:GetLevel() - 1)+value)*(ability:GetCooldownTimeRemaining()/ability:GetCooldown(ability:GetLevel() - 1))
    ability:EndCooldown()
    ability:StartCooldown(cooldown)
end

function FindTelentValue(caster,name)
    local ability = caster:FindAbilityByName(name)
    if ability~=nil then
        return ability:GetSpecialValueFor("value")
    else
        return 0
    end
end




function FindValueTHD(name,ability)

    if ability == nil then
        return 0
    end
    local thdvalue = ability:GetLevelSpecialValueFor(name, ability:GetLevel() - 1 )
--  print(thdvalue)
    return thdvalue

end

function GetSumModifierValues(hUnit, sMethod)
	local sum = 0
	for i, modifier in ipairs(hUnit:FindAllModifiers()) do
		if modifier[sMethod] then
			local bonus = modifier[sMethod](modifier) or 0
			sum = sum + bonus
		end
	end

	return sum
end

function print_r ( t )   --这个t是table，可以查看并打印keys里的所有table子类，一般给t传个keys
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

function IsNotLunchbox_ability(ability)  --御币不能充能的技能
    if ability ~= nil then
        if ability:GetName() == "ability_thdots_patchouli_fire"
        or ability:GetName() == "ability_thdots_patchouli_water"
        or ability:GetName() == "ability_thdots_patchouli_wood"
        or ability:GetName() == "ability_thdots_patchouli_metal"
        or ability:GetName() == "ability_thdots_patchouli_earth" 
        or ability:GetName() == "DOTA_Tooltip_ability_ability_thdots_flandrev2_04"
        or ability:GetName() == "DOTA_Tooltip_ability_ability_thdots_flandrev2_05"
		or ability:GetName() == "ability_thdots_kaguya02"
        then return true end
        if ability:IsToggle() or ability:GetAbilityType() == 3 then  --GetAbilityType() == 3 是HIDDEN技能，一般是天生，不触发
            return true
        end
    end
	if ability:ProcsMagicStick() then	-- 不知道为什么不能用否定
		return false
	end
end

function CastRang_Calculate(caster,point,range)
    local distance = (point - caster:GetOrigin()):Length2D()
    if distance >= range then
        distance = range
    end
    return distance
end

-- function DeleteDummy(targets)
--     for i=#targets,1,-1 do
--         if targets[i]:HasModifier("dummy_unit") then
--             table.remove(targets, i)
--         end
--     end
-- end

function DeleteDummy(targets)
    local slow = 1
    for fast = 1, #targets, 1 do
        if not targets[fast]:HasModifier("dummy_unit") then
            targets[slow] = targets[fast]
            slow = slow + 1
        end
    end
    while #targets >= slow do
        table.remove(targets)
    end
end

function DecideMaxRange(caster,point,max_range)
    local targetPoint = point
    local vecCaster = caster:GetOrigin()
    local maxRange = max_range
    local pointRad = GetRadBetweenTwoVec2D(vecCaster,targetPoint)
    if(GetDistanceBetweenTwoVec2D(vecCaster,targetPoint)<=maxRange)then
        return targetPoint
    else
        local blinkVector = Vector(math.cos(pointRad)*maxRange,math.sin(pointRad)*maxRange,0) + vecCaster
        return blinkVector
    end
end

DragonImmuneModifiers = {
	"modifier_item_dragon_star_buff",
	"modifier_meirin02_buff",
}

function CDOTA_BaseNPC:IsDragonImmune()
	for i, modifier in ipairs(DragonImmuneModifiers) do
		if self:HasModifier(modifier) then return true end
	end

	return false
end

function CDOTA_BaseNPC:IsTHDImmune()
	if self:IsDragonImmune() or self:HasModifier("modifier_item_tsundere_invulnerable") then return true end

	return false
end

function IsTHDImmune(target) --THD的魔免BUFF，如龙星，彩光风铃等
    if target:HasModifier("modifier_item_dragon_star_buff") --道具:龙星
        or target:HasModifier("modifier_meirin02_buff") --红美铃：彩光风铃
        or target:HasModifier("modifier_item_tsundere_invulnerable") --亡灵送行提灯
        then 
        return true
    else
        return false
    end
end

function GetAllModifierName(caster)
    print("--------------",caster:GetName(),"modifier list :--------------")
    for i=0,8 do
         if caster:GetModifierNameByIndex(i) ~= "" then
             print(caster:GetModifierNameByIndex(i))
         end
    end
    print("---------------end------------")
end

function GetAllAbilityName(caster)
    print("--------------",caster:GetName(),"ability list :--------------")
     for i=0,17 do 
         if caster:GetAbilityByIndex(i) and caster:GetAbilityByIndex(i) ~= "" then
             print(caster:GetAbilityByIndex(i):GetName())
         end
     end
    print("---------------end------------")
end

function IsTHDReflect(target) --THD的反弹伤害BUG
    if target:HasModifier("modifier_thdots_medicine03_OnTakeDamage") --毒人偶毒
        or target:HasModifier("modifier_item_frock_OnTakeDamage") --毒裙
        or target:HasModifier("OnMerlin04TakeDamage") --小号大
        then 
        return true
    else
        return false
    end
end

function IsNoBugModifier(modifier)
    if modifier ~= nil and modifier:GetName() ~= "" then
        if modifier:GetName() == "modifier_scripted_motion_controller" then
            return false
        end
        if modifier:GetName() == "modifier_skewer_disable_target" 
            or modifier:GetName() == "modifier_skewer_datadriven"
            or modifier:GetName() == "modifier_skewer_disable_caster"
            or modifier:GetName() == "modifier_scripted_motion_controlleris"
            then 
                -- print("-----------------------------------")
                -- print(modifier:GetName().." ：is Bug Modifier")
                -- print(modifier.parsee01)
                -- print("is Bug Modifier")
                return false
        else
            print(modifier:GetName()..":is NO Modifier")
                -- print(modifier.parsee01)
            return true
        end
    end
end

--P点掉落
function OnCollectionDrop(killedUnit,num)
    print("drop power")
    print(num)
    local point = killedUnit:GetOrigin()
    local radius = 250
    local time = 0
    for i=1,num do
        local random_point = Vector(point.x + RandomInt(-radius, radius),point.y + RandomInt(-radius/2, radius),point.z)
        local unit = CreateModifierThinker(
			nil,
			nil,
			"aura_ability_collection_find_master_lua",
			{model = "models/thd2/power.vmdl", name = "npc_power_up_unit"},
			killedUnit:GetOrigin(),
			DOTA_TEAM_NEUTRALS,
			false
		)
        unit.IsGet = false
        unit:SetThink(
				function()
					if GameRules:IsGamePaused() then return 0.03 end
					if time >= 30.0 then
						unit:RemoveSelf()
						return nil
					end
					time = time + 0.2
					return 0.2
				end, 
				"ability_collection_power_remove",
			0)
    end
end

function IsKilledByYugi04(target,damage)
    if target:HasModifier("modifier_thdots_yugi04_think_interval") and damage>=target:GetMaxHealth() then
        return true
    else 
        return false
    end
end

function IsStealableTHD(ability)
    if ability.stealable == true then return true
    else return false
    end
end

-- 表深拷贝
function DepthCloneTable(table)
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        else
            local newTable = {}
            for key, value in pairs(object) do
                newTable[_copy(key)] = _copy(value)
            end
            return newTable
        end
    end
    return _copy(table)
end
-- 伪随机
-- Rolls a Psuedo Random chance. If failed, chances increases, otherwise chances are reset
-- Numbers taken from https://gaming.stackexchange.com/a/290788
function RollPseudoRandom(base_chance, entity)
	local chances_table = {
		{1, 0.015604},
		{2, 0.062009},
		{3, 0.138618},
		{4, 0.244856},
		{5, 0.380166},
		{6, 0.544011},
		{7, 0.735871},
		{8, 0.955242},
		{9, 1.201637},
		{10, 1.474584},
		{11, 1.773627},
		{12, 2.098323},
		{13, 2.448241},
		{14, 2.822965},
		{15, 3.222091},
		{16, 3.645227},
		{17, 4.091991},
		{18, 4.562014},
		{19, 5.054934},
		{20, 5.570404},
		{21, 6.108083},
		{22, 6.667640},
		{23, 7.248754},
		{24, 7.851112},
		{25, 8.474409},
		{26, 9.118346},
		{27, 9.782638},
		{28, 10.467023},
		{29, 11.171176},
		{30, 11.894919},
		{31, 12.637932},
		{32, 13.400086},
		{33, 14.180520},
		{34, 14.981009},
		{35, 15.798310},
		{36, 16.632878},
		{37, 17.490924},
		{38, 18.362465},
		{39, 19.248596},
		{40, 20.154741},
		{41, 21.092003},
		{42, 22.036458},
		{43, 22.989868},
		{44, 23.954015},
		{45, 24.930700},
		{46, 25.987235},
		{47, 27.045294},
		{48, 28.100764},
		{49, 29.155227},
		{50, 30.210303},
		{51, 31.267664},
		{52, 32.329055},
		{53, 33.411996},
		{54, 34.736999},
		{55, 36.039785},
		{56, 37.321683},
		{57, 38.583961},
		{58, 39.827833},
		{59, 41.054464},
		{60, 42.264973},
		{61, 43.460445},
		{62, 44.641928},
		{63, 45.810444},
		{64, 46.966991},
		{65, 48.112548},
		{66, 49.248078},
		{67, 50.746269},
		{68, 52.941176},
		{69, 55.072464},
		{70, 57.142857},
		{71, 59.154930},
		{72, 61.111111},
		{73, 63.013699},
		{74, 64.864865},
		{75, 66.666667},
		{76, 68.421053},
		{77, 70.129870},
		{78, 71.794872},
		{79, 73.417722},
		{80, 75.000000},
		{81, 76.543210},
		{82, 78.048780},
		{83, 79.518072},
		{84, 80.952381},
		{85, 82.352941},
		{86, 83.720930},
		{87, 85.057471},
		{88, 86.363636},
		{89, 87.640449},
		{90, 88.888889},
		{91, 90.109890},
		{92, 91.304348},
		{93, 92.473118},
		{94, 93.617021},
		{95, 94.736842},
		{96, 95.833333},
		{97, 96.907216},
		{98, 97.959184},
		{99, 98.989899},	
		{100, 100}
	}

	entity.pseudoRandomModifier = entity.pseudoRandomModifier or 0
	local prngBase
	for i = 1, #chances_table do
		if base_chance == chances_table[i][1] then		  
			prngBase = chances_table[i][2]
		end
	end

	if not prngBase then
--		print("The chance was not found! Make sure to add it to the table or change the value.")
		return false
	end
	
	if RollPercentage( prngBase + entity.pseudoRandomModifier ) then
		entity.pseudoRandomModifier = 0
		return true
	else
		entity.pseudoRandomModifier = entity.pseudoRandomModifier + prngBase		
		return false
	end
end