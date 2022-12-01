require "prefabutil"
local assets =
{
	--Asset("ANIM", "anim/icemachine.zip"),
	--Asset("MINIMAP_IMAGE", "icemachine"),
	Asset("ANIM", "anim/coinmaker.zip"),
	Asset("ATLAS", "images/inventoryimages/coinmaker.xml"),
    Asset("IMAGE", "images/inventoryimages/coinmaker.tex"),
}

local prefabs =
{
	"collapse_small",
	"dubloon",
}


local MACHINESTATES =
{
	ON = "_on",
	OFF = "_off",
}
local spawntime = 60
local maxfuel = 500
--local coincounter = 0

local function spawnice(inst)  --没错，直接从制冰机里抄的代码
	inst:RemoveEventCallback("animover", spawnice)
    local coin = SpawnPrefab("dubloon")
    --[[
    local spawnrate = math.random()
    if spawnrate < .7 then
    local ice = SpawnPrefab("dubloon")
	elseif spawnrate < .95 then
	local ice = SpawnPrefab("coin")
	else 
	local ice = SpawnPrefab("coin_dark")
	end
    --]]
    local pt = Vector3(inst.Transform:GetWorldPosition())

	local right = TheCamera:GetRightVec()
	local offset = 1.3
	coin.Transform:SetPosition(pt.x + (right.x*offset) ,1, pt.z + (right.z*offset) )

	local down = TheCamera:GetDownVec()
    local angle = math.atan2(down.z, down.x) + (math.random()*60)*DEGREES
    local sp = 3 + math.random()
    coin.Physics:SetVel(sp*math.cos(angle), math.random()*2+8, sp*math.sin(angle))
    coin.components.inventoryitem:OnStartFalling()

	coin.AnimState:PlayAnimation("idle")
    

    --Machine should only ever be on after spawning an ice
	inst.components.fueled:StartConsuming()
	inst.AnimState:PlayAnimation("idle_on", true)
end

local function onhammered(inst, worked)
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal")

	inst:Remove()
end

local function fueltaskfn(inst)
	inst.AnimState:PlayAnimation("making")
	--inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/icemachine_start")
	inst.components.fueled:StopConsuming() --temp pause fuel so we don't run out in the animation.
	inst:ListenForEvent("animover", spawnice)
end

local function ontakefuelfn(inst)
	inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/machine_fuel")
	inst.components.fueled:StartConsuming()
--	if inst.prefab == "goldnugget" then
--	coincounter = 3
--	end


end

local function fuelupdatefn(inst, dt)
	-- TODO: summer season rate adjustment?
	inst.components.fueled.rate = 1
end

local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit"..inst.machinestate)
	inst.AnimState:PushAnimation("idle"..inst.machinestate, true)
	inst:RemoveEventCallback("animover", spawnice)
	if inst.machinestate == MACHINESTATES.ON then
		inst.components.fueled:StartConsuming() --resume fuel consumption incase you were interrupted from fueltaskfn
	end
end

local function fuelsectioncallback(new, old, inst)
	if new == 0 and old > 0 then
		inst.machinestate = MACHINESTATES.OFF
		--inst.AnimState:PlayAnimation("turn"..inst.machinestate)   --麻烦的要死，以后再做吧
		inst.AnimState:PushAnimation("idle"..inst.machinestate, true)
		inst.SoundEmitter:KillSound("loop")
		if inst.fueltask ~= nil then
			inst.fueltask:Cancel()
			inst.fueltask = nil
		end
	elseif new > 0 and old == 0 then
		inst.machinestate = MACHINESTATES.ON
		--inst.AnimState:PlayAnimation("turn"..inst.machinestate)
		inst.AnimState:PushAnimation("idle"..inst.machinestate, true)
		if not inst.SoundEmitter:PlayingSound("loop") then
			inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/icemachine_lp", "loop")
		end
		if inst.fueltask == nil then
			inst.fueltask = inst:DoPeriodicTask(spawntime, fueltaskfn)
		end
	end
end

local function getstatus(inst)
	local sec = inst.components.fueled:GetCurrentSection()
	if sec == 0 then
		return "OUT"
	elseif sec <= 3 then
		local t = {"LOW","NORMAL","HIGH"}
		return t[sec]
	end
end

local function onbuilt(inst)
	inst.AnimState:PlayAnimation("idle_on")--place
	inst.AnimState:PushAnimation("idle"..inst.machinestate)
	inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/icemaker_place")
end

local function onFloodedStart(inst)
	if inst.components.fueled then 
		inst.components.fueled.accepting = false
	end 
end 

local function onFloodedEnd(inst)
	if inst.components.fueled then 
		inst.components.fueled.accepting = true
	end 
end 

local function fn(Sim)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.MiniMapEntity:SetIcon("coinmaker.tex")

	inst.Transform:SetScale(.7,.7,.7)

	inst.AnimState:SetBank("coinmaker")
	inst.AnimState:SetBuild("coinmaker")

	MakeObstaclePhysics(inst, .4)

    inst:AddTag("structure")

	inst:AddComponent("lootdropper")

	inst:AddComponent("fueled")
	inst.components.fueled.maxfuel = maxfuel
	inst.components.fueled.accepting = true
	inst.components.fueled:SetSections(3)
	inst.components.fueled.ontakefuelfn = ontakefuelfn
	inst.components.fueled:SetUpdateFn(fuelupdatefn)
	inst.components.fueled:SetSectionCallback(fuelsectioncallback)
	inst.components.fueled:InitializeFuelLevel(maxfuel/5) --100
	inst.components.fueled:StartConsuming()
	inst.components.fueled.fueltype = "ORE_MIKOTO"

	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = getstatus

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst:AddComponent("floodable")
	inst.components.floodable.onStartFlooded = onFloodedStart
	inst.components.floodable.onStopFlooded = onFloodedEnd
	inst.components.floodable.floodEffect = "shock_machines_fx"
	inst.components.floodable.floodSound = "dontstarve_DLC002/creatures/jellyfish/electric_land"

	inst.machinestate = MACHINESTATES.ON
	inst:ListenForEvent( "onbuilt", onbuilt)

	return inst
end

return Prefab( "common/objects/coinmaker", fn, assets, prefabs),
		MakePlacer( "common/coinmaker_placer", "coinmaker", "coinmaker", "idle_off" )
