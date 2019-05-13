import XCTest

import RemoteWebTests

var tests = [XCTestCaseEntry]()
tests += RemoteWebTests.allTests()
XCTMain(tests)
