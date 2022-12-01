local assets =
{
Asset("ANIM","anim/fesword.zip"),
Asset("ANIM","anim/swap_fesword.zip"),
Asset("ATLAS","images/inventoryimages/fesword.xml"),

}


local prefebs= {}


local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_fesword", "swap_fesword") 
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    
    if owner.components.sanity.current < 30 then
        owner:DoTaskInTime(0, function()
        owner.components.inventory:GiveItem(inst)
        owner.components.talker:Say(mikoto_speech_unabletoequip)
        
        end)
    end
    
    
    if inst.force_unequip == nil then 

    inst.force_unequip = inst:DoPeriodicTask(5, function()
    if owner.components.sanity.current < 30 then
        owner.components.inventory:GiveItem(inst)
        owner.components.talker:Say(mikoto_speech_unabletoequip)
    end
    end)

    end
    
end
local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry") 
    owner.AnimState:Show("ARM_normal")
    if inst.force_unequip ~= nil then
    inst.force_unequip:Cancel()
    inst.force_unequip = nil
    end
end

local function onbuilt()
---[[
    local x, y, z = GetPlayer().Transform:GetWorldPosition()
    local ground = GetWorld()
    local tile, tileinfo = GetPlayer():GetCurrentTileType(x, y, z)
    if  ground.Map:IsWater(tile) then 
        GetPlayer().components.sanity:DoDelta(-20,false)
        
        GetPlayer().components.talker:Say(mikoto_speech_on_craft)
    else
        
        GetPlayer().components.sanity:DoDelta(-10,false)
        if math.random() < .5 then  GetPlayer().components.talker:Say(mikoto_speech_on_craft_fesword) end
    end
end
local function SanityDebuff(inst)  
     GetPlayer().components.sanity.dapperness = GetPlayer().components.sanity.dapperness + TUNING.CRAZINESS_MED * .5 --(10/min) 
end
--]]
---[[
local function SanityDebuff_shutdown(inst)
    if GetPlayer().components.sanity then
    GetPlayer().components.sanity.dapperness = GetPlayer().components.sanity.dapperness - TUNING.CRAZINESS_MED * .5
        if math.random() < .5 then 
        GetPlayer().components.talker:Say(mikoto_speech_on_disappear)
        end
    end
end
--]]
local  function disappear(inst)
    inst:PushEvent("fesword_disappear")
    inst.disappeartask = nil
    inst.persists = false
    inst:RemoveComponent("inventoryitem")
    inst:RemoveComponent("inspectable")
    inst.SoundEmitter:PlaySound("dontstarve/common/dust_blowaway")
    local pos = inst:GetPosition()
    pos.y = pos.y + 1.2
    inst:StartThread(function()
        for i = 1,10 do
             local fx = SpawnPrefab("ironash_fx")
            --fx.Transform:SetRotation(attacker.Transform:GetRotation())
            fx.Transform:SetPosition(pos:Get())
            fx.Transform:SetScale(.7,.7,.7)
            pos.y = pos.y - 0.13
            Sleep(.12)
        end
        return true end)
    inst.AnimState:PlayAnimation("disappear")
    inst:ListenForEvent("animover", function() inst:Remove() end)
   -- inst:Remove()
    
end

local function Stop_disappear(inst)
    if inst.disappeartask then
        inst.disappeartask:Cancel()
        inst.disappeartask = nil
    end
end

local function prepare_disappear(inst)
    Stop_disappear(inst)  
    inst.disappeartask = inst:DoTaskInTime(1,disappear) 
end


   

local function fn( Sim )
	local inst = CreateEntity()

    inst.entity:AddTransform() 
    inst.entity:AddAnimState() 
    inst.entity:AddSoundEmitter()
    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "idle", "idle")
    
    
   
    inst.AnimState:SetBank("fesword") 
    inst.AnimState:SetBuild("fesword") 
    inst.AnimState:PlayAnimation("idle")
    inst.Transform:SetScale(.8,.8,.8) 


    inst:AddComponent("inspectable")
    

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/fesword.xml"
    inst.components.inventoryitem:SetOnPutInInventoryFn(Stop_disappear)
   

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.dapperness = .75 * TUNING.CRAZINESS_MED --(0.75 * 20 = 15) unequip~10 / equip~25
    
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(60)
    
    SanityDebuff()
    inst.OnBuilt = onbuilt

    inst:ListenForEvent("ondropped", prepare_disappear)
    inst:ListenForEvent("fesword_disappear", SanityDebuff_shutdown)

    inst:AddTag("irreplaceable")
    

	return inst
end

function fxfn()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local snd = inst.entity:AddSoundEmitter()

    anim:SetBank("fesword")
    anim:SetBuild("fesword")
    anim:PlayAnimation("ash")
    inst:AddTag("fx")
    inst:ListenForEvent( "animover", function(inst) inst:Remove() end )
    return inst
end

return Prefab("common/inventory/fesword", fn, assets),
    Prefab("ironash_fx",fxfn,assets)