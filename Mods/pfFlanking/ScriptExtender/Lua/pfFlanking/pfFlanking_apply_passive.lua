local function pfGetDistance(attacker, target)
    -- This is borrowed from Lunisole's Backstabbing Framework. Check it out! https://github.com/Lunisole/BackstabbingFramework
    -- Used to calculate distance between two entities.
    local selfx = attacker.Transform.Transform.Translate[1]
    local selfz = attacker.Transform.Transform.Translate[3]
    local targetx = target.Transform.Transform.Translate[1]
    local targetz = target.Transform.Transform.Translate[3]
    distance = {targetx-selfx,0,targetz-selfz}
    return distance
end

function pfFlankingBonus(attacker)
    local flanked = {}
    local seen = {}
    local index = 1
    local combatants = Ext.Entity.GetAllEntitiesWithComponent("IsInCombat")
    local attacking = Ext.Entity.Get(attacker)
    local allies = {}
    --gets a list of our allies
    for _,combatant in ipairs(combatants) do
        if (Osi.IsAlly(attacking.Uuid.EntityUuid,combatant.Uuid.EntityUuid) == 1) then
            table.insert(allies, combatant)
        end
    end
    --iterate through each combatant to see if we're flanking.
    for _,character in ipairs(combatants) do
        Osi.RemoveStatus(character.Uuid.EntityUuid,"IS_FLANKED")
        --If 'character' is an enemy, lets check for flanking.
        if (Osi.IsAlly(attacking.Uuid.EntityUuid,character.Uuid.EntityUuid) == 0) then
            local threateningRange = 0
            local distanceToTarget = pfGetDistance(attacking, character)
            local partyMemberThreateningRange = 0

            if (attacking:GetComponent("ThreatRange")) then
                threateningRange = (attacking.ThreatRange.field_0 + .1)
            end
            --Check our allies, see if we're flanking. Each enemy is combat runs through this loop once for each of our party members.
            for _,partyMember in pairs(allies) do
                local distanceToPartyMember = pfGetDistance(attacking, partyMember)               
                local distancePartyMemberToTarget = pfGetDistance(partyMember, character)
                if (partyMember:GetComponent("ThreatRange")) then
                    partyMemberThreateningRange = (partyMember.ThreatRange.field_0 + .1)
                end
                --If we're flanking, add the target to the flanked table. Print range info to console, mostly for debugging.
                if ((Ext.Math.Length(distanceToTarget) <= Ext.Math.Length(distanceToPartyMember)) and (Ext.Math.Length(distanceToPartyMember) >= (threateningRange - 0.25)) and (Ext.Math.Length(distanceToTarget) <= threateningRange) and (Ext.Math.Length(distancePartyMemberToTarget) <= partyMemberThreateningRange)) then
                    table.insert(flanked, character.Uuid.EntityUuid)
                    _P(character," is flanked!")
                    _P("distanceToTarget ",Ext.Math.Length(distanceToTarget),character)
                    _P("distanceToPartyMember ",Ext.Math.Length(distanceToPartyMember),partyMember)
                    _P("threateningRange ",threateningRange,attacking)
                    _P("partyMemberThreateningRange ",partyMemberThreateningRange,partyMember)
                end
            end
        end
    end
    --remove duplicates from flanked table
    while index <= #flanked do
        if seen[flanked[index]] then
           table.remove(flanked, index)
        else
            seen[flanked[index]] = true
            index = index + 1
        end
    end
    --apply status to flanked entities
    for _,k in pairs(flanked) do
        Osi.ApplyStatus(k,"IS_FLANKED",5.0,1)
        _P("IS_FLANKED applied to ",k)
    end
end

--When previewing a spell on a target, apply the IS_FLANKED status if the conditions are met.
Ext.Osiris.RegisterListener("StartedPreviewingSpell", 4, "before", function (attacker,_,_,_,_)
    pfFlankingBonus(attacker)
end)

--Give entities the PASSIVE_FLANKING_BONUS passive when they enter combat. This grants a +2 to weapon attack rolls against flanked enemies.
Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(object,_)  
    if Osi.HasPassive(object, "PASSIVE_FLANKING_BONUS") == 0 then
        Ext.Utils.Print("\tAdding passive: " .. "PASSIVE_FLANKING_BONUS" .. object)
        Osi.AddPassive(object, "PASSIVE_FLANKING_BONUS")
    else
        Ext.Utils.Print("\tSkipping; already has PASSIVE_FLANKING_BONUS")
    end
end)