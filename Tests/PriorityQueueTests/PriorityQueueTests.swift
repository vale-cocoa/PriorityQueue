//
//  PriorityQueueTests
//  PriorityQueueTests.swift
//
//
//  Created by Valeriano Della Longa on 20/10/2020.
//

import XCTest
@testable import PriorityQueue
@testable import HeapBuffer

final class PriorityQueueTests: XCTestCase {
    var sut: PriorityQueue<Int>!
    
    override func setUp() {
        super.setUp()
        
        sut = PriorityQueue()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - initialize tests
    func testInit() {
        sut = PriorityQueue<Int>()
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.count, 0)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        assertElementsAreInMaxHeapOrder()
    }
    
    func testInitFromSequence() {
        sut = PriorityQueue<Int>([])
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.count, 0)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        
        let notEmptyElements = [1, 2, 3, 4, 5].shuffled()
        sut = PriorityQueue(notEmptyElements)
        XCTAssertEqual(sut.count, notEmptyElements.count)
        sut.storage!.withUnsafeBufferPointer { buff in
            for element in notEmptyElements where !buff.contains(element) {
                XCTFail("Element was not stored: \(element)")
            }
        }
        assertElementsAreInMaxHeapOrder()
        
        sut = PriorityQueue(AnySequence(notEmptyElements))
        XCTAssertEqual(sut.count, notEmptyElements.count)
        sut.storage!.withUnsafeBufferPointer { buff in
            for element in notEmptyElements where !buff.contains(element) {
                XCTFail("Element was not stored: \(element)")
            }
        }
        assertElementsAreInMaxHeapOrder()
    }
    
    func testInitRepeatingCount() {
        sut = PriorityQueue(repeating: 10, count: 0)
        XCTAssertNotNil(sut)
        XCTAssertNil(sut.storage)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.count, 0)
        assertElementsAreInMaxHeapOrder()
        
        sut = PriorityQueue(repeating: 10, count: 10)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.count, 10)
        XCTAssertTrue(Array(repeating: 10, count: 10).elementsEqual(sut))
        assertElementsAreInMaxHeapOrder()
    }
    
    // MARK: - Computed properties tests
    func testCountAndUnderestimatedCount() {
        XCTAssertNil(sut.storage)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.underestimatedCount, sut.count)
        
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements)
        XCTAssertEqual(sut.count, sut.storage?.count)
        XCTAssertEqual(sut.underestimatedCount, sut.count)
    }
    
    func testIsEmpty() {
        XCTAssertNil(sut.storage)
        XCTAssertEqual(sut.count, 0)
        XCTAssertTrue(sut.isEmpty)
        
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements)
        XCTAssertEqual(sut.isEmpty, sut.storage?.isEmpty)
        XCTAssertGreaterThan(sut.count, 0)
        XCTAssertFalse(sut.isEmpty)
    }
    
    func testStartIndex() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.startIndex, 0)
        
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements)
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.startIndex, 0)
    }
    
    func testEndIndex() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.endIndex, sut.count)
        
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements)
        XCTAssertEqual(sut.endIndex, sut.count)
        XCTAssertGreaterThan(sut.endIndex, sut.startIndex)
    }
    
    func testFirstAndLast() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.first)
        XCTAssertNil(sut.last)
        
        sut = PriorityQueue(repeating: 10, count: 1)
        XCTAssertNotNil(sut.first)
        XCTAssertNotNil(sut.last)
        XCTAssertEqual(sut.first, sut.last)
        XCTAssertEqual(sut.first, 10)
        
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements)
        XCTAssertNotNil(sut.first)
        XCTAssertNotNil(sut.last)
        XCTAssertNotEqual(sut.first, sut.last)
        XCTAssertEqual(sut.first, sut.storage?[sut.startIndex])
        XCTAssertEqual(sut.last, sut.storage?[sut.endIndex - 1])
    }
    
    func testIndices() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertTrue(sut.indices.isEmpty)
        XCTAssertEqual(sut.indices.lowerBound, sut.startIndex)
        XCTAssertEqual(sut.indices.upperBound, sut.endIndex)
        
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements)
        XCTAssertEqual(sut.indices.count, sut.count)
        XCTAssertEqual(sut.indices.lowerBound, sut.startIndex)
        XCTAssertEqual(sut.indices.upperBound, sut.endIndex)
    }
    
    // MARK: - Tests Helpers
    private func assertElementsAreInMaxHeapOrder(file: StaticString = #file, line: UInt = #line) {
        func isHeapPropertyRespected(parent: Int = 0) -> Bool {
            var result = true
            let leftChild = (2 * parent) + 1
            let rightChild = (2 * parent) + 2
            if leftChild < sut.count {
                result = sut[leftChild] <= sut[parent]
                if result {
                    result = isHeapPropertyRespected(parent: leftChild)
                }
            }
            
            if result && rightChild < sut.count {
                result = sut[rightChild] <= sut[parent]
                if result {
                    result = isHeapPropertyRespected(parent: rightChild)
                }
            }
            
            return result
        }
        
        XCTAssertTrue(isHeapPropertyRespected(), "Elements are not in Max Heap Order", file: file, line: line)
    }
}
