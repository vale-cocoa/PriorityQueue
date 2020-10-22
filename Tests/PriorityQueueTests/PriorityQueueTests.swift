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
        XCTAssertNil(sut.storage)
        assertElementsAreInMaxHeapOrder()
    }
    
    func testInitFromSequence() {
        sut = PriorityQueue<Int>([])
        XCTAssertNotNil(sut)
        XCTAssertNil(sut.storage)
        
        let notEmptyElements = [1, 2, 3, 4, 5].shuffled()
        sut = PriorityQueue(notEmptyElements)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.storage!.count, notEmptyElements.count)
        sut.storage!.withUnsafeBufferPointer { buff in
            for element in notEmptyElements where !buff.contains(element) {
                XCTFail("Element was not stored: \(element)")
            }
        }
        assertElementsAreInMaxHeapOrder()
        
        sut = PriorityQueue(AnySequence(notEmptyElements))
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.storage!.count, notEmptyElements.count)
        sut.storage!.withUnsafeBufferPointer { buff in
            for element in notEmptyElements where !buff.contains(element) {
                XCTFail("Element was not stored: \(element)")
            }
        }
        assertElementsAreInMaxHeapOrder()
        
        // let's also test when sequence is another PriorityQueue instance:
        let other = PriorityQueue(sut)
        XCTAssertNotNil(other)
        XCTAssertNotNil(other.storage)
        XCTAssertEqual(other.underestimatedCount, sut.underestimatedCount)
        var result = [Int]()
        var expectedResult = [Int]()
        for element in other {
            result.append(element)
        }
        for element in sut {
            expectedResult.append(element)
        }
        XCTAssertEqual(result, expectedResult)
    }
    
    func testInitRepeatingCount() {
        sut = PriorityQueue(repeating: 10, count: 0)
        XCTAssertNotNil(sut)
        XCTAssertNil(sut.storage)
        assertElementsAreInMaxHeapOrder()
        
        sut = PriorityQueue(repeating: 10, count: 10)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.storage!.count, 10)
        XCTAssertTrue(Array(repeating: 10, count: 10).elementsEqual(sut.storage!.withUnsafeBufferPointer { Array($0) }))
        assertElementsAreInMaxHeapOrder()
    }
    
    func testInitViaArrayLiteral() {
        sut = [1, 2, 3, 4, 5]
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.underestimatedCount, 5)
        assertElementsAreInMaxHeapOrder()
    }
    
    // MARK: - Computed properties tests
    func testUnderestimatedCount() {
        XCTAssertNil(sut.storage)
        XCTAssertEqual(sut.underestimatedCount, 0)
        
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements)
        XCTAssertEqual(sut.underestimatedCount, sut.storage!.count)
    }
    
    func testIsEmpty() {
        XCTAssertNil(sut.storage)
        XCTAssertTrue(sut.isEmpty)
        
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements)
        XCTAssertEqual(sut.isEmpty, sut.storage?.isEmpty)
        XCTAssertGreaterThan(sut.underestimatedCount, 0)
        XCTAssertFalse(sut.isEmpty)
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
        sut = PriorityQueue(notEmptyElements)
        copy = sut!
        while let element = copy.dequeue() { expectedResult.append(element) }
        while let element = sut.next() { result.append(element) }
        XCTAssertEqual(result, expectedResult)
        XCTAssertFalse(result.isEmpty)
        
        // C.O.W. test for value semantics:
        sut = PriorityQueue(notEmptyElements)
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
        sut = PriorityQueue(notEmptyElements)
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
        sut = PriorityQueue(notEmptyElements)
        XCTAssertEqual(sut.peek(), sut.storage?.peek())
    }
    
    func testEnqueue() {
        // Leveraging on HeapBuffer's insert(_:) method, we just need to
        // test C.O.W. for value semantics:
        var copy = sut!
        assertCOW(using: &copy, in: { $0.enqueue(10) })
    }
    
    func testEnqueueSequence_whenSequenceIsAnotherPriorityQueue() {
        // when is empty and other is empty, then nothing gets inserted:
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        var other = PriorityQueue<Int>()
        sut.enqueue(contentsOf: other)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        
        // when is empty, and other is not empty, then all other's elements are inserted
        // in max heap order:
        let otherElements = [10, 20, 30, 40]
        other = PriorityQueue(otherElements)
        sut.enqueue(contentsOf: other)
        var done: Bool = sut.storage?.withUnsafeBufferPointer { buff in
            for element in otherElements {
                XCTAssertTrue(buff.contains(element), "element \(element) was not inserted")
            }
            return true
        } ?? false
        XCTAssertTrue(done, "elements where not inserted")
        assertElementsAreInMaxHeapOrder()
        
        // when is not empty, and other is not empty then all other's elements are
        // inserted and max heap order is maintained:
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements)
        sut.enqueue(contentsOf: other)
        let allElements = notEmptyElements + otherElements
        done = sut.storage?.withUnsafeBufferPointer { buff in
            for element in allElements {
                XCTAssertTrue(buff.contains(element), "element \(element) was not inserted")
            }
            return true
        } ?? false
        XCTAssertTrue(done, "elements where not inserted")
        assertElementsAreInMaxHeapOrder()
        
        // when is not empty, and other is empty, then nothing gets inserted:
        other = PriorityQueue()
        XCTAssertTrue(other.isEmpty)
        XCTAssertFalse(sut.isEmpty)
        let prevContainedElements = sut.storage!.withUnsafeBufferPointer { Array($0) }
        sut.enqueue(contentsOf: other)
        XCTAssertEqual(sut.storage?.withUnsafeBufferPointer { Array($0) }, prevContainedElements)
        
        // let's now test C.O.W. for value semantics:
        other = PriorityQueue(otherElements)
        XCTAssertFalse(other.isEmpty)
        var copy = sut!
        assertCOW(using: &copy, in: { $0.enqueue(contentsOf: other) })
    }
    
    func testEnqueueSequence_whenSequenceIsNotAnotherPriorityQueue() {
        // when is empty and other is empty, then nothing gets inserted:
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        var other: [Int] = []
        sut.enqueue(contentsOf: other)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        // same with a sequence not implementing withContiguousBufferIfAvailable(_:)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        sut.enqueue(contentsOf: MyTestSequence(other, hasUnderestimatedCount: true, hasContiguousBuffer: false))
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        
        // when is empty, and other is not empty, then all other's elements are inserted
        // in max heap order:
        other = [10, 20, 30, 40]
        sut.enqueue(contentsOf: other)
        var done: Bool = sut.storage?.withUnsafeBufferPointer { buff in
            for element in other {
                XCTAssertTrue(buff.contains(element), "element \(element) was not inserted")
            }
            return true
        } ?? false
        XCTAssertTrue(done, "elements where not inserted")
        assertElementsAreInMaxHeapOrder()
        // same with a sequence not implementing withContiguousBufferIfAvailable(_:)
        sut = PriorityQueue()
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        sut.enqueue(contentsOf: MyTestSequence(other, hasUnderestimatedCount: true, hasContiguousBuffer: false))
        done = sut.storage?.withUnsafeBufferPointer { buff in
            for element in other {
                XCTAssertTrue(buff.contains(element), "element \(element) was not inserted")
            }
            return true
        } ?? false
        XCTAssertTrue(done, "elements where not inserted")
        assertElementsAreInMaxHeapOrder()
        
        // when is not empty, and other is not empty then all other's elements are
        // inserted and max heap order is maintained:
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements)
        sut.enqueue(contentsOf: other)
        let allElements = notEmptyElements + other
        done = sut.storage?.withUnsafeBufferPointer { buff in
            for element in allElements {
                XCTAssertTrue(buff.contains(element), "element \(element) was not inserted")
            }
            return true
        } ?? false
        XCTAssertTrue(done, "elements where not inserted")
        assertElementsAreInMaxHeapOrder()
        // same with a sequence not implementing withContiguousBufferIfAvailable(_:)
        sut = PriorityQueue(notEmptyElements)
        sut.enqueue(contentsOf: MyTestSequence(other, hasUnderestimatedCount: true, hasContiguousBuffer: false))
        done = sut.storage?.withUnsafeBufferPointer { buff in
            for element in allElements {
                XCTAssertTrue(buff.contains(element), "element \(element) was not inserted")
            }
            return true
        } ?? false
        XCTAssertTrue(done, "elements where not inserted")
        assertElementsAreInMaxHeapOrder()
        
        // when is not empty, and other is empty, then nothing gets inserted:
        other = []
        XCTAssertTrue(other.isEmpty)
        XCTAssertFalse(sut.isEmpty)
        let prevContainedElements = sut.storage!.withUnsafeBufferPointer { Array($0) }
        sut.enqueue(contentsOf: other)
        XCTAssertEqual(sut.storage?.withUnsafeBufferPointer { Array($0) }, prevContainedElements)
        // same with a sequence not implementing withContiguousBufferIfAvailable(_:)
        sut.enqueue(contentsOf: MyTestSequence([], hasUnderestimatedCount: true, hasContiguousBuffer: false))
        XCTAssertEqual(sut.storage?.withUnsafeBufferPointer { Array($0) }, prevContainedElements)
        
        // let's now test C.O.W. for value semantics:
        sut = PriorityQueue(notEmptyElements)
        var copy = sut!
        assertCOW(using: &copy, in: { $0.enqueue(contentsOf: other) })
    }
    
    func testDequeue() {
        // Leveraging on HeapBuffer's extract method, we just need to
        // test C.O.W. for value semantics:
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements)
        var copy = sut!
        assertCOW(using: &copy, in: { $0.dequeue() })
    }
    
    func testEnqueueDequeue() {
        // Leveraging mainly on HeapBuffer's pushPop(_:) method.
        // we just need to test C.O.W. for value semantics…
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements)
        var copy = sut!
        assertCOW(using: &copy, in: { $0.enqueueDequeue(10) })
        
        // …and that when after mutation is empty, then storage is nil:
        sut = PriorityQueue<Int>()
        XCTAssertTrue(sut.isEmpty)
        sut.enqueueDequeue(10)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
    }
    
    func testDequeueEnqueue() {
        // Leveraging on HeapBuffer's extract method, we just need to
        // test C.O.W. for value semantics:
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements)
        var copy = sut!
        assertCOW(using: &copy, in: { $0.dequeueEnqueue(10) })
    }
    
    func testRemove() {
        // when is empty returns nil:
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.remove(Int.random(in: Int.min...Int.max)))
        
        // when not empty…
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements)
        // …and element is contained, then element gets removed and returned
        let containedElement = notEmptyElements.randomElement()!
        let result = sut.remove(containedElement)
        XCTAssertEqual(result, containedElement)
        XCTAssertFalse(sut.storage!.withUnsafeBufferPointer { buff in
            buff.contains(containedElement)
        }, "element: \(containedElement) was not removed")
        
        // when not empty and element is not contained, then returns nil and doesn't remove
        // anything:
        let prevElements = sut.storage!.withUnsafeBufferPointer { Array($0) }
        // We've removed contained element earlier, thus now it is not contained!
        let notContained = containedElement
        XCTAssertNil(sut.remove(notContained))
        XCTAssertEqual(sut.storage!.withUnsafeBufferPointer { Array($0) }, prevElements)
        
        // let's also check that storage get set to nil when removing the only contained
        // element:
        for element in prevElements {
            sut.remove(element)
        }
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        
        // let's now test C.O.W. for value semantics:
        sut = PriorityQueue(notEmptyElements)
        var copy = sut!
        assertCOW(using: &copy, in: { $0.remove(containedElement) })
    }
    
    func testClear() {
        // when storage is nil:
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        sut.clear(keepingCapacity: false)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        sut.clear(keepingCapacity: true)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        
        // when not empty and keepCapacity is false, then storage becomes nil
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements)
        sut.clear(keepingCapacity: false)
        XCTAssertNil(sut.storage)
        
        // when not empty and keepCapacity is true, then storage removes all its elements,
        // but doesnt become nil and keeps its capacity:
        sut = PriorityQueue(notEmptyElements)
        let prevCapacity = sut.storage!._capacity
        sut.clear(keepingCapacity: true)
        XCTAssertNotNil(sut.storage)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.storage!._capacity, prevCapacity)
        
        // let's also test C.O.W. for value semantics:
        sut = PriorityQueue(notEmptyElements)
        var copy = sut!
        assertCOW(using: &copy, in: { $0.clear(keepingCapacity: false) })
        
        sut = PriorityQueue(notEmptyElements)
        copy = sut!
        assertCOW(using: &copy, in: { $0.clear(keepingCapacity: true) })
    }
    
    // MARK: - Equatable and Hashable conformances tests
    func testEquatable() {
        // when storage instances are equal, returns true:
        var other = PriorityQueue<Int>()
        XCTAssertTrue(sut.storage === other.storage)
        XCTAssertEqual(sut, other)
        let notEmptyElements = [1, 2, 3, 4, 5]
        sut = PriorityQueue(notEmptyElements)
        other = sut
        XCTAssertTrue(sut.storage === other.storage)
        
        // when storage istances are different…
        
        // …and understimatedCount is different, returns false
        other = PriorityQueue<Int>()
        XCTAssertFalse(sut.storage === other.storage)
        XCTAssertNotEqual(sut.underestimatedCount, other.underestimatedCount)
        XCTAssertNotEqual(sut, other)
        other.enqueue(10)
        XCTAssertNotEqual(sut.underestimatedCount, other.underestimatedCount)
        XCTAssertNotEqual(sut, other)
        
        // …and underestimated is equal and elements are the same, returns true
        other = PriorityQueue(notEmptyElements)
        XCTAssertFalse(sut.storage === other.storage)
        XCTAssertEqual(sut.underestimatedCount, other.underestimatedCount)
        XCTAssertEqual(sut.storage?.withUnsafeBufferPointer { Array($0) }, other.storage?.withUnsafeBufferPointer { Array($0)} )
        XCTAssertEqual(sut, other)
        
        //…and underestimated is equal, but elements are different, returns false
        let differentElements = [10, 20, 30, 40, 50]
        other = PriorityQueue(differentElements)
        XCTAssertFalse(sut.storage === other.storage)
        XCTAssertEqual(sut.underestimatedCount, other.underestimatedCount)
        XCTAssertNotEqual(sut.storage?.withUnsafeBufferPointer { Array($0) }, other.storage?.withUnsafeBufferPointer { Array($0)} )
        XCTAssertNotEqual(sut, other)
        
        // let's also test when elements are the same, but oredered in the max heap
        // slightly differently:
        other = PriorityQueue()
        for element in [5, 3, 4, 1, 2] {
            other.enqueue(element)
        }
        XCTAssertNotEqual(sut.storage?.withUnsafeBufferPointer { Array($0) }, other.storage?.withUnsafeBufferPointer { Array($0)} )
        XCTAssertEqual(sut.underestimatedCount, other.underestimatedCount)
        XCTAssertEqual(sut, other)
    }
    
    func testHashable() {
        var set = Set<PriorityQueue<Int>>()
        set.insert(sut)
        XCTAssertTrue(set.contains(sut))
        
        var copy = sut!
        let (inserted, _) = set.insert(copy)
        XCTAssertFalse(inserted)
        
        copy.enqueue(1)
        let afterMutation = set.insert(copy)
        XCTAssertTrue(afterMutation.inserted)
        XCTAssertTrue(afterMutation.memberAfterInsert.storage === copy.storage)
        XCTAssertEqual(afterMutation.memberAfterInsert.hashValue, copy.hashValue)
    }
    
    // MARK: - Codable conformance tests
    func testEncode() {
        sut = [1, 2, 3, 4, 5]
        let encoder = JSONEncoder()
        XCTAssertNoThrow(try encoder.encode(sut))
    }
    
    func testDecode() {
        sut = [1, 2, 3, 4, 5]
        let encoder = JSONEncoder()
        let data = try! encoder.encode(sut)
        
        let decoder = JSONDecoder()
        XCTAssertNoThrow(try decoder.decode(PriorityQueue<Int>.self, from: data))
    }
    
    func testEncodeThanDecode() {
        sut = [1, 2, 3, 4, 5]
        let encoder = JSONEncoder()
        let data = try! encoder.encode(sut)
        
        let decoder = JSONDecoder()
        let decoded = try! decoder.decode(PriorityQueue<Int>.self, from: data)
        XCTAssertEqual(decoded, sut)
    }
    
    // MARK: - Custom(Debug)StringConvertible conformance tests
    func testDescription() {
        sut = [1, 2, 3, 4, 5]
        XCTAssertEqual(sut.description, "PriorityQueue[5, 4, 3, 2, 1]")
    }
    
    func testDebugDescription() {
        sut = [1, 2, 3, 4, 5]
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
            var pq = PriorityQueue<Int>()
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
            var pq = PriorityQueue<Int>()
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
            guard sut.storage != nil else { return true }
            var result = true
            let leftChild = (2 * parent) + 1
            let rightChild = (2 * parent) + 2
            if leftChild < sut.storage!.count {
                result = sut.storage![leftChild] <= sut.storage![parent]
                if result {
                    result = isHeapPropertyRespected(parent: leftChild)
                }
            }
            
            if result && rightChild < sut.storage!.count {
                result = sut.storage![rightChild] <= sut.storage![parent]
                if result {
                    result = isHeapPropertyRespected(parent: rightChild)
                }
            }
            
            return result
        }
        
        XCTAssertTrue(isHeapPropertyRespected(), "Elements are not in Max Heap Order", file: file, line: line)
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
    
    func makeIterator() -> Self {
        self
    }
    
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
