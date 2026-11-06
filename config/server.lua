return {
    keyItem = {
        labelFormat = '%s',                                    -- item name shown in the inventory (%s = plate)
        descriptionFormat = 'Keys to the vehicle with plate %s', -- item description (%s = plate)
    },

    giveKeysToOwnerOnSpawn = true,  -- when a player-owned vehicle spawns (garage, dealer, impound...), give its owner a key item if online
    maxLockDistance = 8.0,          -- server-side max distance between player and vehicle for locking/unlocking
    ---@type table<WeaponTypeGroup, number>
    carjackChance = {                    -- Probability of successful carjacking based on weapon used
        [WeaponTypeGroup.MELEE] = 0.0,
        [WeaponTypeGroup.HANDGUN] = 0.5,
        [WeaponTypeGroup.SMG] = 0.75,
        [WeaponTypeGroup.SHOTGUN] = 0.90,
        [WeaponTypeGroup.RIFLE] = 0.90,
        [WeaponTypeGroup.LMG] = 0.99,
        [WeaponTypeGroup.SNIPER] = 0.99,
        [WeaponTypeGroup.HEAVY] = 0.99,
        [WeaponTypeGroup.THROWABLE] = 0.0,
        [WeaponTypeGroup.MISC] = 0.0,
    },
}
