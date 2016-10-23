//
//  EVTWindow.swift
//  EventsUI
//
//  Created by Guilherme Rambo on 02/04/16.
//  Copyright © 2016 Guilherme Rambo. All rights reserved.
//

import Cocoa
import AVFoundation

open class EVTWindow: NSWindow {
    
    @IBInspectable @objc open var hidesTitlebar = true
    
    // MARK: - Initialization
    
    override init(contentRect: NSRect, styleMask style: NSWindowStyleMask, backing bufferingType: NSBackingStoreType, defer flag: Bool) {
        var effectiveStyle = style
        effectiveStyle.insert(.fullSizeContentView)
        
        super.init(contentRect: contentRect, styleMask: effectiveStyle, backing: bufferingType, defer: flag)
        
        applyCustomizations()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        applyCustomizations()
    }
    
    // MARK: - Custom appearance
    
    open override var effectiveAppearance: NSAppearance {
        return NSAppearance(named: NSAppearanceNameVibrantDark)!
    }
    
    fileprivate var titlebarWidgets: [NSButton]? {
        return titlebarView?.subviews.flatMap { subview in
            guard subview.isKind(of: NSClassFromString("_NSThemeWidget")!) else { return nil }
            return subview as? NSButton
        }
    }
    
    fileprivate func appearanceForWidgets() -> NSAppearance? {
        if allowsPiPMode {
            return NSAppearance(appearanceNamed: "PiPZoom", bundle: Bundle(for: EVTWindow.self))
        } else {
            return NSAppearance(named: NSAppearanceNameAqua)
        }
    }
    
    fileprivate func applyAppearanceToWidgets() {
        let appearance = appearanceForWidgets()
        titlebarWidgets?.forEach { $0.appearance = appearance }
    }
    
    fileprivate var _storedTitlebarView: NSVisualEffectView?
    open var titlebarView: NSVisualEffectView? {
        guard _storedTitlebarView == nil else { return _storedTitlebarView }
        guard let containerClass = NSClassFromString("NSTitlebarContainerView") else { return nil }
        
        guard let containerView = contentView?.superview?.subviews.filter({ $0.isKind(of: containerClass) }).last else { return nil }
        
        guard let titlebar = containerView.subviews.filter({ $0.isKind(of: NSVisualEffectView.self) }).last as? NSVisualEffectView else { return nil }
        
        _storedTitlebarView = titlebar
        
        return _storedTitlebarView
    }
    
    fileprivate var titleTextField: NSTextField?
    fileprivate var titlebarSeparatorLayer: CALayer?
    fileprivate var titlebarGradientLayer: CAGradientLayer?
    
    fileprivate var fullscreenObserver: NSObjectProtocol?
    
    fileprivate func applyCustomizations(_ note: Notification? = nil) {
        titleVisibility = .hidden
        isMovableByWindowBackground = true
        
        titlebarView?.material = .ultraDark
        titlebarView?.state = .active
        
        installTitlebarGradientIfNeeded()
        installTitlebarSeparatorIfNeeded()
        installTitleTextFieldIfNeeded()
        
        installFullscreenObserverIfNeeded()
        
        applyAppearanceToWidgets()
    }
    
    fileprivate func installTitleTextFieldIfNeeded() {
        guard titleTextField == nil && titlebarView != nil else { return }
        
        titleTextField = NSTextField(frame: titlebarView!.bounds)
        titleTextField!.isEditable = false
        titleTextField!.isSelectable = false
        titleTextField!.drawsBackground = false
        titleTextField!.isBezeled = false
        titleTextField!.isBordered = false
        titleTextField!.stringValue = title
        titleTextField!.font = NSFont.titleBarFont(ofSize: 13.0)
        titleTextField!.textColor = NSColor(calibratedWhite: 0.9, alpha: 0.8)
        titleTextField!.alignment = .center
        titleTextField!.translatesAutoresizingMaskIntoConstraints = false
        titleTextField!.lineBreakMode = .byTruncatingMiddle
        titleTextField!.sizeToFit()
        
        titlebarView!.addSubview(titleTextField!)
        titleTextField!.centerYAnchor.constraint(equalTo: titlebarView!.centerYAnchor).isActive = true
        titleTextField!.centerXAnchor.constraint(equalTo: titlebarView!.centerXAnchor).isActive = true
        titleTextField!.leadingAnchor.constraint(greaterThanOrEqualTo: titlebarView!.leadingAnchor, constant: 67.0).isActive = true
        titleTextField!.setContentCompressionResistancePriority(0.1, for: .horizontal)
        
        titleTextField!.layer?.compositingFilter = "lightenBlendMode"
    }
    
    fileprivate func installTitlebarGradientIfNeeded() {
        guard titlebarGradientLayer == nil && titlebarView != nil else { return }
        
        titlebarGradientLayer = CAGradientLayer()
        titlebarGradientLayer!.colors = [NSColor(calibratedWhite: 0.0, alpha: 0.4).cgColor, NSColor.clear.cgColor]
        titlebarGradientLayer!.frame = titlebarView!.bounds
        titlebarGradientLayer!.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        titlebarGradientLayer!.compositingFilter = "overlayBlendMode"
        titlebarView?.layer?.insertSublayer(titlebarGradientLayer!, at: 0)
    }
    
    fileprivate func installTitlebarSeparatorIfNeeded() {
        guard titlebarSeparatorLayer == nil && titlebarView != nil else { return }
        
        titlebarSeparatorLayer = CALayer()
        titlebarSeparatorLayer!.backgroundColor = NSColor(calibratedWhite: 0.0, alpha: 0.9).cgColor
        titlebarSeparatorLayer!.frame = CGRect(x: 0.0, y: 0.0, width: titlebarView!.bounds.width, height: 1.0)
        titlebarSeparatorLayer!.autoresizingMask = [.layerWidthSizable, .layerMinYMargin]
        titlebarView?.layer?.addSublayer(titlebarSeparatorLayer!)
    }
    
    fileprivate func installFullscreenObserverIfNeeded() {
        guard fullscreenObserver == nil else { return }
        
        let nc = NotificationCenter.default
        
        // the customizations (especially the title text field ones) have to be reapplied when entering and exiting fullscreen
        nc.addObserver(forName: NSNotification.Name.NSWindowDidEnterFullScreen, object: self, queue: nil, using: applyCustomizations)
        nc.addObserver(forName: NSNotification.Name.NSWindowDidExitFullScreen, object: self, queue: nil, using: applyCustomizations)
    }
    
    open override func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        
        applyCustomizations()
    }
    
    // MARK: - Titlebar management
    
    func hideTitlebar(_ animated: Bool = true) {
        setTitlebarOpacity(0.0, animated: animated)
    }
    
    func showTitlebar(_ animated: Bool = true) {
        setTitlebarOpacity(1.0, animated: animated)
    }
    
    fileprivate func setTitlebarOpacity(_ opacity: CGFloat, animated: Bool) {
        guard hidesTitlebar else { return }
        
        // when the window is in full screen, the titlebar view is in another window (the "toolbar window")
        guard titlebarView?.window == self else { return }
        
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = animated ? 0.4 : 0.0
            self.titlebarView?.animator().alphaValue = opacity
            }, completionHandler: nil)
    }
    
    // MARK: - Content management
    
    open override var title: String {
        didSet {
            titleTextField?.stringValue = title
        }
    }
    
    open override var contentView: NSView? {
        set {
            let darkContentView = EVTWindowContentView(frame: newValue?.frame ?? NSZeroRect)
            if let newContentView = newValue {
                newContentView.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
                darkContentView.addSubview(newContentView)
            }
            super.contentView = darkContentView
        }
        get {
            return super.contentView
        }
    }
    
    // MARK: - PiP Mode
    
    open var allowsPiPMode = false {
        didSet {
            applyAppearanceToWidgets()
            if isInPiPMode {
                exitPiPMode()
            }
        }
    }
    
    @objc open var isInPiPMode = false
    
    open override func toggleFullScreen(_ sender: Any?) {
        if canEnterPiPMode || isInPiPMode {
            togglePiPMode(sender as AnyObject?)
        } else {
            self.reallyDoToggleFullScreenImNotEvenKiddingItsRealThisTimeISwear(sender as AnyObject?)
        }
    }
    
    @IBAction open func reallyDoToggleFullScreenImNotEvenKiddingItsRealThisTimeISwear(_ sender: AnyObject?) {
        super.toggleFullScreen(sender)
    }
    
    fileprivate var canEnterPiPMode: Bool {
        return allowsPiPMode && !isInPiPMode && !styleMask.contains(.fullScreen) && screen != nil
    }
    
    fileprivate var levelBeforePiPMode: Int = 0
    fileprivate var collectionBehaviorBeforePiPMode: NSWindowCollectionBehavior = []
    fileprivate var frameBeforePiPMode: NSRect = NSZeroRect
    
    @IBAction open func togglePiPMode(_ sender: AnyObject?) {
        if isInPiPMode {
            exitPiPMode()
        } else {
            enterPiPMode()
        }
    }
    
    fileprivate func enterPiPMode() {
        guard canEnterPiPMode else { return }
        guard !isInPiPMode else { return }
        
        willChangeValue(forKey: "isInPiPMode")
        
        hideTitlebar()
        isInPiPMode = true
        
        frameBeforePiPMode = frame
        levelBeforePiPMode = level
        collectionBehaviorBeforePiPMode = collectionBehavior
        
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenPrimary]
        level = Int(CGWindowLevelForKey(CGWindowLevelKey.maximumWindow))
        setFrame(frameForPiPMode, display: true, animate: true)
        
        didChangeValue(forKey: "isInPiPMode")
    }
    
    fileprivate func exitPiPMode() {
        guard isInPiPMode else { return }
        
        willChangeValue(forKey: "isInPiPMode")
        isInPiPMode = false
        
        let aspectBeforePiP = aspectRatio
        resizeIncrements = NSSize(width: 1.0, height: 1.0)
        setFrame(frameBeforePiPMode, display: true, animate: true)
        aspectRatio = aspectBeforePiP
        
        collectionBehavior = collectionBehaviorBeforePiPMode
        level = levelBeforePiPMode
        didChangeValue(forKey: "isInPiPMode")
    }
    
    fileprivate var frameForPiPMode: NSRect {
        guard let screen = screen else { return frame }
        
        struct PiPConstants {
            static let width = CGFloat(320.0)
            static let height = CGFloat(134.0)
        }
        
        let baseRect = NSRect(
            x: 0,
            y: 0,
            width: PiPConstants.width,
            height: PiPConstants.height
        )
        
        var effectiveAspectRatio = aspectRatio
        if (effectiveAspectRatio == .zero) {
            effectiveAspectRatio = NSSize(width: 960.0, height: 400.0)
        }
        
        var effectiveRect = AVMakeRect(aspectRatio: effectiveAspectRatio, insideRect: baseRect)
        
        effectiveRect.origin.x = screen.frame.width - effectiveRect.width - 40.0
        effectiveRect.origin.y = 40.0
        
        return effectiveRect
    }
    
}

private class EVTWindowContentView: NSView {
    
    fileprivate var overlayView: EVTWindowOverlayView?
    
    fileprivate func installOverlayView() {
        overlayView = EVTWindowOverlayView(frame: bounds)
        overlayView!.autoresizingMask = [.viewWidthSizable, .viewHeightSizable]
        addSubview(overlayView!, positioned: .above, relativeTo: subviews.last)
    }
    
    fileprivate func moveOverlayViewToTop() {
        if overlayView == nil {
            installOverlayView()
        } else {
            overlayView!.removeFromSuperview()
            addSubview(overlayView!, positioned: .above, relativeTo: subviews.last)
        }
    }
    
    fileprivate override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        NSRectFill(dirtyRect)
    }
    
    fileprivate override func addSubview(_ aView: NSView) {
        super.addSubview(aView)
        
        if aView != overlayView {
            moveOverlayViewToTop()
        }
    }
    
}

private class EVTWindowOverlayView: NSView {
    
    fileprivate var evtWindow: EVTWindow? {
        return window as? EVTWindow
    }
    
    fileprivate var mouseTrackingArea: NSTrackingArea!
    
    fileprivate override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if mouseTrackingArea != nil {
            removeTrackingArea(mouseTrackingArea)
        }
        
        mouseTrackingArea = NSTrackingArea(rect: bounds, options: [.inVisibleRect, .mouseEnteredAndExited, .mouseMoved, .activeAlways], owner: self, userInfo: nil)
        addTrackingArea(mouseTrackingArea)
    }
    
    fileprivate var mouseIdleTimer: Timer!
    
    fileprivate func resetMouseIdleTimer() {
        if mouseIdleTimer != nil {
            mouseIdleTimer.invalidate()
            mouseIdleTimer = nil
        }
        
        mouseIdleTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(mouseIdleTimerAction(_:)), userInfo: nil, repeats: false)
    }
    
    @objc fileprivate func mouseIdleTimerAction(_ sender: Timer) {
        evtWindow?.hideTitlebar()
    }
    
    fileprivate override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillExitFullscreen), name: NSNotification.Name.NSWindowWillExitFullScreen, object: window)
        resetMouseIdleTimer()
    }
    
    @objc fileprivate func windowWillExitFullscreen() {
        resetMouseIdleTimer()
    }
    
    fileprivate override func mouseEntered(with theEvent: NSEvent) {
        resetMouseIdleTimer()
        evtWindow?.showTitlebar()
    }
    
    fileprivate override func mouseExited(with theEvent: NSEvent) {
        evtWindow?.hideTitlebar()
    }
    
    fileprivate override func mouseMoved(with theEvent: NSEvent) {
        resetMouseIdleTimer()
        evtWindow?.showTitlebar()
    }
    
    fileprivate override func draw(_ dirtyRect: NSRect) {
        return
    }
    
    fileprivate override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        if event.clickCount == 2 {
            self.evtWindow?.reallyDoToggleFullScreenImNotEvenKiddingItsRealThisTimeISwear(self)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        mouseIdleTimer.invalidate()
        mouseIdleTimer = nil
    }
    
}
