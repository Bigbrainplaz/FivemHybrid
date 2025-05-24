Hybrid Vehicle Script for FiveM

Overview

This script adds a realistic hybrid vehicle system to your FiveM server, enabling vehicles to switch between electric (hybrid) and engine modes based on speed and driver behavior. It supports creep mode and ensures notifications are only sent to the driver.

Features

- Hybrid Mode: Vehicles start in hybrid mode immediately when the driver enters the vehicle.
- Speed-Based Switching: Automatically disables hybrid mode above certain speeds and re-enables it after 1 minute 45 seconds of low speed or being stopped.
- Creep Mode: Optional toggle to simulate slow vehicle movement behavior.
- Driver-Only Notifications: Chat messages about hybrid status changes are shown only to the driver.
- Sound Effects: Electric and engine sounds play corresponding to the hybrid mode status.
- Sync Across Network: Hybrid mode status is synced with the server and other clients.

Supported Vehicles

- Currently configured for the vehicle model `slick20fpiu`.
- Electric sound: "voltic"
- Engine sound: "ecoboostv6"

To add more vehicles, extend the `hybridVehicles` table with your vehicle model hash and associated sounds.

Installation

1. Place the script in your server resources folder.
2. Add the resource to your `server.cfg`:

   start hybrid-vehicle-script

3. Make sure your server has the necessary permissions for `TriggerServerEvent` calls.

Usage

- Hybrid Mode automatically starts when the driver enters the vehicle.
- Use the /creep command to toggle creep mode on/off while in a vehicle.
- Hybrid mode disables above 60 km/h (or 70 km/h in creep mode) and re-enables after 1:45 of low speed or stopped.
- Notifications appear only to the driver in the chat.

Configuration

- Modify the `hybridVehicles` table to add or change supported vehicles and sounds.
- Adjust speed thresholds and timers in the main loop as needed.

Notes

- This script assumes the driver is always in seat -1.
- Notifications are client-side and visible only to the vehicle driver.
- Timers reset when entering or exiting vehicles to prevent unwanted hybrid toggling.

Support

If you encounter issues or have suggestions, feel free to reach out!

Enjoy your smooth and realistic hybrid vehicle experience on FiveM!
