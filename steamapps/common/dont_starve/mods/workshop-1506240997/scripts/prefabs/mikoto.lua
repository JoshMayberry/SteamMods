
local MakePlayerCharacter = require "prefabs/player_common"
local assets = {
        Asset( "ANIM", "anim/mikoto.zip" ),
        Asset( "ANIM", "anim/shock_railgun_fx.zip" ),
        
}
local prefabs = {}
local start_inv =
 {
  "dubloon","dubloon","dubloon","dubloon","dubloon","dubloon",
    
}

local zaprange_big, zaprange_mid ,zaprange_small = 4, 3, 2
local zapdmg_high, zapdmg_fair, zapdmg_low, zapdmg_verylow = 40, 35, 10, 5 --被动伤害
local attdmg_high, attdmg_fair, attdmg_low, attdmg_verylow = 25, 20, 10, 5 --主动伤害


local function IsTargetWet(inst)
    if inst.components.moisture
        or inst.components.moisturelistener and inst.components.moisturelistener:IsWet()
        or GetWorld() and GetWorld().components.moisturemanager and GetWorld().components.moisturemanager:IsEntityWet(inst) 
        then 
        return true
    end
end

local function onlightingstrike(inst)
    if inst.components.health and not inst.components.health:IsDead() then
        inst.components.health:DoDelta(10,false)
        inst.components.sanity:DoDelta(5,false)
    inst.components.talker:Say(mikoto_speech_on_zapped[math.random(#mikoto_speech_on_zapped)])   
    end
end
local function setcharged(inst)--为电羊使用
    inst:AddTag("charged")
    inst.components.lootdropper:SetChanceLootTable('chargedlightninggoat') 
    inst.AnimState:SetBuild("lightning_goat_shocked_build")
    inst.AnimState:Show("fx") 
    inst.sg:GoToState("shocked")
    inst.AnimState:SetBloomEffectHandle( "shaders/anim.ksh" )
    inst.charged = true
    inst.chargeleft = 3
    inst.Light:Enable(true)
    inst:ListenForEvent( "daycomplete", function()
        if inst.chargeleft then
            inst.chargeleft = inst.chargeleft - 1
            if inst.chargeleft <= 0 then
                discharge(inst)
            end
        end
    end, GetWorld())
end

local function OnAttacked(inst, data)--对近战攻击反弹闪电伤害，与san值有关，潮湿效果加倍；如果攻击者是电羊，则直接充电   
    local mikoto_san = inst.components.sanity.current
    local pos = inst:GetPosition() 
    if data and data.attacker and data.attacker.components.health and data.attacker ~= inst and mikoto_san ~= 0
       
            then

        if math.random() <= .3 then 
            if math.random() <= .1 then 
            inst.components.talker:Say(mikoto_speech_on_attacked_2) 
            else inst.components.talker:Say(mikoto_speech_on_attacked_1) 
            end
        end

        if mikoto_san > 170 then
            inst.components.sanity:DoDelta(-1,false)
            local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, zaprange_big) --3
            for k,v in pairs(ents) do
                if v.components.health and v.components.combat and not v.components.health:IsDead() and not v:HasTag("player") then
                    local dmg = zapdmg_high --40
                    dmg = (IsTargetWet(v) and 2 or 1 )* dmg
                    v.components.combat:GetElectroAttack(inst,dmg)
                    if v.sg then  
                    v.sg:GoToState("hit")
                    end
                    if v:HasTag("lightninggoat")and not v:HasTag("charged")then
                    setcharged(v)
                    end
                end
            end

        local zap_fx = SpawnPrefab("mikoto_zap") 
        pos.y = pos.y + 1
        zap_fx.Transform:SetPosition(pos:Get()) 
        zap_fx.Transform:SetScale(2,2,2) 
      

        elseif mikoto_san > 30 then
            
            local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, zaprange_mid) --2
            for k,v in pairs(ents) do
               if v.components.health and v.components.combat and not v.components.health:IsDead() and not v:HasTag("player") then
                    local dmg = Remap(mikoto_san,30,170, zapdmg_low, zapdmg_fair )  --10~35
                    dmg = (IsTargetWet(v) and 2 or 1 )* dmg
                    v.components.combat:GetElectroAttack(inst,dmg)
                    if v.sg then  
                    v.sg:GoToState("hit")
                    end
                    if v:HasTag("lightninggoat")and not v:HasTag("charged")then
                    setcharged(v)
                    end
                end
            end
         local zap = SpawnPrefab("mikoto_zap_small") 
         pos.y = pos.y + 1
         zap.Transform:SetPosition(pos:Get()) 
        elseif mikoto_san > 0 then
            local dmg = zapdmg_verylow --5
            if data.attacker.components.health and data.attacker.components.combat and not data.attacker.components.health:IsDead() and not data.attacker:HasTag("player") 
             and not (
            data.attacker:HasTag("walrus") or--别想着拿反弹伤害去弹死海象爸爸
            data.attacker:HasTag("bishop") or--也别想弹死主教
            data.attacker:HasTag("spider_spitter")--这个既有远程也有近战，怎么分开呢......
            --海难里还有一大堆会远程攻击也会近战攻击的生物，不知道怎么弄......
            )then
                data.attacker.components.health:DoDelta((IsTargetWet(data.attacker) and -2 or -1)* dmg) 
                if data.attacker:HasTag("lightninggoat") and not data.attacker:HasTag("charged") then
                setcharged(data.attacker)
                end
            end
        end
    end
 
end

local function ElectroDamage( inst,data )--近战攻击附带闪电伤害，与san值有关，潮湿效果加倍
    local mikoto_san = inst.components.sanity.current 
    if mikoto_san > 0 and data and data.target and data.target and not (
        data.target:HasTag("prey") or
        data.target:HasTag("bird") or
        data.target:HasTag("wall") or
        data.target:HasTag("butterfly") or
        data.target:HasTag("veggie") or
        data.target:HasTag("smashable") 
        )
        then
        if mikoto_san > 170 then
            local dmg = (IsTargetWet(data.target) and 2 or 1)*attdmg_high
            data.target.components.combat:GetElectroAttack(data.target,dmg)          
            local sparks = SpawnPrefab("sparks")
            sparks.Transform:SetPosition(data.target.Transform:GetWorldPosition())     
            inst.components.sanity:DoDelta(-.5,true)
        elseif mikoto_san > 30 then 
            local dmg = Remap(mikoto_san,30,170,attdmg_low,attdmg_fair)
            dmg = (IsTargetWet(data.target) and 2 or 1)*dmg
            data.target.components.combat:GetElectroAttack(data.target,dmg) 
        elseif mikoto_san > 0 then
            local dmg = (IsTargetWet(data.target) and 2 or 1)*attdmg_verylow
             data.target.components.combat:GetElectroAttack(data.target,dmg) 
        end            

        if data.target:HasTag("lightninggoat") and not data.target:HasTag("charged") then
            setcharged(data.target)
        end
    end
end

local function OnSanityDelta(inst,data)
    if data.newpercent <= .15  then
        inst.components.locomotor:AddSpeedModifier_Mult("MIKOTO_SAN", -0.1)
        if data.oldpercent > .15 then
            inst.components.talker:Say(mikoto_san_low)
        end
    elseif data.newpercent <= .85 then
        inst.components.locomotor:AddSpeedModifier_Mult("MIKOTO_SAN", 0)
        inst.components.health:SetAbsorptionAmount(0)
    elseif data.newpercent <= 1 then
        if data.oldpercent < .85 then
            inst.components.talker:Say(mikoto_san_high)
        end
        inst.components.locomotor:AddSpeedModifier_Mult("MIKOTO_SAN", .1)
        inst.components.health:SetAbsorptionAmount(.15)
    end
end 

local function commonzap(inst)
    local san = inst.components.sanity.current
    if san < 30 then return end

    inst.zaptimer = inst.zaptimer - .5
    
    if inst.zaptimer < 0 then 
        if san >= 170 then
        inst.zaptimer = 6 + 8*math.random()
        elseif san >= 30 then
        inst.zaptimer = 10 + 5*math.random()
        end
        local fx = SpawnPrefab("mikoto_zap_small")
        fx.entity:SetParent(inst.entity)
        fx.Transform:SetPosition(0,1,0)
    end
end


local fn = function(inst) 
    -- choose which sounds this character will play
    inst.soundsname = "willow"
    -- Minimap icon
    inst.MiniMapEntity:SetIcon( "mikoto.tex" )
    -- 三围
    inst.components.health:SetMaxHealth(100)
    inst.components.hunger:SetMax(150)
    inst.components.sanity:SetMax(200)
    
    -- 攻击乘数
    inst.components.combat.damagemultiplier = 0.6
----------------------------------------------
    inst.components.playerlightningtarget:SetOnStrikeFn(onlightingstrike)
    inst:AddTag("electricdamageimmune")--机器人也有这个标签，但不知道有什么用
    inst:AddTag("mikoto")
    inst:ListenForEvent("attacked", OnAttacked)
    --inst:ListenForEvent("onhitother",OnHitOther)
    inst:ListenForEvent("onhitother_notprojectile",ElectroDamage)
    inst:ListenForEvent("sanitydelta",OnSanityDelta)
    inst.components.playerlightningtarget:SetHitChance(0.6)

    inst.components.inventory.insulated = true

    inst.railgunpower = true
    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", function (inst,data)
        if data.name == "railgun_cd" then
            inst.railgunpower = true
        end
        local mCDd = ""
        if type(mikoto_CD_down) == "table" then
            if math.random() <.95 then
            mCDd = mikoto_CD_down[math.random(1,4)]
            else
            mCDd = mikoto_CD_down[5]
            end
        else
        mCDd = mikoto_CD_down
        end
        if inst.components.sanity.current >= 30 then inst.components.talker:Say(mCDd) end
    end)

    inst.zaptimer = 0
    inst:DoPeriodicTask(.5,commonzap)

    inst.OnSave = function(inst,data) data.railgunpower = inst.railgunpower end
    inst.OnLoad = function(inst,data) if data then inst.railgunpower = data.railgunpower end end   
end

local zap = function (inst)
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local snd = inst.entity:AddSoundEmitter()
    --inst.Transform:SetFourFaced()
    snd:PlaySound("dontstarve_DLC002/creatures/jellyfish/electric_land")
    anim:SetBank("shock_railgun_fx")
    anim:SetBuild("shock_railgun_fx")
    anim:PlayAnimation("electricity")
    inst.entity:AddLight()
    inst.Light:Enable(true)
    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(.9)
    inst.Light:SetColour(235/255,121/255,12/255)
    
    inst:AddTag("fx")
    inst:ListenForEvent( "animover", function(inst) inst:Remove() end )
    return inst
end

return MakePlayerCharacter("mikoto", prefabs, assets, fn, start_inv),
    Prefab("mikoto_zap", zap, assets, prefabs)
    
