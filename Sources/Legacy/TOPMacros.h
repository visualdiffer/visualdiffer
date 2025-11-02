//
//  TOPMacros.h
//  TernaryOp
//
//  Created by davide ficano on 21/11/14.
//  Copyright (c) 2014 visualdiffer.com
//

#ifndef TernaryOp_TOPMacros_h
#define TernaryOp_TOPMacros_h

// Output log only when in debug mode showing the method name
#if defined(DEBUG)
#define TOP_DEBUG_METHOD_LOG(text, ...) NSLog(@"%@ " text, NSStringFromSelector(_cmd), ## __VA_ARGS__)
#else
#define TOP_DEBUG_METHOD_LOG(text, ...)
#endif

#define TOP_LOG(text, ...) NSLog(text, ## __VA_ARGS__)
#define TOP_METHOD_LOG(text, ...) NSLog(@"%@ " text, NSStringFromSelector(_cmd), ## __VA_ARGS__)

#define TOP_IS_FLAG_ON(wholeFlags, flagToTest) ((wholeFlags & flagToTest) == flagToTest)
#define TOP_SET_FLAG_ON(wholeFlags, flagToSet) (wholeFlags | flagToSet)
#define TOP_SET_FLAG_OFF(wholeFlags, flagToSet) (wholeFlags & ~flagToSet)
#define TOP_TOGGLE_FLAG(wholeFlags, flagToTest) ((wholeFlags & flagToTest) == flagToTest ? (wholeFlags & ~flagToTest) : (wholeFlags | flagToTest))
// If flagToTest is on then return NSControlStateValueOn otherwise NSControlStateValueOff
#define TOP_BUTTON_STATE(wholeFlags, flagToTest) ((wholeFlags & flagToTest) == flagToTest ? NSControlStateValueOn : NSControlStateValueOff)
#define TOP_TOGGLE_BUTTON_STATE(wholeFlags, flagToTest, state) (state == NSControlStateValueOn ? TOP_SET_FLAG_ON(wholeFlags, flagToTest) : TOP_SET_FLAG_OFF(wholeFlags, flagToTest))

#endif
