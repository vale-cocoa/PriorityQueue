//
//  PriorityQueueTests
//  PriorityQueueTests.swift
//
//
//  Created by Valeriano Della Longa on 20/10/2020.
//  Copyright © 2020 Valeriano Della Longa. All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

import XCTest
@testable import PriorityQueue
@testable import HeapBuffer

final class PriorityQueueTests: XCTestCase {
    var sut: PriorityQueue<Int>!
    
    override func setUp() {
        super.setUp()
        
        sut = PriorityQueue(sort: <)
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - Initializers tests
    func testInitMinCapacitySort() {
        let minCapacity = Int.random(in: 0..<1000)
        sut = PriorityQueue<Int>(minimumCapacity: minCapacity, sort: >)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.storage.count, 0)
        XCTAssertGreaterThanOrEqual(sut.storage.capacity, minCapacity)
        assertElementsAreInMaxHeapOrder()
        
        // Let's also test it with another sort function
        sut = PriorityQueue<Int>(minimumCapacity: minCapacity, sort: <)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.storage.count, 0)
        XCTAssertGreaterThanOrEqual(sut.storage.capacity, minCapacity)
        assertElementsAreInMinHeapOrder()
    }
    
    func testInitFromSequence() {
        sut = PriorityQueue<Int>([], sort: >)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.storage.count, 0)
        
        let notEmptyElements = [1, 2, 3, 4, 5].shuffled()
        sut = PriorityQueue(notEmptyElements, sort: >)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.storage.count, notEmptyElements.count)
        sut.storage.withUnsafeBufferPointer { buff in
            for element in notEmptyElements where !buff.contains(element) {
                XCTFail("Element was not stored: \(element)")
            }
        }
        assertElementsAreInMaxHeapOrder()
        
        sut = PriorityQueue(AnySequence(notEmptyElements), sort: >)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.storage.count, notEmptyElements.count)
        sut.storage.withUnsafeBufferPointer { buff in
            for element in notEmptyElements where !buff.contains(element) {
                XCTFail("Element was not stored: \(element)")
            }
        }
        assertElementsAreInMaxHeapOrder()
        
        // let's also test with another sort:
        sut = PriorityQueue<Int>([], sort: <)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.storage.count, 0)
        
        sut = PriorityQueue(notEmptyElements, sort: <)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.storage.count, notEmptyElements.count)
        sut.storage.withUnsafeBufferPointer { buff in
            for element in notEmptyElements where !buff.contains(element) {
                XCTFail("Element was not stored: \(element)")
            }
        }
        assertElementsAreInMinHeapOrder()
        
        sut = PriorityQueue(AnySequence(notEmptyElements), sort: <)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.storage.count, notEmptyElements.count)
        sut.storage.withUnsafeBufferPointer { buff in
            for element in notEmptyElements where !buff.contains(element) {
                XCTFail("Element was not stored: \(element)")
            }
        }
        assertElementsAreInMinHeapOrder()
    }
    
    func testInitRepeatingCount() {
        sut = PriorityQueue(repeating: 10, count: 0, sort: >)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.storage.count, 0)
        
        sut = PriorityQueue(repeating: 10, count: 10, sort: >)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.storage.count, 10)
        XCTAssertTrue(Array(repeating: 10, count: 10).elementsEqual(sut.storage.withUnsafeBufferPointer { Array($0) }))
        assertElementsAreInMaxHeapOrder()
        
        // let's also test with a different sort:
        sut = PriorityQueue(repeating: 10, count: 0, sort: <)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.storage.count, 0)
        
        sut = PriorityQueue(repeating: 10, count: 10, sort: <)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.storage.count, 10)
        XCTAssertTrue(Array(repeating: 10, count: 10).elementsEqual(sut.storage.withUnsafeBufferPointer { Array($0) }))
        assertElementsAreInMinHeapOrder()
    }
    
    // MARK: - Computed properties tests
    func testUnderestimatedCount() {
        XCTAssertEqual(sut.underestimatedCount, 0)
        
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements, sort: >)
        XCTAssertEqual(sut.underestimatedCount, sut.storage.count)
    }
    
    func testCount() {
        XCTAssertEqual(sut.count, sut.underestimatedCount)
        
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements, sort: >)
        XCTAssertEqual(sut.count, sut.underestimatedCount)
    }
    
    func testIsEmpty() {
        XCTAssertTrue(sut.isEmpty)
        
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements, sort: >)
        XCTAssertEqual(sut.isEmpty, sut.storage.isEmpty)
        XCTAssertGreaterThan(sut.underestimatedCount, 0)
        XCTAssertFalse(sut.isEmpty)
    }
    
    func testCapacity() {
        XCTAssertEqual(sut.capacity, sut.storage.capacity)
        
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements, sort: >)
        XCTAssertEqual(sut.capacity, sut.storage.capacity)
    }
    
    func testIsFull() {
        XCTAssertFalse(sut.isFull)
        
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements, sort: >)
        XCTAssertGreaterThan(sut.capacity, sut.count)
        XCTAssertFalse(sut.isFull)
        sut.enqueue(contentsOf: 6...8)
        XCTAssertEqual(sut.capacity, sut.count)
        XCTAssertTrue(sut.isFull)
    }
    
    // MARK: - IteratorProtocol and Sequence tests
    func testNext_returnsElementsInSameOrderAsRepeatedlyDequeue() {
        // when empty:
        XCTAssertTrue(sut.isEmpty)
        var copy = sut!
        var expectedResult = [Int]()
        while let element = copy.dequeue() { expectedResult.append(element) }
        
        var result = [Int]()
        while let element = sut.next() { result.append(element) }
        XCTAssertEqual(result, expectedResult)
        XCTAssertTrue(result.isEmpty)
        
        // when not empty:
        let notEmptyElements = [1, 2, 3, 4, 5]
        expectedResult.removeAll()
        result.removeAll()
        sut = PriorityQueue(notEmptyElements, sort: >)
        copy = sut!
        while let element = copy.dequeue() { expectedResult.append(element) }
        while let element = sut.next() { result.append(element) }
        XCTAssertEqual(result, expectedResult)
        XCTAssertFalse(result.isEmpty)
        
        // C.O.W. test for value semantics:
        sut = PriorityQueue(notEmptyElements, sort: >)
        copy = sut!
        assertCOW(using: &copy, in: { _ in let _ = sut.next() })
    }
    
    func testMakeIterator_returnsIterator() {
        let iter = sut.makeIterator()
        XCTAssertNotNil(iter)
        XCTAssertTrue(type(of: iter) == PriorityQueue<Int>.self)
    }
    
    func testFastIteration_doesntConsumeSelf() {
        // when not empty:
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements, sort: >)
        var expectedResult = [Int]()
        var result = [Int]()
        for element in sut {
            expectedResult.append(element)
        }
        
        XCTAssertEqual(sut.underestimatedCount, notEmptyElements.count)
        XCTAssertFalse(sut.isEmpty)
        
        for element in sut {
            result.append(element)
        }
        XCTAssertEqual(sut.underestimatedCount, notEmptyElements.count)
        XCTAssertFalse(sut.isEmpty)
        
        XCTAssertEqual(result, expectedResult)
    }
    
    // MARK: - Queue functionalities tests
    func testPeek() {
        // when empty, returns nil:
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.peek())
        
        // when is not empty, returns storage.peek() element:
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements, sort: >)
        XCTAssertEqual(sut.peek(), sut.storage.peek())
        
        // Let's also test with another sort
        sut = PriorityQueue(notEmptyElements, sort: <)
        XCTAssertEqual(sut.peek(), sut.storage.peek())
    }
    
    func testEnqueue() {
        // Leveraging on HeapBuffer's insert(_:) method, we just need to
        // test C.O.W. for value semantics:
        var copy = sut!
        assertCOW(using: &copy, in: { $0.enqueue(10) })
    }
    
    func testEnqueueSequence_whenIsEmpty_andOtherIsEmpty_thenNothingGetsInserted() {
        // when is empty and other is empty, then nothing gets inserted:
        XCTAssertTrue(sut.isEmpty)
        let other = [Int]()
        sut.enqueue(contentsOf: other)
        XCTAssertTrue(sut.isEmpty)
       
        // same with a sequence not implementing withContiguousBufferIfAvailable(_:)
        XCTAssertTrue(sut.isEmpty)
        sut.enqueue(contentsOf: MyTestSequence(other, hasUnderestimatedCount: true, hasContiguousBuffer: false))
        XCTAssertTrue(sut.isEmpty)
    }
    
    func testEnqueueSequence_whenIsEmpty_andElementsIsNotEmpty_thenElementsGetsInsertedAndPriorityIsRespected() {
        // when is empty, and other is not empty, then all other's elements are inserted
        // in adopting given priority sort order:
        let other = [10, 20, 30, 40]
        sut = PriorityQueue(minimumCapacity: other.count, sort: >)
        sut.enqueue(contentsOf: other)
        var done: Bool = sut.storage.withUnsafeBufferPointer { buff in
            for element in other {
                XCTAssertTrue(buff.contains(element), "element \(element) was not inserted")
            }
            return true
        } ?? false
        XCTAssertTrue(done, "elements where not inserted")
        assertElementsAreInMaxHeapOrder()
        
        // other sort:
        sut = PriorityQueue(minimumCapacity: other.count, sort: <)
        sut.enqueue(contentsOf: other)
        done = sut.storage.withUnsafeBufferPointer { buff in
            for element in other {
                XCTAssertTrue(buff.contains(element), "element \(element) was not inserted")
            }
            return true
        } ?? false
        XCTAssertTrue(done, "elements where not inserted")
        assertElementsAreInMinHeapOrder()
        
        // same with a sequence not implementing withContiguousBufferIfAvailable(_:)
        sut = PriorityQueue(minimumCapacity: other.count, sort: >)
        sut.enqueue(contentsOf: MyTestSequence(other, hasUnderestimatedCount: true, hasContiguousBuffer: false))
        done = sut.storage.withUnsafeBufferPointer { buff in
            for element in other {
                XCTAssertTrue(buff.contains(element), "element \(element) was not inserted")
            }
            return true
        } ?? false
        XCTAssertTrue(done, "elements where not inserted")
        assertElementsAreInMaxHeapOrder()
        
        // other sort:
        sut = PriorityQueue(minimumCapacity: other.count, sort: <)
        sut.enqueue(contentsOf: MyTestSequence(other, hasUnderestimatedCount: true, hasContiguousBuffer: false))
        done = sut.storage.withUnsafeBufferPointer { buff in
            for element in other {
                XCTAssertTrue(buff.contains(element), "element \(element) was not inserted")
            }
            return true
        } ?? false
        XCTAssertTrue(done, "elements where not inserted")
        assertElementsAreInMinHeapOrder()
    }
    func testEnqueueSequence_whenIsNotEmptyAndElementsIsNotEmpty_thenElementsAreInsertedAndPriorityIsMainteined() {
        let other = [10, 20, 30, 40]
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements, sort: >)
        sut.enqueue(contentsOf: other)
        var allElements = notEmptyElements + other
        var done: Bool = sut.storage.withUnsafeBufferPointer { buff in
            for element in allElements {
                XCTAssertTrue(buff.contains(element), "element \(element) was not inserted")
            }
            return true
        } ?? false
        XCTAssertTrue(done, "elements where not inserted")
        assertElementsAreInMaxHeapOrder()
        
        // other sort:
        sut = PriorityQueue(notEmptyElements, sort: <)
        sut.enqueue(contentsOf: other)
        allElements = notEmptyElements + other
        done = sut.storage.withUnsafeBufferPointer { buff in
            for element in allElements {
                XCTAssertTrue(buff.contains(element), "element \(element) was not inserted")
            }
            return true
        } ?? false
        XCTAssertTrue(done, "elements where not inserted")
        assertElementsAreInMinHeapOrder()
        
        // sequence is not implementing withContiguousBufferIfAvailable(_:)
        sut = PriorityQueue(notEmptyElements, sort: >)
        sut.enqueue(contentsOf: MyTestSequence(other, hasUnderestimatedCount: true, hasContiguousBuffer: false))
        done = sut.storage.withUnsafeBufferPointer { buff in
            for element in allElements {
                XCTAssertTrue(buff.contains(element), "element \(element) was not inserted")
            }
            return true
        } ?? false
        XCTAssertTrue(done, "elements where not inserted")
        assertElementsAreInMaxHeapOrder()
        
        // other sort:
        sut = PriorityQueue(notEmptyElements, sort: <)
        sut.enqueue(contentsOf: MyTestSequence(other, hasUnderestimatedCount: true, hasContiguousBuffer: false))
        done = sut.storage.withUnsafeBufferPointer { buff in
            for element in allElements {
                XCTAssertTrue(buff.contains(element), "element \(element) was not inserted")
            }
            return true
        } ?? false
        XCTAssertTrue(done, "elements where not inserted")
        assertElementsAreInMinHeapOrder()
    }
    func testEnqueueSequence_whenIsNotEmptyAndOtherIsEmpty_thenNothingChanges() {
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements, sort: >)
        let other = [Int]()
        var prevContainedElements = sut.storage.withUnsafeBufferPointer { Array($0) }
        sut.enqueue(contentsOf: other)
        XCTAssertEqual(sut.storage.withUnsafeBufferPointer { Array($0) }, prevContainedElements)
        
        // other sort:
        sut = PriorityQueue(notEmptyElements, sort: <)
        prevContainedElements = sut.storage.withUnsafeBufferPointer { Array($0) }
        sut.enqueue(contentsOf: other)
        XCTAssertEqual(sut.storage.withUnsafeBufferPointer { Array($0) }, prevContainedElements)
        
        // same with a sequence not implementing withContiguousBufferIfAvailable(_:)
        sut = PriorityQueue(notEmptyElements, sort: >)
        prevContainedElements = sut.storage.withUnsafeBufferPointer { Array($0) }
        sut.enqueue(contentsOf: MyTestSequence([], hasUnderestimatedCount: true, hasContiguousBuffer: false))
        XCTAssertEqual(sut.storage.withUnsafeBufferPointer { Array($0) }, prevContainedElements)
        
        // other sort:
        sut = PriorityQueue(notEmptyElements, sort: <)
        prevContainedElements = sut.storage.withUnsafeBufferPointer { Array($0) }
        sut.enqueue(contentsOf: MyTestSequence([], hasUnderestimatedCount: true, hasContiguousBuffer: false))
        XCTAssertEqual(sut.storage.withUnsafeBufferPointer { Array($0) }, prevContainedElements)
    }
    
    func testEnqueueSequence_COW() {
        let notEmptyElements = [1, 2, 3, 4, 5]
        let other = [10, 20, 30, 40]
        sut = PriorityQueue(notEmptyElements, sort: >)
        var copy = sut!
        assertCOW(using: &copy, in: { $0.enqueue(contentsOf: other) })
    }
    
    func testDequeue() {
        // Leveraging on HeapBuffer's extract method, we just need to
        // test C.O.W. for value semantics:
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements, sort: >)
        var copy = sut!
        assertCOW(using: &copy, in: { $0.dequeue() })
    }
    
    func testEnqueueDequeue() {
        // Leveraging mainly on HeapBuffer's pushPop(_:) method.
        // we just need to test C.O.W. for value semantics…
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements, sort: >)
        var copy = sut!
        assertCOW(using: &copy, in: { $0.enqueueDequeue(10) })
    }
    
    func testDequeueEnqueue() {
        // when empty, then return nil and store new element:
        XCTAssertTrue(sut.isEmpty)
        let newElement = Int.random(in: Int.min..<Int.max)
        XCTAssertNil(sut.dequeueEnqueue(newElement))
        XCTAssertEqual(sut.storage.withUnsafeBufferPointer { Array($0) }, [newElement])
        
        // Leveraging on HeapBuffer's extract method, we just need to
        // test C.O.W. for value semantics:
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements, sort: >)
        var copy = sut!
        assertCOW(using: &copy, in: { $0.dequeueEnqueue(10) })
    }
    
    func testClear() {
        // when storage is empty:
        XCTAssertTrue(sut.isEmpty)
        sut.clear(keepingCapacity: false)
        XCTAssertTrue(sut.isEmpty)
        sut.clear(keepingCapacity: true)
        XCTAssertTrue(sut.isEmpty)
        
        // when not empty and keepCapacity is false, then storage becomes empty and reduces
        // its capacity
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements, sort: >)
        var prevCapacity = sut.storage.capacity
        sut.clear(keepingCapacity: false)
        XCTAssertTrue(sut.storage.isEmpty)
        XCTAssertLessThan(sut.storage.capacity, prevCapacity)
        
        // when not empty and keepCapacity is true, then storage removes all its elements,
        // and keeps its capacity:
        sut = PriorityQueue(notEmptyElements, sort: >)
        prevCapacity = sut.storage._capacity
        sut.clear(keepingCapacity: true)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.storage._capacity, prevCapacity)
        
        // let's also test C.O.W. for value semantics:
        sut = PriorityQueue(notEmptyElements, sort: >)
        var copy = sut!
        assertCOW(using: &copy, in: { $0.clear(keepingCapacity: false) })
        
        sut = PriorityQueue(notEmptyElements, sort: >)
        copy = sut!
        assertCOW(using: &copy, in: { $0.clear(keepingCapacity: true) })
    }
    
    func testReserveCapacity() {
        // when empty
        var prevCapacity = sut.capacity
        sut.reserveCapacity(0)
        XCTAssertEqual(sut.capacity, prevCapacity)
        sut.reserveCapacity(1)
        XCTAssertGreaterThanOrEqual(sut.capacity, 1)
        
        prevCapacity = sut.capacity
        var prevStorage = sut.storage
        sut.reserveCapacity(prevCapacity - sut.count)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertTrue(sut.storage === prevStorage)
        sut.reserveCapacity(sut.capacity - sut.count + 1)
        XCTAssertGreaterThan(sut.capacity, prevCapacity)
        XCTAssertFalse(sut.storage === prevStorage)
        
        // when not empty
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements, sort: >)
        prevCapacity = sut.capacity
        prevStorage = sut.storage
        sut.reserveCapacity(sut.capacity - sut.count)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertTrue(sut.storage === prevStorage)
        sut.reserveCapacity(sut.capacity - sut.count + 1)
        XCTAssertGreaterThan(sut.capacity, prevCapacity)
        XCTAssertFalse(sut.storage === prevStorage)
        sut.withContiguousStorageIfAvailable({ buffer in
            XCTAssertTrue(buffer.elementsEqual(notEmptyElements))
        })
        
        // C.O.W. for value semantics:
        var copy = sut!
        assertCOW(using: &copy, in: { $0.reserveCapacity($0.capacity - $0.count + 1) })
    }
    
    // MARK: - Custom(Debug)StringConvertible conformance tests
    func testDescription() {
        sut = PriorityQueue([1, 2, 3, 4, 5], sort: >)
        XCTAssertEqual(sut.description, "PriorityQueue[5, 4, 3, 2, 1]")
    }
    
    func testDebugDescription() {
        sut = PriorityQueue([1, 2, 3, 4, 5], sort: >)
        XCTAssertEqual(sut.debugDescription, "Optional(PriorityQueue.PriorityQueue<Swift.Int>([5, 4, 3, 2, 1]))")
    }
    
    // MARK: - Performance tests
    func testPerformanceOfPriorityQueueOnSmallCount() {
        measure(performanceLoopPriotyQueueSmallCount)
    }
    
    func testPerformanceOfPQArrayOnSmallCount() {
        measure(performanceLoopPQArraySmallCount)
    }
    
    func testPerformanceOfPriorityQueueOnLargeCount() {
        measure(performanceLoopPriotyQueueLargeCount)
    }
    
    func testPerformanceOfPQArrayOnLargeCount() {
        measure(performanceLoopPQArrayLargeCount)
    }
    
    // MARK: - Helpers for tests
    private func performanceLoopPriotyQueueSmallCount() {
        let outerCount: Int = 10_000
        let innerCount: Int = 20
        var accumulator = 0
        for _ in 1...outerCount {
            var pq = PriorityQueue<Int>(minimumCapacity: innerCount, sort: >)
            for i in 1...innerCount {
                pq.enqueue(i)
                accumulator ^= (pq.peek() ?? 0)
            }
            for _ in 1...innerCount {
                accumulator ^= (pq.dequeue() ?? 0)
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private func performanceLoopPQArraySmallCount() {
        let outerCount: Int = 10_000
        let innerCount: Int = 20
        var accumulator = 0
        for _ in 1...outerCount {
            var pq = ArrayBasedPQ<Int>()
            for i in 1...innerCount {
                pq.enqueue(i)
                accumulator ^= (pq.peek() ?? 0)
            }
            for _ in 1...innerCount {
                accumulator ^= (pq.dequeue() ?? 0)
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private func performanceLoopPriotyQueueLargeCount() {
        let outerCount: Int = 10
        let innerCount: Int = 20_000
        var accumulator = 0
        for _ in 1...outerCount {
            var pq = PriorityQueue<Int>(minimumCapacity: innerCount, sort: <)
            for i in 1...innerCount {
                pq.enqueue(i)
                accumulator ^= (pq.peek() ?? 0)
            }
            for _ in 1...innerCount {
                accumulator ^= (pq.dequeue() ?? 0)
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private func performanceLoopPQArrayLargeCount() {
        let outerCount: Int = 10
        let innerCount: Int = 20_000
        var accumulator = 0
        for _ in 1...outerCount {
            var pq = ArrayBasedPQ<Int>()
            for i in 1...innerCount {
                pq.enqueue(i)
                accumulator ^= (pq.peek() ?? 0)
            }
            for _ in 1...innerCount {
                accumulator ^= (pq.dequeue() ?? 0)
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private func assertElementsAreInMaxHeapOrder(file: StaticString = #file, line: UInt = #line) {
        func isHeapPropertyRespected(parent: Int = 0) -> Bool {
            var result = true
            let leftChild = (2 * parent) + 1
            let rightChild = (2 * parent) + 2
            if leftChild < sut.storage.count {
                result = sut.storage[leftChild] <= sut.storage[parent]
                if result {
                    result = isHeapPropertyRespected(parent: leftChild)
                }
            }
            
            if result && rightChild < sut.storage.count {
                result = sut.storage[rightChild] <= sut.storage[parent]
                if result {
                    result = isHeapPropertyRespected(parent: rightChild)
                }
            }
            
            return result
        }
        
        XCTAssertTrue(isHeapPropertyRespected(), "Elements are not in Max Heap Order", file: file, line: line)
    }
    
    private func assertElementsAreInMinHeapOrder(file: StaticString = #file, line: UInt = #line) {
        func isHeapPropertyRespected(parent: Int = 0) -> Bool {
            var result = true
            let leftChild = (2 * parent) + 1
            let rightChild = (2 * parent) + 2
            if leftChild < sut.storage.count {
                result = sut.storage[leftChild] >= sut.storage[parent]
                if result {
                    result = isHeapPropertyRespected(parent: leftChild)
                }
            }
            
            if result && rightChild < sut.storage.count {
                result = sut.storage[rightChild] >= sut.storage[parent]
                if result {
                    result = isHeapPropertyRespected(parent: rightChild)
                }
            }
            
            return result
        }
        
        XCTAssertTrue(isHeapPropertyRespected(), "Elements are not in Min Heap Order", file: file, line: line)
    }
    
    private func assertCOW(using copy: inout PriorityQueue<Int>, file: StaticString = #file, line: UInt = #line, in mutationBody: (inout PriorityQueue<Int>) -> Void) {
        assertSameStorageInstance(of: copy, file: file, line: line)
        mutationBody(&copy)
        assertDifferentStorageInstance(than: copy, file: file, line: line)
    }
    
    private func assertSameStorageInstance(of copy: PriorityQueue<Int>, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(sut.storage === copy.storage, "copy storage is a different instance despite no mutation has yet happened", file: file, line: line)
    }
    
    private func assertDifferentStorageInstance(than copy: PriorityQueue<Int>, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(sut.storage !== copy.storage, "copy storage is same instance despite mutation has happened after copy", file: file, line: line)
    }
    
}

// MARK: - Other helpers
struct MyTestSequence<Element>: Sequence {
    let elements: Array<Element>
    let underestimatedCount: Int
    let hasContiguousBuffer: Bool
    
    init() {
        self.elements = []
        self.underestimatedCount = 0
        self.hasContiguousBuffer = true
    }
    
    init(elements: [Element], underestimatedCount: Int, hasContiguousBuffer: Bool) {
        self.elements = elements
        self.underestimatedCount = underestimatedCount >= 0 ? (underestimatedCount <= elements.count ? underestimatedCount : elements.count) : 0
        self.hasContiguousBuffer = hasContiguousBuffer
    }
    
    init(_ elements: [Element], hasUnderestimatedCount: Bool = true, hasContiguousBuffer: Bool = true) {
        self.elements = elements
        self.underestimatedCount = hasContiguousBuffer ? elements.count : 0
        self.hasContiguousBuffer = hasContiguousBuffer
    }
    
    // Sequence
    func makeIterator() -> AnyIterator<Element> {
        AnyIterator(elements.makeIterator())
    }
    
    func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Iterator.Element>) throws -> R) rethrows -> R? {
        guard hasContiguousBuffer else { return nil }
        
        return try elements.withUnsafeBufferPointer(body)
    }
    
}

// MARK: - Array based PriorityQueue for performance tests
// Since usually PriorityQueue are implemented on Array with heap implementations, we
// introduce use one of those for performance comparsions.
struct ArrayBasedPQ<Element: Comparable>: IteratorProtocol, Sequence {
    private(set) var storage = Array<Element>()
    
    init() { }
    
    init<S: Sequence>(_ elements: S) where S.Iterator.Element == Element {
        storage = Array(elements)
        _buildMaxHeap()
    }
    
    mutating func next() -> Element? {
        storage.heapExtract(heapType: .maxHeap)
    }
    
    typealias Iterator = Self
    
    var underestimatedCount: Int { storage.count }
    
    var isEmpty: Bool { storage.isEmpty }
    
    func peek() -> Element? {
        storage.first
    }
    
    mutating func enqueue(_ newElement: Element) {
        storage.heapInsert(newElement, heapType: .maxHeap)
    }
    
    mutating func enqueue<S: Sequence>(elements: S) where S.Iterator.Element == Element {
        storage.append(contentsOf: elements)
        _buildMaxHeap()
    }
    
    mutating func dequeue() -> Element? {
        storage.heapExtract(heapType: .maxHeap)
    }
    
    mutating func clear(keepingCapacity keepCapacity: Bool = false) {
        storage.removeAll(keepingCapacity: keepCapacity)
    }
    
    private mutating func _buildMaxHeap() {
        guard !storage.isEmpty else { return }
        
        for i in stride(from: storage.count / 2 - 1, through: 0, by: -1) {
            storage._siftDown(from: i, heapType: .maxHeap)
        }
    }
    
}

extension Array where Element: Comparable {
    mutating func heapExtract(heapType: HeapBuffer<Element>.HeapType) -> Element? {
        guard !isEmpty else { return nil }
        
        swapAt(0, count - 1)
        let removed = self.popLast()
        defer { _siftDown(from: 0, heapType: heapType) }
        
        return removed
    }
    
    mutating func heapInsert(_ newElement: Element, heapType: HeapBuffer<Element>.HeapType) {
        append(newElement)
        _siftUp(from: count - 1, heapType: heapType)
    }
    
    fileprivate mutating func _siftUp(from idx: Int, heapType: HeapBuffer<Element>.HeapType) {
        let sort: (Element, Element) -> Bool = { lhs, rhs in
            switch heapType {
            case .minHeap:
                return lhs < rhs
            case .maxHeap:
                return lhs > rhs
            }
        }
        var child = idx
        var parent = _parentIdx(of: child)
        while child > 0 && sort(self[child], self[parent]) {
            swapAt(child, parent)
            child = parent
            parent = _parentIdx(of: child)
        }
    }
    
    fileprivate mutating func _siftDown(from idx: Int, heapType: HeapBuffer<Element>.HeapType) {
        let sort: (Element, Element) -> Bool = { lhs, rhs in
            switch heapType {
            case .minHeap:
                return lhs < rhs
            case .maxHeap:
                return lhs > rhs
            }
        }
        var parent = idx
        while true {
            let left = _leftChild(of: parent)
            let right = _rightChild(of: parent)
            var candidate = parent
            if left < count && sort(self[left], self[candidate]) {
                candidate = left
            }
            if right < count && sort(self[right], self[candidate]) {
                candidate = right
            }
            if candidate == parent { return }
            
            swapAt(parent, candidate)
            parent = candidate
        }
    }
    
    fileprivate func _leftChild(of parent: Int) -> Int { (parent * 2) + 1 }
    
    fileprivate func _rightChild(of parent: Int) -> Int { (parent * 2) + 2 }
    
    fileprivate func _parentIdx(of child: Int) -> Int { (child - 1) / 2 }
    
}
