![image](https://github.com/user-attachments/assets/02fd0189-afc9-45d0-8377-0d1ae929f0ff)

# qbx_vehiclekeys
An advanced customizable vehicle key system for the Qbox framework

# Item based keys (modified)
- Every key is an ox_inventory item named `carkeys` (see `config/shared.lua`, add it to `ox_inventory/data/items.lua`)
- Each vehicle has one unique key id (`V<database id>` for owned vehicles, random for others). The key item stores it in its metadata with the plate, and the item is labelled with the plate
- Only a player holding the key item for that exact vehicle (or a shared job) can lock, unlock or start it. The server verifies every lock toggle
- Owners are handed the key when their vehicle spawns with a database id, which covers garages and dealerships
- Copies made with `/givekeys` share the same key id

# Features

## Backwards Compatibility with qb-vehiclekeys
All exports and events from qb-vehiclekeys will continue to work with qbx_vehiclekeys. However, we still recommend using the qbx_vehiclekey exports as they use less resources.

## General
- Players can obtain keys when entering a running vehicle (configurable)
- Vehicles can keep their engine running after exiting (configurable)
- World spawn vehicles have a random initial lock state (configurable)
- Exports to give/remove keys
- Vehicle lock status synced between clients
- Animations for all activities to increase immersion, including a special animation to play when toggling the engine!
- Keys are real `carkeys` items in ox_inventory, so they persist across reconnects and restarts

## Players Transfering Keys
- Players can give keys to the closest player or passengers in their vehicle via command
- Admins can also give keys
- Owners receive a key item when their vehicle spawns (garage, dealer, impound)

## Shared Job Vehicles
- Jobs can share vehicles, letting emergency workers all have keys to emergency vehicles for example
- Autolock supported so that players don't need to remember to lock their vehicles when exiting (configurable)

## Highly Customizable
Apply config to all vehicles, or choose a specific vehicle type, class, category, or model to apply settings to. This allows for different minigame difficulties dependent on the vehicle, or exempt certain vehicles from hotwiring, etc.

## Criminal Actions

### Carjacking
Point a weapon at an NPC driver to force them to stop, put their hands up, exit the vehicle, and run away, giving you keys. Only weapons on the configurable allow list work for carjacking.

### Lockpicking
Use lockpicks with ox_lib skill minigames to unlock vehicle doors.

### Hotwiring
Use lockpicks when in the driver seat to get keys to the vehicle.

### Searching For Keys
Search for the keys when in the driver seat to get keys to the vehicle.

### Police Alerts
Alerts police when a vehicle is being broken into, or stolen.
- Lower chance to alert at night (configurable)
- cooldown to prevent spam (configurable)
