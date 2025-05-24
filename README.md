# Hybrid Vehicle Script for FiveM

## License

**Custom License Agreement for hybridsystem**

Copyright © 2025 Tyler. All rights reserved.

This script is licensed under the following terms:

**YOU MAY:**  
- Use this script for personal or community server use only.  
- Modify the script for private use only (no distribution of modified versions).  

**YOU MAY NOT:**  
- Reupload, resell, share, or redistribute this script in any form.  
- Modify and rebrand the script to claim it as your own.  
- Remove or alter any copyright notices, credits, or license-related information.  
- Use any part of this script in another resource meant for resale.  
- Bypass or tamper with any licensing or authentication mechanisms if present.  

**OWNERSHIP:**  
This script remains the intellectual property of Tyler, its original author. You are granted a limited-use license, but all rights are reserved by the original creator.

**ENFORCEMENT:**  
Violations of this license may result in:  
- Revocation of your license and support  
- Permanent ban from future purchases or updates  
- DMCA takedowns, legal actions, or reporting to FiveM/Cfx.re  

**CONTACT:**  
For support or licensing inquiries, contact:  
Discord: bigbrainplaz  
Email: tstipcak@icloud.com

---

## Overview

This script adds a realistic hybrid vehicle system to your FiveM server, enabling vehicles to switch between electric (hybrid) and engine modes based on speed and driver behavior. It supports creep mode and ensures notifications are only sent to the driver.

## Features

- Hybrid Mode: Vehicles start in hybrid mode immediately when the driver enters the vehicle.  
- Speed-Based Switching: Automatically disables hybrid mode above certain speeds and re-enables it after 1 minute 45 seconds of low speed or being stopped.  
- Creep Mode: Optional toggle to simulate slow vehicle movement behavior.  
- Driver-Only Notifications: Chat messages about hybrid status changes are shown only to the driver.  
- Sound Effects: Electric and engine sounds play corresponding to the hybrid mode status.  
- Sync Across Network: Hybrid mode status is synced with the server and other clients.

## Supported Vehicles

- Currently configured for the vehicle model `slick20fpiu`.  
- Electric sound: "voltic"  
- Engine sound: "ecoboostv6"

To add more vehicles, extend the `hybridVehicles` table with your vehicle model hash and associated sounds.

## Installation

1. Place the script in your server resources folder.  
2. Add the resource to your `server.cfg`:

