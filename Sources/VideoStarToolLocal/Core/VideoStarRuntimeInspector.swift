import Foundation

/// Selector + Objective-C type encoding captured from the supplied
/// Video Star 15.0.3 (1847) ARM64 executable. This is a read-only runtime
/// compatibility check; it never invokes host-app methods.
public struct VideoStarMethodRequirement: Codable, Equatable, Sendable {
    public let className: String
    public let selector: String
    public let typeEncoding: String

    public init(className: String, selector: String, typeEncoding: String) {
        self.className = className
        self.selector = selector
        self.typeEncoding = typeEncoding
    }
}

public struct VideoStarMethodObservation: Codable, Equatable, Sendable {
    public let className: String
    public let selector: String
    public let expectedTypeEncoding: String
    public let actualTypeEncoding: String?

    public var isAvailable: Bool { actualTypeEncoding != nil }
    public var signatureMatches: Bool { actualTypeEncoding == expectedTypeEncoding }
}

public struct VideoStarImageRequirement: Codable, Equatable, Sendable {
    public let name: String
    public let acceptedPathFragments: [String]

    public init(name: String, acceptedPathFragments: [String]) {
        self.name = name
        self.acceptedPathFragments = acceptedPathFragments
    }
}

public struct VideoStarImageObservation: Codable, Equatable, Sendable {
    public let name: String
    public let isLoaded: Bool
    public let matchedImagePath: String?
}

public struct VideoStarRuntimeReport: Codable, Equatable, Sendable {
    public let inspectionSupported: Bool
    public let hostBundleIdentifier: String?
    public let hostVersion: String?
    public let hostBuild: String?
    public let methodObservations: [VideoStarMethodObservation]
    public let imageObservations: [VideoStarImageObservation]

    public var missingMethods: [VideoStarMethodObservation] {
        methodObservations.filter { !$0.isAvailable }
    }

    public var signatureMismatches: [VideoStarMethodObservation] {
        methodObservations.filter { $0.isAvailable && !$0.signatureMatches }
    }

    public var missingImages: [VideoStarImageObservation] {
        imageObservations.filter { !$0.isLoaded }
    }

    /// True only when every declared editor method has its expected encoding.
    /// This is not a guarantee that the host's internal behavior is safe to call.
    public var hostMatchesInspectedTarget: Bool {
        hostBundleIdentifier == VideoStarRuntimeInspector.targetBundleIdentifier &&
        hostVersion == VideoStarRuntimeInspector.targetVersion &&
        hostBuild == VideoStarRuntimeInspector.targetBuild
    }

    public var editorAPIShapeMatches: Bool {
        inspectionSupported && hostMatchesInspectedTarget &&
        missingMethods.isEmpty && signatureMismatches.isEmpty
    }

    /// True only when all base images mentioned in the supplied IPA are loaded.
    /// Presence does not mean their functionality or entitlement hooks are used.
    public var runtimeBaseImagesPresent: Bool {
        inspectionSupported && missingImages.isEmpty
    }
}

public enum VideoStarRuntimeInspector {
    public static let targetBundleIdentifier = "com.frontierdesign.videostar"
    public static let targetVersion = "15.0.3"
    public static let targetBuild = "1847"

    /// These signatures were read from class method metadata in the supplied
    /// Video Star 15.0.3 executable. Kept to non-entitlement editor / QR APIs.
    public static let methodRequirements: [VideoStarMethodRequirement] = [
        .init(className: "MultiLayerEngine", selector: "layerAtLayerNum:",
              typeEncoding: "@24@0:8Q16"),
        .init(className: "MultiLayerEngine", selector: "layerTypeForLayer:",
              typeEncoding: "i24@0:8Q16"),
        .init(className: "MultiLayerEngine", selector: "setupImage:layerNum:layerType:clearMask:",
              typeEncoding: "@40@0:8@16Q24i32B36"),
        .init(className: "MultiLayerEngine", selector: "setupVideoLayer:forLayer:withInitialVolume:multiCheck:",
              typeEncoding: "@40@0:8@16Q24f32B36"),
        .init(className: "MultiLayerEngine", selector: "setupPresetLayer:fromLayer:",
              typeEncoding: "v32@0:8@16@24"),
        .init(className: "MultiLayerEngine", selector: "copyContentFromLayerNum:toLayerNum:forScene:",
              typeEncoding: "v40@0:8Q16Q24Q32"),
        .init(className: "MultiLayerWizEffectVC", selector: "getMultiLayerEngine",
              typeEncoding: "@16@0:8"),
        .init(className: "MultiLayerWizEffectVC", selector: "importNewPreset:keyFrameAction:qrDurationInFrames:",
              typeEncoding: "v40@0:8@16@24q32"),
        .init(className: "MultiLayerWizEffectVC", selector: "selectLayerNum:flash:",
              typeEncoding: "v28@0:8Q16B24"),
        .init(className: "MultiLayerWizEffectVC", selector: "makePhotoLayer:",
              typeEncoding: "v24@0:8@16"),
        .init(className: "MultiLayerWizEffectVC", selector: "makeVideoLayer:frameTimes:volume:",
              typeEncoding: "v40@0:8@16@24@32"),
        .init(className: "QRCodeManager", selector: "readQRCode:",
              typeEncoding: "@24@0:8@16"),
        .init(className: "QRCodeManager", selector: "validQRCheck:",
              typeEncoding: "B24@0:8@16"),
        .init(className: "QRCodeManager", selector: "selectedCode:withImageData:",
              typeEncoding: "v32@0:8@16@24"),
        .init(className: "QRCodeManager", selector: "saveCodeToPlist:desc:",
              typeEncoding: "v32@0:8@16@24")
    ]

    /// Runtime components explicitly present / weak-linked in the submitted IPA.
    /// They are checked for presence only; this code does not invoke or alter hooks.
    public static let imageRequirements: [VideoStarImageRequirement] = [
        .init(name: "VSPlusUltra", acceptedPathFragments: ["VSPlusUltra.dylib"]),
        .init(name: "VSFix1", acceptedPathFragments: ["VSFix1.dylib", "ipacrack_ioscodevn.dylib"]),
        .init(name: "VSFix2", acceptedPathFragments: ["VSFix2.dylib", "LeTi.dylib"]),
        .init(name: "VSFix3", acceptedPathFragments: ["VSFix3.dylib", "FireStore.dylib"]),
        .init(name: "VSFix4", acceptedPathFragments: ["VSFix4.dylib", "libsubstrate.dylib"]),
        .init(name: "CydiaSubstrate", acceptedPathFragments: ["CydiaSubstrate.framework/CydiaSubstrate"])
    ]

    public static func inspect() -> VideoStarRuntimeReport {
        #if canImport(ObjectiveC) && canImport(MachO)
        return inspectAppleRuntime()
        #else
        return VideoStarRuntimeReport(
            inspectionSupported: false,
            hostBundleIdentifier: nil,
            hostVersion: nil,
            hostBuild: nil,
            methodObservations: methodRequirements.map {
                .init(className: $0.className, selector: $0.selector,
                      expectedTypeEncoding: $0.typeEncoding, actualTypeEncoding: nil)
            },
            imageObservations: imageRequirements.map {
                .init(name: $0.name, isLoaded: false, matchedImagePath: nil)
            }
        )
        #endif
    }
}

#if canImport(ObjectiveC) && canImport(MachO)
import ObjectiveC
import MachO

private extension VideoStarRuntimeInspector {
    static func inspectAppleRuntime() -> VideoStarRuntimeReport {
        let methods = methodRequirements.map { requirement -> VideoStarMethodObservation in
            guard let targetClass = NSClassFromString(requirement.className) else {
                return .init(className: requirement.className, selector: requirement.selector,
                             expectedTypeEncoding: requirement.typeEncoding, actualTypeEncoding: nil)
            }
            let selector = NSSelectorFromString(requirement.selector)
            guard let method = class_getInstanceMethod(targetClass, selector),
                  let rawEncoding = method_getTypeEncoding(method) else {
                return .init(className: requirement.className, selector: requirement.selector,
                             expectedTypeEncoding: requirement.typeEncoding, actualTypeEncoding: nil)
            }
            return .init(className: requirement.className, selector: requirement.selector,
                         expectedTypeEncoding: requirement.typeEncoding,
                         actualTypeEncoding: String(cString: rawEncoding))
        }

        var loadedImages: [String] = []
        let count = _dyld_image_count()
        for index in 0..<count {
            guard let imageName = _dyld_get_image_name(index) else { continue }
            loadedImages.append(String(cString: imageName))
        }

        let images = imageRequirements.map { requirement -> VideoStarImageObservation in
            let match = loadedImages.first { path in
                requirement.acceptedPathFragments.contains { path.localizedCaseInsensitiveContains($0) }
            }
            return .init(name: requirement.name, isLoaded: match != nil, matchedImagePath: match)
        }

        let info = Bundle.main.infoDictionary ?? [:]
        return VideoStarRuntimeReport(
            inspectionSupported: true,
            hostBundleIdentifier: Bundle.main.bundleIdentifier,
            hostVersion: info["CFBundleShortVersionString"] as? String,
            hostBuild: info["CFBundleVersion"] as? String,
            methodObservations: methods,
            imageObservations: images
        )
    }
}
#endif
