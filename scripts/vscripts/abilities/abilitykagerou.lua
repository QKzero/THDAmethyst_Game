
-- 一级能施法 跳跃
ability_thdots_kagerou01 = {}

function ability_thdots_kagerou01:GetCastRange()
	if IsServer() then return 0 end
end

function ability_thdots_kagerou01:OnSpellStart()
	local cs = self:GetCaster()
	local p = self:GetCursorPosition()
	local distance = (p - cs:GetOrigin()):Length2D()
	local ab = self
	local cast_range = ab:GetSpecialValueFor("cast_range")
	local radius = ab:GetSpecialValueFor("damage_radius")
	local damage = ab:GetSpecialValueFor("damage_const")
	local ratio = ab:GetSpecialValueFor("damage_ratio")
	local speed = 1600
	local bf = cs:AddNewModifier(cs, ab, "modifier_kagerou_moving", {Duration = 2}) --临时buff

	if distance >= cast_range then
		p = cs:GetOrigin() + cs:GetForwardVector() * cast_range
	end

	--移动完成后调用
	bf.success = function ()
		local step_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_jump_stomp.vpcf",PATTACH_WORLDORIGIN,nil)
		ParticleManager:SetParticleControl(step_particle, 0, cs:GetOrigin())
		ParticleManager:SetParticleControl(step_particle, 1, cs:GetOrigin())
		ParticleManager:ReleaseParticleIndex(step_particle)
		ParticleManager:DestroyParticleSystem(step_particle,false)
		EmitSoundOn("Hero_MonkeyKing.Spring.Target", cs)

		--天生强化 刷新技能
		if cs:HasModifier("modifier_kagerou_lonely2") then
			cs:RemoveModifierByName("modifier_kagerou_lonely2")
			ab:EndCooldown()
		end

		local targets = FindUnitsInRadius(cs:GetTeam(), cs:GetOrigin(), nil, radius,
			ab:GetAbilityTargetTeam(), ab:GetAbilityTargetType(), 0,0,false)

		each(targets,function (t)
			UnitDamageTarget({
				victim = t, attacker = cs, damage = damage + cs:GetAgility() * ratio,
				damage_type = getDamageType(), damage_flags = getDamageFlags()
			})
		end)
	end

	bf.p = p --目标点
	bf.tg = cs --移动单位
	bf.len = speed * 0.02 --每次移动距离
	bf.current = 0 --已经移动的距离
	bf.total = getDistance(cs:GetAbsOrigin(),p) --总移动距离
	bf.baseHigh = cs:GetAbsOrigin().z --起始高度
	bf.high = 200

	bf:StartIntervalThink(0.02)
end

function A1Start(k)
	local cs = k.caster
	local p = k.target_points[1]
	local distance = (p - cs:GetOrigin()):Length2D()
	local ab = k.ability
	local cast_range = ab:GetSpecialValueFor("cast_range")
	local radius = ab:GetSpecialValueFor("damage_radius")
	local damage = ab:GetSpecialValueFor("damage_const")
	local ratio = ab:GetSpecialValueFor("damage_ratio")
	local speed = 1600
	local bf = cs:AddNewModifier(cs, ab, "modifier_kagerou_moving", {Duration = 2}) --临时buff

	if distance >= cast_range then
		p = cs:GetOrigin() + cs:GetForwardVector() * cast_range
	end

	--移动完成后调用
	bf.success = function ()
		local step_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_jump_stomp.vpcf",PATTACH_WORLDORIGIN,nil)
		ParticleManager:SetParticleControl(step_particle, 0, cs:GetOrigin())
		ParticleManager:SetParticleControl(step_particle, 1, cs:GetOrigin())
		ParticleManager:ReleaseParticleIndex(step_particle)
		ParticleManager:DestroyParticleSystem(step_particle,false)
		EmitSoundOn("Hero_MonkeyKing.Spring.Target", cs)

		--天生强化 刷新技能
		if cs:HasModifier("modifier_kagerou_lonely2") then
			cs:RemoveModifierByName("modifier_kagerou_lonely2")
			ab:EndCooldown()
		end

		local targets = FindUnitsInRadius(cs:GetTeam(), cs:GetOrigin(), nil, radius,
			ab:GetAbilityTargetTeam(), ab:GetAbilityTargetType(), 0,0,false)

		each(targets,function (t)
			UnitDamageTarget({
				victim = t, attacker = cs, damage = damage + cs:GetAgility() * ratio,
				damage_type = getDamageType(), damage_flags = getDamageFlags()
			})
		end)
	end

	bf.p = p --目标点
	bf.tg = cs --移动单位
	bf.len = speed * 0.02 --每次移动距离
	bf.current = 0 --已经移动的距离
	bf.total = getDistance(cs:GetAbsOrigin(),p) --总移动距离
	bf.baseHigh = cs:GetAbsOrigin().z --起始高度
	bf.high = 200

	bf:StartIntervalThink(0.02)

end

-- 二技能施法
function A2Start(k)
	local cs = k.caster
	local ab = k.ability
	local len = ab:GetSpecialValueFor("len")
	local len_up = ab:GetSpecialValueFor("len_up")
	local width = ab:GetSpecialValueFor("width")
	local width_up = ab:GetSpecialValueFor("width_up")
	local speed = ab:GetSpecialValueFor("speed");

	--天生强化 长度宽度
	--使用变量的原因：这个buff的触发是在伤害的时候，由于是弹道技能，释放技能不能马上触发buff，但是独孤强化效果必须马上移除（如果不马上移除，也会强化其他技能）
	cs.lonely2 = false
	if cs:HasModifier("modifier_kagerou_lonely2") then
		cs:RemoveModifierByName("modifier_kagerou_lonely2")
		cs.lonely2 = true
		len = len_up; width = width_up;
	end

	local direction = cs:GetForwardVector()
	local selfOrigin = cs:GetAbsOrigin()

	function launch (direction) -- 释放在不同的角度
		launch0({
			cs = cs,ab = ab,len = len,origin = selfOrigin,width = width,speed = speed,direction = direction
		})
	end

	launch(direction)
	EmitSoundOn("Hero_VengefulSpirit.WaveOfTerror", cs)

	--万宝槌额外发射
	if cs:HasModifier("modifier_item_wanbaochui") then
		launch(getAngleVector(direction,15))
		launch(getAngleVector(direction,-15))
	end

end

--二技能投射物 碰撞目标
function A2Hit(k)
	local cs = k.caster
	local tg = k.target
	local ab = k.ability
	local damage = ab:GetSpecialValueFor("damage_const")
	local ratio = ab:GetSpecialValueFor("damage_ratio")
	local len = ab:GetSpecialValueFor("len")
	local len_up = ab:GetSpecialValueFor("len_up")
	local width = ab:GetSpecialValueFor("width")
	local width_up = ab:GetSpecialValueFor("width_up")
	local reduceMin = ab:GetSpecialValueFor("reduce_min") * 0.01 --最小受到伤害比例
	local reduceVal = 1 - ab:GetSpecialValueFor("reduce") * 0.01 --每次递减伤害比例
	local speed = ab:GetSpecialValueFor("speed");

	--天生强化 减速效果
	if cs.lonely2 then
		len = len_up; width = width_up
		ab:ApplyDataDrivenModifier(cs,tg,"modifier_ability_thdots_kagerou02_slow",{})
	end

	--多次受伤 伤害减免层数计算
	local reduce = tg:FindModifierByName("modifier_ability_thdots_kagerou02_reduce")
	if reduce == nil then
		ab:ApplyDataDrivenModifier(cs,tg,"modifier_ability_thdots_kagerou02_reduce",{}) --首次受伤 添加buff
		reduce = tg:FindModifierByName("modifier_ability_thdots_kagerou02_reduce")
	end

	--计算承受伤害比例
	local reduceRatio = math.pow(reduceVal,reduce:GetStackCount());

	--最小伤害
	if reduceRatio < reduceMin then reduceRatio = reduceMin end
	print("----------------")
	print("reduceMin is :",reduceMin)
	print("reduceVal is :",reduceVal)
	print("reduce:GetStackCount() is :",reduce:GetStackCount())

	damage = reduceRatio * (damage + cs:GetAgility() * ratio)
	print("reduceRatio is :",reduceRatio)
	print("cs:GetAgility() is :",cs:GetAgility())
	print("damage is ",damage)
	print("ratio is ",ratio)

	local damage_table = {
		victim = tg, attacker = cs, damage = damage, damage_type = getDamageType(), damage_flags = getDamageFlags()
	}

	UnitDamageTarget(damage_table)

	--增加层数 刷新时间
	reduce:IncrementStackCount(); reduce:SetDuration(1,true)

	--天赋 造成伤害后有概率随即角度再次释放
	if RandomInt(1,100) <= FindTelentValue(cs,"special_bonus_unique_kagerou_4") then
		if not tg or tg:IsNull() or tg:GetUnitName() == "npc_ability_parsee03_dummy" then return end
		launch0({
			cs = cs,ab = ab,len = len,origin = tg:GetOrigin(),width = width,speed = speed
			,direction = angleToVector(RandomInt(0,360))
		})
	end

end

--二技能投射物 到达终点
function A2End(k)
	local cs = k.caster
	local tg = k.target
	local ab = k.ability
	local p = k.target_points[1]

	-- local back = FindTelentValue(caster,"special_bonus_unique_kagerou_2")

	--天赋 技能到达终点后 立即返回施法者身边
	--150码内能找到施法者 就说明返回成功
	if FindTelentValue(cs,"special_bonus_unique_kagerou_2") == 0 or cs:IsPositionInRange(p,150) then return end

	local damage = ab:GetSpecialValueFor("damage_const")
	local ratio = ab:GetSpecialValueFor("damage_ratio")
	local width = ab:GetSpecialValueFor("width")
	local width_up = ab:GetSpecialValueFor("width_up")
	local speed = 3200;
	if cs.lonely2 then --距离已经固定 如果是天生化状态 提升宽度
		width = width_up;
	end

	local selfOrigin = cs:GetOrigin()

	launch0({
		cs = cs,ab = ab,len = getDistance(p,selfOrigin),origin = p,width = width,speed = speed
		,direction = getAngleVector(Vector(0,0,0),getAngleByPos(p,selfOrigin))
	})

end

--二技能升级回调,获得被动
function A2Passive(k)
	k.caster:SetContextThink("kagerou02_addPassive",
		function ()
			if GameRules:IsGamePaused() then return 0.03 end
			if not k.caster:HasModifier("modifier_kagerou_add_damage") and k.caster:FindAbilityByName("ability_thdots_kagerou02"):GetLevel() ~= 0 then
				print(k.caster:FindAbilityByName("ability_thdots_kagerou02"):GetLevel())
				k.caster:AddNewModifier(k.caster,k.ability,"modifier_kagerou_add_damage",{})
		    end
		end
		, 
    	0.03)
end

--三技能施法 变身
function A3Start(k)
	local cs = k.caster
	local ab = k.ability
	ab.first = true
	if cs:HasModifier("modifier_kagerou_lonely2") then
		cs:RemoveModifierByName("modifier_kagerou_lonely2")
		local ratio =  ab:GetSpecialValueFor("health_ratio")
		local const = ab:GetSpecialValueFor("health_val")
		local heal = cs:GetMaxHealth() * ratio/100 + const
		cs:Heal(heal,cs)
		SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,cs,heal,nil)
	end

	--天赋强化
	if FindTelentValue(cs,"special_bonus_unique_kagerou_3") ~= 0  then
		ab:ApplyDataDrivenModifier(cs,cs,"modifier_ability_thdots_kagerou03_up",{})
	end

	EmitSoundOn("Hero_Lycan.Howl",cs)
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_lycan/lycan_shapeshift_cast.vpcf",PATTACH_ROOTBONE_FOLLOW,cs)
	ParticleManager:ReleaseParticleIndex(particle)
	ParticleManager:DestroyParticleSystemTime(particle,false)

	if not cs.originalModel then cs.originalModel = cs:GetModelName() end

	local wolfModel = "models/items/lycan/ultimate/blood_moon_hunter_shapeshift_form/blood_moon_hunter_shapeshift_form.vmdl"
	cs:SetOriginalModel(wolfModel)
	cs:SetModelScale(1)
	cs:ManageModelChanges()



end

--变身后首次攻击直接触发被动
function A3FirstAtt(k)
	local cs = k.caster
	local ab = k.ability
	local t = k.target
	if ab.first then
		k.first = true
		local modifier = cs:FindModifierByName("modifier_ability_thdots_kagerou03")
		modifier:SetStackCount(1)
		A3PassiveTrig(k)
		ab.first = false
		k.first = false --防止首次攻击回复两次生命值
	end
end

--变身结束
function A3End(k)
	local cs = k.caster
	cs:SetOriginalModel(cs.originalModel)
	cs:SetModelScale(1.2)
	cs:ManageModelChanges()
end

-- 三技能的被动动画
function A3PassiveStart(keys)
	local caster = keys.caster
	local modifier = caster:FindModifierByName("modifier_ability_thdots_kagerou03")
	modifier:SetStackCount(1)
	if not caster:HasModifier("modifier_ability_thdots_kagerou03_wolf") then
		caster:StartGestureWithPlaybackRate(ACT_DOTA_CAST_ABILITY_5,caster:GetDisplayAttackSpeed()/170)
	end
end
-- 三技能的被动效果触发
function A3PassiveTrig(k)
	local cs = k.caster
	local ab = k.ability
	local t = k.target

	print("do it")
	local modifier = cs:FindModifierByName("modifier_ability_thdots_kagerou03")
	if modifier:GetStackCount() ~= 1 then return end
	print("2222222222222222")
	modifier:SetStackCount(0)

	local heal = ab:GetSpecialValueFor("health_regen")
	local ratio =  ab:GetSpecialValueFor("health_ratio")
	local const = ab:GetSpecialValueFor("health_val")
	local stun_time = ab:GetSpecialValueFor("stun_time")
	if ab.first and not k.first then return end --防止首次攻击回复两次生命值
	if not t:IsTower() and not t:IsBuilding() then
		UtilStun:UnitStunTarget( cs,t,stun_time)--击晕目标
		cs:EmitSound("Voice_Thdots_Kagerou.AbilityKagerou03")
	end
	--天生强化 触发三技能攻击特效时回复生命值
	if cs:HasModifier("modifier_ability_thdots_kagerou03_wolf") then
		cs:Heal(heal,cs)
		SendOverheadEventMessage(nil,OVERHEAD_ALERT_HEAL,cs,heal,nil)
	end
end

--被动技能检测回调
function A4OnInterval(k)
	local ab =  k.ability
	local cs =  k.caster
	local radius = ab:GetSpecialValueFor("trig_radius")
	local trigTime = ab:GetSpecialValueFor("trig_time")
	if FindTelentValue(cs,"special_bonus_unique_kagerou_1") ~= 0 then
		trigTime = trigTime-1.5
	end
	-- GetAllModifierName(cs)
	-- --检测白天黑夜，更换模型
	-- if not cs:HasModifier("modifier_ability_thdots_kagerou03_wolf") and cs:GetName() == "npc_dota_hero_lycan" then
	-- 	if GameRules:IsDaytime() then
	-- 		cs:SetModel("models/kagerou/kagerou.vmdl")
	-- 		cs:SetOriginalModel("models/kagerou/kagerou.vmdl")
	-- 	else
	-- 		cs:SetModel("models/kagerou2/kagerou2.vmdl")
	-- 		cs:SetOriginalModel("models/kagerou2/kagerou2.vmdl")
	-- 	end
	-- end

	--周围的友方单位
	local units = FindUnitsInRadius(cs:GetTeam(), cs:GetOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		ab:GetAbilityTargetType(), 0,0,false)
	--判断周围有没有除了自己的友方单位
	local exists = false
	for _,v in pairs(units) do
		if v:IsRealHero() and v ~= cs then
			exists = true
		end
	end
	-- if #units >= 2 then
	-- 	exists = true
	-- end

	ab.time = ab.time or 0.0

	if exists then
		ab.time = 0.0 --有友方单位，计时清空
	else
		ab.time = ab.time + 0.02 --没有友方单位，增加计时时间
	end

	local lonely = ab.time >= trigTime --独孤效果激活与否

	ab:SetActivated(lonely) -- 主动效果 可用/不可用


	--添加/移除 buff
	if lonely then
		--天赋强化
		-- print(FindTelentValue(cs,"special_bonus_unique_kagerou_1"))
		if FindTelentValue(cs,"special_bonus_unique_kagerou_1") ~= 0 and not cs:HasModifier("modifier_ability_thdots_kagerouEx_up")  then
			print("args")
			ab:ApplyDataDrivenModifier(cs,cs,"modifier_ability_thdots_kagerouEx_up",{})
		end
		if not cs:HasModifier("modifier_kagerou_lonely") then
			ab:ApplyDataDrivenModifier(cs,cs,"modifier_kagerou_lonely",{})
		end
	else
		if cs:HasModifier("modifier_kagerou_lonely") then
			cs:RemoveModifierByName("modifier_kagerou_lonely")
		end
	end

end


-- 大招施法 跳跃
function A6Start(k)
	local cs = k.caster
	local p = k.target_points[1]
	local ab = k.ability
	local radius = ab:GetSpecialValueFor("damage_radius")
	local damage = ab:GetSpecialValueFor("damage_const")
	local ratio = ab:GetSpecialValueFor("damage_ratio")
	local stunTime = ab:GetSpecialValueFor("stun_time")
	local delayTime = ab:GetSpecialValueFor("delay_time")
	local len = ab:GetSpecialValueFor("len")
	local vector_distance = p - cs:GetAbsOrigin()
	local direction = (vector_distance):Normalized()
	local speed = 2400

	cs:EmitSound("Voice_Thdots_Kagerou.AbilityKagerou04")
	--天生强化 距离翻倍
	if cs:HasModifier("modifier_kagerou_lonely2") then
		cs:RemoveModifierByName("modifier_kagerou_lonely2")
		len = len * 2
	end

	local bf = cs:AddNewModifier(cs, ab, "modifier_kagerou_moving", {Duration = 2}) --临时buff
	local selfOrigin = cs:GetAbsOrigin()
	bf.p = selfOrigin + cs:GetForwardVector() * len --目标点
	bf.tg = cs --移动单位
	bf.len = speed * 0.02 --每次移动距离
	bf.current = 0 --已经移动的距离
	bf.total = len --总移动距离
	bf.baseHigh = selfOrigin.z --起始高度
	bf.high = 0

	local name = "particles/econ/items/slark/slark_ti6_blade/slark_ti6_pounce_trail.vpcf"
	local particle = ParticleManager:CreateParticle(name, PATTACH_ABSORIGIN_FOLLOW, cs)
	ParticleManager:ReleaseParticleIndex(particle)
	ParticleManager:DestroyParticleSystem(particle,false)

	--每次位移调用，判断是否有敌人可以被抓住
	bf.callback = function ()
		local units = FindUnitsInLine(
	      	cs:GetTeam(),
	      	cs:GetOrigin(),
	      	cs:GetAbsOrigin() + 10 * direction,
	      	nil,
	      	radius,
	      	ab:GetAbilityTargetTeam(),
	      	DOTA_UNIT_TARGET_HERO,
	      	0)
		-- local units = FindUnitsInRadius(cs:GetTeam(), cs:GetOrigin(), nil, radius, ab:GetAbilityTargetTeam(),
		-- 	DOTA_UNIT_TARGET_HERO, 0,0,false)
		--DOTA_UNIT_TARGET_HERO
		--ab:GetAbilityTargetType()
		local t = units[1]

		if t == nil then return end

		--已经抓住敌人

		EmitSoundOn("Hero_LifeStealer.Consume.Layer", cs)

		partic0(t:GetOrigin(),"particles/econ/items/elder_titan/elder_titan_ti7/elder_titan_echo_stomp_cast_combined_detail_ti7.vpcf")

		local selfOrigin = cs:GetOrigin()
		local targetOrigin = t:GetOrigin()
		cs.z = selfOrigin.z
		t.z = targetOrigin.z
		t.cz = targetOrigin.z

		cs:RemoveModifierByName("modifier_kagerou_moving")
		ab.time = 0.0
		ab.angle = getAngleByPos(selfOrigin,targetOrigin)
		ab:ApplyDataDrivenModifier(cs,t,"modifier_ability_thdots_kagerou06",{})
		ab:ApplyDataDrivenModifier(cs,cs,"modifier_ability_thdots_kagerou06_self",{})

	end

	--移动完成后调用 （没有抓住任何敌人）
	bf.success = function ()

		if cs:HasModifier("modifier_ability_thdots_kagerou06_self") then return end

		local localOrigin = cs:GetAbsOrigin()

		local a = angleToVector(getAngleByPos(selfOrigin,localOrigin))

		local len = getDistance(selfOrigin,localOrigin)


		cs:SetContextThink(DoUniqueString("A6End"), function ()

			EmitSoundOn("Hero_Centaur.DoubleEdge.TI9", cs)
			for i = 1,4 do
				cs:SetContextThink(DoUniqueString("0"), function ()
					EmitSoundOn("Hero_Centaur.DoubleEdge.TI9", cs)
				end,0.1 * i)
			end

			--施加特效
			local name = "particles/econ/items/shadow_fiend/sf_desolation/sf_rze_dso_scratch.vpcf"
			partic(selfOrigin,localOrigin,name,75,0.5,cs) --在0.5秒内 以75码的间隔连续部署特效

			local units = FindUnitsInLine(cs:GetTeam(), selfOrigin, localOrigin, cs, radius,
				ab:GetAbilityTargetTeam(), ab:GetAbilityTargetType(), ab:GetAbilityTargetFlags())

			each(units,function (t)
				UnitDamageTarget({
					victim = t, attacker = cs, damage = damage + cs:GetAgility() * ratio,
					damage_type = getDamageType(), damage_flags = getDamageFlags()
				})
			end)

		end,delayTime)
	end

	bf:StartIntervalThink(0.02)

end

-- 大招命中
function A6OnInterval(k)

	local ab = k.ability
	local t = k.target
	local cs = k.caster
	local stunTime = ab:GetSpecialValueFor("stun_time")

	if not t:HasModifier("modifier_ability_thdots_kagerou06") or not cs:IsAlive()
	then return end

	ab:ApplyDataDrivenModifier(cs,cs,"modifier_ability_thdots_kagerou06_invulnerable",{})

	ab.time = ab.time + 0.01

	local p = t:GetOrigin()
	local tp = p + angleToVector(ab.angle) * 150 --在目标周围旋转
	ab.angle = ab.angle + 5

	tp.z = cs.z + 200 -- 固定自己的高度
	cs:SetOrigin(tp)

	if ab.time <= 0.75 then --敌人的高度 先上后下
		t.z = t.z + 4
	else
		t.z = t.z - 4
	end

	p.z = t.z

	t:SetOrigin(p)

	local srcAngle = cs:GetAngles()
	cs:SetAngles(srcAngle.x,getAngleByPos(cs:GetOrigin(),p),srcAngle.z) --使自己的方向朝向敌人


	if ab.time > stunTime then --杜绝卡位
		cs:AddNewModifier(cs, ab, "modifier_kagerou_moving", {Duration = 0.1})
		t:AddNewModifier(cs, ab, "modifier_kagerou_moving", {Duration = 0.1})
	end

end

-- 大招命中 技能效果结束
function A6End(k)

	local cs = k.caster
	local ab = k.ability
	local t = k.target
	local damage = ab:GetSpecialValueFor("damage_const")
	local ratio = ab:GetSpecialValueFor("damage_ratio")
	local stunTime = ab:GetSpecialValueFor("stun_time")

	--确保双方的高度可以被还原
	local to = t:GetOrigin()
	local co = cs:GetOrigin()
	t:SetOrigin(Vector(to.x,to.y,t.z))
	cs:SetOrigin(Vector(co.x,co.y,cs.z))

	cs:RemoveModifierByName("modifier_ability_thdots_kagerou06_self")
	cs:RemoveModifierByName("modifier_ability_thdots_kagerou06_invulnerable")

	if ab.time < stunTime - 0.1 then return end --目标被控制效果已经被驱散

	local particle = ParticleManager:CreateParticle("particles/econ/items/elder_titan/elder_titan_ti7/elder_titan_echo_stomp_ti7_ring_wave.vpcf", PATTACH_ROOTBONE_FOLLOW, t)
	ParticleManager:ReleaseParticleIndex(particle)
	ParticleManager:DestroyParticleSystem(particle,false)
	EmitSoundOn("Hero_ElderTitan.EchoStomp.ti7", cs)
	UnitDamageTarget({
		victim = t, attacker = cs, damage = damage + cs:GetAgility() * ratio,
		damage_type = getDamageType(), damage_flags = getDamageFlags()
	})

end

--################################  工具函數 begin

-- 迭代table 遍历集合类table时不需要索引，所以k放在第二个参数，回调函数省略第二个参数即可
function each(list,cb)
	for k,v in pairs(list) do
		cb(v,k)
	end
end

-- 一点到另一点之间一段距离的点 args - L:一段距离
function GetPoint(p2,p1,L)
	return {
		x = L * (p1.x - p2.x) / math.sqrt( math.pow(p1.y - p2.y,2) + math.pow(p1.x - p2.x,2) ) + p2.x,
		y = L * (p1.y - p2.y) / math.sqrt( math.pow(p1.y - p2.y,2) + math.pow(p1.x - p2.x,2) ) + p2.y,
	}
end

--两点间的距离
function getDistance(p1,p2)
	return math.sqrt(math.pow((p2.y-p1.y),2)+math.pow((p2.x-p1.x),2))
end

--p2相对p1的方向 （角度）
function getAngleByPos(p1,p2)
	local p = {}
	p.x = p2.x - p1.x
	p.y = p2.y - p1.y

	local angle = math.atan2(p.y,p.x)*180/math.pi
	return angle
end

--角度转方向向量 （平面）
function angleToVector(angle)
	return getAngleVector(Vector(0,0,0),angle)
end

--计算一个 方向向量 偏移角度 后 的结果
function getAngleVector(v,angle)
	local radian = (VectorToAngles(v).y + angle) * math.pi/180.0
	local x = math.cos(radian)
	local y = math.sin(radian)
	return Vector(x,y,v.z)
end

-- 向目标点移动一段距离 args - e1:移动者 p2:目标点 len:移动的距离 h高度
function Move(e1,p2,len,h)
	p1 = e1:GetAbsOrigin()
	p = GetPoint(p1,p2,len)
	p1.z = h or p1.z
	e1:SetAbsOrigin(Vector(p.x,p.y,p1.z))
end

-- 判断是否到达目标终点 args - offset 距离目标点可接受范围
function IsMoveEnd(p1,p2,offset)
	return getDistance(p1,p2) <= offset
end

--白天返回魔法伤害 晚上返回物理伤害
function getDamageType()
	if GameRules:IsDaytime() then
		return DAMAGE_TYPE_MAGICAL
	else
		return DAMAGE_TYPE_PHYSICAL
	end
end

--白天返回0 晚上返回无视格挡
function getDamageFlags()
	if GameRules:IsDaytime() then
		return 0
	else
		return DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
	end
end

-- 在两点之间释放一个特效多次 space:间隔 time:开启延迟释放，time为总时间
function partic(p1,p2,name,space,time,cs)

		local a = angleToVector(getAngleByPos(p1,p2))
		local len = getDistance(p1,p2)

		local count = len / space

		for i = 1,count do
			if not time or time == 0 then
				partic0(p1 + a * space * i,name)
			else
				cs:SetContextThink(DoUniqueString("0"), function ()
					partic0(p1 + a * space * i,name)
				end,time / count * i)
			end
		end

end
--在指定点 施加特效
function partic0(p,name)
	local id = ParticleManager:CreateParticle(name, PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(id, 0, p)
	ParticleManager:ReleaseParticleIndex(id)
	ParticleManager:DestroyParticleSystemTime(id,2)
end

--释放投射物
function launch0 (t)
	ProjectileManager:CreateLinearProjectile({
		Ability = t.ab,
		EffectName = "particles/econ/items/vengeful/vengeful_weapon_talon/vengeful_wave_of_terror_weapon_talon.vpcf",
		vSpawnOrigin = t.origin, --起始位置
		fDistance = t.len, -- 射程
		fStartRadius = t.width, -- 起始宽度
		fEndRadius = t.width, -- 结束宽度
		Source = t.cs,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		fExpireTime = GameRules:GetGameTime() + 2.0, -- 最多持续时间
		bDeleteOnHit = false,
		vVelocity = t.direction * t.speed, -- 射速
		bProvidesVision = true,
		iVisionRadius = 300, -- 开视野范围
		iVisionTeamNumber = t.cs:GetTeamNumber()
	})
end
--################################  工具函數 end

--################################  modifier begin
modifier_kagerou_moving = class({})
LinkLuaModifier("modifier_kagerou_moving", "scripts/vscripts/abilities//abilitykagerou.lua", LUA_MODIFIER_MOTION_NONE) --移动buff
function modifier_kagerou_moving:IsHidden() 		return true end
function modifier_kagerou_moving:IsPurgable()		return false end
function modifier_kagerou_moving:RemoveOnDeath() 	return false end
function modifier_kagerou_moving:IsDebuff()		return false end

modifier_kagerou_add_damage = class({})
LinkLuaModifier("modifier_kagerou_add_damage", "scripts/vscripts/abilities/abilitykagerou.lua", LUA_MODIFIER_MOTION_NONE) --二技能被动攻击力buff
function modifier_kagerou_add_damage:IsHidden() 		return false end
function modifier_kagerou_add_damage:IsPurgable()		return false end
function modifier_kagerou_add_damage:RemoveOnDeath() 	return false end
function modifier_kagerou_add_damage:IsDebuff()		return false end


--相位移动，防止与其他单位重叠卡死 （因为相位移动效果在释放的时候会解除卡位）
function modifier_kagerou_moving:CheckState()
	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

--每次位移回调函数
function modifier_kagerou_moving:OnIntervalThink()
	local this = self
	local len = this.len
	local tg = this.tg
	local p1 = tg:GetOrigin()
	local p2 = this.p
	local total = this.total
	local highLimit = this.high

	if not tg:HasModifier("modifier_kagerou_moving") then return end

	if this.callback ~= nil then this.callback() end

	if this.current < total then
		local high = (0.5 - math.abs(self.current / total - 0.5)) * highLimit
		Move(tg,p2,len,this.baseHigh + high)
		this.current = this.current + len
	else
		Move(tg,p2,0,nil)
		tg:RemoveModifierByName("modifier_kagerou_moving") --移除目标身上移动buff
		if this.success ~= nil then this.success() end
	end
end

function modifier_kagerou_add_damage:DeclareFunctions()
	return {
	--	MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,--攻击力
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,--敏捷
	}
end

--攻击力buff
function modifier_kagerou_add_damage:GetModifierPreAttack_BonusDamage()
	local damage = self:GetAbility():GetSpecialValueFor("add_damage")

	if self:GetCaster():HasModifier("modifier_kagerou_lonely") then
		damage = damage * 2
	end

	return damage
end
function modifier_kagerou_add_damage:GetModifierBonusStats_Agility()
	local damage = self:GetAbility():GetSpecialValueFor("add_damage")

	if self:GetCaster():HasModifier("modifier_kagerou_lonely") then
		damage = damage * 2
	end

	return damage
end

--################################  modifier end