//
//  ScreenTracking.swift
//  SwiftalyticsGASample
//
//  Created by KawaiTakeshi on 2016/03/16.
//  Copyright © 2016年 Takeshi Kawai. All rights reserved.
//

import UIKit
import Swiftalytics

struct ScreenTracking {
    static func setup() {
        FirstViewController.self >> "First Screen"
        SecondViewController.self >> "Second Screen"
    }
}

extension UIViewController {
    public override class func initialize() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        // make sure this isn't a subclass
        if self !== UIViewController.self {
            return
        }
        
        dispatch_once(&Static.token) {
            let originalSelector = Selector("viewDidAppear:")
            let swizzledSelector = Selector("swiftalytics_viewDidAppear:")
            
            let originalMethod = class_getInstanceMethod(self, originalSelector)
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            
            let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            if didAddMethod {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }
    
    func swiftalytics_viewDidAppear(animated: Bool) {
        swiftalytics_viewDidAppear(animated)
        if let name = Swiftalytics.trackingNameForViewController(self) {
            print("\(name)")
            let tracker = GAI.sharedInstance().defaultTracker
            tracker.set(kGAIScreenName, value: name)
            let builder = GAIDictionaryBuilder.createScreenView()
            tracker.send(builder.build() as [NSObject: AnyObject])
        }
    }
}

postfix operator << {}
private postfix func << <T: UIViewController>(trackClassFunction: (T -> () -> String)) {
   Swiftalytics.setTrackingNameForViewController(trackClassFunction)
}

private func >> <T: UIViewController>(left: T.Type, @autoclosure right: () -> String) {
    Swiftalytics.setTrackingNameForViewController(left, name: right)
}

private func >> <T: UIViewController>(left: T.Type, right: TrackingNameType) {
    Swiftalytics.setTrackingNameForViewController(left, trackingType: right)
}

private func >> <T: UIViewController>(left: T.Type, right: (T -> String)) {
    Swiftalytics.setTrackingNameForViewController(left, nameFunction: right)
}
