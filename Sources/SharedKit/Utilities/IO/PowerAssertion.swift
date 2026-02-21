//
//  PowerAssertion.swift
//  VisualDiffer
//
//  Created by davide ficano on 12/12/15.
//  Copyright (c) 2015 visualdiffer.com
//

import IOKit.pwr_mgt

private class PowerItem {
    var pmAssertion = IOPMAssertionID(kIOPMNullAssertionID)
    var refCount = 0

    var name = ""

    init() {}

    convenience init(name: String) {
        self.init()

        self.name = name
    }

    deinit {
        releasePMAssertion()
    }

    @discardableResult
    func createPMAssertion(type: String) -> IOReturn {
        guard pmAssertion == kIOPMNullAssertionID else {
            return kIOReturnError
        }
        return IOPMAssertionCreateWithName(
            type as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            name as CFString,
            &pmAssertion
        )
    }

    func releasePMAssertion() {
        guard pmAssertion != kIOPMNullAssertionID else {
            return
        }

        IOPMAssertionRelease(pmAssertion)
        pmAssertion = IOPMAssertionID(kIOPMNullAssertionID)
    }

    func setDisableSystemSleep(_ disableSleep: Bool) {
        if disableSleep {
            refCount += 1
            if refCount == 1 {
                createPMAssertion(type: kIOPMAssertPreventUserIdleSystemSleep)
            }
        } else {
            // Prevent refCount from becoming negative
            if refCount > 0 {
                refCount -= 1
                if refCount == 0 {
                    releasePMAssertion()
                }
            }
        }
    }
}

/**
 * Disable computer sleep using IOPMAssertion implemented as singleton
 * Minimize the number of IOPMAssertions creating different instances only when the name differs
 *
 */
@objc
class PowerAssertion: NSObject, @unchecked Sendable {
    @objc static let shared = PowerAssertion()
    private var pmAssertions: [String: PowerItem] = [:]

    override private init() {}

    @objc
    func setDisableSystemSleep(_ disableSleep: Bool, with name: String) {
        let item: PowerItem

        if let existingItem = pmAssertions[name] {
            item = existingItem
        } else {
            item = PowerItem(name: name)
            pmAssertions[name] = item
        }
        item.setDisableSystemSleep(disableSleep)
    }
}
