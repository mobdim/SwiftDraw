//
//  ScannerTests.swift
//  SwiftDraw
//
//  Created by Simon Whitty on 31/12/16.
//  Copyright 2016 Simon Whitty
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/swhitty/SwiftDraw
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

import XCTest
@testable import SwiftDraw

private typealias CharacterSet = SwiftDraw.CharacterSet

class ScannerTests: XCTestCase {
    
    private let emoji: CharacterSet = "🤠🌞💎🐶\u{1f1e6}\u{1f1fa}"

    func testIsEOF() throws {
        var scanner = XMLParser.Scanner(text: "Hi")
        XCTAssertFalse(scanner.isEOF)
        try scanner.scanString("Hi")
        XCTAssertTrue(scanner.isEOF)
    }

    func testScanCharsetHex() {
        var scanner = SlowScanner(text: "  \t   8badf00d  \t  \t  007")
        
        XCTAssertEqual(scanner.scan(any: CharacterSet.hexadecimal), "8badf00d")
        XCTAssertEqual(scanner.scan(any: CharacterSet.hexadecimal), "007")
        XCTAssertNil(scanner.scan(any: CharacterSet.hexadecimal))
    }
    
    func testScanCharsetEmoji() {
        var scanner = SlowScanner(text: "  \t   8badf00d  \t🐶  \t🌞🇦🇺  007")
        
        XCTAssertNil(scanner.scan(any: emoji))
        XCTAssertEqual(scanner.scan(any: CharacterSet.hexadecimal), "8badf00d")
        XCTAssertNil(scanner.scan(any: CharacterSet.hexadecimal))
        XCTAssertEqual(scanner.scan(any: emoji), "🐶")
        XCTAssertNil(scanner.scan(any: CharacterSet.hexadecimal))
        XCTAssertEqual(scanner.scan(any: emoji), "🌞🇦🇺")
        XCTAssertNil(scanner.scan(any: emoji))
        XCTAssertEqual(scanner.scan(any: CharacterSet.hexadecimal), "007")
    }
    
    func testScanString() {
        var scanner =  XMLParser.Scanner(text: "  \t The quick brown fox")

        XCTAssertThrowsError(try scanner.scanString("fox"))
        XCTAssertNoThrow(try scanner.scanString("The"))
        XCTAssertThrowsError(try scanner.scanString("quick fox"))
        XCTAssertNoThrow(try scanner.scanString("quick brown"))
        XCTAssertNoThrow(try scanner.scanString("fox"))
        XCTAssertThrowsError(try scanner.scanString("fox"))
    }

    func testScanCharacter() {
        var scanner = XMLParser.Scanner(text: "  \t The fox 8badf00d ")
        let hexadecimalSet: Foundation.CharacterSet = "0123456789ABCDEFabcdef"

        XCTAssertThrowsError(_ = try scanner.scanCharacter(matchingAny: "qfxh"))
        XCTAssertEqual(try scanner.scanCharacter(matchingAny: "fxT"), "T")
        XCTAssertThrowsError(_ = try scanner.scanCharacter(matchingAny: "fxT"))
        XCTAssertEqual(try scanner.scanCharacter(matchingAny: "qfxh"), "h")
        XCTAssertNoThrow(try scanner.scanString("e fox"))
        XCTAssertEqual(try scanner.scanCharacter(matchingAny: hexadecimalSet), "8")
        XCTAssertEqual(try scanner.scanCharacter(matchingAny: hexadecimalSet), "b")
        XCTAssertEqual(try scanner.scanCharacter(matchingAny: hexadecimalSet), "a")
        XCTAssertEqual(try scanner.scanCharacter(matchingAny: hexadecimalSet), "d")
        XCTAssertEqual(try scanner.scanCharacter(matchingAny: hexadecimalSet), "f")
        XCTAssertEqual(try scanner.scanCharacter(matchingAny: hexadecimalSet), "0")
        XCTAssertEqual(try scanner.scanCharacter(matchingAny: hexadecimalSet), "0")
        XCTAssertEqual(try scanner.scanCharacter(matchingAny: hexadecimalSet), "d")
    }

    func testScanUInt8() {
        AssertScanUInt8("0", 0)
        AssertScanUInt8("124", 124)
        AssertScanUInt8(" 045", 45)
        AssertScanUInt8("-29", nil)
        AssertScanUInt8("ab24", nil)
    }

    func testScanFloat() {
        AssertScanFloat("0", 0)
        AssertScanFloat("124", 124)
        AssertScanFloat(" 045", 45)
        AssertScanFloat("-29", -29)
        AssertScanFloat("ab24", nil)
    }

    func testScanDouble() {
        AssertScanDouble("0", 0)
        AssertScanDouble("124", 124)
        AssertScanDouble(" 045", 45)
        AssertScanDouble("-29", -29)
        AssertScanDouble("ab24", nil)
    }

    func testScanLength() {
        AssertScanLength("0", 0)
        AssertScanLength("124", 124)
        AssertScanLength(" 045", 45)
        AssertScanLength("-29", -29)
        AssertScanLength("ab24", nil)
    }
    
    func testScanBool() {
        AssertScanBool("0", false)
        AssertScanBool("1", true)
        AssertScanBool("true", true)
        AssertScanBool("false", false)
        AssertScanBool("false", false)

        var scanner = XMLParser.Scanner(text: "-29")
        XCTAssertThrowsError(try scanner.scanBool())
        XCTAssertEqual(scanner.scanLocation, 0)
    }

    func testScanPercentageFloat() {
        AssertScanPercentageFloat("0", 0)
        AssertScanPercentageFloat("0.5", 0.5)
        AssertScanPercentageFloat("0.75", 0.75)
        AssertScanPercentageFloat("1.0", 1.0)
        AssertScanPercentageFloat("-0.5", nil)
        AssertScanPercentageFloat("1.5", nil)
        AssertScanPercentageFloat("as", nil)
        AssertScanPercentageFloat("29", nil)
        AssertScanPercentageFloat("24", nil)
    }

    func testScanPercentage() {
        AssertScanPercentage("0", 0)
        AssertScanPercentage("0%", 0)
        AssertScanPercentage("100%", 1.0)
        AssertScanPercentage("100 %", 1.0)
        AssertScanPercentage("45.5 %", 0.455)
        AssertScanPercentage("0.5 %", 0.005)
        AssertScanPercentage("as", nil)
        AssertScanPercentage("29", nil)
        AssertScanPercentage("24", nil)
    }
    
    func testScanCoordinate() throws {
        var scanner = XMLParser.Scanner(text: "10.05,12.04-49.05,30.02-10")

        XCTAssertEqual(try scanner.scanCoordinate(), 10.05)
        _ = try? scanner.scanString(",")
        XCTAssertEqual(try scanner.scanCoordinate(), 12.04)
        _ = try? scanner.scanString(",")
        XCTAssertEqual(try scanner.scanCoordinate(), -49.05)
        _ = try? scanner.scanString(",")
        XCTAssertEqual(try scanner.scanCoordinate(), 30.02)
        _ = try? scanner.scanString(",")
        XCTAssertEqual(try scanner.scanCoordinate(), -10)
    }
}

private func AssertScanUInt8(_ text: String, _ expected: UInt8?, file: StaticString = #file, line: UInt = #line) {
    var scanner = XMLParser.Scanner(text: text)
    XCTAssertEqual(try? scanner.scanUInt8(), expected, file: file, line: line)
}

private func AssertScanFloat(_ text: String, _ expected: Float?, file: StaticString = #file, line: UInt = #line) {
    var scanner = XMLParser.Scanner(text: text)
    XCTAssertEqual(try? scanner.scanFloat(), expected, file: file, line: line)
}

private func AssertScanDouble(_ text: String, _ expected: Double?, file: StaticString = #file, line: UInt = #line) {
    var scanner = XMLParser.Scanner(text: text)
    XCTAssertEqual(try? scanner.scanDouble(), expected, file: file, line: line)
}

private func AssertScanLength(_ text: String, _ expected: DOM.Length?, file: StaticString = #file, line: UInt = #line) {
    var scanner = XMLParser.Scanner(text: text)
    XCTAssertEqual(try? scanner.scanLength(), expected, file: file, line: line)
}

private func AssertScanBool(_ text: String, _ expected: Bool?, file: StaticString = #file, line: UInt = #line) {
    var scanner = XMLParser.Scanner(text: text)
    XCTAssertEqual(try? scanner.scanBool(), expected, file: file, line: line)
}

private func AssertScanPercentage(_ text: String, _ expected: Float?, file: StaticString = #file, line: UInt = #line) {
    var scanner = XMLParser.Scanner(text: text)
    XCTAssertEqual(try? scanner.scanPercentage(), expected, file: file, line: line)
}

private func AssertScanPercentageFloat(_ text: String, _ expected: Float?, file: StaticString = #file, line: UInt = #line) {
    var scanner = XMLParser.Scanner(text: text)
    XCTAssertEqual(try? scanner.scanPercentageFloat(), expected, file: file, line: line)
}


extension Foundation.CharacterSet: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self.init(charactersIn: value)
    }

}
