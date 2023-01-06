# Device Authority for iOS

In [our blog post](https://blog.sidetrack.app/debugging-in-production) we discussed the ability to create configuration profiles on iOS to secure access to certain functionality. This acts as a form of keycard, allowing the right people access to the right areas - useful for both indie developers and large companies who want to grant access to debug menus to employees only.

This Swift package aims to make it as easy as possible to adopt this pattern, building on top of the step-by-step instructions we published in [this Gist](https://gist.github.com/Sherlouk/ba24f6366cd2cb1f9ad9c400ca18ad09).

## Installation

### Command Line Tool

Each [release](https://github.com/getsidetrack/swift-device-authority/releases) includes a binary which you can download and execute.

Alternatively, you can clone the repository and `swift build` in the root of the project.

### DeviceAuthority Framework

You can add the DeviceAuthority package to your application using Swift Package Manager.

File > Add Packages > Paste URL `https://github.com/getsidetrack/swift-device-authority` > Add Package.

## Usage

### Command Line Tool

There are two commands provided by the command-line tool. Neither take parameters, but will ask you for inputs (defaults are provided where possible).

```shell
$ swift-device-authority create-authority
$ swift-device-authority create-leaf
```

Creating the authority will provide you with the mobileconfig which can be installed onto your iOS device or simulator.

Creating the leaf will provide you with the certificate which needs to be embedded within your iOS application.

All files will be saved in the current working directory. Only the mobileconfig and Leaf certificate are required, unless you intend on creating multiple leafs in the future (in which case you need to keep all authority files).

### DeviceAuthority Framework

Once installed, import `DeviceAuthority` and instantiate the `DeviceAuthority` struct with your Leaf certificate name (by default this will be 'SwiftDeviceAuthority-Leaf' but you can change this to anything you wish).

There are then three functions you can call, each provide the same functionality but vary with how they handle async code. See the Sample app for more information.