Ext.Osiris.RegisterListener("EnteredCombat", 2, "after", function(object,_)  
    if Osi.HasPassive(object, "PASSIVE_FLANKING_BONUS") == 0 then
        Ext.Utils.Print("\tAdding passive: " .. "PASSIVE_FLANKING_BONUS" .. object)
        Osi.AddPassive(object, "PASSIVE_FLANKING_BONUS")
    else
        Ext.Utils.Print("\tSkipping; already has PASSIVE_FLANKING_BONUS")
    end
end)