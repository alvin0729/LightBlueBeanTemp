source 'https://github.com/CocoaPods/Specs.git'
workspace 'BeanXcodeWorkspace.xcworkspace'

xcodeproj 'iOSApiExample/iOSApiExample.xcodeproj'

target :iOSApiExample, :exclusive => true do
    platform :ios, '7.0'
    xcodeproj 'iOSApiExample/iOSApiExample.xcodeproj'
    pod 'Bean-iOS-OSX-SDK'
end

target :iOSConnectionExample, :exclusive => true do
    platform :ios, '7.0'
    xcodeproj 'iOSConnectionExample/iOSConnectionExample.xcodeproj'
    pod 'Bean-iOS-OSX-SDK'
end

target :MacApiExample, :exclusive => true do
    platform :osx, '10.9'
    xcodeproj 'MacApiExample/MacApiExample.xcodeproj'
    pod 'Bean-iOS-OSX-SDK'
end

target :MacConnectionExample, :exclusive => true do
    platform :osx, '10.9'
    xcodeproj 'MacConnectionExample/MacConnectionExample.xcodeproj'
    pod 'Bean-iOS-OSX-SDK'
end