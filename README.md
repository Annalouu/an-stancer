# An-stancer
- Fivem Stancer - Vehicle Adjustable Wheel Offsets and Suspension Height

# Script Based on renzu_stancer 
https://github.com/renzuzu/renzu_stancer

# Feats
- Item Supported (Install Stancer Kit)
- Very optimised for Qbcore Framework
- Adjustable Wheel Offsets
- Adjustable Vehicle Suspension Height
- Fully Server Sync (One Sync and Infinity only)
- Optimized System (Nearby Vehicles are only looped in client)
- Data is Saved to Database (Attached to Plate)
- One Sync State Bag system to avoid callbacks and triggerevents for data sharing from client to server.
- NUI Based and User Friendly Interface.

# Install
- Installation:
- Drag an-stancer to your resource folder and start at server.cfg
- Import stancer.sql
- ensure an-stancer (After Qb-core)
- Add this to your qb-core/shared/items.lua.

['stancerkit'] 				 	 = {['name'] = 'stancerkit', 			    	['label'] = 'Camber Arms', 				['weight'] = 2000, 	['type'] = 'item', 		['image'] = 'tunerchip.png', 			['unique'] = false, 	['useable'] = true, 	['shouldClose'] = true,	   ['combinable'] = nil,    ['description'] = 'Camber arms can be used to adjust vehicle tire angle'},


# Image
![image](https://cdn.discordapp.com/attachments/837147253562146846/1020302491646169088/unknown.png)

# Video

https://youtu.be/4bEgUwasUFg

# Framework Usage: 
- use item inside vehicle
- /giveitem id stancerkit 1

# ITEMS
- stancerkit

# dependency 
- QBcore
- PolyZone