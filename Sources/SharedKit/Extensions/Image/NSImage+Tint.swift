//
//  NSImage+Tint.swift
//  VisualDiffer
//
//  Created by davide ficano on 04/07/15.
//  Converted to Swift by davide ficano on 03/05/25.
//  Copyright (c) 2010 visualdiffer.com

import Cocoa

public extension NSImage {
    // copied from https://stackoverflow.com/a/1415200/195893
    // On Catalina kCIContextUseSoftwareRenderer raises error
    // ** OpenCL Error Notification: [CL_DEVICE_NOT_AVAILABLE] : OpenCL Error : Error: build program driver returned (-1) **
    // ** OpenCL Error Notification: OpenCL Warning : clBuildProgram failed: could not build program for 0xffffffff (Intel(R) Core(TM) i5-3210M CPU  2.50GHz) (err:-1) **
    // https://developer.apple.com/devcenter/download.action?path=/videos/wwdc_2011__hd/session_422__using_core_image_on_ios_and_mac_os_x.m4v
    // https://docs.huihoo.com/apple/wwdc/2011/session_422__using_core_image_on_ios_and_mac_os_x.pdf
    /**
     * Apply the tint color to image
     */
    func tintImage(
        _ tint: NSColor?,
        useSoftwareRenderer: Bool
    ) -> NSImage {
        if let tint,
           let color = CIColor(color: tint),
           let compositingFilter = composingFilter(colorFilter(color: color), monochromeFilter()),
           let outputImage = compositingFilter.value(forKey: kCIOutputImageKey) as? CIImage {
            let extend = outputImage.extent
            let tintedImage = NSImage(size: size)

            tintedImage.lockFocus()
            if let contextRef = NSGraphicsContext.current?.cgContext {
                let ciContext = CIContext(
                    cgContext: contextRef,
                    options: [CIContextOption.useSoftwareRenderer: useSoftwareRenderer]
                )
                let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                ciContext.draw(outputImage, in: rect, from: extend)
            }
            tintedImage.unlockFocus()

            return tintedImage
        }
        // swiftlint:disable:next force_cast
        return copy() as! NSImage
    }

    /**
     * Create a new image drawing the overImage in front of current image (the background image).
     * Use NSImageRep to improve image quality results
     * @param overImage the image to draw over the background
     */
    func overImage(_ overImage: NSImage) -> NSImage {
        let size = overImage.size
        let imageBounds = NSRect(x: 0, y: 0, width: size.width, height: size.height)
        let rep = NoodleCustomImageRep { _ in
            self.draw(at: NSPoint.zero, from: imageBounds, operation: .copy, fraction: 1)
            overImage.draw(at: NSPoint.zero, from: imageBounds, operation: .sourceOver, fraction: 1)
        }
        rep.size = size
        let image = NSImage(size: size)
        image.addRepresentation(rep)
        return image
    }

    private func colorFilter(color: CIColor) -> CIFilter? {
        guard let colorGenerator = CIFilter(name: "CIConstantColorGenerator"),
              let colorFilter = CIFilter(name: "CIColorControls") else {
            return nil
        }
        colorGenerator.setValue(color, forKey: kCIInputColorKey)

        colorFilter.setValue(colorGenerator.value(forKey: kCIOutputImageKey), forKey: kCIInputImageKey)
        colorFilter.setValue(NSNumber(value: 3.0), forKey: kCIInputSaturationKey)
        colorFilter.setValue(NSNumber(value: 0.35), forKey: kCIInputBrightnessKey)
        colorFilter.setValue(NSNumber(value: 1.0), forKey: kCIInputContrastKey)

        return colorFilter
    }

    private func monochromeFilter() -> CIFilter? {
        guard let monochromeFilter = CIFilter(name: "CIColorMonochrome"),
              let data = tiffRepresentation,
              let baseImage = CIImage(data: data) else {
            return nil
        }

        monochromeFilter.setValue(baseImage, forKey: kCIInputImageKey)
        monochromeFilter.setValue(CIColor(red: 0.75, green: 0.75, blue: 0.75), forKey: kCIInputColorKey)
        monochromeFilter.setValue(NSNumber(value: 1.0), forKey: kCIInputIntensityKey)

        return monochromeFilter
    }

    private func composingFilter(_ colorFilter: CIFilter?, _ monochromeFilter: CIFilter?) -> CIFilter? {
        guard let colorFilter,
              let monochromeFilter,
              let compositingFilter = CIFilter(name: "CIMultiplyCompositing") else {
            return nil
        }

        compositingFilter.setValue(colorFilter.value(forKey: kCIOutputImageKey), forKey: kCIInputImageKey)
        compositingFilter.setValue(monochromeFilter.value(forKey: kCIOutputImageKey), forKey: kCIInputBackgroundImageKey)

        return compositingFilter
    }
}
