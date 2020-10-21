//
//  PriorityQueueTests
//  PriorityQueueSliceTests.swift
//  
//
//  Created by Valeriano Della Longa on 21/10/2020.
//

import XCTest
@testable import PriorityQueue
@testable import HeapBuffer

final class PriorityQueueSliceTests: XCTestCase {
    var sut: PriorityQueueSlice<Int>!
    
    override func setUp() {
        super.setUp()
        
        sut = PriorityQueueSlice()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
}
