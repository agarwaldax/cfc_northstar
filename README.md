# Call For Code 2019 - Northstar Front End
## About 
This is the front end iOS app for the Northstar project. It communicates with the backend Northstar cloud to predict wildfires, send alerts and route users to safe locations. In its current state, the app demonstrates the following functionality:
- alerts for wildfire danger and directions to safety
- exploration of and navigation to safe zones near your location
- exploration of potential fire hazards near your location

The app makes internal calls to the backend. Our current integration allows recieving an image of the wildfire using the GRPC protocol. Due to the effort required to setup a local server, the integration has been disabled for this demo. Instead, backend calls are mimicked in the front end. There are also other integrations that are yet to be implemented.

## Requirements
- Mac OS Mojave (v10.14.5) 
- XCode App (v10.2.1)

## Setting up the app
1. Clone this repository
2. Navigate to the repository in your terminal
3. Install Cocoapods
`$ sudo gem install cocoapods`
4. Run Cocoapods to create or update the XCode Workspace file in the repository
`$ pod repo update && pod install`
5. Open the resulting XCode **Workspace** file which will launch the XCode App
6. Build and run the app
![Alt text](/Screenshots/build_run.png?raw=true "Build Location")

If you run into issues please email daxit.agarwal@ibm.com

## Screenshots

![Alt text](/Screenshots/current_location.png?raw=true "Current Location")
![Alt text](/Screenshots/wildfire_alert.png?raw=true "Wildfire Alert")
![Alt text](/Screenshots/safe_zone_nav.png?raw=true "Safe Zone Navigation")
![Alt text](/Screenshots/explore_safe_zones.png?raw=true "Safe Zone Exploration")

