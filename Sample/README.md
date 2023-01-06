# DeviceAuthority - Sample App

This is a very basic iOS application which provides barebones usage of the available APIs and acts as a simple test of functionality.

For your convenience, we have provided a mobileconfig and certificate to be used in this project. Do NOT use these in your own projects as it negates all security benefits - follow instructions in the root README on how to generate your own using our command-line tool.

## Demonstration

1. Open the Xcode project, and build the project to a simulator of your choice.
2. Notice how the app is 'Locked' because your simulator is not yet trusted.
3. Drag the mobileconfig file onto your Simulator.
4. Safari will open and it will ask if you want it to allow the profile to be downloaded - allow it.
5. Open Settings on your Simulator.
6. Select General and then Device Management.
7. Select 'DeviceAuthority Sample' (the profile we just copied over)
8. Select Install, Install and Install again.
9. You can then re-open or rebuild the iOS app onto the same simulator.
10. Now notice how the app is 'Unlocked' because the device has the secure profile on it.

At any time you can return to the Device Management page in Settings and remove the profile. This will put the application back to 'Locked'.

It is up to you as to when and how you choose to verify the device. You may choose to do it once on app startup, or perhaps every time the settings page in your app is opened. This is personal taste and depends on your app architecture.