import XCTest

import pb2mdTests

var tests = [XCTestCaseEntry]()
tests += pb2mdTests.allTests()
XCTMain(tests)
