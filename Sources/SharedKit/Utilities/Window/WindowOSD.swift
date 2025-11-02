//
//  WindowOSD.swift
//  VisualDiffer
//
//  Created by davide ficano on 22/11/14.
//  Copyright (c) 2014 visualdiffer.com
//

class WindowOSD: NSWindow, NSAnimationDelegate {
    private static let textColor = NSColor.white
    private static let backgroundColor = NSColor(
        calibratedRed: 83.0 / 255,
        green: 83.0 / 255,
        blue: 83.0 / 255,
        alpha: 1.0
    )

    // the image distance from the window top
    private static let imageOffsetY: CGFloat = 10.0
    // the text distance from the window bottom
    private static let textOffsetY: CGFloat = 10.0

    private static let textFontFamily = "Lucida Grande"
    private static let textFontSize: CGFloat = 14.0

    private static let windowWidth: CGFloat = 160.0
    private static let windowHeight: CGFloat = 150.0

    private var viewAnimation: NSViewAnimation?

    @objc init(image: NSImage, parent: NSWindow?) {
        let windowFrame = NSRect(x: 0, y: 0, width: Self.windowWidth, height: Self.windowHeight)

        super.init(
            contentRect: windowFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        let content = Self.createContent(frame: windowFrame)
        content.addSubview(Self.createImageView(image: image, windowFrame: windowFrame))
        content.addSubview(Self.createTextField())

        contentView = content
        isOpaque = false
        backgroundColor = NSColor.clear
        animationBehavior = .none

        if let parent {
            parent.addChildWindow(self, ordered: .above)
        }

        // the window is not visible at init time
        // this is necessary because the createContent forces thw window to be visible after creation
        orderOut(nil)
    }

    private static func createContent(frame: NSRect) -> NSView {
        // The frame uses the entire window size
        let content = NSView(frame: frame)

        content.wantsLayer = true
        if let layer = content.layer {
            layer.masksToBounds = true
            layer.cornerRadius = 10.0
            // wantsLayer is enabled so we don't need to subclass NSView and fill with color in drawRect
            // we can use the layer background color directly
            layer.backgroundColor = backgroundColor.cgColor
        }

        return content
    }

    private static func createImageView(image: NSImage, windowFrame: NSRect) -> NSImageView {
        let imageFrame = NSRect(
            x: 0,
            y: windowFrame.height - image.size.height - Self.imageOffsetY,
            width: windowFrame.width,
            height: image.size.height
        )
        let view = NSImageView(frame: imageFrame)
        view.imageScaling = .scaleNone
        view.image = image

        return view
    }

    private static func createTextField() -> NSTextField {
        let view = NSTextField(frame: .zero)

        view.isSelectable = false
        view.isEditable = false
        view.font = NSFontManager.shared.font(
            withFamily: textFontFamily,
            traits: .boldFontMask,
            weight: 0,
            size: textFontSize
        )
        view.alignment = .center
        view.isBordered = false
        view.textColor = textColor
        view.backgroundColor = .clear

        return view
    }

    override var acceptsFirstResponder: Bool {
        false
    }

    @objc func animateInside(_ areaFrame: NSRect) {
        let frame = frame
        setFrameOrigin(NSPoint(
            x: areaFrame.origin.x + (areaFrame.width - frame.width) / 2,
            y: areaFrame.origin.y + (areaFrame.height - frame.height) / 2
        ))

        if let viewAnimation {
            // set progress to 1.0 so that animation will display its last frame (eg. to get correct window height)
            viewAnimation.currentProgress = 1.0
            viewAnimation.stop()
        }
        alphaValue = 1.0
        orderFront(NSApp)

        viewAnimation = createViewAnimation()
    }

    private func createViewAnimation() -> NSViewAnimation {
        let animateOutDict: [NSViewAnimation.Key: Any] = [
            .target: self,
            .effect: NSViewAnimation.EffectName.fadeOut,
        ]
        let animation = NSViewAnimation(viewAnimations: [animateOutDict])
        animation.delegate = self
        animation.start()

        return animation
    }

    func animationDidEnd(_: NSAnimation) {
        Task { @MainActor in
            self.viewAnimation = nil
        }
    }

    // MARK: - Image

    @objc func setImage(_ image: NSImage?) {
        guard let imageView = contentView?.subviews[0] as? NSImageView else {
            return
        }

        if imageView.image != image {
            imageView.image = image
        }
    }

    func setBackgroundColor(_ backgroundColor: NSColor) {
        contentView?.layer?.backgroundColor = backgroundColor.cgColor
    }

    // MARK: - Text

    @objc func setText(_ text: String) {
        guard let textField = contentView?.subviews[1] as? NSTextField,
              let font = textField.font else {
            return
        }
        let height = (text as NSString).size(withAttributes: [.font: font]).height

        let windowFrame = frame
        textField.frame = NSRect(x: 0, y: Self.textOffsetY, width: windowFrame.size.width, height: height)
        textField.stringValue = text
    }

    func setTextColor(_ textColor: NSColor) {
        guard let textField = contentView?.subviews[1] as? NSTextField else {
            return
        }
        textField.textColor = textColor
    }

    func setTextFont(_ textFont: NSFont) {
        guard let textField = contentView?.subviews[1] as? NSTextField else {
            return
        }
        textField.font = textFont
    }
}
