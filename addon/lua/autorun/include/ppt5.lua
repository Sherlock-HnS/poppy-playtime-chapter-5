
hook.Add("OnEntityCreated", "ppt5t_initialize_gem_2", function(ent)
    timer.Simple(0.01, function()
        if !IsValid(ent) then return end
        if ent:GetClass() ~= "pill_ent_costume" then return end


        if ent.formTable then
            local PuppetEntity = ent:GetPuppet()
            local targetOrigin = ent:LocalToWorld(Vector(0, 0, 50))
local entity
if SherlockHNS then
    entity = SherlockHNS.FindVictim(ply, targetOrigin, 130, {
        filter = function(v)
            local trace = util.TraceLine({
                start = ent:EyePos(),
                endpos = v:EyePos(),
                filter = {ent, ply},
                mask = MASK_VISIBLE
            })
            return not trace.Hit
        end,
    })
else
    for k, v in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 130)) do
                if v:IsPlayer() or v:IsNextBot() or v:IsNPC() then
                    if v == ent or v == ply then continue end
    
                    if (v:IsPlayer() and v:Team() ~= TEAM_SPECTATOR) or ((v:IsNPC() or v:IsNextBot()) and v:Health() > 0) then
                        local trace = util.TraceLine({
                            start = ent:EyePos(),
                            endpos = v:EyePos(),
                            filter = {ent, ply},
                            mask = MASK_VISIBLE
                        })
    
                        if not trace.Hit then
                            entity = v
                            break
                        end
                    end
                end
            end
end

if SherlockHNS and IsValid(entity) and entity:IsPlayer() then
            return pk_pills.playHNSJumpscare(ply, ent, entity, 8, {
                camera = "ppt5_jumpscare_gen",
                offset = 50,
                animation = "jumpscare",
                sound = "kill",
            })
        end

        if not IsValid(entity) then return end

        local pill = ent:GetPuppet()

        if entity:IsPlayer() then
            entity:Freeze(true)
            entity:AddFlags(FL_NOTARGET)
            entity:DrawViewModel(false)
            entity:SetActiveWeapon(nil)

            net.Start('ppt5_jumpscare_gen')
            net.WriteEntity(pill)
            net.WriteBool(true)
            net.Send(entity)

            
        else
            entity:NextThink(CurTime() + 1e9)
        end

        entity:SetPos(pill:GetPos() + pill:GetForward() * 50)

        ply:Freeze(true)
        

        ent:PillAnim('jumpscare')
        ent:PillSound('kill')

        timer.Simple(8, function()
            if not (IsValid(entity) and IsValid(ent)) then return end
            
            ply:Freeze(false)

            if entity:IsPlayer() then
                entity:Kill(ply)
               

                net.Start('ppt5_jumpscare_gen')
                net.WriteEntity(pill)
                net.WriteBool(false)
                net.Send(entity)

                
                entity:RemoveFlags(FL_NOTARGET)
                entity:Freeze(false)
                entity:DrawViewModel(true)
            else
                entity:NextThink(CurTime())
                entity:TakeDamage(1e9, ply)
            end
        end)

        timer.Simple(9, function()
            ent:PillSound('killvoiceline')
            ply.OnHold = false
            entity = nil
        end)
    end,
},

	
    --Right Click Attack Function
    attack2 = {
        mode = "trigger",
        func = function(ply, ent)

        end,
    },
    
    
    

noragdoll=true,
	
	-- R click function
   	reload=function(ply,ent)

    end,

	
    -- F Click function
    flashlight=function(ply,ent)

    end,
	
	-- Jump Attack Spacebar Function 
    jump=function(ply,ent)

    end
    
}, function(form)
    -- The legacy damage branches are for Sandbox and NPCs.
    form.hnsKillAPI = true
    form.hnsAbilities = {
        { id = "attack", name = "Ataque", key = IN_ATTACK, OnUse = form.attack.func },
    }
    form.attack, form.attack2, form.reload = nil, nil, nil
end)

pk_pills.register("pill_ppt5huggy",{

    printName="Huggy (Injured)",
	
    model="models/ppt/HuggyInjured.mdl",
	
	modelScale="1",

    noragdoll = true,
    muteSteps = true,
    _ppt5_pill_ds = true,
	
    anims={
        default={
            idle="idle",
			run="run_2",
            walk="walk",
            crouch_walk="walk_duck",
            crouch_idle="walk_duck",
            crouch="walk_duck",
            roar="roar",
			attack="combat_destruction_1",
			jumpscare="kill"
        },
    },

    FirstPersonBone = {
        'head',
        15,
        0,
        10,
    },
    ThirdPersonBone = {
        'cog',
        0,
        22,
        10,
    },
	
    moveSpeed={
        walk=120,
        run=500,
        ducked=120,
    },
	
    sounds={
		kill="huggych5/SW_SFX_Huggy_Jumpscare.wav",
        laugh="huggych5/SW_SFX_Wuggy_Laugh.wav",
    },
	

    type="ply",

    camera={
        dist=120
    },
	
    jumpPower=0,
	
    health=200000,
	
	movePoseMode="xy",
		aim={
		xPose="aim_pitch",
		yPose="aim_yaw",
		nocrosshair = true
	},
	
	canAim=function(ply,ent)
		return ent.active
	end,
    
    ppt5_initialize=function(ply,ent,puppet)
    end,

    think_n_ppt5=function(ply, ent)
        if (not ply.WugVoiceTick) and (not ply.OnHold) then
            ply.WugVoiceTick = true

            local snd = nil
            local dur = 0
            local del = math.random(5, 10)

            if ply:KeyDown(IN_SPEED) then
                local del = math.random(1, 2)
                
                if math.random(2) == 1 then
                    if math.random(2) == 2 then
                        snd = 'PPT5.Huggy.ScreamShort'
                    else
                        snd = 'PPT5.Huggy.Agitated'
                    end
                end
            else
                if math.random(10) > 5 then
                    if math.random(3) == 1 then
                        snd = 'PPT5.Huggy.DocileShort'
                    elseif math.random(3) == 2 then
                        snd = 'PPT5.Huggy.Breathe'
                    else
                        snd = 'PPT5.Huggy.DocileGrowl'
                    end
                end
            end

            if snd then
                dur = SoundDuration(snd)

                ply:EmitSound(snd)
            end

            timer.Simple(del + dur, function()
                ply.WugVoiceTick = false
            end)
        end
    end,

attack = {
    mode = 'trigger',
    func = function(ply, ent)
        local targetOrigin = ent:LocalToWorld(Vector(0, 0, 50))
local entity
if SherlockHNS then
    entity = SherlockHNS.FindVictim(ply, targetOrigin, 130, {
        filter = function(v)
            local trace = util.TraceLine({
                start = ent:EyePos(),
                endpos = v:EyePos(),
                filter = {ent, ply},
                mask = MASK_VISIBLE
            })
            return not trace.Hit
        end,
    })
else
    for k, v in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 130)) do
                if v:IsPlayer() or v:IsNextBot() or v:IsNPC() then
                    if v == ent or v == ply then continue end
    
                    if (v:IsPlayer() and v:Team() ~= TEAM_SPECTATOR) or ((v:IsNPC() or v:IsNextBot()) and v:Health() > 0) then
                        local trace = util.TraceLine({
                            start = ent:EyePos(),
                            endpos = v:EyePos(),
                            filter = {ent, ply},
                            mask = MASK_VISIBLE
                        })
    
                        if not trace.Hit then
                            entity = v
                            break
                        end
                    end
                end
            end
end

if SherlockHNS and IsValid(entity) and entity:IsPlayer() then
            return pk_pills.playHNSJumpscare(ply, ent, entity, 1.5, {
                camera = "ppt5_jumpscare_gen",
                offset = 50,
                animation = "jumpscare",
                sound = "kill",
            })
        end

        if not IsValid(entity) then 
            --ent:PillAnim('attack')
            return 
        end

        local pill = ent:GetPuppet()

        if entity:IsPlayer() then
            entity:Freeze(true)
            entity:AddFlags(FL_NOTARGET)
            entity:DrawViewModel(false)
            entity:SetActiveWeapon(nil)

            net.Start('ppt5_jumpscare_gen')
            net.WriteEntity(pill)
            net.WriteBool(true)
            net.Send(entity)

            
        else
            entity:NextThink(CurTime() + 1e9)
        end

        entity:SetPos(pill:GetPos() + pill:GetForward() * 50)

        ply:Freeze(true)
        

        ent:PillAnim('jumpscare')

        timer.Simple(0.6, function()
            ent:PillSound('kill')
        end)

        timer.Simple(1.5, function()
            if not (IsValid(entity) and IsValid(ent)) then return end
            
            ply:Freeze(false)

            if entity:IsPlayer() then
                entity:Kill(ply)
               

                net.Start('ppt5_jumpscare_gen')
                net.WriteEntity(pill)
                net.WriteBool(false)
                net.Send(entity)

                
                entity:RemoveFlags(FL_NOTARGET)
                entity:Freeze(false)
                entity:DrawViewModel(true)
            else
                entity:NextThink(CurTime())
                entity:TakeDamage(1e9, ply)
            end
        end)

        timer.Simple(2.5, function()
            if math.random(2) == 1 then
                ent:PillSound('laugh')
            end

            ply.OnHold = false
            entity = nil
        end)
    end,
},

	
    --Right Click Attack Function
    attack2 = {
        mode = "trigger",
        func = function(ply, ent)

        end,
    },
    
    
    

noragdoll=true,
	
	-- R click function
   	reload=function(ply,ent)
        ply.OnHold = true

        ply:Freeze(true)

        ent:PillAnim('roar')

        timer.Simple(3, function()
            ply.OnHold = false

            ply:Freeze(false)
        end)
    end,

	
    -- F Click function
    flashlight=function(ply,ent)

    end,
	
	-- Jump Attack Spacebar Function 
    jump=function(ply,ent)

    end
    
}, function(form)
    -- The legacy damage branches are for Sandbox and NPCs.
    form.hnsKillAPI = true
    form.hnsAbilities = {
        { id = "attack", name = "Ataque", key = IN_ATTACK, OnUse = form.attack.func },
        { id = "roar", name = "Rugido", key = IN_RELOAD, OnUse = form.reload },
    }
    form.attack, form.attack2, form.reload = nil, nil, nil
end)

pk_pills.register("pill_ppt5chum",{

    printName="Chum Chompkins",
	
    model="models/ppt/Chum.mdl",
	
	modelScale="1",

    noragdoll = true,
    muteSteps = true,
    _ppt5_pill_ds = true,
	
    anims={
        default={
            idle="hostile_idle",
			run="hostile_run",
            walk="hostile_walk",
            crouch_idle="idle",
            crouch_walk="walk",
			jumpscare="kill"
        },
    },

    FirstPersonBone = {
        'head',
        15,
        0,
        10,
    },
    ThirdPersonBone = {
        'spine_02',
        0,
        22,
        10,
    },
	
    moveSpeed={
        walk=47,
        run=500,
        ducked=96,
    },
	
    sounds={
		kill="chum/kill.wav",
    },
	

    type="ply",

    camera={
        dist=130
    },
	
    jumpPower=0,
	
    health=200000,
	
	movePoseMode="xy",
		aim={
		xPose="aim_pitch",
		yPose="aim_yaw",
		nocrosshair = true
	},
	
	canAim=function(ply,ent)
		return ent.active
	end,
    
    ppt5_initialize=function(ply,ent,puppet)
    end,

    think_n_ppt5=function(ply, ent)
    end,

    attack = {
        mode = 'trigger',
        func = function(ply, ent)
            if CLIENT then return end
    
            local targetOrigin = ent:LocalToWorld(Vector(0, 0, 50))
local entity
if SherlockHNS then
    entity = SherlockHNS.FindVictim(ply, targetOrigin, 130, {
        filter = function(v)
            local trace = util.TraceLine({
                start = ent:EyePos(),
                endpos = v:EyePos(),
                filter = {ent, ply},
                mask = MASK_VISIBLE
            })
            return not trace.Hit
        end,
    })
else
    for k, v in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 130)) do
                    if v:IsPlayer() or v:IsNextBot() or v:IsNPC() then
                        if v == ent or v == ply then continue end
        
                        if (v:IsPlayer() and v:Team() ~= TEAM_SPECTATOR) or ((v:IsNPC() or v:IsNextBot()) and v:Health() > 0) then
                            local trace = util.TraceLine({
                                start = ent:EyePos(),
                                endpos = v:EyePos(),
                                filter = {ent, ply},
                                mask = MASK_VISIBLE
                            })
        
                            if not trace.Hit then
                                entity = v
                                break
                            end
                        end
                    end
                end
end

if SherlockHNS and IsValid(entity) and entity:IsPlayer() then
                return pk_pills.playHNSJumpscare(ply, ent, entity, 2, {
                    camera = "ppt5_jumpscare_gen",
                    offset = 50,
                    animation = "jumpscare",
                    sound = "kill",
                })
            end

            if not IsValid(entity) then return end
    
            local pill = ent:GetPuppet()
            if not IsValid(pill) then return end
    
            local rag = ents.Create("prop_ragdoll")
            rag:SetModel(entity:GetModel())
            rag:SetPos(entity:GetPos())
            rag:SetAngles(entity:GetAngles())
            rag:Spawn()
            rag:SetCollisionGroup(COLLISION_GROUP_NONE)
            rag._thrown = false
            rag:SetOwner(ply)
    
            if entity:IsPlayer() then
                entity:Freeze(true)
                entity:AddFlags(FL_NOTARGET)
                entity:DrawViewModel(false)
                entity:SetActiveWeapon(nil)
    
                net.Start('ppt5_jumpscare_gen')
                net.WriteEntity(pill)
                net.WriteBool(true)
                net.Send(entity)
    
                entity:SetNoDraw(true)
                entity:SetNotSolid(true)
                entity:SetMoveType(MOVETYPE_NONE)
                entity:Freeze(true)
    
                rag:SetPreventTransmit(entity, true)
            else
                entity:NextThink(CurTime() + 1e9)
                entity:SetNoDraw(true)
                entity:SetNotSolid(true)
                entity:SetMoveType(MOVETYPE_NONE)
                if entity.SetIdle then pcall(entity.SetIdle, entity, true) end
            end
    
            entity:SetPos(pill:GetPos() + pill:GetForward() * 50)
    
            ply:Freeze(true)
    
            ent:PillAnim('jumpscare')
            ent:PillSound('kill')
    
            local TOTAL_KILL_TIME = 2
            local followHook = "ppt5_chum_kill_follow_" .. ent:EntIndex()
    
            local POS_OFFSET = Vector(0, 0, 0)
            local ANG_OFFSET = Angle(0, 0, 0)
    
            local boneIndex = pill:LookupBone("camera") or 0
            local startTime = CurTime()
    
            hook.Add("Think", followHook, function()
                if not IsValid(ent) or not IsValid(rag) or not IsValid(pill) or not IsValid(entity) then
                    hook.Remove("Think", followHook)
                    return
                end
    
                if CurTime() - startTime >= TOTAL_KILL_TIME then
                    hook.Remove("Think", followHook)
                    return
                end
    
                local bonePos, boneAng = pill:GetBonePosition(boneIndex)
                if (not bonePos or bonePos == vector_origin) then
                    bonePos = pill:GetPos() + pill:GetForward() * 30 + pill:GetUp() * 20
                    boneAng = boneAng or pill:GetAngles()
                end
    
                local forward = boneAng:Forward()
                local right   = boneAng:Right()
                local up      = boneAng:Up()
    
                local worldOffset = forward * POS_OFFSET.x + right * POS_OFFSET.y + up * POS_OFFSET.z
                local finalPos = bonePos + worldOffset
                local finalAng = boneAng + ANG_OFFSET
    
                local headPhys
                for i = 0, rag:GetPhysicsObjectCount() - 1 do
                    local phys = rag:GetPhysicsObjectNum(i)
                    if IsValid(phys) then
                        local physBone = rag:TranslatePhysBoneToBone(i)
                        local name = string.lower(rag:GetBoneName(physBone) or "")
                        if string.find(name, "head", 1, true) then
                            headPhys = phys
                            break
                        end
                    end
                end
                headPhys = headPhys or rag:GetPhysicsObject()
    
                if IsValid(headPhys) then
                    headPhys:SetPos(finalPos)
                    headPhys:SetAngles(finalAng)
                    headPhys:Wake()
                end
    
                for i = 0, rag:GetPhysicsObjectCount() - 1 do
                    local phys = rag:GetPhysicsObjectNum(i)
                    if IsValid(phys) then phys:Wake() end
                end
            end)
    
            timer.Simple(TOTAL_KILL_TIME, function()
                if IsValid(rag) then rag:Remove() end
                hook.Remove("Think", followHook)
    
                if not IsValid(entity) then
                    ply:Freeze(false)
                    return
                end
    
                ply:Freeze(false)
    
                if entity:IsPlayer() then
                    entity:Kill(ply)
    
                    net.Start('ppt5_jumpscare_gen')
                    net.WriteEntity(pill)
                    net.WriteBool(false)
                    net.Send(entity)
    
                    entity:RemoveFlags(FL_NOTARGET)
                    entity:Freeze(false)
                    entity:DrawViewModel(true)
    
                    entity:SetNoDraw(false)
                    entity:SetNotSolid(false)
                    entity:SetMoveType(MOVETYPE_WALK)
                else
                    entity:NextThink(CurTime())
                    entity:SetNoDraw(false)
                    entity:SetNotSolid(false)
                    entity:SetMoveType(MOVETYPE_STEP)
                    entity:TakeDamage(1e9, ply)
                end
            end)
    
            timer.Simple(2.2, function()
                if IsValid(ply) then ply.OnHold = false end
                entity = nil
            end)
        end,
    },

	
    --Right Click Attack Function
    attack2 = {
        mode = "trigger",
        func = function(ply, ent)

        end,
    },
    
    
    

noragdoll=true,
	
	-- R click function
    reload=function(ply,ent)
        if not ply.angry then ply.angry = 1 end
        if ply.angry and ply.angry == 1 then
            ent.formTable.anims.default.idle = "idle"
            ent.formTable.anims.default.walk = "walk" 
            pk_pills.setCostumeMoveSpeed(ent, 120, 500)
            ply.angry = 0
        else
            ent.formTable.anims.default.idle = "hostile_idle"
            ent.formTable.anims.default.walk = "hostile_walk" 
            ply.angry = 1
            pk_pills.setCostumeMoveSpeed(ent, 47, 500)
        end
    end,

	
    -- F Click function
    flashlight=function(ply,ent)

    end,
	
	-- Jump Attack Spacebar Function 
    jump=function(ply,ent)

    end
    
}, function(form)
    -- The legacy damage branches are for Sandbox and NPCs.
    form.hnsKillAPI = true
    form.hnsAbilities = {
        { id = "attack", name = "Ataque", key = IN_ATTACK, OnUse = form.attack.func },
        { id = "stance", name = "Alternar postura", key = IN_RELOAD, OnUse = form.reload },
    }
    form.attack, form.attack2, form.reload = nil, nil, nil
end)

pk_pills.register("pill_ppt5lily",{

    printName="Lily Lovebraids",
	
    model="models/ppt/Lily.mdl",
	
	modelScale="1",

    noragdoll = true,
    muteSteps = true,
    _ppt5_pill_ds = true,
    LilyLovebraidshud = true,
	
    anims={
        default={
            idle="idle",
			run="run",
            walk="walk",
			jumpscare="kill"
        },
    },

    FirstPersonBone = {
        'head',
        15,
        0,
        10,
    },
    ThirdPersonBone = {
        'cog',
        0,
        22,
        10,
    },
	
    moveSpeed={
        walk=60,
        run=500,
        ducked=60,
    },
	
    sounds={
		kill="lily/lilykillfixed.wav",
        killvo="PPT5.Lily.KillVO"
    },
	

    type="ply",

    camera={
        dist=120
    },
	
    jumpPower=0,
	
    health=200000,
	
	movePoseMode="xy",
		aim={
		xPose="aim_pitch",
		yPose="aim_yaw",
		nocrosshair = true
	},
	
	canAim=function(ply,ent)
		return ent.active
	end,
    
    ppt5_initialize=function(ply,ent,puppet)
    end,

    think_n_ppt5=function(ply, ent)
    end,

attack = {
    mode = 'trigger',
    func = function(ply, ent)
        local targetOrigin = ent:LocalToWorld(Vector(0, 0, 50))
local entity
if SherlockHNS then
    entity = SherlockHNS.FindVictim(ply, targetOrigin, 130, {
        filter = function(v)
            local trace = util.TraceLine({
                start = ent:EyePos(),
                endpos = v:EyePos(),
                filter = {ent, ply},
                mask = MASK_VISIBLE
            })
            return not trace.Hit
        end,
    })
else
    for k, v in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 130)) do
                if v:IsPlayer() or v:IsNextBot() or v:IsNPC() then
                    if v == ent or v == ply then continue end
    
                    if (v:IsPlayer() and v:Team() ~= TEAM_SPECTATOR) or ((v:IsNPC() or v:IsNextBot()) and v:Health() > 0) then
                        local trace = util.TraceLine({
                            start = ent:EyePos(),
                            endpos = v:EyePos(),
                            filter = {ent, ply},
                            mask = MASK_VISIBLE
                        })
    
                        if not trace.Hit then
                            entity = v
                            break
                        end
                    end
                end
            end
end

if SherlockHNS and IsValid(entity) and entity:IsPlayer() then
            return pk_pills.playHNSJumpscare(ply, ent, entity, 7, {
                camera = "ppt5_jumpscare_gen",
                offset = 50,
                animation = "jumpscare",
                sound = "kill",
            })
        end

        if not IsValid(entity) then 
            return 
        end

        local pill = ent:GetPuppet()

        if entity:IsPlayer() then
            entity:Freeze(true)
            entity:AddFlags(FL_NOTARGET)
            entity:DrawViewModel(false)
            entity:SetActiveWeapon(nil)

            net.Start('ppt5_jumpscare_gen')
            net.WriteEntity(pill)
            net.WriteBool(true)
            net.Send(entity)

            
        else
            entity:NextThink(CurTime() + 1e9)
        end

        entity:SetPos(pill:GetPos() + pill:GetForward() * 50)

        ply:Freeze(true)
        

        ent:PillAnim('jumpscare')

        ent:PillSound('kill')

        timer.Simple(2, function()
            if not (IsValid(ent)) then return end
            
            ent:PillSound('killvo')
        end)
        
        timer.Simple(7, function()
            if not (IsValid(entity) and IsValid(ent)) then return end
            
            ply:Freeze(false)

            if entity:IsPlayer() then
                entity:Kill(ply)
               

                net.Start('ppt5_jumpscare_gen')
                net.WriteEntity(pill)
                net.WriteBool(false)
                net.Send(entity)

                
                entity:RemoveFlags(FL_NOTARGET)
                entity:Freeze(false)
                entity:DrawViewModel(true)
            else
                entity:NextThink(CurTime())
                entity:TakeDamage(1e9, ply)
            end
        end)

        timer.Simple(7.3, function()
            ply.OnHold = false
            entity = nil
        end)
    end,
},

	
    --Right Click Attack Function
    attack2 = {
        mode = "trigger",
        func = function(ply, ent)

        end,
    },
    
    
    

noragdoll=true,
	
	-- R click function
   	reload=function(ply,ent)
        if SERVER then

            if ent:GetNWFloat("blastnit_lilylovebraids_ability") > CurTime() then return end

            local tr = ply:GetEyeTrace()
            local door = tr.Entity

            if IsValid(door) then
                if door:GetClass() == "prop_door_rotating" or door:GetClass() == "func_door" or door:GetClass() == "func_door_rotating" then

                    ent:SetNWFloat("blastnit_lilylovebraids_ability", CurTime() + 30)
                    pk_pills.setHNSCooldown(ent, "lock", ent:GetNWFloat("blastnit_lilylovebraids_ability") - CurTime())
                    if door:GetNWBool("CoveredInWebs_lilylove_blastnit") then
                        door:SetNWBool("CoveredInWebs_lilylove_blastnit", false)
                    else
                        door:SetNWBool("CoveredInWebs_lilylove_blastnit", true)
                        local lockProp1 = ents.Create("prop_physics")
                        if IsValid(lockProp1) then
                            lockProp1:SetModel("models/ppt/hairbow.mdl")
                            lockProp1:SetPos(door:LocalToWorld(door:OBBCenter()) + door:GetForward()*5)
                            lockProp1:SetAngles(door:GetAngles())
                            lockProp1:Spawn()
                            lockProp1:Activate()

                            lockProp1:SetMoveType(MOVETYPE_NONE)
                            lockProp1:SetCollisionGroup(COLLISION_GROUP_WEAPON)

                            lockProp1:SetParent(door)
                            door:DeleteOnRemove(lockProp1)
                            
                            lockProp1:SetHealth(50)
                            lockProp1:SetMaxHealth(50)
                            --ent:DeleteOnRemove(lockProp1)
                        end
                        local lockProp2 = ents.Create("prop_physics")
                        if IsValid(lockProp2) then
                            lockProp2:SetModel("models/ppt/hairbow.mdl")
                            lockProp2:SetPos(door:LocalToWorld(door:OBBCenter()) + door:GetForward()*-5)
                            local doorangle = door:GetAngles()
                            doorangle:RotateAroundAxis(door:GetUp(), 180)
                            lockProp2:SetAngles(doorangle)
                            lockProp2:Spawn()
                            lockProp2:Activate()

                            lockProp2:SetMoveType(MOVETYPE_NONE)
                            lockProp2:SetCollisionGroup(COLLISION_GROUP_WEAPON)

                            lockProp2:SetParent(door)
                            door:DeleteOnRemove(lockProp2)

                            lockProp2:SetHealth(50)
                            lockProp2:SetMaxHealth(50)
                            --ent:DeleteOnRemove(lockProp2)
                        end


                        local damagehookname = "Lily_DoorLock_Damage".. lockProp2:EntIndex().. " " .. lockProp1:EntIndex()
                        hook.Add("EntityTakeDamage", damagehookname, function(ent, dmginfo)
                            if ent == lockProp2 or ent == lockProp1 or ent == Door then else return end
                            lockProp1:SetHealth(lockProp1:Health()-dmginfo:GetDamage())
                            lockProp2:SetHealth(lockProp2:Health()-dmginfo:GetDamage())

                            if lockProp2:Health() <= 0 or lockProp1:Health() <= 0 then
                                if IsValid(lockProp1) then
                                    lockProp1:Remove()
                                end
                                if IsValid(lockProp2) then
                                    lockProp2:Remove()
                                end
                                if IsValid(door) then
                                    door:SetNWBool("CoveredInWebs_lilylove_blastnit", false)
                                    door:Fire("Unlock", "", 0)
                                end
                            end
                            return true
                        end)

                        lockProp1:CallOnRemove("UnlockDoor", function()
                            if IsValid(lockProp2) then
                                lockProp2:Remove()
                            end
                            if IsValid(door) then
                                door:Fire("Unlock", "", 0)
                                door:SetNWBool("CoveredInWebs_lilylove_blastnit", false)
                            end
                        end)
                        lockProp2:CallOnRemove("UnlockDoor", function()
                            if IsValid(lockProp1) then
                                lockProp1:Remove()
                            end
                            if IsValid(door) then
                                door:Fire("Unlock", "", 0)
                                door:SetNWBool("CoveredInWebs_lilylove_blastnit", false)
                            end
                        end)
                        local hookname = "LilyLoveBriads_lockdoor".. lockProp2:EntIndex().. " " .. lockProp1:EntIndex()
                        hook.Add("Tick", hookname, function()

                            if !IsValid(lockProp1) or !IsValid(lockProp2) or !IsValid(door) or not door:GetNWBool("CoveredInWebs_lilylove_blastnit") then
                                if IsValid(lockProp1) then
                                    lockProp1:Remove()
                                end
                                if IsValid(lockProp2) then
                                    lockProp2:Remove()
                                end
                                hook.Remove("Tick", hookname)
                                hook.Remove("EntityTakeDamage", damagehookname)
                                if IsValid(door) then
                                    door:Fire("Unlock", "", 0)
                                    door:SetNWBool("CoveredInWebs_lilylove_blastnit", false)
                                end
                                return
                            end
                            
                            door:Fire("Close", "", 0)
                            door:Fire("Lock", "", 0)
                        end)
                    end
                end
            end
            
        end
    end,

	
    -- F Click function
    flashlight=function(ply,ent)

    end,
	
	-- Jump Attack Spacebar Function 
    jump=function(ply,ent)

    end
    
}, function(form)
    -- The legacy damage branches are for Sandbox and NPCs.
    form.hnsKillAPI = true
    form.hnsAbilities = {
        { id = "attack", name = "Ataque", key = IN_ATTACK, OnUse = form.attack.func },
        { id = "lock", name = "Trancar porta", key = IN_RELOAD, OnUse = form.reload },
    }
    form.attack, form.attack2, form.reload = nil, nil, nil
end)