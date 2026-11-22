
hook.Add("OnEntityCreated", "ppt5t_initialize_gem_2", function(ent)
    timer.Simple(0.01, function()
        if !IsValid(ent) then return end
        if ent:GetClass() ~= "pill_ent_costume" then return end


        if ent.formTable then
            local PuppetEntity = ent:GetPuppet()
            local entityply = ent:GetPillUser()

            if ent.formTable.ppt5_initialize then
                ent.formTable:ppt5_initialize(entityply, ent, PuppetEntity)
                 hook.Add("PlayerFootstep", "DisableFootstepID_OM:".. ent:EntIndex(), function(ply) if entityply == ply then return true end end)

                    ent:CallOnRemove("RemoveHook_OM"..ent:EntIndex(), function()
                        hook.Remove("PlayerFootstep", "DisableFootstepID_OM:".. ent:EntIndex())
                    end)

                local self = ent
                ent.Think = function()
                    local ply = self:GetPillUser()
                    local puppet = self:GetPuppet()
                    if not IsValid(puppet) or not IsValid(ply) then return end
                    local vel = ply:GetVelocity():Length()

                    if SERVER then
                        --Anims
                        local anims = table.Copy(self.formTable.anims.default or {})
                        table.Merge(anims, (IsValid(ply:GetActiveWeapon()) and self.formTable.anims[ply:GetActiveWeapon():GetHoldType()]) or (self.forceAnimSet and self.formTable.anims[self.forceAnimSet]) or {})
                        local anim
                        --local useSeqVel=true
                        local overrideRate

                        if (not self.anim or not anims[self.anim]) then
                            self.animFreeze = nil
                            self.animStart = nil
                        end

                        if self.animFreeze and not self.plyFrozen then
                            self:ApplyMoveSpeed()
                            self.plyFrozen = true
                        elseif not self.animFreeze and self.plyFrozen then
                            self:ApplyMoveSpeed()
                            self.plyFrozen = nil
                        end

                        if self.anim and anims[self.anim] then
                            anim = anims[self.anim]
                            overrideRate = anims[self.anim .. "_rate"] or 1
                            local cycle = puppet:GetCycle()

                            if not self.animStart then
                                if cycle == 1 or (self.animCycle and self.animCycle > cycle) or (string.lower(anim) ~= string.lower(puppet:GetSequenceName(puppet:GetSequence()))) then
                                    self.anim = nil
                                    self.animCycle = nil

                                    if self.animFreeze then
                                        self.animFreeze = nil
                                    end
                                elseif self.animCycle then
                                    self.animCycle = cycle
                                end
                            end
                        elseif self.tickAnim and anims[self.tickAnim] then
                            anim = anims[self.tickAnim]
                            overrideRate = anims[self.tickAnim .. "_rate"] or 1
                            self.tickAnim = nil
                        elseif self.burrowed then
                            anim = anims["burrow_loop"]
                        elseif ply:WaterLevel() > 2 then
                            anim = anims["swim"] or anims["glide"] or anims["idle"]
                        elseif ply:IsOnGround() then
                            if ply:Crouching() then
                                if vel > ply:GetCrouchedWalkSpeed() / 4 then
                                    anim = anims["crouch_walk"] or anims["crouch"] or anims["walk"] or anims["idle"]
                                else
                                    anim = anims["crouch"] or anims["idle"]
                                end
                            else
                                if vel > (ply:GetWalkSpeed() + ply:GetRunSpeed()) / 2 then
                                    anim = anims["run"] or anims["walk"] or anims["idle"]
                                elseif vel > ply:GetWalkSpeed() / 4 then
                                    anim = anims["walk"] or anims["idle"]
                                else
                                    anim = anims["idle"]
                                end
                            end
                        else
                            anim = anims["glide"] or anims["idle"]
                        end

                        if anim == anims["idle"] or anim == anims["crouch"] then
                            overrideRate = 1
                        end

                        if (anim and puppet:GetSequence() ~= puppet:LookupSequence(anim)) or self.animStart or (self.formTable.autoRestartAnims and puppet:GetCycle() == 1) then
                            puppet:ResetSequence(puppet:LookupSequence(anim))
                            puppet:SetCycle(0)
                            self.animCycle = 0
                        end

                        self.animStart = nil
                        local seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                        --if true then
                        if self.formTable.movePoseMode ~= "xy" and self.formTable.movePoseMode ~= "xy-bot" and not overrideRate then
                            local rate = overrideRate or vel / seq_vel

                            --goofy limitation (floods console with errors if above 12!)
                            if rate > 12 then
                                rate = 12
                            end

                            puppet:SetPlaybackRate(rate)
                        else
                            --puppet:SetPlaybackRate(1)
                        end

                        --print(puppet:GetCycle())
                        if self.formTable.movePoseMode then
                            --
                            if self.formTable.movePoseMode == "yaw" then
                                local move_dir = puppet:WorldToLocalAngles(ply:GetVelocity():Angle())
                                puppet:SetPoseParameter("move_yaw", move_dir.y)
                            elseif self.formTable.movePoseMode == "xy" then
                                if not overrideRate then
                                    local localvel = ply:WorldToLocal(ply:GetPos() + ply:GetVelocity())
                                    local maxdim = math.Max(math.abs(localvel.x), math.abs(localvel.y))
                                    local clampedvel = maxdim == 0 and Vector(0, 0, 0) or localvel / maxdim
                                    puppet:SetPoseParameter("move_x", clampedvel.x)
                                    puppet:SetPoseParameter("move_y", -clampedvel.y)
                                    seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                                    if seq_vel ~= 0 then
                                        puppet:SetPoseParameter("move_x", math.Clamp(localvel.x / seq_vel, -.99, .99))
                                        puppet:SetPoseParameter("move_y", math.Clamp(-localvel.y / seq_vel, -.99, .99))
                                    end
                                    --print(puppet:GetPlaybackRate())
                                else
                                    puppet:SetPoseParameter("move_x", 0)
                                    puppet:SetPoseParameter("move_y", 0)
                                end
                            elseif self.formTable.movePoseMode == "xy-bot" then
                                if not overrideRate then
                                    local localvel = ply:WorldToLocal(ply:GetPos() + ply:GetVelocity())
                                    local maxdim = math.Max(math.abs(localvel.x), math.abs(localvel.y))
                                    local clampedvel = maxdim == 0 and Vector(0, 0, 0) or localvel / maxdim
                                    local move_dir = puppet:WorldToLocalAngles(ply:GetVelocity():Angle())
                                    puppet:SetPoseParameter("move_x", clampedvel.x)
                                    puppet:SetPoseParameter("move_y", -clampedvel.y)
                                    puppet:SetPoseParameter("move_yaw", move_dir.y)
                                    puppet:SetPoseParameter("move_scale", 1)
                                    seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                                    if seq_vel ~= 0 then
                                        puppet:SetPoseParameter("move_x", math.Clamp(localvel.x / seq_vel, -.99, .99))
                                        puppet:SetPoseParameter("move_y", math.Clamp(-localvel.y / seq_vel, -.99, .99))
                                        puppet:SetPoseParameter("move_scale", math.Clamp(localvel:Length() / seq_vel, -.99, .99))
                                    end
                                    --print(puppet:GetPlaybackRate())
                                else
                                    puppet:SetPoseParameter("move_x", 0)
                                    puppet:SetPoseParameter("move_y", 0)
                                    puppet:SetPoseParameter("move_yaw", 0)
                                    puppet:SetPoseParameter("move_scale", 0)
                                end
                            end
                        end

                        --Aimage
                        if self.formTable.aim then
                            if self.formTable.aim.xPose then
                                local yaw = math.AngleDifference(ply:EyeAngles().y, self:GetAngles().y)

                                if self.formTable.aim.xInvert then
                                    yaw = -yaw
                                end

                                puppet:SetPoseParameter(self.formTable.aim.xPose, yaw)
                            end

                            if self.formTable.aim.yPose then
                                local pitch = math.AngleDifference(ply:EyeAngles().p, self:GetAngles().p)

                                if self.formTable.aim.yInvert then
                                    pitch = -pitch
                                end

                                puppet:SetPoseParameter(self.formTable.aim.yPose, pitch)
                            end
                        end

                        --gliding and landing
                        if not ply:IsOnGround() and ply:WaterLevel() == 0 and self.formTable.glideThink then
                            self.formTable.glideThink(ply, self)
                        end

                        if not ply:IsOnGround() and not self.touchingWater and ply:WaterLevel() > 0 and self.formTable.land then
                            self.formTable.land(ply, self)
                        end

                        --water death
                        self.touchingWater = ply:WaterLevel() > 1

                        if not SherlockHNS and self.formTable.damageFromWater and self.touchingWater then
                            if self.formTable.damageFromWater == -1 then
                                --self:PillDie()
                                ply:Kill()
                            else
                                ply:TakeDamage(self.formTable.damageFromWater)
                                --TODO APPLY DAMAGE
                            end
                        end

                        --tick attack
                        if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "tick" then
                            self.formTable.attack.func(ply, self, self.formTable.attack)
                        end

                        if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "tick" then
                            self.formTable.attack2.func(ply, self, self.formTable.attack2)
                        end

                        --auto attack
                        if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "auto" then
                            if not self.formTable.aim then
                                self:PillLoopSound("attack")
                            else
                                self:PillLoopStop("attack")
                            end

                            if (not self.lastAttack or (self.formTable.attack.interval or self.formTable.attack.delay) < CurTime() - self.lastAttack) then
                                self.formTable.attack.func(ply, self, self.formTable.attack)
                                self.lastAttack = CurTime()
                            end
                        else
                            self:PillLoopStop("attack")
                        end

                        if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "auto" then
                            if not self.formTable.aim then
                                self:PillLoopSound("attack2")
                            else
                                self:PillLoopStop("attack2")
                            end

                            if not self.lastAttack2 or (self.formTable.attack2.interval or self.formTable.attack2.delay) < CurTime() - self.lastAttack2 then
                                self.formTable.attack2.func(ply, self, self.formTable.attack2)
                                self.lastAttack2 = CurTime()
                            end
                        else
                            self:PillLoopStop("attack2")
                        end

                        --charge
                        if not SherlockHNS and self:GetChargeTime() ~= 0 then
                            if ply:OnGround() then
                                local charge = self.formTable.charge
                                local angs = ply:EyeAngles()
                                self:PillAnimTick("charge_loop")
                                local hit_ent = ply:TraceHullAttack(ply:EyePos(), ply:EyePos() + angs:Forward() * 100, Vector(-20, -20, -20), Vector(20, 20, 20), charge.dmg, DMG_CRUSH, 1, true)

                                if IsValid(hit_ent) then
                                    self:PillAnim("charge_hit", true)
                                    --self:PillGesture("charge_hit")
                                    self:PillSound("charge_hit")
                                    self:SetChargeTime(0)
                                    self:PillLoopStop("charge")
                                end
                            else
                                self:SetChargeTime(0)
                                self:PillLoopStop("charge")
                            end
                        end

                        --Cloak
                        if self.formTable.cloak then
                            local cloak = self.formTable.cloak

                            if self.iscloaked then
                                local cloakamt = self:GetCloakLeft()

                                if cloakamt ~= -1 then
                                    cloakamt = cloakamt - FrameTime()

                                    if cloakamt < 0 then
                                        cloakamt = 0
                                        self:ToggleCloak()
                                    end

                                    self:SetCloakLeft(cloakamt)
                                end
                            else
                                local cloakamt = self:GetCloakLeft()

                                if cloakmt ~= -1 and cloakamt < cloak.max then
                                    cloakamt = cloakamt + FrameTime() * cloak.rechargeRate

                                    if cloakamt > cloak.max then
                                        cloakamt = cloak.max
                                    end

                                    self:SetCloakLeft(cloakamt)
                                end
                            end

                            local color = self:GetPuppet():GetColor()

                            if self.iscloaked then
                                if color.a > 0 then
                                    color.a = color.a - 5
                                    self:GetPuppet():SetColor(color)
                                end
                            else
                                if color.a < 255 then
                                    color.a = color.a + 5
                                    self:GetPuppet():SetColor(color)
                                end
                            end

                            --PrintTable(color)
                            if IsValid(self.wepmdl) and self.wepmdl:GetColor().a ~= color.a then
                                self.wepmdl:SetColor(color)
                            end
                        end

                        --if !IsValid(ply) then self:NextThink(CurTime()) return true end
                        --wepon-no longer SO hackey
                        if not self.formTable.hideWeapons then
                            local realWep = self:GetPillUser():GetActiveWeapon()

                            --&&self:GetPillUser()!=ply or pk_pills.var_thirdperson:GetBool()) then
                            if IsValid(realWep) and realWep:GetModel() ~= "" then
                                --hiding the real thing [BROKEN]
                                --[[if realWep:GetRenderMode()!=RENDERMODE_NONE then
                                    realWep:SetRenderMode(RENDERMODE_NONE)
                                end]]
                                if realWep.pill_attachment then
                                    if IsValid(self.wepmdl) then
                                        self.wepmdl:Remove()
                                    end

                                    self.wepmdl = ents.Create("pill_attachment_wep")
                                    self.wepmdl:SetParent(self:GetPuppet())
                                    self.wepmdl:SetModel(realWep:GetModel())
                                    self.wepmdl.attachment = realWep.pill_attachment
                                    self.wepmdl:Spawn()

                                    if realWep.pill_offset then
                                        self.wepmdl:SetWepOffset(realWep.pill_offset)
                                    end

                                    if realWep.pill_angle then
                                        self.wepmdl:SetWepAng(realWep.pill_angle)
                                    end

                                    realWep.pill_proxy = self.wepmdl
                                elseif not IsValid(self.wepmdl) then
                                    self.wepmdl = ents.Create("pill_attachment_wep")
                                    self.wepmdl:SetParent(self:GetPuppet())
                                    self.wepmdl:SetModel(realWep:GetModel())
                                    self.wepmdl:Spawn()
                                    realWep.pill_proxy = self.wepmdl
                                elseif self.wepmdl:GetModel() ~= realWep:GetModel() then
                                    self.wepmdl:SetModel(realWep:GetModel())
                                end
                            elseif IsValid(self.wepmdl) then
                                self.wepmdl:Remove()
                            end
                        end
                    else
                        self:SetNWBool('clientsideshould', not pk_pills.convars.cl_thirdperson:GetBool())

                        if self:GetPillUser() ~= LocalPlayer() or true then
                            puppet:SetNoDraw(false)
                        end

                        local realWep = self:GetPillUser():GetActiveWeapon()

                        if IsValid(realWep) and realWep:GetModel() ~= "" and not realWep:GetNoDraw() then
                            realWep:SetNoDraw(true)
                        end
                    end

                    --Align pos and angles with player
                    if SERVER then
                        puppet:SetPos(ply:GetPos())
                        self:SetAngles(ply:GetAngles())
                    else
                        puppet:SetRenderOrigin(ply:GetPos())
                    end

                    if vel > 0 or math.abs(math.AngleDifference(puppet:GetAngles().y, ply:EyeAngles().y)) > 350 or self:GetNWBool('clientsideshould') then
                        local angs = ply:EyeAngles()
                        angs.p = 0

                        if SERVER then
                            puppet:SetAngles(angs)
                        else
                            --puppet:SetAngles(angs)
                            puppet:SetRenderAngles(angs)
                        end
                    end

                    self:NextThink(CurTime())

                    return true
                end


            else
            end
        end

        if ent.formTable.HandleAnimEvent_g_bear then
            local PuppetEntity = ent:GetPuppet()
            local entityply = ent:GetPillUser()

            if IsValid(PuppetEntity) then
                function PuppetEntity:AcceptInput(inputName, activator, caller, data)
                    ent.formTable.HandleAnimEvent_g_bear(entityply, ent, inputName)
                    return true
                end
            end
        end
    end)
end)

hook.Add("Think", "TrackPillCostumes_ppt5", function()
    for _, ent in ipairs(ents.FindByClass("pill_ent_costume")) do
        if !IsValid(ent) then continue end
        local ply = ent:GetPillUser()
        local puppet = ent:GetPuppet()

        if not IsValid(puppet) or not IsValid(ply) then continue end

        if ent.formTable.think_n_ppt5 then
            ent.formTable.think_n_ppt5(ply, ent)
        end
    end
end)



if SERVER then
    AddCSLuaFile()
    util.AddNetworkString('ppt5_jumpscare_gen')

else

    hook.Remove("CalcView", "momo_calcview")

    hook.Add("CalcView", "momo_calcview", function(ply, pos, ang, fov)
        local ent = pk_pills.getMappedEnt(LocalPlayer())

        if IsValid(ent) and ply:GetViewEntity() == ply then
            local startpos

            if ent.formTable.type == "phys" then
                startpos = ent:LocalToWorld(ent.formTable.camera and ent.formTable.camera.offset or Vector(0, 0, 0))
            else
                startpos = pos
            end

            if pk_pills.convars.cl_thirdperson:GetBool() then

                if ent.formTable.ThirdPersonBone then

                    if IsValid(ent:GetPuppet()) then
                        local bonename = ent.formTable.ThirdPersonBone[1]
                        local boneID = ent:GetPuppet():LookupBone(bonename)
                        local bonePos, boneAng = ent:GetPuppet():GetBonePosition(boneID)

                        local dist

                        if ent.formTable.type == "phys" and ent.formTable.camera and ent.formTable.camera.distFromSize then
                            dist = ent:BoundingRadius() * 5
                        else
                            dist = ent.formTable.camera and ent.formTable.camera.dist or 100
                        end
                        local startpos = bonePos + LocalPlayer():GetForward() * (ent.formTable.ThirdPersonBone[2]) + LocalPlayer():GetUp() * (ent.formTable.ThirdPersonBone[4])+ LocalPlayer():GetRight() * (ent.formTable.ThirdPersonBone[3])
                        local underslung = ent.formTable.camera and ent.formTable.camera.underslung
                        local offset = LocalToWorld(Vector(-dist, 0, underslung and -dist / 5 or dist / 5), Angle(0, 0, 0), Vector(0, 0, 0), ang)

                        local tr = util.TraceHull({
                            start = startpos,
                            endpos = startpos + offset,
                            filter = ent.camTraceFilter,
                            mins = Vector(-5, -5, -5),
                            maxs = Vector(5, 5, 5),
                            mask = MASK_VISIBLE
                        })

                        local view = {}
                        view.origin = tr.HitPos
                        view.angles = ang
                        view.fov = fov
                        view.drawviewer = true

                        return view
                    end
                end

                local dist

                if ent.formTable.type == "phys" and ent.formTable.camera and ent.formTable.camera.distFromSize then
                    dist = ent:BoundingRadius() * 5
                else
                    dist = ent.formTable.camera and ent.formTable.camera.dist or 100
                end

                local underslung = ent.formTable.camera and ent.formTable.camera.underslung
                local offset = LocalToWorld(Vector(-dist, 0, underslung and -dist / 5 or dist / 5), Angle(0, 0, 0), Vector(0, 0, 0), ang)

                local tr = util.TraceHull({
                    start = startpos,
                    endpos = startpos + offset,
                    filter = ent.camTraceFilter,
                    mins = Vector(-5, -5, -5),
                    maxs = Vector(5, 5, 5),
                    mask = MASK_VISIBLE
                })

                local view = {}
                view.origin = tr.HitPos
                view.angles = ang
                view.fov = fov
                view.drawviewer = true

                return view
            else
                if ent.formTable.FirstPersonBone then
                    if IsValid(ent:GetPuppet()) then
                        local bonename = ent.formTable.FirstPersonBone[1]
                        local boneID = ent:GetPuppet():LookupBone(bonename)
                        local bonePos, boneAng = ent:GetPuppet():GetBonePosition(boneID)
                        local view = {}
                        view.origin = bonePos + LocalPlayer():GetForward() * (ent.formTable.FirstPersonBone[2]) + LocalPlayer():GetUp() * (ent.formTable.FirstPersonBone[4])+ LocalPlayer():GetRight() * (ent.formTable.FirstPersonBone[3])
                        view.angles = ang
                        view.fov = fov
                        view.drawviewer = false
                        return view
                    end
                end
            end
        end
    end)


    surface.CreateFont("CreditsText_Large_LilyLoveBraids", {
        font = "Arial",
        size = 70,
        weight = 700,
        antialias = true,
    })

    local preservedmats = {
        ["BowTie"] = Material("blastnit/icon/BowTie.png"),
    }

    hook.Add("HUDPaint", "blastnit_lilylovebraids_hud", function()
        if SherlockHNS then return end
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local pillentity = ply.pk_pill_ent
        if not IsValid(pillentity) then return end
        if not pillentity.GetPuppet then return end
        if not IsValid(pillentity:GetPuppet()) then return end
        if not pillentity.formTable.LilyLovebraidshud then return end

        local screenW, screenH = ScrW(), ScrH()
        local iconize = ScreenScale(70)

        local lx, ly = screenW/2 + screenW/3, screenH - ScreenScale(80)

        surface.SetDrawColor(255,255,255,255)
        surface.SetMaterial(preservedmats["BowTie"])
        surface.DrawTexturedRectRotated(lx + iconize/2,ly + iconize/2,iconize,iconize,0)

        if pillentity:GetNWFloat("blastnit_lilylovebraids_ability") > CurTime() then
            local frac = math.Clamp(
                (pillentity:GetNWFloat("blastnit_lilylovebraids_ability") - CurTime()) /
                30,
                0, 1
            )

            local h  = Lerp(frac, 0, iconize)
            local y2 = Lerp(frac, ly + iconize, ly)
            local uv = Lerp(frac, 1, 0)

            surface.SetDrawColor(25,25,25,255)
            surface.DrawTexturedRectUV(lx,y2,iconize,h,0,uv,1,1)

            local number = math.ceil(pillentity:GetNWFloat("blastnit_lilylovebraids_ability") - CurTime())
            draw.SimpleTextOutlined(number,"CreditsText_Large_LilyLoveBraids",lx +iconize/2,ly +iconize/2,color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,6,color_black)
        end

        draw.SimpleTextOutlined("R","CreditsText_Large_LilyLoveBraids",lx + ScreenScale(5),ly + ScreenScale(2),color_white,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER,6,color_black)
    end)



    hook.Add("SetupPlayerVisibility", "VisibilityHandler_v2", function()
        local ply = LocalPlayer()

        local pillentity = ply.pk_pill_ent
        if IsValid(pillentity) then
            if ( pillentity:GetNWInt('Swallhaks', 0) >= CurTime() ) then

                for _, ent in ipairs(ents.GetAll()) do
                    if IsValid(ent) then
                        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
                            AddOriginToPVS(plr:GetPos())
                        end
                    end
                end
            end
        end
    end)

    hook.Add( "PreDrawHalos", "ppt5season_v2", function()
        local ply = LocalPlayer()

        local pillentity = ply.pk_pill_ent
        if IsValid(pillentity) then
            if ( pillentity:GetNWInt('Swallhaks', 0) >= CurTime() ) then
                local entities = {}

                for _, ent in ipairs(ents.GetAll()) do
                    if IsValid(ent) then
                        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
                            if ent == ply then continue end 
                            if ent == pillentity then continue end 
                            if ent:IsPlayer() and ent:Team() == TEAM_SPECTATOR then continue end

                            if ent:GetColor().a <= 30 then continue end
                            if ent:GetClass() == "pill_puppet" then continue end

                            table.insert(entities, ent)
                            
                        end
                    end
                end

                local alpha = 0
                local endTime = pillentity:GetNWInt('Swallhaks', 0) 

                if endTime > CurTime() then
                    local totalDuration = 10
                    local startTime = endTime - totalDuration
                    local fadeDuration = 1
                    if CurTime() < startTime + fadeDuration then
                        alpha = Lerp((CurTime() - startTime) / fadeDuration, 0, 155)
                    elseif CurTime() > endTime - fadeDuration then
                        alpha = Lerp((endTime - CurTime()) / fadeDuration, 0, 155)
                    else
                        alpha = 155
                    end
                end

                halo.Add(entities, Color(alpha,0,alpha), 5, 5, 50, true, true)
            end
        end
    end )


    net.Receive('ppt5_jumpscare_gen', function()
        local ent = net.ReadEntity()
        local state = net.ReadBool()
        local startTime = CurTime()

        local hookID = "ppt5_jumpscare_" .. LocalPlayer():SteamID()

        --print(state)

        if not state then
            hook.Remove('CalcView', hookID)
        else
            hook.Add('CalcView', hookID, function(ply, pos, angles, fov)
                if not IsValid(ply) or not ply:Alive() or !IsValid(ent) then
                    hook.Remove('CalcView', hookID)
                    if IsValid(ply) then
                        ply:RemoveFlags(FL_NOTARGET)
                        ply:Freeze(false)
                        ply:DrawViewModel(true)
                    end
                    return
                end

                local cam = ent:GetAttachment(ent:LookupAttachment('camera'))

                ply:AddFlags(FL_NOTARGET)
                ply:Freeze(true)
                ply:DrawViewModel(false)

                local lerpFactor = math.Clamp((CurTime() - startTime) / (0.7/3), 0, 1)
                
                local targetFOV = 75 

                local orgiginlerpto = LerpVector(lerpFactor, pos, cam.Pos)
                local angleslerpto = LerpAngle(lerpFactor, angles, cam.Ang)
                local interpolatedFOV = Lerp(lerpFactor, fov, targetFOV)

                local view = {
                    origin = orgiginlerpto,
                    angles = angleslerpto,
                    fov = interpolatedFOV,
                    drawviewer = false
                }
                return view
            end)
        end
    end)
end

local function AdvancedPillSound(SoundData, ent)
    if IsValid(ent) then
        SoundData = SoundData or {}
        SoundData.stringe = SoundData.stringe or {}
        SoundData.soundLevel = SoundData.soundLevel or 75
        SoundData.pitchPercent = SoundData.pitchPercent or 100
        SoundData.volume = SoundData.volume or 1
        SoundData.channel = SoundData.channel or CHAN_AUTO
        SoundData.soundFlags = SoundData.soundFlags or 0
        SoundData.dsp = SoundData.dsp or 0
        SoundData.filter = SoundData.filter or nil

        local chosenSound = SoundData.stringe

        if istable(SoundData.stringe) then
            local index = math.random(1, #SoundData.stringe)
            chosenSound = SoundData.stringe[index]
        end

        ent:EmitSound(
            chosenSound,
            SoundData.soundLevel,
            SoundData.pitchPercent,
            SoundData.volume,
            SoundData.channel,
            SoundData.soundFlags,
            SoundData.dsp,
            SoundData.filter
        )
    end
    return true
end


local function ppt5jackietien_jumpscare(ply, ent, duration, customanimstuff)
    if not ent.IsInJumpscare then ent.IsInJumpscare = 0 end
    if ent.IsInJumpscare >= CurTime() then return end
    if not ent.IsInJumpscareCooldown then ent.IsInJumpscareCooldown = 0 end
    if ent.IsInJumpscareCooldown >= CurTime() then return end

    local jumpscare_entity = nil

    for _, ent2 in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 90)) do
        if (ent2:IsPlayer() or ent2:IsNextBot() or ent2:IsNPC()) and ent2:Health() >= 0.1 then
            if ent2 == ply then continue end
            if ent2:IsPlayer() and ent2:Team() == TEAM_SPECTATOR then continue end

            if IsValid(ent2) then
                jumpscare_entity = ent2
                break
            end
        end
    end

    if SherlockHNS and IsValid(jumpscare_entity) and jumpscare_entity:IsPlayer() then
        return pk_pills.playHNSJumpscare(ply, ent, jumpscare_entity, duration, {
            camera = "ppt5_jumpscare_gen",
            onStart = customanimstuff,
        })
    end

    if jumpscare_entity ~= nil then
        
        ent.JuumpscareStart = CurTime()

        ent.jumpscare_entity = jumpscare_entity
        ent.entitylastpos = jumpscare_entity:GetPos()
        ent.entitylastang = jumpscare_entity:GetAngles()

        local targetAngle = (ply:GetPos() - jumpscare_entity:GetPos()):Angle()

        targetAngle.p = 0
        targetAngle.r = 0

        ply:SetNWInt("DisableMovement_jumpscare_pill_ppt5", duration+CurTime())
        jumpscare_entity:SetNWInt("DisableMovement_jumpscare_pill_ppt5", duration+CurTime())

        ent.IsInJumpscare = CurTime() + duration

        local puppet = ent:GetPuppet()

        if jumpscare_entity:IsPlayer() then
            net.Start('ppt5_jumpscare_gen')
            net.WriteEntity(puppet)
            net.WriteBool(true)
            net.Send(jumpscare_entity)
        else
            jumpscare_entity:NextThink(duration+0.1+CurTime())
        end
        
        jumpscare_entity:AddFlags(FL_NOTARGET)

        ent:CallOnRemove("ppt5Jumpscare"..ent:EntIndex(), function()
            if !IsValid(jumpscare_entity) then return end

            jumpscare_entity:RemoveFlags(FL_NOTARGET)
            ent.jumpscare_entity = nil

            if jumpscare_entity:IsPlayer() then
                net.Start('ppt5_jumpscare_gen')
                net.WriteEntity(puppet)
                net.WriteBool(false)
                net.Send(jumpscare_entity)
            else
                jumpscare_entity:NextThink(CurTime())
            end
            jumpscare_entity:SetPos(ent.entitylastpos)
            jumpscare_entity:SetAngles(ent.entitylastang)
            jumpscare_entity:SetNWInt("DisableMovement_jumpscare_pill_ppt5", CurTime())
        end)

        customanimstuff()
    end
end

hook.Add("SetupMove", "DisablePlayerMovement_ppt5", function(ply, mv, cmd)
    if ply:GetNWInt("DisableMovement_jumpscare_pill_ppt5") >= CurTime() then
        mv:SetForwardSpeed(0)
        mv:SetSideSpeed(0)
        mv:SetUpSpeed(0)
        mv:SetButtons(0)
    end
end)    

pk_pills.packStart("Poppy Playtime Chapter 5","Poppy Playtime Chapter 5","icon/proto_pill_thumb.png")

pk_pills.register("pill_ppt5prototype",{

    printName="The Prototype",
	
    model="models/ppt/Prototype.mdl",
	
	modelScale="2",

    noragdoll = true,
    muteSteps = true,
    _ppt5_pill_ds = true,
	
    anims={
        default={
            idle="idle",
			run="run",
            walk="walk",
			attack="kill",
			jumpscare="kill",
        },
    },

    FirstPersonBone = {
        'head',
        15,
        0,
        10,
    },
    ThirdPersonBone = {
        'spine_06',
        0,
        22,
        10,
    },
	
    moveSpeed={
        walk=120,
        run=530,
        ducked=75,
    },
	
    sounds={
		kill="proto/prototypekill.wav",
        killvoiceline=pk_pills.helpers.makeList("proto/killvoiceline#.wav",23),
    },
	

    type="ply",

    camera={
        dist=120
    },
	
    jumpPower=0,
	
    health=250000,
	
	movePoseMode="xy",
		aim={
		xPose="aim_yaw",
		yPose="aim_pitch",
		nocrosshair = true
	},
	
	canAim=function(ply,ent)
		return ent.active
	end,
    
    ppt5_initialize=function(ply,ent,puppet)

    end,

    think_n_ppt5=function()

    end,

attack = {
    mode = 'trigger',
    func = function(ply, ent)
        local entity

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
        local entity

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
    
            local entity
    
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
        local entity

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