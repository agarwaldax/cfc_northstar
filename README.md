# Call For Code 2019 - Northstar Front End
## About 
This is the front end iOS app for the Northstar project. It communicates with the backend ML model to predict wildfires, send alerts and route users to safe locations. In its current state, the app demonstrates the following functionality:
- alerts for wildfire danger and directions to safety
- exploration of and navigation to safe zones near your location
- exploration of potential fire hazards near your location

The app makes internal calls to the backend, but due to the effort required to setup a local server, the functionality has been disabled for this demo. Instead, backend calls are mimicked in the front end.

## Setting up the app (Mac OS Only)
1. Clone the repository
2. Navigate to the repository in your terminal
3. Install Cocoapods
`$ sudo gem install cocoapods`
4. Run Cocoapods 
`$ pod repo update && pod install`
5. Open the XCode **Workspace**
6. Build and run the app

If you run into issues please email daxit.agarwal@ibm.com
