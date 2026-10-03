#!/usr/bin/env swift

import Foundation

// MARK: - App Store Submission Validation Script
// This script validates your ProTip365 app before App Store submission

struct ValidationResult {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
}

class AppStoreValidator {
    
    func validateSubmission() -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        print("🔍 Validating ProTip365 App Store Submission...")
        print(String(repeating: "=", count: 50))
        
        // 1. Validate Info.plist
        validateInfoPlist(&errors, &warnings)
        
        // 2. Validate Subscription Configuration
        validateSubscriptionConfig(&errors, &warnings)
        
        // 3. Validate App Icons
        validateAppIcons(&errors, &warnings)
        
        // 4. Validate Localization
        validateLocalization(&errors, &warnings)
        
        // 5. Validate Privacy Descriptions
        validatePrivacyDescriptions(&errors, &warnings)
        
        // 6. Validate Project Settings
        validateProjectSettings(&errors, &warnings)
        
        print("\n📊 Validation Summary:")
        print(String(repeating: "=", count: 30))
        
        if errors.isEmpty {
            print("✅ All critical validations passed!")
        } else {
            print("❌ Critical issues found:")
            errors.forEach { print("   • \($0)") }
        }
        
        if !warnings.isEmpty {
            print("\n⚠️  Warnings:")
            warnings.forEach { print("   • \($0)") }
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    private func validateInfoPlist(_ errors: inout [String], _ warnings: inout [String]) {
        print("\n📋 Validating Info.plist...")
        
        guard FileManager.default.fileExists(atPath: "ProTip365/Info.plist"),
              let plistData = FileManager.default.contents(atPath: "ProTip365/Info.plist"),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            errors.append("Info.plist not found or invalid")
            return
        }
        
        // Check version consistency
        let bundleVersion = plist["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = plist["CFBundleVersion"] as? String ?? ""
        
        if bundleVersion == "1.1.30" && buildNumber == "30" {
            print("   ✅ Version: \(bundleVersion) (\(buildNumber))")
        } else {
            errors.append("Version mismatch: \(bundleVersion) (\(buildNumber))")
        }
        
        // Check required keys
        let requiredKeys = [
            "CFBundleDisplayName",
            "CFBundleIdentifier",
            "NSFaceIDUsageDescription",
            "NSLocalNetworkUsageDescription"
        ]
        
        for key in requiredKeys {
            if plist[key] != nil {
                print("   ✅ \(key)")
            } else {
                errors.append("Missing required key: \(key)")
            }
        }
        
        // Check localization
        if let localizations = plist["CFBundleLocalizations"] as? [String] {
            if localizations.contains("en") && localizations.contains("fr") && localizations.contains("es") {
                print("   ✅ Localizations: \(localizations.joined(separator: ", "))")
            } else {
                warnings.append("Incomplete localization: \(localizations.joined(separator: ", "))")
            }
        }
    }
    
    private func validateSubscriptionConfig(_ errors: inout [String], _ warnings: inout [String]) {
        print("\n💳 Validating Subscription Configuration...")
        
        guard FileManager.default.fileExists(atPath: "ProTip365/Protip365.storekit"),
              let storekitData = FileManager.default.contents(atPath: "ProTip365/Protip365.storekit"),
              let storekit = try? JSONSerialization.jsonObject(with: storekitData) as? [String: Any] else {
            errors.append("StoreKit configuration file not found")
            return
        }
        
        // Check subscription groups
        if let subscriptionGroups = storekit["subscriptionGroups"] as? [[String: Any]],
           let group = subscriptionGroups.first,
           let subscriptions = group["subscriptions"] as? [[String: Any]],
           let subscription = subscriptions.first {
            
            let productID = subscription["productID"] as? String ?? ""
            let price = subscription["displayPrice"] as? String ?? ""
            let period = subscription["recurringSubscriptionPeriod"] as? String ?? ""
            
            if productID == "com.protip365.premium.monthly" {
                print("   ✅ Product ID: \(productID)")
            } else {
                errors.append("Incorrect Product ID: \(productID)")
            }
            
            if price == "3.99" {
                print("   ✅ Price: $\(price)")
            } else {
                warnings.append("Price mismatch: $\(price)")
            }
            
            if period == "P1M" {
                print("   ✅ Subscription Period: Monthly")
            } else {
                warnings.append("Subscription period mismatch: \(period)")
            }
            
            // Check introductory offer
            if let introOffer = subscription["introductoryOffer"] as? [String: Any] {
                let paymentMode = introOffer["paymentMode"] as? String ?? ""
                let introPeriod = introOffer["subscriptionPeriod"] as? String ?? ""
                
                if paymentMode == "free" && introPeriod == "P1W" {
                    print("   ✅ Introductory Offer: 1 week free")
                } else {
                    warnings.append("Introductory offer mismatch: \(paymentMode) for \(introPeriod)")
                }
            }
        } else {
            errors.append("No subscription groups found")
        }
    }
    
    private func validateAppIcons(_ errors: inout [String], _ warnings: inout [String]) {
        print("\n🖼️  Validating App Icons...")
        
        let iconPath = "ProTip365/Assets.xcassets/AppIcon.appiconset/ProTip365Icon_1024.png"
        
        if FileManager.default.fileExists(atPath: iconPath) {
            print("   ✅ App icon exists: \(iconPath)")
            
            // Check if it's a valid image (basic check)
            if let imageData = FileManager.default.contents(atPath: iconPath),
               imageData.count > 1000 { // Basic size check
                print("   ✅ App icon appears valid")
            } else {
                warnings.append("App icon may be corrupted or too small")
            }
        } else {
            errors.append("App icon not found: \(iconPath)")
        }
    }
    
    private func validateLocalization(_ errors: inout [String], _ warnings: inout [String]) {
        print("\n🌍 Validating Localization...")
        
        // Check if localization files exist (basic check)
        let localizationPaths = [
            "ProTip365/Info.plist", // Already checked above
        ]
        
        for path in localizationPaths {
            if FileManager.default.fileExists(atPath: path) {
                print("   ✅ \(path)")
            } else {
                warnings.append("Missing localization file: \(path)")
            }
        }
    }
    
    private func validatePrivacyDescriptions(_ errors: inout [String], _ warnings: inout [String]) {
        print("\n🔒 Validating Privacy Descriptions...")
        
        guard FileManager.default.fileExists(atPath: "ProTip365/Info.plist"),
              let plistData = FileManager.default.contents(atPath: "ProTip365/Info.plist"),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return
        }
        
        let privacyKeys = [
            "NSFaceIDUsageDescription",
            "NSLocalNetworkUsageDescription",
            "NSPhotoLibraryUsageDescription",
            "NSCameraUsageDescription"
        ]
        
        for key in privacyKeys {
            if let description = plist[key] as? String, !description.isEmpty {
                print("   ✅ \(key)")
            } else {
                warnings.append("Missing or empty privacy description: \(key)")
            }
        }
    }
    
    private func validateProjectSettings(_ errors: inout [String], _ warnings: inout [String]) {
        print("\n⚙️  Validating Project Settings...")
        
        guard FileManager.default.fileExists(atPath: "ProTip365.xcodeproj/project.pbxproj"),
              let projectContent = try? String(contentsOfFile: "ProTip365.xcodeproj/project.pbxproj", encoding: .utf8) else {
            errors.append("Project file not found")
            return
        }
        
        // Check for version consistency
        let marketingVersionMatches = projectContent.components(separatedBy: .newlines)
            .filter { $0.contains("MARKETING_VERSION") }
            .allSatisfy { $0.contains("1.1.30") }
        
        let buildVersionMatches = projectContent.components(separatedBy: .newlines)
            .filter { $0.contains("CURRENT_PROJECT_VERSION") }
            .allSatisfy { $0.contains("30") }
        
        if marketingVersionMatches {
            print("   ✅ Marketing Version: 1.1.30")
        } else {
            errors.append("Marketing version mismatch in project settings")
        }
        
        if buildVersionMatches {
            print("   ✅ Build Version: 30")
        } else {
            errors.append("Build version mismatch in project settings")
        }
        
        // Check bundle identifier
        if projectContent.contains("com.protip365.monthly") {
            print("   ✅ Bundle Identifier: com.protip365.monthly")
        } else {
            errors.append("Bundle identifier mismatch")
        }
    }
}

// MARK: - Main Execution
let validator = AppStoreValidator()
let result = validator.validateSubmission()

if result.isValid {
    print("\n🎉 Ready for App Store submission!")
    print("You can now archive and submit your app.")
    exit(0)
} else {
    print("\n❌ Please fix the errors above before submitting.")
    exit(1)
}