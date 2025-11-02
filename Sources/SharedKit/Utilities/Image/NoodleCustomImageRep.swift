//
//  NoodleCustomImageRep.swift
//  NoodleKit
//
//  Created by Paul Kim on 3/16/11.
//  Copyright 2011 Noodlesoft, LLC. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
//  Converted to Swift by davide ficano on 03/05/25.

import Cocoa

typealias NoodleCustomImageRepDrawBlock = (NoodleCustomImageRep) -> Void

/*
 This image rep just provides a way to specify the image drawing via a block.

 For more details, check out the related blog post at http://www.noodlesoft.com/blog/2011/04/15/the-proper-care-and-feeding-of-nsimage
 */
class NoodleCustomImageRep: NSImageRep {
    private var drawBlock: NoodleCustomImageRepDrawBlock?

    init(drawBlock block: NoodleCustomImageRepDrawBlock?) {
        super.init()

        drawBlock = block
    }

    init?(
        drawBlock block: NoodleCustomImageRepDrawBlock?,
        coder: NSCoder
    ) {
        super.init(coder: coder)

        drawBlock = block
    }

    override convenience init() {
        self.init(drawBlock: nil)
    }

    required convenience init?(coder: NSCoder) {
        self.init(drawBlock: nil, coder: coder)
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        // swiftlint:disable:next force_cast
        let copy = super.copy(with: zone) as! NoodleCustomImageRep

        // NSImageRep uses NSCopyObject so we have to force a copy here
        copy.drawBlock = drawBlock

        return copy
    }

    override func draw() -> Bool {
        guard let drawBlock else {
            return false
        }
        drawBlock(self)
        return true
    }
}
