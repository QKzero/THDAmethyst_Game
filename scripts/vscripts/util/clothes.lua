
Hero_Cloth = 
{
	["npc_dota_hero_visage"] =	--小爱
		{	
			"models/alice/alice.vmdl",
			"models/alice_cloth01/alice_cloth01.vmdl"
		},

	["npc_dota_hero_visage_size"] =	--对应尺寸
		{	
			1.2,
			1.2
		},

	["npc_dota_hero_obsidian_destroyer"] =	--紫
		{	
			"models/new_touhou_model/yukari/yukari.vmdl",
			"models/thd2/yukari/yukari_mmd.vmdl"
		},

	["npc_dota_hero_obsidian_destroyer_size"] =
		{	
			0.95,
			1.0
		},

	["npc_dota_hero_crystal_maiden"] = --黑白
		{	
			"models/new_touhou_model/marisa/marisa.vmdl",
			"models/thd2/marisa/marisa_mmd.vmdl"
		},

	["npc_dota_hero_crystal_maiden_size"] =
		{	
			1.15,
			0.95
		},

	["npc_dota_hero_juggernaut"] = --妖梦
		{	
			"models/new_touhou_model/youmu/youmu.vmdl",
			"models/thd2/youmu/youmu_mmd.vmdl"
		},

	["npc_dota_hero_juggernaut_size"] =
		{	
			1.2,
			1.0
		},

	["npc_dota_hero_slark"] = --文
		{	
			"models/new_touhou_model/aya/aya.vmdl",
		},

	["npc_dota_hero_slark_size"] =
		{	
			1.15,
		},

	["npc_dota_hero_earthshaker"] = --天子
		{	
			"models/new_touhou_model/tenshi/tenshi.vmdl",
			"models/thd2/tenshi/tenshi_mmd.vmdl"
		},

	["npc_dota_hero_earthshaker_size"] =
		{	
			1.2,
			1.0
		},

	["npc_dota_hero_templar_assassin"] = --16
		{	
			"models/new_touhou_model/sakuya/sakuya.vmdl",
			"models/thd2/sakuya/sakuya_mmd.vmdl"
		},

	["npc_dota_hero_templar_assassin_size"] =
		{	
			1.15,
			1.0
		},
	["npc_dota_hero_naga_siren"] = --二妹
		{	
			"models/thd2/flandre/flandre_mmd.vmdl",
			"models/flandre_scarlet_skin4/flandre_scarlet_skin4.vmdl",
			"models/flandre_scarlet_skin5/flandre_scarlet_skin5.vmdl",
			"models/flandrev2/flandrev2.vmdl",
			--"models/flandre_scarlet_skin3/flandre_scarlet_skin3.vmdl",
			--"models/flandre_scarlet/flandre_scarlet.vmdl",
		},

	["npc_dota_hero_naga_siren_size"] =
		{	
			0.9,
			1.3,
			1.3,
			1.25,
			--1.3,
			--1.0,
		},
	["npc_dota_hero_warlock"] = --大妹
		{	
			"models/remilia/remilia.vmdl",
			"models/thd2/remilia/remilia_mmd.vmdl"
		},

	["npc_dota_hero_warlock_size"] =
		{	
			1.2,
			1.0
		},
	["npc_dota_hero_life_stealer"] =
	     {
	     	"models/thd2/rumia/rumia_mmd.vmdl",
	     	"models/exrumia/exrumia.vmdl",
	     },
    ["npc_dota_hero_life_stealer_size"] =
        {
           1.0,
           1.3,
        },
	["npc_dota_hero_axe"] = --9
	     {
	     	"models/thd2/chiruno/chiruno_mmd.vmdl",
	     	"models/cirno2/cirno2.vmdl",
	     },
    ["npc_dota_hero_axe_size"] =
        {
           1.0,
           0.9,
        },
	["npc_dota_hero_centaur"] =
	     {
	     	"models/thd2/yuugi/yuugi_mmd.vmdl",
	     	"models/hoshiguma/hoshiguma.vmdl",
	     },
    ["npc_dota_hero_centaur_size"] =
        {
           0.8,
           1.25,
        },
	["npc_dota_hero_mirana"] = --大兔
		{
			"models/reisen/reisen.vmdl",
			"models/reisen/reisen_new.vmdl",
		},
   	["npc_dota_hero_mirana_size"] =
	   {
		  0.75,
		  1.1,
	   },
	["npc_dota_hero_bloodseeker"] =	-- 胡桃
	   {
			"models/kurumi/kurumi.vmdl",
			"models/kurumi/kurumi.vmdl",
	   },
	["npc_dota_hero_bloodseeker_material"] = -- 材质组
		{
			"default",		-- 材质名1
			"mesh02",		-- 材质名2
		},
}

function add_cloth( heroname, model, scale, cloth_id, material )
	if cloth_id == nil then
		if Hero_Cloth[heroname] == nil then
			Hero_Cloth[heroname] = {}
			cloth_id = 1
		else 
			for i=1,99 do
				if Hero_Cloth[heroname][i] == nil then
					cloth_id = i
					break
				end
			end
		end
	end

	Hero_Cloth[heroname][cloth_id] = model
	if scale ~= nil then
		Hero_Cloth[heroname..'_size'][cloth_id] = scale
	end
	if material ~= nil then
		Hero_Cloth[heroname..'_material'][cloth_id] = material
	end
end

function update_cloth( G_Player_Cloth, plyid, cloth_id )
	local hero = PlayerResource:GetPlayer(plyid):GetAssignedHero()
	local classname = hero:GetClassname()

	if Hero_Cloth[classname] == nil then return end

	-- 模型
	if Hero_Cloth[classname][cloth_id] ~= nil then
		hero:SetModel(Hero_Cloth[classname][cloth_id])
		hero:SetOriginalModel(Hero_Cloth[classname][cloth_id])
	end
	-- 模型缩放
	if Hero_Cloth[classname..'_size'] ~= nil
		and Hero_Cloth[classname..'_size'][cloth_id] ~= nil then

		hero:SetModelScale(Hero_Cloth[classname..'_size'][cloth_id])
	end
	-- 材质组
	if Hero_Cloth[classname..'_material'] ~= nil
		and Hero_Cloth[classname..'_material'][cloth_id] ~= nil then

		hero:SetMaterialGroup(Hero_Cloth[classname..'_material'][cloth_id])
	end

	G_Player_Cloth[plyid + 1] = cloth_id
end