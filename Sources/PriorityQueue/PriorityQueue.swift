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
import Queue

/// A queue data structure — with value semantics— whose elements are dequeued by priority order.
///
/// Priority of one element over another is defined via a *strict ordering function* given at creation time and
/// invariable during the life time of an instance.
/// Such that given `sort` as the ordering function, then for any elements `a`, `b`, and `c`,
/// the following conditions must hold:
///
/// -   `sort(a, a)` is always `false`. (Irreflexivity)
/// -   If `sort(a, b)` and `sort(b, c)` are both `true`, then `sort(a, c)` is also `true`.
///    ( Transitive comparability)
/// -   Two elements are *incomparable* if neither is ordered before the other according to the sort function.
///    If `a` and `b` are incomparable, and `b` and `c` are incomparable, then `a` and `c` are also incomparable.
///    (Transitive incomparability)
public struct PriorityQueue<Element> {
    private(set) var storage: HeapBuffer<Element>
    
    /// Returns a new empty instance of `PriorityQueue` intialized  with the minimum given capacity and
    /// adopting the given sort to calculate the priority on its elements.
    ///
    /// - Parameter minimumCapacity:    An `Int` value representing the minium number of elements
    ///                                 the priority queue should be able to store without having
    ///                                 to reallocate its storage.
    ///                                 Default to `0`.
    /// - Parameter sort:   A closure that given two elements returns either `true` if they are sorted,
    ///                     or `false` if they aren't sorted.
    ///                     Must be a *strict weak ordering* over the elements.
    /// - Returns:  A new empty priority queue adopting the given sort closure to determine the priority
    ///             of its elment, with a storage dimensioned to the hold at least the given minimum number
    ///             of elements without having to reallocate memory.
    public init(minimumCapacity: Int = 0, sort: @escaping(Element, Element) -> Bool) {
        precondition(minimumCapacity >= 0)
        self.storage = HeapBuffer(minimumCapacity, sort: sort)
    }
    
    /// Returns a new instance of `PriorityQueue`, storing all elements in given sequence.
    ///
    /// - Parameter elements:   A sequence of elements to store.
    /// - Parameter sort:   A closure that given two elements returns either `true` if they are sorted,
    ///                     or `false` if they aren't sorted.
    ///                     Must be a *strict weak ordering* over the elements.
    /// - Returns:  A new instance adopting the given `sort` closure to determine priority of elments,
    ///             containing all elements contained in given `elements` sequence .
    /// - Complexity: O(log*n*) where *n* is the count of elements in given `elements` sequence.
    public init<S: Sequence>(_ elements: S, sort: @escaping(Element, Element) -> Bool) where S.Iterator.Element == Element {
        self.storage = HeapBuffer(elements, sort: sort)
    }
    
    /// Returns a new instance of `PriorityQueue` adopting the given sort to determine the priority of its elements,
    /// initialized by storing the same given element for the specified count.
    ///
    /// - Parameter repeatedValue: The element to repeat.
    /// - Parameter count:  the number of times the given `repeatedValue` element has to be repeated.
    ///                     **Must not be negative**.
    /// - Parameter sort:   A closure that given two elements returns either `true` if they are sorted,
    ///                     or `false` if they aren't sorted.
    ///                     Must be a *strict weak ordering* over the elements.
    /// - Returns:  A new instance of `PriorityQueue` adopting the given `sort` closure
    ///             to determine the priority of its elements, initialized by storing the same given element
    ///              for the specified count.
    public init(repeating repeatedValue: Element, count: Int, sort: @escaping(Element, Element) -> Bool) {
        precondition(count >= 0)
        
        storage = HeapBuffer(repeating: repeatedValue, count: count, sort: sort)
    }
    
}

// MARK: - Public Interface
// MARK: - IteratorProtocol and Sequence conformances
extension PriorityQueue: IteratorProtocol, Sequence {
    public typealias Iterator = Self
    
    public var underestimatedCount: Int { storage.count }
    
    public mutating func next() -> Element? {
        dequeue()
    }
    
}

// MARK: - Queue conformance
extension PriorityQueue: Queue {
    public var count: Int { underestimatedCount }
    
    public var isEmpty: Bool { storage.isEmpty }
    
    public var capacity: Int { storage.capacity }
    
    public var isFull: Bool { storage.isFull }
    
    @discardableResult
    public func peek() -> Element? {
        storage.peek()
    }
    
    public mutating func enqueue(_ newElement: Element) {
        _makeUnique()
        storage.insert(newElement)
    }
    
    public mutating func enqueue<S: Sequence>(contentsOf newElements: S) where S.Iterator.Element == Element {
        _makeUnique(reservingCapacity: newElements.underestimatedCount)
        let done = newElements
            .withContiguousStorageIfAvailable { buff in
                storage.insert(contentsOf: buff, at: underestimatedCount)
                
                return true
            } ?? false
        
        if !done {
            for newElement in newElements {
                enqueue(newElement)
            }
        }
        
    }
    
    @discardableResult
    public mutating func dequeue() -> Element? {
        _makeUnique()
        
        return storage.extract()
    }
    
    
    public mutating func clear(keepingCapacity keepCapacity: Bool = false) {
        guard
            !storage.isEmpty
        else { return }
        
        _makeUnique()
        storage.remove(at: storage.startIndex, count: storage.count, keepingCapacity: keepCapacity)
    }
    
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        precondition(minimumCapacity >= 0)
        guard
            minimumCapacity > 0,
            (capacity - count) < minimumCapacity
        else { return }
        
        _makeUnique(reservingCapacity: minimumCapacity)
    }
    
}

// MARK: - Priority Queue specific functionalities
extension PriorityQueue {
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
        
        return storage.pushPop(newElement)
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
        guard
            !isEmpty
        else {
            defer { enqueue(newElement) }
            
            return nil
        }
        
        return storage.replace(newElement)
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

    public var description: String { makeDescription(debug: false) }
    
    public var debugDescription: String { makeDescription(debug: true) }
    
}

// MARK: - MinPQ and MaxPQ factory
extension PriorityQueue where Element: Comparable {
    public static var minPQ: Self { Self.init(sort: <) }
    
    public static var maxPQ: Self { Self.init(sort: >) }
    
    public static func minPQ<S: Sequence>(_ elements: S) -> Self where S.Iterator.Element == Element {
        Self.init(elements, sort: <)
    }
    
    public static func maxPQ<S: Sequence>(_ elements: S) -> Self where S.Iterator.Element == Element {
        Self.init(elements, sort: >)
    }
    
}

// MARK: - Private Interface
// MARK: - Copy On Write helpers
extension PriorityQueue {
    private mutating func _makeUnique(reservingCapacity minCapacity: Int = 0) {
        if !isKnownUniquelyReferenced(&storage) {
            storage = storage.copy(reservingCapacity: minCapacity)
        } else if minCapacity > 0 {
            storage.reserveCapacity(minCapacity)
        }
    }
    
}
