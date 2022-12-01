local assets=
{
    Asset("ANIM", "anim/dubloon.zip"),
    Asset("ANIM", "anim/swap_dubloon.zip"),
    Asset("ANIM", "anim/dubloon_air.zip"),

    Asset("SOUNDPACKAGE", "sound/mikoto.fev"),
    Asset("SOUND", "sound/mikoto.fsb"), 
}

local prefabs =
{
    "mikoto",
    "collapse_small",    --冒烟
    "groundpoundring_fx", --环形冲击波
    "shock_fx", --电击
    "shock_fx_soundless",
}

local railgunCD = 10

local san_used = -10

local railgun_damage = 150
local railgun_range = 4

local railgun_track_damage = 10
local dt = FRAMES

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_dubloon", "swap_dubloon") 
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry") 
    owner.AnimState:Show("ARM_normal")  
    
end

local function setcharged(inst, instant)--为电羊使用
    inst:AddTag("charged")
    inst.components.lootdropper:SetChanceLootTable('chargedlightninggoat') 
    inst.AnimState:SetBuild("lightning_goat_shocked_build")
    inst.AnimState:Show("fx") 
    if not instant then
        inst.sg:GoToState("shocked")
    end
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

local function onshoot(inst, owner, target)
    
    inst.AnimState:SetBank("dubloon_air")
    inst.AnimState:SetBuild("dubloon_air")
    inst:AddTag("NOCLICK")
    RemovePhysicsColliders(inst)
    if owner.components.sanity.current < 30 or owner.railgunpower == false then
         
    inst.AnimState:PlayAnimation("dubloon", true)
    inst.AnimState:SetOrientation( ANIM_ORIENTATION.OnGround )
    inst.Transform:SetScale(1,1,1)
        if owner.components.sanity.current < 30 then
        owner.components.talker:Say(mikoto_speech_noshootpower)
        else 
            local timeleft = owner.components.timer:GetTimeLeft("railgun_cd")
            timeleft = math.ceil(timeleft)
            if timeleft <= 1 then --区分单复数
            owner.components.talker:Say(mikoto_speech_inCD_1.. timeleft ..mikoto_speech_inCD_2)
            elseif timeleft > 1 then
            owner.components.talker:Say(mikoto_speech_inCD_1.. timeleft ..mikoto_speech_inCD_3)
            end
        end
    else
    inst:AddTag("railgun")
    inst.AnimState:PlayAnimation("railgun_" .. math.random(1,2),true)
    inst.SoundEmitter:PlaySound("mikoto/railgun/rg"..math.random(1,2))
    inst.Transform:SetScale(.5,.5,.5)
     
    owner.components.sanity:DoDelta(-10 , true)
    owner.components.timer:StartTimer("railgun_cd",10)
    owner.railgunpower = false
    
    inst:DoPeriodicTask(dt, function(inst) 
    local pos = Vector3(inst.Transform:GetWorldPosition())
    local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, 1.5)
        for k,v in pairs(ents) do
            if v.components.health and v.components.combat and not v.components.health:IsDead() and not v:HasTag("player") then
            v.components.combat:GetAttacked(owner, railgun_track_damage,inst)
            SpawnPrefab("sparks").Transform:SetPosition(v:GetPosition():Get())
            end
            if v.components.workable and not v:HasTag("insect") then 
                v.components.workable:Destroy(inst)
            SpawnPrefab("collapse_small").Transform:SetPosition(v:GetPosition():Get())
            end
            if v:HasTag("lightninggoat") and not v:HasTag("charged") then
            setcharged(v)
            end
           end end)
    
    inst:PushEvent("railgunshoot")
    end
    
end

local function onattack( inst,attacker,target)
    
    if not inst:HasTag("railgun")  then
    --[[
    local spawncoin = SpawnPrefab("dubloon") 
    spawncoin.Transform:SetPosition(inst:GetPosition():Get())  
        local x,y,z = inst.Transform:GetWorldPosition()
        local tile,tileinfo = inst:GetCurrentTileType(x,y,z)
        if GetWorld().Map:IsWater(tile) then
        spawncoin.AnimState:PlayAnimation("idle_water")  
        else
        spawncoin.AnimState:PlayAnimation("idle")
        end
    --]]
    inst:Remove() 
    -----------

    else  -- 一个蠢得不行的圆形的AOE，后续版本会考虑改为激光形式的伤害
    

    local ringfx = SpawnPrefab("groundpoundring_fx")
    ringfx.Transform:SetPosition(target:GetPosition():Get())
    ringfx.Transform:SetScale(.5,.5,.5)

    local shockfx = SpawnPrefab("shock_fx_soundless")
    shockfx.Transform:SetRotation(attacker.Transform:GetRotation())
    shockfx.Transform:SetPosition(target:GetPosition():Get())
    shockfx.Transform:SetScale(1.5,1.5,1.5)
    
    local pos = Vector3(target.Transform:GetWorldPosition())
        local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, railgun_range)
        for k,v in pairs(ents) do
            if v.components.health and v.components.combat and not v.components.health:IsDead() and  v.prefab ~= "mikoto" then
            v.components.combat:GetAttacked(attacker, railgun_damage,inst) 
            SpawnPrefab("sparks").Transform:SetPosition(v:GetPosition():Get())
            end
            if v.components.workable and not v:HasTag("insect") then 
                v.components.workable:Destroy(inst)
                SpawnPrefab("collapse_small").Transform:SetPosition(v:GetPosition():Get())
            end
            if v:HasTag("lightninggoat") and not v:HasTag("charged") then
            setcharged(v)
            end
        end
        inst:Remove()      
    end 
end 
local function onmiss(inst, attacker ,target)
    if  not inst:HasTag("railgun")  then

    local spawncoin = SpawnPrefab("dubloon") 
    spawncoin.Transform:SetPosition(inst:GetPosition():Get())  
        local x,y,z = inst.Transform:GetWorldPosition()
        local tile,tileinfo = inst:GetCurrentTileType(x,y,z)
        if GetWorld().Map:IsWater(tile) then
    spawncoin.AnimState:PlayAnimation("idle_water")  
    else
    spawncoin.AnimState:PlayAnimation("idle")
    end
    inst:Remove() 
    -----------

    else  
    attacker.components.sanity:DoDelta(san_used , false)

    local ringfx = SpawnPrefab("groundpoundring_fx")
    ringfx.Transform:SetPosition(inst:GetPosition():Get())
    ringfx.Transform:SetScale(.5,.5,.5)

    local shockfx = SpawnPrefab("shock_fx")
    shockfx.Transform:SetRotation(attacker.Transform:GetRotation())
    shockfx.Transform:SetPosition(inst:GetPosition():Get())
    shockfx.Transform:SetScale(1.5,1.5,1.5)
    
    local pos = Vector3(inst.Transform:GetWorldPosition())
        local ents = TheSim:FindEntities(pos.x,pos.y,pos.z, railgun_range)
        for k,v in pairs(ents) do
            if v.components.health and v.components.combat and not v.components.health:IsDead() and not v:HasTag("player") then
            v.components.combat:GetAttacked(attacker, railgun_damage) 
            end
            if v.components.workable and not v:HasTag("insect") then 
                v.components.workable:Destroy(inst)
                SpawnPrefab("collapse_small").Transform:SetPosition(v:GetPosition():Get())
            end
            if v:HasTag("lightninggoat") and not v:HasTag("charged") then
            setcharged(v)
            end
        end
        inst:Remove()      
    end 
end

--------------------------------------------------------------
local function shine(inst)
    inst.task = nil
    -- hacky, need to force a floatable anim change
    inst.components.floatable:UpdateAnimations("idle_water", "idle")
    inst.components.floatable:UpdateAnimations("sparkle_water", "sparkle")

    if inst.components.floatable.onwater then
        inst.AnimState:PushAnimation("idle_water")
    else
        inst.AnimState:PushAnimation("idle")
    end
    
    if inst.entity:IsAwake() then
        inst:DoTaskInTime(4+math.random()*5, function() shine(inst) end)
    end
end

local function onwake(inst)
    inst.task = inst:DoTaskInTime(4+math.random()*5, function() shine(inst) end)
end

local function fn(Sim)
    
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddPhysics()

    inst.OnEntityWake = onwake

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "idle_water", "idle")
    MakeBlowInHurricane(inst, TUNING.WINDBLOWN_SCALE_MIN.MEDIUM, TUNING.WINDBLOWN_SCALE_MAX.MEDIUM)

    inst.AnimState:SetBloomEffectHandle( "shaders/anim.ksh" )    
    
    inst.AnimState:SetBank("dubloon")
    inst.AnimState:SetBuild("dubloon")
    inst.AnimState:PlayAnimation("idle")

    inst:AddComponent("edible")
    inst.components.edible.foodtype = "ELEMENTAL"
    inst.components.edible.hungervalue = 1
    
    inst:AddComponent("currency")
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("appeasement")
    inst.components.appeasement.appeasementvalue = TUNING.APPEASEMENT_TINY

    inst:AddComponent("waterproofer")
    inst.components.waterproofer.effectiveness = 0
    inst:AddComponent("inventoryitem")

    inst:AddComponent("bait")
    inst:AddTag("molebait")
    -----------------------------------------------------------------------
    if GetPlayer().prefab == "mikoto" then
    
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.equipstack = true

    inst:AddTag("projectile")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(5)
    inst.components.weapon:SetRange(10, 12)
    inst.components.weapon:SetOnAttack(onattack)
    
    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(30)
    inst.components.projectile:SetOnThrownFn(onshoot)
    inst.components.projectile:SetOnMissFn(onmiss)
    inst.components.projectile:SetLaunchOffset(Vector3(0, 0.5, 0))

    end
    return inst
end

return  Prefab( "common/inventory/dubloon", fn, assets, prefabs)