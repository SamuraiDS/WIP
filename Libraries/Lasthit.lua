require("libs.Utils")
require("libs.Animations")
require("libs.HeroInfo")
--[[
                             ___
                            ( ((
                             ) ))              
  .::.   LASTHIT LIBRARY    / /(   MADE BY MOONES      
 'M .-;-.-.-.-.-.-.-.-.-.-/| ((:::::::::::::::::::::::::::::::::::::::::::::.._
(O ( ( ( ( ( ( ( ( ( ( ( ( |  ))   -===========VERSION 1.0.0===========-      _.>
 `M `-;-`-`-`-`-`-`-`-`-`-\| ((::::::::::::::::::::::::::::::::::::::::::::::''
  `::'                      \ \(
        Description:         ) ))
        ------------        (_((                           		 
        
         Lasthit.GetLastHit(hero) - Use this in your script when your hero is able to attack. It will execute attack command to a creep which can be lasthitted by your hero.
		 
        Changelog:
        ----------
		
		 VERSION 1.0.0 - asdfghjklqwertzuiop. Fixed yxcvmnbyxcvljhsgdfjasdasiudghasjd.
		
]]--

Lasthit = {}
Lasthit.creepTable = {}
Lasthit.table = {}
Lasthit.armorTypeModifiers = { Normal = {Unarmored = 1.00, Light = 1.00, Medium = 1.50, Heavy = 1.25, Fortified = 0.70, Hero = 0.75}, Pierce = {Unarmored = 1.50, Light = 2.00, Medium = 0.75, Heavy = 0.75, Fortified = 0.35, Hero = 0.50}, Siege = {Unarmored = 1.00, Light = 1.00, Medium = 0.50, Heavy = 1.25, Fortified = 1.50, Hero = 0.75}, Chaos = {Unarmored = 1.00, Light = 1.00, Medium = 1.00, Heavy = 1.00, Fortified = 0.40, Hero = 1.00},	Hero = {Unarmored = 1.00, Light = 1.00, Medium = 1.00, Heavy = 1.00, Fortified = 0.50, Hero = 1.00}, Magic = {Unarmored = 1.00, Light = 1.00, Medium = 1.00, Heavy = 1.00, Fortified = 1.00, Hero = 0.75} }
Lasthit.sleepTick = 0

function Lasthit.Tick(tick)
	if not PlayingGame() or client.paused or Animations.maxCount <= 0 then return end
	local me = entityList:GetMyHero()
	if Animations.maxCount and tick > Lasthit.sleepTick  then
		Lasthit.mapCreeps()
		Lasthit.sleepTick = tick + 2000
	end
	for creepHandle, creepClass in pairs(Lasthit.creepTable) do
		if not creepClass.creepEntity.visible or not creepClass.creepEntity.alive or GetDistance2D(me, creepClass.creepEntity) > Lasthit.AttackRange(me)*2+800 then
			Lasthit.creepTable[creepHandle] = nil
		else
			creepClass:Update()
		end
	end
end

function Lasthit.close()
	Lasthit.creepTable = {}
	Lasthit.table = {}
	Lasthit.sleepTick = 0	
end

function Lasthit.GetLasthit(hero)
	if hero then
		if Lasthit.table[hero.handle] and Lasthit.table[hero.handle].creep and (not Lasthit.table[hero.handle].creep.alive or not Lasthit.table[hero.handle].creep.visible) then
			Lasthit.table[hero.handle].creep = nil
		end
		local sortedTable = { }
		for creepHandle, creepClass in pairs(Lasthit.creepTable) do	table.insert(sortedTable, creepClass) end
		table.sort(sortedTable, function(a,b) return a.creepEntity.health < b.creepEntity.health end)		
		for creepHandle, creepClass in pairs(sortedTable) do	
			if creepClass.creepEntity.team ~= hero.team and GetDistance2D(hero, creepClass.creepEntity) < Lasthit.AttackRange(hero)*2 then
				local Dmg = (GetDamage(hero,creepClass) + hero.dmgMax)/2				
				if not Lasthit.table[hero.handle] then
					Lasthit.table[hero.handle] = {}
				end
				Lasthit.table[hero.handle].time = creepClass:GetTimeToHealth(Dmg)
				Lasthit.table[hero.handle].timeToDie = creepClass:GetTimeToHealth(0)
				local myattackTime = (client.gameTime + Animations.GetAttackTime(hero) + client.latency/1000 + (1/Animations.maxCount)*3 + hero:GetTurnTime(creepClass.creepEntity) + (math.max((GetDistance2D(hero, creepClass.creepEntity) - 50 - Lasthit.AttackRange(hero)), 0)/hero.movespeed))
				if heroInfo[hero.name].projectileSpeed then
					myattackTime = myattackTime + ((GetDistance2D(hero, creepClass.creepEntity)-math.max((GetDistance2D(hero, creepClass.creepEntity) - 50 - Lasthit.AttackRange(hero)), 0))/heroInfo[hero.name].projectileSpeed)
				end			
				-- if Lasthit.table[hero.handle].time then
					-- print(Lasthit.table[hero.handle].time, myattackTime - client.gameTime) end
				if hero.team ~= creepClass.creepEntity.team then
					if ((Lasthit.table[hero.handle].timeToDie and Lasthit.table[hero.handle].timeToDie > myattackTime) or not Lasthit.table[hero.handle].timeToDie) and (Dmg >= creepClass.creepEntity.health or (Lasthit.table[hero.handle].time and Lasthit.table[hero.handle].time <= myattackTime)) then
						if not Lasthit.table[hero.handle].creep or not Lasthit.table[hero.handle].creep.alive or not Lasthit.table[hero.handle].creep.visible then
							Lasthit.table[hero.handle].creep = creepClass.creepEntity
							Lasthit.table[hero.handle].class = creepClass
						end
					end
				end
			end
		end
	end
end	
 
function StopAttack(hero)
	if SleepCheck("attack") and hero and Lasthit.table[hero.handle].creep and Lasthit.table[hero.handle].creep.alive then
		local Dmg = (GetDamage(hero,Lasthit.table[hero.handle].class) + (hero.dmgMin + hero.dmgMax)/2)/2
		--Lasthit.table[hero.handle].time = Lasthit.table[hero.handle].class:GetTimeToHealth(Dmg)
		Lasthit.table[hero.handle].timeToDie = Lasthit.table[hero.handle].class:GetTimeToHealth(0)
		local myattackTime = (client.gameTime + Animations.GetAttackTime(hero))
		if heroInfo[hero.name].projectileSpeed then
			myattackTime = myattackTime + ((GetDistance2D(hero, Lasthit.table[hero.handle].creep)-math.max((GetDistance2D(hero, Lasthit.table[hero.handle].creep) - 50 - Lasthit.AttackRange(hero)), 0))/heroInfo[hero.name].projectileSpeed)
		end
		if (not Lasthit.table[hero.handle].timeToDie or Lasthit.table[hero.handle].timeToDie > myattackTime) and (((Lasthit.table[hero.handle].time and Lasthit.table[hero.handle].time > myattackTime) and (Lasthit.table[hero.handle].creep.health > Dmg)) or (not Lasthit.table[hero.handle].time and Lasthit.table[hero.handle].creep.health > Dmg)) then
			--print((Lasthit.table[hero.handle].time and Lasthit.table[hero.handle].time > myattackTime),(not Lasthit.table[hero.handle].time and Lasthit.table[hero.handle].creep.health > Dmg2))
			hero:Stop()
			Sleep((myattackTime - client.gameTime)*500, "attack")
		end
	end
end

function Lasthit.mapCreeps()
	local me = entityList:GetMyHero()
	local ents = Animations.entities
	if ents then
		for _, entity in ipairs(ents) do
			if entity.handle ~= me.handle and entity.alive and GetDistance2D(me, entity) < Lasthit.AttackRange(me)*2+800 and not Lasthit.creepTable[entity.handle] and not entity:IsInvul() and not entity:IsAttackImmune() then
				Lasthit.creepTable[entity.handle] = Creep(entity)
			end	
		end
	end
end

function Lasthit.AttackRange(unit)
	local bonus = 0
	if unit.classId == CDOTA_Unit_Hero_TemplarAssassin then	
		local psy = unit:GetAbility(3)
		if psy and psy.level > 0 then		
			bonus = psy:GetSpecialData("bonus_attack_range",psy.level)			
		end
	elseif unit.classId == CDOTA_Unit_Hero_Sniper then	
		local aim = unit:GetAbility(3)		
		if aim and aim.level > 0 then		
			bonus = aim:GetSpecialData("bonus_attack_range",aim.level)		 
		end		
	elseif unit.classId == CDOTA_Unit_Hero_Enchantress then
		if enablemodifiers then
			local impetus = unit:GetAbility(4)
			if impetus.level > 0 and unit:AghanimState() then
				bonus = 190
			end
		end
	end
	return unit.attackRange + bonus
end


function GetDamage(hero,target,crit)
	local dmg = hero.dmgMin + hero.dmgBonus
	local qblade = hero:FindItem("item_quelling_blade")
	local magical = nil
	if target.creepEntity.team ~= hero.team then
		if attackmodifiers then
			if hero.classId == CDOTA_Unit_Hero_Clinkz then		
				local searinga = hero:GetAbility(2)			
				if searinga.level > 0 then
					dmg = dmg + searina:GetSpecialData("bonus_damage",searinga.level)
				end
			end
		end
		if hero.classId == CDOTA_Unit_Hero_AntiMage then		
			local manabreak = hero:GetAbility(1)		
			if manabreak.level > 0 and target.creepEntity.maxMana > 0 and target.creepEntity.mana > 0 then
				dmg = dmg + manabreak:GetSpecialData("mana_per_hit",manabreak.level)*manabreak:GetSpecialData("mana_per_hit",manabreak.level)
			end
		elseif hero.classId == CDOTA_Unit_Hero_Viper then
			local nethertoxin = hero:GetAbility(2)
			local nethertoxindmg = nethertoxin:GetSpecialData("bonus_damage",nethertoxin.level)
			if nethertoxin.level > 0 then					
				local hplosspercent = target.creepEntity.health/(target.creepEntity.maxHealth / 100)
				local netherdmg = nil					
				if hplosspercent > 80 and hplosspercent <= 100 then
					netherdmg = nethertoxindmg*0.5
				elseif hplosspercent > 60 and hplosspercent <= 80 then
					netherdmg = nethertoxindmg*1
				elseif hplosspercent > 40 and hplosspercent <= 60 then
					netherdmg = nethertoxindmg*2
				elseif hplosspercent > 20 and hplosspercent <= 40 then
					netherdmg = nethertoxindmg*4
				elseif hplosspercent > 0 and hplosspercent <= 20 then
					netherdmg = nethertoxindmg*8
				end					
				if netherdmg then
					dmg = dmg + netherdmg
				end					
			end
		elseif hero.classId == CDOTA_Unit_Hero_Ursa then
			local furyswipes = hero:GetAbility(3)
			local furymodif = target.creepEntity:FindModifier("modifier_ursa_fury_swipes_damage_increase")
			if furyswipes.level > 0 then
				if furymodif then
					dmg = dmg + furyswipes:GetSpecialData("damage_per_stack",furyswipes.level)*furymodif.stacks
				else
					dmg = dmg + furyswipes:GetSpecialData("damage_per_stack",furyswipes.level)
				end
			end
		elseif hero.classId == CDOTA_Unit_Hero_BountyHunter then
			local jinada = hero:GetAbility(2)
			if jinada.level > 0 and crit and jinada.cd < (Animations.table[hero.handle].attackTime + (math.max((GetDistance2D(hero, target.creepEntity) - Lasthit.AttackRange(hero)), 0)/hero.movespeed)/1.1) then
				crit = nil
				dmg = dmg*(jinada:GetSpecialData("crit_multiplier",jinada.level)/100)
			end
		elseif hero.classId == CDOTA_Unit_Hero_Weaver then
			local geminate = hero:GetAbility(3)
			if geminate.level > 0 and target.creepEntity.health > dmg*1.3 and geminate.cd < (Animations.table[hero.handle].attackTime + (math.max((GetDistance2D(hero, target.creepEntity) - Lasthit.AttackRange(hero)), 0)/hero.movespeed) + ((GetDistance2D(hero, target.creepEntity)-math.max((GetDistance2D(hero, target.creepEntity) - Lasthit.AttackRange(hero)), 0))/heroInfo[hero.name].projectileSpeed)/1.1) then
				geminate_attack = ((GetDistance2D(hero, target.creepEntity)-math.max((GetDistance2D(hero, target.creepEntity) - Lasthit.AttackRange(hero)), 0))/heroInfo[hero.name].projectileSpeed)*1000 + geminate.cd*100 + Animations.table[hero.handle].attackTime
				dmg = dmg*2
			else
				geminate_attack = 0
			end
		elseif hero.classId == CDOTA_Unit_Hero_Juggernaut or hero.classId == CDOTA_Unit_Hero_Brewmaster then
			local doublecrit = hero:GetAbility(3)
			if doublecrit.level > 0 and crit then crit = nil
				dmg = dmg*1.8
			end
		elseif hero.classId == CDOTA_Unit_Hero_ChaosKnight or hero.classId == CDOTA_Unit_Hero_SkeletonKing then
			local lowcrit = hero:GetAbility(3)
			if lowcrit.level > 0 and crit then crit = nil
				dmg = dmg*(lowcrit:GetSpecialData("crit_damage",lowcrit.level)/100 or lowcrit:GetSpecialData("crit_mult",lowcrit.level)/100)
			end
		elseif hero.classId == CDOTA_Unit_Hero_PhantomAssassin then
			local highcrit = hero:GetAbility(4)
			if highcrit.level > 0 and crit then crit = nil
				dmg = dmg*(highcrit:GetSpecialData("crit_bonus",highcrit.level)/100)
			end
		end
		if qblade then
			if hero.attackRange < 200 then
				dmg = dmg*1.32
			else
				dmg = dmg*1.12
			end
		end
	end
	
	if hero.classId == CDOTA_Unit_Hero_Kunkka then
		local tidebringer = hero:GetAbility(2)
		if tidebringer.level > 0 and tidebringer.cd < (Animations.table[hero.handle].attackTime + client.latency/1100 + (math.max((GetDistance2D(hero, target.creepEntity) - Lasthit.AttackRange(hero)), 0)/hero.movespeed)/1.1) then
			dmg = dmg+tidebringer:GetSpecialData("damage_bonus", tidebringer.level)
		end
	end
	dmg = (math.floor(dmg * Lasthit.armorTypeModifiers["Hero"][target.armorType] * (1 - target.creepEntity.dmgResist)))		
	return dmg
end 

function Hit(hero)
	if Lasthit.table[hero.handle].creep and Lasthit.table[hero.handle].creep.team ~= hero.team then
		if hero.classId == CDOTA_Unit_Hero_Clinkz then
			local searinga = hero:GetAbility(2)
			if searinga.level > 0 then
				hero:SafeCastAbility(searinga, Lasthit.table[hero.handle].creep)
				return true
			end
		end
		hero:Attack(Lasthit.table[hero.handle].creep)
		return true
	end
end

class 'Creep'

function Creep:__init(creepEntity)
	self.creepEntity = creepEntity
	if self.creepEntity.classId == CDOTA_BaseNPC_Creep_Siege then
		self.creepType = "Siege Creep"
		self.attackType = "Siege"
		self.armorType = "Fortified"
	elseif self.creepEntity.classId == CDOTA_BaseNPC_Creep_Lane and (self.creepEntity.armor == 0 or self.creepEntity.armor == 1) then
		self.creepType = "Ranged Creep"
		self.attackType = "Pierce"
		self.armorType = "Unarmored"
	elseif self.creepEntity.classId == CDOTA_BaseNPC_Creep_Lane and (self.creepEntity.armor == 2 or self.creepEntity.armor == 3) then
		self.creepType = "Melee Creep"
		self.attackType = "Normal"
		self.armorType = "Unarmored"
	elseif self.creepEntity.classId == CDOTA_BaseNPC_Venomancer_PlagueWard and self.creepEntity.armor == 0 then
		self.creepType = "Plague Ward"
		self.attackType = "Pierce"
		self.armorType = "Unarmored"
	elseif self.creepEntity.classId == CDOTA_BaseNPC_Tower then
		self.creepType = "Tower"
		self.attackType = "Siege"
		self.armorType = "Fortified"
	elseif self.creepEntity.type == LuaEntity.TYPE_HERO then
		self.creepType = "Hero"
		self.attackType = "Hero"
		self.armorType = "Hero"
	elseif self.creepEntity.classId == CDOTA_BaseNPC_Invoker_Forged_Spirit then
		self.creepType = "Forged Spirit"
		self.attackType = "Chaos"
		self.armorType = "Unarmored"
	end
	self.nextAttackTicks = {}
	self.futureAttackTicks = {}
end

function Creep:GetTimeToHealth(health)
	numItems = 0
	for k,v in pairs(self.nextAttackTicks) do
		numItems = numItems + 1
	end
	for k,v in pairs(self.futureAttackTicks) do
		numItems = numItems + 1
	end
	if numItems > 0 then
		local sortedTable = { }
		for k, v in pairs(self.nextAttackTicks) do table.insert(sortedTable, v) end
		for k, v in pairs(self.futureAttackTicks) do table.insert(sortedTable, v) end
		table.sort(sortedTable, function(a,b) return a[2] < b[2] end)		
		local totalDamage = 0
		for i = 1, Animations.maxCount do
			for _, nextAttackTickTable in pairs(sortedTable) do					
				if nextAttackTickTable[1].creepEntity.alive and self.creepEntity.alive and client.gameTime <= nextAttackTickTable[2] then
					totalDamage = totalDamage + (math.floor((nextAttackTickTable[1].creepEntity.dmgMin + nextAttackTickTable[1].creepEntity.dmgBonus) * Lasthit.armorTypeModifiers[nextAttackTickTable[1].attackType][self.armorType] * (1 - self.creepEntity.dmgResist)))						
					if (self.creepEntity.health - totalDamage) <= health then	
						return nextAttackTickTable[2]*i + nextAttackTickTable[4]/i
					end
				end
			end 
		end
	end
	return nil
end

function Creep:Update()
	self:MapDamageSources()
	for k, nextAttackTickTable in pairs(self.nextAttackTicks) do
		if not nextAttackTickTable[1].creepEntity.alive or not self.creepEntity.alive or (math.max(math.abs(FindAngleR(nextAttackTickTable[1].creepEntity) - math.rad(FindAngleBetween(nextAttackTickTable[1].creepEntity, self.creepEntity))), 0)) > 0.011 or GetDistance2D(self.creepEntity,nextAttackTickTable[1].creepEntity) > nextAttackTickTable[1].creepEntity.attackRange+50 then
			self.nextAttackTicks[k] = nil
		-- elseif client.gameTime > nextAttackTickTable[3] then
			-- self.nextAttackTicks[k][2] = self.nextAttackTicks[k][2] + ((((nextAttackTickTable[1].projectileSpeed) and (((GetDistance2D(nextAttackTickTable[1].creepEntity.alive, self.creepEntity))/nextAttackTickTable[1].projectileSpeed))) or 0)) + (Animations.GetAttackTime(nextAttackTickTable[1].creepEntity) or (heroInfo[nextAttackTickTable[1].creepEntity.name].attackPoint / (1 + (nextAttackTickTable[1].creepEntity.attackSpeed - 100) / 100)))
			-- self.nextAttackTicks[k][3] = self.nextAttackTicks[k][3] + ((((nextAttackTickTable[1].projectileSpeed) and (((GetDistance2D(nextAttackTickTable[1].creepEntity.alive, self.creepEntity))/nextAttackTickTable[1].projectileSpeed))) or 0) + (nextAttackTickTable[1].creepEntity.attackBaseTime / (1 + (nextAttackTickTable[1].creepEntity.attackSpeed - 100) / 100))) + (Animations.GetAttackTime(nextAttackTickTable[1].creepEntity) or (heroInfo[nextAttackTickTable[1].creepEntity.name].attackPoint / (1 + (nextAttackTickTable[1].creepEntity.attackSpeed - 100) / 100)))
			-- self.nextAttackTicks[k][4] = ((((nextAttackTickTable[1].projectileSpeed) and (((GetDistance2D(nextAttackTickTable[1].creepEntity.alive, self.creepEntity))/nextAttackTickTable[1].projectileSpeed))) or 0) + (nextAttackTickTable[1].creepEntity.attackBaseTime / (1 + (nextAttackTickTable[1].creepEntity.attackSpeed - 100) / 100))) + (Animations.GetAttackTime(nextAttackTickTable[1].creepEntity) or (heroInfo[nextAttackTickTable[1].creepEntity.name].attackPoint / (1 + (nextAttackTickTable[1].creepEntity.attackSpeed - 100) / 100)))
		end
	end
	for k, nextAttackTickTable in pairs(self.futureAttackTicks) do
		if not nextAttackTickTable[1].creepEntity.alive or not self.creepEntity.alive or (math.max(math.abs(FindAngleR(nextAttackTickTable[1].creepEntity) - math.rad(FindAngleBetween(nextAttackTickTable[1].creepEntity, self.creepEntity))), 0)) > 0.0109 or GetDistance2D(self.creepEntity,nextAttackTickTable[1].creepEntity) > nextAttackTickTable[1].creepEntity.attackRange then
			self.futureAttackTicks[k] = nil
		-- elseif client.gameTime > nextAttackTickTable[3] then
			-- self.futureAttackTicks[k][2] = self.futureAttackTicks[k][2] + ((((nextAttackTickTable[1].projectileSpeed) and (((GetDistance2D(nextAttackTickTable[1].creepEntity.alive, self.creepEntity))/nextAttackTickTable[1].projectileSpeed))) or 0)) + (Animations.GetAttackTime(nextAttackTickTable[1].creepEntity) or (heroInfo[nextAttackTickTable[1].creepEntity.name].attackPoint / (1 + (nextAttackTickTable[1].creepEntity.attackSpeed - 100) / 100)))
			-- self.futureAttackTicks[k][3] = self.futureAttackTicks[k][3] + ((((nextAttackTickTable[1].projectileSpeed) and (((GetDistance2D(nextAttackTickTable[1].creepEntity.alive, self.creepEntity))/nextAttackTickTable[1].projectileSpeed))) or 0) + (nextAttackTickTable[1].creepEntity.attackBaseTime / (1 + (nextAttackTickTable[1].creepEntity.attackSpeed - 100) / 100))) + (Animations.GetAttackTime(nextAttackTickTable[1].creepEntity) or (heroInfo[nextAttackTickTable[1].creepEntity.name].attackPoint / (1 + (nextAttackTickTable[1].creepEntity.attackSpeed - 100) / 100)))
			-- self.futureAttackTicks[k][4] = ((((nextAttackTickTable[1].projectileSpeed) and (((GetDistance2D(nextAttackTickTable[1].creepEntity.alive, self.creepEntity))/nextAttackTickTable[1].projectileSpeed))) or 0) + (nextAttackTickTable[1].creepEntity.attackBaseTime / (1 + (nextAttackTickTable[1].creepEntity.attackSpeed - 100) / 100))) + (Animations.GetAttackTime(nextAttackTickTable[1].creepEntity) or (heroInfo[nextAttackTickTable[1].creepEntity.name].attackPoint / (1 + (nextAttackTickTable[1].creepEntity.attackSpeed - 100) / 100)))
		end
	end
end

function Creep:MapDamageSources()
	for creepHandle, creepClass in pairs(Lasthit.creepTable) do
		for k,z in ipairs(entityList:GetProjectiles({target=self.creepEntity})) do
			if z.source == creepClass.creepEntity then
				local nextAttackTick = (((Animations.table[z.source.handle] and Animations.table[z.source.handle].moveTime) and (Animations.table[z.source.handle].moveTime)) or ((heroInfo[z.source.name].attackBackswing / (1 + (z.source.attackSpeed - 100) / 100)) - (1/Animations.maxCount)*3)) - Animations.getAttackDuration(creepClass.creepEntity)
				local timeToDamageHit = ((GetDistance2D(z.position, self.creepEntity))/z.speed)
				local timeTofutureDamageHit = (((creepClass.projectileSpeed) and (((GetDistance2D(creepClass.creepEntity, self.creepEntity))/creepClass.projectileSpeed))) or 0) + ((Animations.GetAttackTime(creepClass.creepEntity)) or ((heroInfo[creepClass.creepEntity.name].attackPoint / (1 + (creepClass.creepEntity.attackSpeed - 100) / 100))))	
				local futureAttackTick = (((Animations.table[creepClass.creepEntity.handle] and Animations.table[creepClass.creepEntity.handle].moveTime) and (Animations.table[creepClass.creepEntity.handle].moveTime)) or (Animations.GetEndTime(creepClass.creepEntity)))
				if not self.nextAttackTicks[creepClass.creepEntity.handle] or self.nextAttackTicks[creepClass.creepEntity.handle][2] < client.gameTime then
					self.nextAttackTicks[z.source.handle] = {creepClass, timeToDamageHit + client.gameTime, nextAttackTick + client.gameTime, nextAttackTick, self}	
				end
				if not self.futureAttackTicks[creepClass.creepEntity.handle] or self.futureAttackTicks[creepClass.creepEntity.handle][2] < client.gameTime then
					self.futureAttackTicks[z.source.handle] = {creepClass, timeToDamageHit + timeTofutureDamageHit + (Animations.table[creepClass.creepEntity.handle].startTime or client.gameTime) + nextAttackTick, nextAttackTick + futureAttackTick + client.gameTime, nextAttackTick + futureAttackTick, self}
				end
			end
		end
		if self.creepEntity.team ~= creepClass.creepEntity.team and creepClass.creepEntity.alive and Animations.table[creepClass.creepEntity.handle] then
			local timeToDamageHit = 0
			local nextAttackTick = 0
			if GetDistance2D(creepClass.creepEntity.position, self.creepEntity) < creepClass.creepEntity.attackRange and (math.max(math.abs(FindAngleR(creepClass.creepEntity) - math.rad(FindAngleBetween(creepClass.creepEntity, self.creepEntity))), 0)) <= 0.0109 and Animations.isAttacking(creepClass.creepEntity) and not Animations.CanMove(creepClass.creepEntity) then
				if Animations.getAttackDuration(creepClass.creepEntity) and Animations.getAttackDuration(creepClass.creepEntity) > 0 and Animations.getAttackDuration(creepClass.creepEntity) <= Animations.GetAttackTime(creepClass.creepEntity) then
					nextAttackTick = (((Animations.table[creepClass.creepEntity.handle] and Animations.table[creepClass.creepEntity.handle].moveTime) and (Animations.table[creepClass.creepEntity.handle].moveTime)) or (Animations.GetEndTime(creepClass.creepEntity))) - Animations.getAttackDuration(creepClass.creepEntity)
					timeToDamageHit = (((creepClass.projectileSpeed) and (((GetDistance2D(creepClass.creepEntity, self.creepEntity))/creepClass.projectileSpeed))) or 0) + ((Animations.GetAttackTime(creepClass.creepEntity)) or ((heroInfo[creepClass.creepEntity.name].attackPoint / (1 + (creepClass.creepEntity.attackSpeed - 100) / 100))) - Animations.getAttackDuration(creepClass.creepEntity))
					local timeTofutureDamageHit = (((creepClass.projectileSpeed) and (((GetDistance2D(creepClass.creepEntity, self.creepEntity))/creepClass.projectileSpeed))) or 0) + ((Animations.GetAttackTime(creepClass.creepEntity)) or ((heroInfo[creepClass.creepEntity.name].attackPoint / (1 + (creepClass.creepEntity.attackSpeed - 100) / 100))))	
					local futureAttackTick = (((Animations.table[creepClass.creepEntity.handle] and Animations.table[creepClass.creepEntity.handle].moveTime) and (Animations.table[creepClass.creepEntity.handle].moveTime)) or (Animations.GetEndTime(creepClass.creepEntity)))
					if not self.nextAttackTicks[creepClass.creepEntity.handle] or self.nextAttackTicks[creepClass.creepEntity.handle][2] < client.gameTime then
						self.nextAttackTicks[creepClass.creepEntity.handle] = {creepClass, timeToDamageHit, nextAttackTick + (Animations.table[creepClass.creepEntity.handle].startTime or client.gameTime), nextAttackTick, self}		
					end
					if not self.futureAttackTicks[creepClass.creepEntity.handle] or self.futureAttackTicks[creepClass.creepEntity.handle][2] < client.gameTime then	
						self.futureAttackTicks[creepClass.creepEntity.handle] = {creepClass, timeToDamageHit + timeTofutureDamageHit + nextAttackTick + (Animations.table[creepClass.creepEntity.handle].startTime or client.gameTime), nextAttackTick + futureAttackTick + (Animations.table[creepClass.creepEntity.handle].startTime or client.gameTime), nextAttackTick + futureAttackTick, self}		
					end
				end
			end
		end
	end	
end

scriptEngine:RegisterLibEvent(EVENT_FRAME,Lasthit.Tick)
scriptEngine:RegisterLibEvent(EVENT_CLOSE,Lasthit.close)
