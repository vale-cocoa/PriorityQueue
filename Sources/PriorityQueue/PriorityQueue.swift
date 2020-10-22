//
//  PriorityQueue
//  PriorityQueue.swift
//
//  Created by Valeriano Della Longa on 2020/10/20.
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

import HeapBuffer

/// A queue data structure — with value semantics— whose elements are dequeued by priority order, which is associated to
/// the value of the elements themself.
/// That is, given its associated type `Element` has to conform to `Comparable`, then stored elements are dequeued
/// starting from the largest and ending to to the smallest.
public struct PriorityQueue<Element: Comparable> {
    private(set) var storage: HeapBuffer<Element>? = nil
    
    /// Returns a new empty instance of `PriorityQueue`.
    public init() {  }
    
    /// Returns a new instance of `PriorityQueue`, storing all elements in given sequence.
    ///
    /// - Parameter _: a sequence of elements to store.
    /// - Returns: a new instance storing all elements contained in given `elements` sequence.
    /// - Complexity: O(log*n*) where *n* is the count of elements in given `elements` sequence.
    public init<S: Sequence>(_ elements: S) where S.Iterator.Element == Element {
        if let other = elements as? Self {
            self.storage = other.storage
            
            return
        }
        
        let newStorage = HeapBuffer(elements, heapType: .maxHeap)
        guard !newStorage.isEmpty else { return }
        
        storage = newStorage
    }
    
    /// Returns a new instance of `PriorityQueue`, initialized to store the same given element for the specified count.
    ///
    /// - Parameter repeatring: the element to repeat.
    /// - Parameter count:  the number of times the given `repeatedValue` element has to be repeated.
    ///                     **Must not be negative**.
    public init(repeating repeatedValue: Element, count: Int) {
        precondition(count >= 0)
        guard count > 0 else { return }
        
        storage = HeapBuffer(repeating: repeatedValue, count: count, heapType: .maxHeap)
    }
    
}

// MARK: - Public Interface
// MARK: - Computed properties
extension PriorityQueue {
    /// The number of stored elements.
    ///
    /// - Complexity: O(1)
    public var underestimatedCount: Int { storage?.count ?? 0 }
    
    /// Flags if there are or not stored elements.
    ///
    /// - Note: `true` when `underestimatedCount == 0`, `false` for `underestimatedCount` values
    ///         greater than `0`.
    /// - Complexity: O(1)
    public var isEmpty: Bool { storage?.isEmpty ?? true }
    
}

// MARK: - Queue operations
extension PriorityQueue {
    /// Returns (without removing it), the next element that will be dequeued when present, otherwise `nil`
    ///
    /// - Returns: the next element to be dequeued, when present, otherwise `nil`
    /// - Complexity: O(1)
    @discardableResult
    public func peek() -> Element? {
        storage?.peek()
    }
    
    /// Stores specified element in this instance, inserting it at appropriate position for its value in regards to other
    ///  stored elements.
    ///
    /// - Parameter _: the element to store.
    ///- Complexity: O(log *n*) where *n* is the number of stored elements after the insertion operation.
    public mutating func enqueue(_ newElement: Element) {
        _makeUnique()
        storage!.insert(newElement)
    }
    
    /// Stores all elements contained in given sequence in this instance, inserting them at appropriate positions
    /// in regards to each other and contained values.
    ///
    /// - Parameter contentsOf: the sequence of elements to store.
    /// - Complexity: O(log *n*) where *n* is the number of stored elements after the insertion operation.
    public mutating func enqueue<S: Sequence>(contentsOf newElements: S) where S.Iterator.Element == Element {
        if let other = newElements as? Self {
            guard !other.isEmpty else { return }
            
            _makeUnique(reservingCapacity: other.storage!.count)
            other.storage!.withUnsafeBufferPointer { otherBuff in
                self.storage!.insert(elements: otherBuff, at: underestimatedCount)
            }
            
            return
        }
        
        _makeUnique(reservingCapacity: newElements.underestimatedCount)
        let done = newElements
            .withContiguousStorageIfAvailable { buff in
                storage!.insert(elements: buff, at: underestimatedCount)
                
                return true
            } ?? false
        
        if !done {
            for newElement in newElements {
                enqueue(newElement)
            }
        }
        
        _checkForEmptyAtEndOfMutation()
    }
    
    /// Removes and returns, if not empty, the stored element with the highest priority, otherwise `nil`.
    ///
    /// - Returns: the stored element with highest priority, otherwise `nil`.
    /// - Complexity: O(log *n*) where *n* is the count of stored elements after the removal.
    @discardableResult
    public mutating func dequeue() -> Element? {
        _makeUnique()
        defer {
            _checkForEmptyAtEndOfMutation()
        }
        
        return storage!.extract()
    }
    
    /// Enqueues given element, then dequeues.
    ///
    /// This method is in average faster than doing the two operations sequentially in separate steps.
    /// - Parameter _: the element to enqueue.
    /// - Returns: the stored element with the highest priority after the given `newElement` was inserted.
    /// - Complexity: O(log *n*) where *n* is the count of stored elements after the enqueue operation.
    /// - Note: when `isEmpty` is `true`, or the newly enqueud element has highest priority than those already
    ///         stored, this method performs in O(1).
    @discardableResult
    public mutating func enqueueDequeue(_ newElement: Element) -> Element {
        _makeUnique()
        defer {
            _checkForEmptyAtEndOfMutation()
        }
        
        return storage!.pushPop(newElement)
    }
    
    /// Dequeues, and then enqueue given element.
    ///
    /// This method is in average faster than doing the two operations sequentially in two steps.
    /// - Parameter _: the element to enqueue after having dequeued.
    /// - Returns:  the stored element with the highest priority before the given `newElement` was inserted, or
    ///             `nil` if it was empty.
    /// - Complexity: O(log *n*) where *n* is the count of elements after the given one has been equeued.
    /// - Note: might perform in O(1) when the given new element has a value greater than the one just being
    ///         dequeued, or if it was empty prior the operation took effect.
    @discardableResult
    public mutating func dequeueEnqueue(_ newElement: Element) -> Element? {
        _makeUnique()
        guard !isEmpty else {
            defer { enqueue(newElement) }
            
            return nil
        }
        
        return storage!.replace(newElement)
    }
    
    /// Returns and removes from storage, if present, specified element, keeping other elements in order.
    ///
    /// - Parameter _: the element to remove.
    /// - Returns: the removed element, if present, otherwise `nil`.
    /// - Complexity: Amortized O(log *n*), where *n* is the count of stored elements.
    @discardableResult
    public mutating func remove(_ element: Element) -> Element? {
        _makeUnique()
        defer {
            _checkForEmptyAtEndOfMutation()
        }
        
        guard let idx = storage!.indexOf(element) else { return nil }
        
        return storage!.remove(at: idx)
    }
    
    /// Removes all stored elements, eventually keeping the storage capacity if so specified.
    ///
    /// - Parameter keepingCapacity:    when set to `true`, the storage doesn't reduce its capacity.
    ///                                 Deafults to `false`.
    public mutating func clear(keepingCapacity keepCapacity: Bool = false) {
        guard storage != nil else { return }
        
        _makeUnique()
        guard keepCapacity else {
            storage = nil
            
            return
        }
        
        storage!.remove(at: storage!.startIndex, count: storage!.count, keepingCapacity: true)
    }
    
}

// MARK: - IteratorProtocol and Sequence conformances
extension PriorityQueue: IteratorProtocol, Sequence {
    public typealias Iterator = Self
    
    public mutating func next() -> Element? {
        dequeue()
    }
    
    public func makeIterator() -> Self {
        self
    }
    
}

// MARK: - ExpressibleByArrayLiteral conformance
extension PriorityQueue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
    
}

// MARK: - Equatable conformance
extension PriorityQueue: Equatable {
    public static func == (lhs: PriorityQueue<Element>, rhs: PriorityQueue<Element>) -> Bool {
        guard lhs.storage !== rhs.storage else { return true }
        
        guard lhs.underestimatedCount == rhs.underestimatedCount else { return false }
        
        for (lhsElement, rhsElement) in zip(lhs, rhs) where lhsElement != rhsElement {
            
            return false
        }
        
        return true
    }
    
}

// MARK: - Hashable conformance
extension PriorityQueue: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(underestimatedCount)
        forEach { hasher.combine($0) }
    }
    
}

// MARK: - Codable conformance
extension PriorityQueue: Codable where Element: Codable {
    private enum CodingKeys: String, CodingKey {
        case maxHeapOfElements
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(storage?.withUnsafeBufferPointer { Array($0) } ?? [Element](), forKey: .maxHeapOfElements)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let arr = try container.decode(Array<Element>.self, forKey: .maxHeapOfElements)
        guard !arr.isEmpty else { return }
        
        storage = HeapBuffer(arr, heapType: .maxHeap)
    }
    
}

// MARK: CustomStringConvertible and CustomDebugStringConvertible conformances
extension PriorityQueue: CustomStringConvertible, CustomDebugStringConvertible {
    private func makeDescription(debug: Bool) -> String {
            var result = debug ? "\(String(reflecting: PriorityQueue.self))([" : "PriorityQueue["
            var first = true
            for item in self {
                if first {
                    first = false
                } else {
                    result += ", "
                }
                if debug {
                    debugPrint(item, terminator: "", to: &result)
                }
                else {
                    print(item, terminator: "", to: &result)
                }
            }
            result += debug ? "])" : "]"
            return result
        }

    public var description: String {
        return makeDescription(debug: false)
    }
    
    public var debugDescription: String {
        return makeDescription(debug: true)
    }
    
}

// MARK: - Private Interface
// MARK: - Copy on write helpers
extension PriorityQueue {
    private var _isUnique: Bool {
        mutating get {
            isKnownUniquelyReferenced(&storage)
        }
    }
    
    private mutating func _makeUnique(reservingCapacity minCapacity: Int = 0) {
        if self.storage == nil {
            self.storage = HeapBuffer(minCapacity, heapType: .maxHeap)
        } else if !_isUnique {
            storage = storage!.copy(reservingCapacity: minCapacity)
        } else if minCapacity > 0 {
            storage!.reserveCapacity(minCapacity)
        }
    }
    
    private mutating func _checkForEmptyAtEndOfMutation() {
        if self.storage?.count == 0 {
            self.storage = nil
        }
    }
    
}
