//
//  TealiumDeviceDataModule.swift
//  SegueCatalog
//
//  Created by Jason Koo on 8/3/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import UIKit
import CoreTelephony

enum TealiumDeviceDataModuleKey {
    static let moduleName = "devicedata"
}

enum TealiumDeviceDataValue {
    static let unknown = "unknown"
}

class TealiumDeviceDataModule : TealiumModule {
    
    var data = [String:Any]()
    
    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumDeviceDataModuleKey.moduleName,
                                   priority: 525,
                                   build: 1,
                                   enabled: true)
    }
    
    override func enable(_ request: TealiumEnableRequest) {
        
        isEnabled = true
        data = enableTimeData()
        
        didFinish(request)
    }
    
    override func track(_ request: TealiumTrackRequest) {
        
        // Add device data to the data stream.
        var newData = request.data
        newData += data
        newData += trackTimeData()
        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: request.completion)
        
        didFinish(newTrack)
    }
    
    
    /// Data that only needs to be retrieved once for the lifetime of the host app.
    ///
    /// - Returns: Dictionary of device data.
    func enableTimeData() -> [String : Any] {
        
        var result = [String : Any]()

        result[TealiumDeviceDataKey.architecture] = TealiumDeviceData.architecture()
        result[TealiumDeviceDataKey.build] = TealiumDeviceData.oSBuild()
        result[TealiumDeviceDataKey.cpuType] = TealiumDeviceData.cpuType()
        result[TealiumDeviceDataKey.model] = TealiumDeviceData.model()
        result[TealiumDeviceDataKey.name] = TealiumDeviceData.name()
        result[TealiumDeviceDataKey.osVersion] = TealiumDeviceData.oSVersion()

        return result
    }
    
    
    /// Data that needs to be polled at time of interest, these may change during the lifetime of the host app.
    ///
    /// - Returns: Dictionary of device data.
    func trackTimeData() -> [String : Any] {
        
        var result = [String:Any]()
        
        result[TealiumDeviceDataKey.batteryPercent] = TealiumDeviceData.batteryPercent()
        result[TealiumDeviceDataKey.isCharging] = TealiumDeviceData.isCharging()
        result[TealiumDeviceDataKey.language] = TealiumDeviceData.iso639Language()
        result.merge(TealiumDeviceData.orientation()) { (_, new) -> Any in
            new
        }
        result.merge(TealiumDeviceData.carrierInfo()) { (_, new) -> Any in
            new
        }
        return result
        
    }
}

enum TealiumDeviceDataKey {
    static let name = "device"
    static let architecture = "device_architecture"
    static let batteryPercent = "device_battery_percent"
    static let build = "device_build"
    static let cpuType = "device_cputype"
    static let isCharging = "device_ischarging"
    static let language = "device_language"
    static let memoryAvailable = "device_memory_available"
    static let memoryUsage = "device_memory_usage"
    static let model = "device_model"
    static let orientation = "device_orientation"
    static let osBuild = "device_os_build"
    static let osVersion = "device_os_version"
    static let resolution = "device_resolution"
}

class TealiumDeviceData {
    
    class func architecture() -> String {
    
        let bit = MemoryLayout<Int>.size
        if bit == MemoryLayout<Int64>.size {
            return "64"
        }
        return "32"
        
    }
    
    class func batteryPercent() -> String {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return String(describing: (UIDevice.current.batteryLevel * 100))
        
    }
    
    class func cpuType() -> String {
        
        var type = cpu_type_t()
        var cpuSize = MemoryLayout<cpu_type_t>.size
        sysctlbyname("hw.cputype", &type, &cpuSize, nil, 0)
        
        var subType = cpu_subtype_t()
        var subTypeSize = MemoryLayout<cpu_subtype_t>.size
        sysctlbyname("hw.cpusubtype", &subType, &subTypeSize, nil, 0)

        if type == CPU_TYPE_X86 {
            return "x86"
        }
        
        if subType == CPU_SUBTYPE_ARM64_V8 { return "ARM64v8"}
        if subType == CPU_SUBTYPE_ARM64_ALL { return "ARM64" }
        if subType == CPU_SUBTYPE_ARM_V8 { return "ARMV8"}
        if subType == CPU_SUBTYPE_ARM_V7 { return "ARMV7"}
        if subType == CPU_SUBTYPE_ARM_V7EM { return "ARMV7em"}
        if subType == CPU_SUBTYPE_ARM_V7F { return "ARMV7f"}
        if subType == CPU_SUBTYPE_ARM_V7K { return "ARMV7k"}
        if subType == CPU_SUBTYPE_ARM_V7M { return "ARMV7m"}
        if subType == CPU_SUBTYPE_ARM_V7S { return "ARMV7s"}
        if subType == CPU_SUBTYPE_ARM_V6 { return "ARMV6" }
        if subType == CPU_SUBTYPE_ARM_V6M { return "ARMV6m" }

        if type == CPU_TYPE_ARM { return "ARM" }

        
        return "Unknown"
    }
    
    class func isCharging() -> String {
    
        if UIDevice.current.batteryState == .charging {
            return "true"
        }
        
        return "false"
    }
    
    class func iso639Language() -> String {
        
        return Locale.preferredLanguages[0]
        
    }
    
    class func memoryAvailable() -> String {
        
        // TODO:
        return ""
    }
    
    class func memoryUsage() -> String {
        
        // TODO:
        return ""
    }
    
    class func model() -> String {
        var model = ""
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
                model = simulatorModelIdentifier
        }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        model = String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
        
        switch model {
            // iPhone
            case "iPhone4,1":
                return "iPhone 4S"
            case "iPhone5,1":
                return "iPhone 5 (model A1428, AT&T/Canada)"
            case "iPhone5,2":
                return "iPhone 5 (model A1429, everything else)"
            case "iPhone5,3":
                return "iPhone 5c (model A1456, A1532 | GSM)"
            case "iPhone5,4":
                return "iPhone 5c (model A1507, A1516, A1526 (China), A1529 | Global)"
            case "iPhone6,1":
                return "iPhone 5s (model A1433, A1533 | GSM)"
            case "iPhone6,2":
                return "iPhone 5s (model A1457, A1518, A1528 (China), A1530 | Global)"
            case "iPhone7,1":
                return "iPhone 6 Plus"
            case "iPhone7,2":
                return "iPhone 6"
            case "iPhone8,1":
                return "iPhone 6S"
            case "iPhone8,2":
                return "iPhone 6S Plus"
            case "iPhone8,4":
                return "iPhone SE"
            case "iPhone9,1":
                return "iPhone 7 (CDMA)"
            case "iPhone9,2":
                return "iPhone 7 Plus (CDMA)"
            case "iPhone9,3":
                return "iPhone 7 (GSM)"
            case "iPhone9,4":
                return "iPhone 7 Plus (GSM)"
            case "iPhone10,1":
                return "iPhone 8 (CDMA)"
            case "iPhone10,2":
                return "iPhone 8 Plus (CDMA)"
            case "iPhone10,3":
                return "iPhone X (CDMA)"
            case "iPhone10,4":
                return "iPhone 8 (GSM)"
            case "iPhone10,5":
                return "iPhone 8 Plus (GSM)"
            case "iPhone10,6":
                return "iPhone X (GSM)"
            // iPod Touch
            case "iPod5,1":
                return "iPod Touch 5th Generation"
            case "iPod7,1":
                return "iPod Touch 6th Generation"
            // iPad
            
            // Apple TV
            default:
                return "Unknown Device"
            
        }
    }
    
    class func name() -> String {
        
        return UIDevice.current.model
    }
    
    class func carrierInfo() -> Dictionary<String, String> {
        let networkInfo = CTTelephonyNetworkInfo()
        let connection = TealiumConnectivityModule.currentConnectionType()
        let carrier = networkInfo.subscriberCellularProvider
        return [
            "carrier_mnc" : carrier?.mobileNetworkCode ?? "",
            "carrier_mcc" : carrier?.mobileCountryCode ?? "",
            "carrier_iso" : carrier?.isoCountryCode ?? "",
            "carrier" : carrier?.carrierName ?? "",
            "connection_type" : connection
        ]
    }
    
    class func orientation() -> Dictionary<String, Any> {
        
        let orientation = UIDevice.current.orientation
        
        let isLandscape = orientation.isLandscape
        var fullOrientation = ["device_orientation" : isLandscape ? "Landscape" : "Portrait"]
        
        switch orientation {
        case .faceUp:
            fullOrientation["device_full_orientation"] = "Face Up"
        case .faceDown:
            fullOrientation["device_full_orientation"] = "Face Down"
        case .landscapeLeft:
            fullOrientation["device_full_orientation"] = "Landscape Left"
        case .landscapeRight:
            fullOrientation["device_full_orientation"] = "Landscape Right"
        case .portrait:
            fullOrientation["device_full_orientation"] = "Portrait"
        case .portraitUpsideDown:
            fullOrientation["device_full_orientation"] = "Portrait"
        case .unknown:
            fullOrientation["device_full_orientation"] = TealiumDeviceDataValue.unknown
        }
        return fullOrientation
    }
    
    class func oSBuild() -> String {
        
        guard let build = Bundle.main.infoDictionary?["DTSDKBuild"] as? String else {
            return TealiumDeviceDataValue.unknown
        }
        return build
        
    }
    
    class func oSVersion() -> String {
        
        return UIDevice.current.systemVersion
    }
    
}
