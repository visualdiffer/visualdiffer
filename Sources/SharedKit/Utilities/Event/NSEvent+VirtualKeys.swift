//
//  NSEvent+VirtualKeys.swift
//  VisualDiffer
//
//  Created by davide ficano on 06/04/14.
//  Copyright (c) 2014 visualdiffer.com
//

// swiftformat:disable wrapPropertyBodies
// swiftlint:disable identifier_name
@objc
enum KeyCode: UInt16 {
    case ansi_A = 0x00
    case ansi_S = 0x01
    case ansi_D = 0x02
    case ansi_F = 0x03
    case ansi_H = 0x04
    case ansi_G = 0x05
    case ansi_Z = 0x06
    case ansi_X = 0x07
    case ansi_C = 0x08
    case ansi_V = 0x09
    case ansi_B = 0x0B
    case ansi_Q = 0x0C
    case ansi_W = 0x0D
    case ansi_E = 0x0E
    case ansi_R = 0x0F
    case ansi_Y = 0x10
    case ansi_T = 0x11
    case ansi_1 = 0x12
    case ansi_2 = 0x13
    case ansi_3 = 0x14
    case ansi_4 = 0x15
    case ansi_6 = 0x16
    case ansi_5 = 0x17
    case ansi_Equal = 0x18
    case ansi_9 = 0x19
    case ansi_7 = 0x1A
    case ansi_Minus = 0x1B
    case ansi_8 = 0x1C
    case ansi_0 = 0x1D
    case ansi_RightBracket = 0x1E
    case ansi_O = 0x1F
    case ansi_U = 0x20
    case ansi_LeftBracket = 0x21
    case ansi_I = 0x22
    case ansi_P = 0x23
    case ansi_L = 0x25
    case ansi_J = 0x26
    case ansi_Quote = 0x27
    case ansi_K = 0x28
    case ansi_Semicolon = 0x29
    case ansi_Backslash = 0x2A
    case ansi_Comma = 0x2B
    case ansi_Slash = 0x2C
    case ansi_N = 0x2D
    case ansi_M = 0x2E
    case ansi_Period = 0x2F
    case ansi_Grave = 0x32
    case ansi_KeypadDecimal = 0x41
    case ansi_KeypadMultiply = 0x43
    case ansi_KeypadPlus = 0x45
    case ansi_KeypadClear = 0x47
    case ansi_KeypadDivide = 0x4B
    case ansi_KeypadEnter = 0x4C
    case ansi_KeypadMinus = 0x4E
    case ansi_KeypadEquals = 0x51
    case ansi_Keypad0 = 0x52
    case ansi_Keypad1 = 0x53
    case ansi_Keypad2 = 0x54
    case ansi_Keypad3 = 0x55
    case ansi_Keypad4 = 0x56
    case ansi_Keypad5 = 0x57
    case ansi_Keypad6 = 0x58
    case ansi_Keypad7 = 0x59
    case ansi_Keypad8 = 0x5B
    case ansi_Keypad9 = 0x5C

    /* keycodes for keys that are independent of keyboard layout */
    case returnKey = 0x24
    case tab = 0x30
    case space = 0x31
    case delete = 0x33
    case escape = 0x35
    case command = 0x37
    case shift = 0x38
    case capsLock = 0x39
    case option = 0x3A
    case control = 0x3B
    case rightShift = 0x3C
    case rightOption = 0x3D
    case rightControl = 0x3E
    case function = 0x3F
    case f17 = 0x40
    case volumeUp = 0x48
    case volumeDown = 0x49
    case mute = 0x4A
    case f18 = 0x4F
    case f19 = 0x50
    case f20 = 0x5A
    case f5 = 0x60
    case f6 = 0x61
    case f7 = 0x62
    case f3 = 0x63
    case f8 = 0x64
    case f9 = 0x65
    case f11 = 0x67
    case f13 = 0x69
    case f16 = 0x6A
    case f14 = 0x6B
    case f10 = 0x6D
    case f12 = 0x6F
    case f15 = 0x71
    case help = 0x72
    case home = 0x73
    case pageUp = 0x74
    case forwardDelete = 0x75
    case f4 = 0x76
    case end = 0x77
    case f2 = 0x78
    case pageDown = 0x79
    case f1 = 0x7A
    case leftArrow = 0x7B
    case rightArrow = 0x7C
    case downArrow = 0x7D
    case upArrow = 0x7E

    /* ISO keyboards only */
    case iso_Section = 0x0A

    /* JIS keyboards only */
    case jis_Yen = 0x5D
    case jis_Underscore = 0x5E
    case jis_KeypadComma = 0x5F
    case jis_Eisu = 0x66
    case jis_Kana = 0x68
}

extension KeyCode {
    static var ansi_ACharacter: Int { Int(KeyCode.ansi_A.rawValue) }
    static var ansi_SCharacter: Int { Int(KeyCode.ansi_S.rawValue) }
    static var ansi_DCharacter: Int { Int(KeyCode.ansi_D.rawValue) }
    static var ansi_FCharacter: Int { Int(KeyCode.ansi_F.rawValue) }
    static var ansi_HCharacter: Int { Int(KeyCode.ansi_H.rawValue) }
    static var ansi_GCharacter: Int { Int(KeyCode.ansi_G.rawValue) }
    static var ansi_ZCharacter: Int { Int(KeyCode.ansi_Z.rawValue) }
    static var ansi_XCharacter: Int { Int(KeyCode.ansi_X.rawValue) }
    static var ansi_CCharacter: Int { Int(KeyCode.ansi_C.rawValue) }
    static var ansi_VCharacter: Int { Int(KeyCode.ansi_V.rawValue) }
    static var ansi_BCharacter: Int { Int(KeyCode.ansi_B.rawValue) }
    static var ansi_QCharacter: Int { Int(KeyCode.ansi_Q.rawValue) }
    static var ansi_WCharacter: Int { Int(KeyCode.ansi_W.rawValue) }
    static var ansi_ECharacter: Int { Int(KeyCode.ansi_E.rawValue) }
    static var ansi_RCharacter: Int { Int(KeyCode.ansi_R.rawValue) }
    static var ansi_YCharacter: Int { Int(KeyCode.ansi_Y.rawValue) }
    static var ansi_TCharacter: Int { Int(KeyCode.ansi_T.rawValue) }
    static var ansi_1Character: Int { Int(KeyCode.ansi_1.rawValue) }
    static var ansi_2Character: Int { Int(KeyCode.ansi_2.rawValue) }
    static var ansi_3Character: Int { Int(KeyCode.ansi_3.rawValue) }
    static var ansi_4Character: Int { Int(KeyCode.ansi_4.rawValue) }
    static var ansi_6Character: Int { Int(KeyCode.ansi_6.rawValue) }
    static var ansi_5Character: Int { Int(KeyCode.ansi_5.rawValue) }
    static var ansi_EqualCharacter: Int { Int(KeyCode.ansi_Equal.rawValue) }
    static var ansi_9Character: Int { Int(KeyCode.ansi_9.rawValue) }
    static var ansi_7Character: Int { Int(KeyCode.ansi_7.rawValue) }
    static var ansi_MinusCharacter: Int { Int(KeyCode.ansi_Minus.rawValue) }
    static var ansi_8Character: Int { Int(KeyCode.ansi_8.rawValue) }
    static var ansi_0Character: Int { Int(KeyCode.ansi_0.rawValue) }
    static var ansi_RightBracketCharacter: Int { Int(KeyCode.ansi_RightBracket.rawValue) }
    static var ansi_OCharacter: Int { Int(KeyCode.ansi_O.rawValue) }
    static var ansi_UCharacter: Int { Int(KeyCode.ansi_U.rawValue) }
    static var ansi_LeftBracketCharacter: Int { Int(KeyCode.ansi_LeftBracket.rawValue) }
    static var ansi_ICharacter: Int { Int(KeyCode.ansi_I.rawValue) }
    static var ansi_PCharacter: Int { Int(KeyCode.ansi_P.rawValue) }
    static var ansi_LCharacter: Int { Int(KeyCode.ansi_L.rawValue) }
    static var ansi_JCharacter: Int { Int(KeyCode.ansi_J.rawValue) }
    static var ansi_QuoteCharacter: Int { Int(KeyCode.ansi_Quote.rawValue) }
    static var ansi_KCharacter: Int { Int(KeyCode.ansi_K.rawValue) }
    static var ansi_SemicolonCharacter: Int { Int(KeyCode.ansi_Semicolon.rawValue) }
    static var ansi_BackslashCharacter: Int { Int(KeyCode.ansi_Backslash.rawValue) }
    static var ansi_CommaCharacter: Int { Int(KeyCode.ansi_Comma.rawValue) }
    static var ansi_SlashCharacter: Int { Int(KeyCode.ansi_Slash.rawValue) }
    static var ansi_NCharacter: Int { Int(KeyCode.ansi_N.rawValue) }
    static var ansi_MCharacter: Int { Int(KeyCode.ansi_M.rawValue) }
    static var ansi_PeriodCharacter: Int { Int(KeyCode.ansi_Period.rawValue) }
    static var ansi_GraveCharacter: Int { Int(KeyCode.ansi_Grave.rawValue) }
    static var ansi_KeypadDecimalCharacter: Int { Int(KeyCode.ansi_KeypadDecimal.rawValue) }
    static var ansi_KeypadMultiplyCharacter: Int { Int(KeyCode.ansi_KeypadMultiply.rawValue) }
    static var ansi_KeypadPlusCharacter: Int { Int(KeyCode.ansi_KeypadPlus.rawValue) }
    static var ansi_KeypadClearCharacter: Int { Int(KeyCode.ansi_KeypadClear.rawValue) }
    static var ansi_KeypadDivideCharacter: Int { Int(KeyCode.ansi_KeypadDivide.rawValue) }
    static var ansi_KeypadEnterCharacter: Int { Int(KeyCode.ansi_KeypadEnter.rawValue) }
    static var ansi_KeypadMinusCharacter: Int { Int(KeyCode.ansi_KeypadMinus.rawValue) }
    static var ansi_KeypadEqualsCharacter: Int { Int(KeyCode.ansi_KeypadEquals.rawValue) }
    static var ansi_Keypad0Character: Int { Int(KeyCode.ansi_Keypad0.rawValue) }
    static var ansi_Keypad1Character: Int { Int(KeyCode.ansi_Keypad1.rawValue) }
    static var ansi_Keypad2Character: Int { Int(KeyCode.ansi_Keypad2.rawValue) }
    static var ansi_Keypad3Character: Int { Int(KeyCode.ansi_Keypad3.rawValue) }
    static var ansi_Keypad4Character: Int { Int(KeyCode.ansi_Keypad4.rawValue) }
    static var ansi_Keypad5Character: Int { Int(KeyCode.ansi_Keypad5.rawValue) }
    static var ansi_Keypad6Character: Int { Int(KeyCode.ansi_Keypad6.rawValue) }
    static var ansi_Keypad7Character: Int { Int(KeyCode.ansi_Keypad7.rawValue) }
    static var ansi_Keypad8Character: Int { Int(KeyCode.ansi_Keypad8.rawValue) }
    static var ansi_Keypad9Character: Int { Int(KeyCode.ansi_Keypad9.rawValue) }

    /* keycodes for keys that are independent of keyboard layout */
    static var returnKeyCharacter: Int { Int(KeyCode.returnKey.rawValue) }
    static var tabCharacter: Int { Int(KeyCode.tab.rawValue) }
    static var spaceCharacter: Int { Int(KeyCode.space.rawValue) }
    static var deleteCharacter: Int { Int(KeyCode.delete.rawValue) }
    static var escapeCharacter: Int { Int(KeyCode.escape.rawValue) }
    static var commandCharacter: Int { Int(KeyCode.command.rawValue) }
    static var shiftCharacter: Int { Int(KeyCode.shift.rawValue) }
    static var capsLockCharacter: Int { Int(KeyCode.capsLock.rawValue) }
    static var optionCharacter: Int { Int(KeyCode.option.rawValue) }
    static var controlCharacter: Int { Int(KeyCode.control.rawValue) }
    static var rightShiftCharacter: Int { Int(KeyCode.rightShift.rawValue) }
    static var rightOptionCharacter: Int { Int(KeyCode.rightOption.rawValue) }
    static var rightControlCharacter: Int { Int(KeyCode.rightControl.rawValue) }
    static var functionCharacter: Int { Int(KeyCode.function.rawValue) }
    static var f17Character: Int { Int(KeyCode.f17.rawValue) }
    static var volumeUpCharacter: Int { Int(KeyCode.volumeUp.rawValue) }
    static var volumeDownCharacter: Int { Int(KeyCode.volumeDown.rawValue) }
    static var muteCharacter: Int { Int(KeyCode.mute.rawValue) }
    static var f18Character: Int { Int(KeyCode.f18.rawValue) }
    static var f19Character: Int { Int(KeyCode.f19.rawValue) }
    static var f20Character: Int { Int(KeyCode.f20.rawValue) }
    static var f5Character: Int { Int(KeyCode.f5.rawValue) }
    static var f6Character: Int { Int(KeyCode.f6.rawValue) }
    static var f7Character: Int { Int(KeyCode.f7.rawValue) }
    static var f3Character: Int { Int(KeyCode.f3.rawValue) }
    static var f8Character: Int { Int(KeyCode.f8.rawValue) }
    static var f9Character: Int { Int(KeyCode.f9.rawValue) }
    static var f11Character: Int { Int(KeyCode.f11.rawValue) }
    static var f13Character: Int { Int(KeyCode.f13.rawValue) }
    static var f16Character: Int { Int(KeyCode.f16.rawValue) }
    static var f14Character: Int { Int(KeyCode.f14.rawValue) }
    static var f10Character: Int { Int(KeyCode.f10.rawValue) }
    static var f12Character: Int { Int(KeyCode.f12.rawValue) }
    static var f15Character: Int { Int(KeyCode.f15.rawValue) }
    static var helpCharacter: Int { Int(KeyCode.help.rawValue) }
    static var homeCharacter: Int { Int(KeyCode.home.rawValue) }
    static var pageUpCharacter: Int { Int(KeyCode.pageUp.rawValue) }
    static var forwardDeleteCharacter: Int { Int(KeyCode.forwardDelete.rawValue) }
    static var f4Character: Int { Int(KeyCode.f4.rawValue) }
    static var endCharacter: Int { Int(KeyCode.end.rawValue) }
    static var f2Character: Int { Int(KeyCode.f2.rawValue) }
    static var pageDownCharacter: Int { Int(KeyCode.pageDown.rawValue) }
    static var f1Character: Int { Int(KeyCode.f1.rawValue) }
    static var leftArrowCharacter: Int { Int(KeyCode.leftArrow.rawValue) }
    static var rightArrowCharacter: Int { Int(KeyCode.rightArrow.rawValue) }
    static var downArrowCharacter: Int { Int(KeyCode.downArrow.rawValue) }
    static var upArrowCharacter: Int { Int(KeyCode.upArrow.rawValue) }

    /* ISO keyboards only */
    static var iso_SectionCharacter: Int { Int(KeyCode.iso_Section.rawValue) }

    /* JIS keyboards only */
    static var jis_YenCharacter: Int { Int(KeyCode.jis_Yen.rawValue) }
    static var jis_UnderscoreCharacter: Int { Int(KeyCode.jis_Underscore.rawValue) }
    static var jis_KeypadCommaCharacter: Int { Int(KeyCode.jis_KeypadComma.rawValue) }
    static var jis_EisuCharacter: Int { Int(KeyCode.jis_Eisu.rawValue) }
    static var jis_KanaCharacter: Int { Int(KeyCode.jis_Kana.rawValue) }

    var intValue: Int {
        Int(rawValue)
    }
}

// swiftlint:enable identifier_name

extension NSEvent {
    @objc
    func isDeleteShortcutKey(_ checkCommandDeleteKey: Bool) -> Bool {
        if checkCommandDeleteKey, modifierFlags.contains(.command), keyCode == KeyCode.deleteCharacter {
            return true
        }
        return keyCode == KeyCode.forwardDeleteCharacter
    }
}
