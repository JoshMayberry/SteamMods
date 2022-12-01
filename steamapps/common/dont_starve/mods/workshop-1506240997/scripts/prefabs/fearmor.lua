local assets =
{
Asset("ANIM","anim/fearmor.zip"),
--Asset("ANIM","anim/swap_fearmor.zip"),
Asset("ATLAS","images/inventoryimages/fearmor.xml"),

}

local prefebs={}

local function OnBlocked(owner) 
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_marble")
end

local function onequip(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_body", "fearmor", "swap_body")
    inst:ListenForEvent("blocked", OnBlocked, owner)
end


local function onunequip(inst, owner) 
    owner.AnimState:ClearOverrideSymbol("swap_body")
    inst:RemoveEventCallback("blocked", OnBlocked, owner)
end

local function getstatus( inst )
    local status = {"WEAK","FAIR","STEADY","PERFECT"}
    local health = inst.components.armor.condition
    if health == 1000 then 
        return status[4]
    else
        local num = math.ceil( health / 334 )
        return status[num]
    end
end

local function SanityDebuff(inst)
    if not inst.components.equippable.equipper then
        --inst.chargetimer = 1
    elseif inst.components.armor.condition == inst.components.armor.maxcondition then

    else
        inst.chargetimer = inst.chargetimer - 1
        if inst.chargetimer <= 0 then 
            local sanity = inst.components.equippable.equipper.components.sanity
            if sanity.current > 30 then
                local nexttime = Lerp(30,5,sanity:GetPercent())
                sanity:DoDelta(-5,false)
                inst.chargetimer = nexttime
                local health = math.min( inst.components.armor.condition + 100 ,inst.components.armor.maxcondition)
                inst.components.armor:SetCondition(health)
                local fuel = inst.components.armor.condition *.2 
                inst.components.fuel.fuelvalue = fuel
            end
        end   
    end
    inst:DoTaskInTime(1,function (inst) SanityDebuff(inst)end )
end

local function fn( Sim )
	local inst = CreateEntity()

    inst.entity:AddTransform() 
    inst.entity:AddAnimState() 
    MakeInventoryPhysics(inst)
    inst.entity:AddSoundEmitter()
    
   
    inst.AnimState:SetBank("fearmor") 
    inst.AnimState:SetBuild("fearmor") 
    inst.AnimState:PlayAnimation("anim") 
    MakeInventoryFloatable(inst, "idle_water", "anim")


    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/fearmor.xml"
    

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
   
   
    inst:AddComponent("armor")
    inst.components.armor.condition = 10
    inst.components.armor.maxcondition = 1000
    inst.components.armor.absorb_percent = .99

    inst.OnSave = function (inst,data)
        data.condition = inst.components.armor.condition
    end
    inst.OnLoad = function (inst,data)
        if data then
            inst.components.armor.condition = data.condition 
        end
    end

    inst:AddComponent("fuel") 
    inst.components.fuel.fuelvalue = 0
    inst.components.fuel.fueltype = "ORE_MIKOTO"

    inst.chargetimer = 1
    SanityDebuff(inst)

	return inst
end

return Prefab("common/inventory/fearmor", fn, assets)