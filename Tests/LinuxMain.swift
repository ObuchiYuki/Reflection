import XCTest

import ReflectionTests

var tests = [XCTestCaseEntry]()
tests += ReflectionTests.allTests()
XCTMain(tests)
