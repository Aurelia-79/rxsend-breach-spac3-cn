-- RXSEND compatibility DModelPanel.
-- This panel supplies BoneMerged(), used by the inventory and chat avatars.
-- The full implementation is kept in the server's lua/vgui copy; this shim
-- is intentionally loaded from the gamemode so clients receive it reliably.
if CLIENT and vgui and vgui.GetControlTable and vgui.GetControlTable("DModelPanel") then
    local base = vgui.GetControlTable("DModelPanel")
    if base and not base.BoneMerged then
        function base:BoneMerged(model, sub_material, no_draw, skin)
            local ent = self:GetEntity()
            if not IsValid(ent) or not model then return end
            local child = ClientsideModel(model, RENDERGROUP_OTHER)
            if not IsValid(child) then return end
            child:SetParent(ent, 0)
            child:SetLocalPos(vector_origin)
            child:SetLocalAngles(angle_zero)
            child:AddEffects(bit.bor(EF_BONEMERGE, EF_NOSHADOW, EF_NORECEIVESHADOW))
            if skin then child:SetSkin(skin) end
            if sub_material then child:SetSubMaterial(0, sub_material) end
            ent.BoneMergedEnts = ent.BoneMergedEnts or {}
            table.insert(ent.BoneMergedEnts, child)
            ent.bonemerge_ent = child
            return child
        end
    end
end
