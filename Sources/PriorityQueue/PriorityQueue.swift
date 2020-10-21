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

public struct PriorityQueue<Element: Comparable> {
    private(set) var storage: HeapBuffer<Element>? = nil
    
    public init() {  }
    
    public init<S: Sequence>(_ elements: S) where S.Iterator.Element == Element {
        let newStorage = HeapBuffer(elements, heapType: .maxHeap)
        guard !newStorage.isEmpty else { return }
        
        storage = newStorage
    }
    
    public init(repeating repeatedValue: Element, count: Int) {
        precondition(count >= 0)
        guard count > 0 else { return }
        
        storage = HeapBuffer(repeating: repeatedValue, count: count, heapType: .maxHeap)
    }
    
}

// MARK: - Public Interface
// MARK: - Computed properties
extension PriorityQueue {
    public var count: Int { storage?.count ?? 0 }
    
    public var underestimatedCount: Int { storage?.count ?? 0 }
    
    public var isEmpty: Bool { storage?.isEmpty ?? true }
    
    public var startIndex: Int { 0 }
    
    public var endIndex: Int { storage?.endIndex ?? 0 }
    
    public var first: Element? {
        peek()
    }
    
    public var last: Element? {
        guard !isEmpty else { return nil }
        
        return storage![endIndex - 1]
    }
    
    public var indices: CountableRange<Int> {
        startIndex..<endIndex
    }
    
}

// MARK: - Common Sequence/MutableCollection operations
extension PriorityQueue {
    public func allSatisfy(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        for i in startIndex..<endIndex where try predicate(storage![i]) == false {
            
            return false
        }
        
        return true
    }
    
    public func forEach(_ body: (Element) throws -> Void) rethrows {
        try storage?.forEach(body)
    }
    
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
        try compactMap { try isIncluded($0) ? $0 : nil }
    }
    
    public func map<T>(_ body: (Element) throws -> T) rethrows -> [T] {
        var result = [T]()
        try storage?.forEach { result.append(try body($0)) }
        
        return result
    }
    
    public func flatMap<SegmentOfResult>(_ transform: (Element) throws -> SegmentOfResult) rethrows -> [SegmentOfResult.Element] where SegmentOfResult: Sequence {
        var result = [SegmentOfResult.Element]()
        try storage?.forEach {
            result.append(contentsOf: try transform($0))
        }
        
        return result
    }
    
    @available(swift, deprecated: 4.1, renamed: "compactMap(_:)", message: "Please use compactMap(_:) for the case where closure returns an optional value")
    public func flatMap<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        
        return try compactMap(transform)
    }
    
    public func compactMap<T>(_ transform: (Element) throws -> T?) rethrows -> [T] {
        var result = [T]()
        try storage?.forEach { element in
            try transform(element).map { result.append($0) }
        }
        
        return result
    }
    
    public func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, Element) throws -> ()) rethrows -> Result {
        var finalResult = initialResult
        try storage?.forEach {
            try updateAccumulatingResult(&finalResult, $0)
        }
        
        return finalResult
    }
    
    public func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, Element) throws -> Result) rethrows -> Result {
        try reduce(into: initialResult) { accumulator, element in
            accumulator = try nextPartialResult(accumulator, element)
        }
    }
    
    public subscript(_ position: Int) -> Element {
        get { storage![position] }
        set {
            _makeUnique()
            storage![position] = newValue
        }
    }
    
    public subscript(bounds: Range<Int>) -> SubSequence {
        get { SubSequence(base: self, bounds: bounds) }
        set { replaceSubrange(bounds, with: newValue) }
    }
    
    public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R? {
        try self.storage?.withUnsafeBufferPointer(body) ??  body(UnsafeBufferPointer<Element>(start: nil, count: 0))
    }
    
    public mutating func withContiguousMutableStorageIfAvailable<R>(_ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R) rethrows -> R? {
        _makeUnique()
        
        // Ensure that body can't invalidate the storage or its
        // bounds by moving self into a temporary working PriorityQueue.
        // NOTE: The stack promotion optimization that keys of the
        // "priorityQueue.withContiguousMutableStorageIfAvailable"
        // semantics annotation relies on the PriorityQueue buffer not
        // being able to escape in the closure.
        // It can do this because we swap the PriorityQueue buffer in self
        // with an empty buffer here.
        // Any escape via the address of self in the closure will
        // therefore escape the empty PriorityQueue.
        var work = PriorityQueue()
        (work, self) = (self, work)
        
        // Put back in place PriorityQueue:
        defer {
            (work, self) = (self, work)
            _checkForEmptyAtEndOfMutation()
        }
        
        // Invoke body taking advantage of HeapBuffer's
        // withUnsafeMutableBufferPointer(_:) method.
        // Here it's safe to force-unwrap storage on work since
        // it must not be nil having invoked _makeUnique() in the
        // beginning.
        return try work.storage!
            .withUnsafeMutableBufferPointer(body)
    }
    
}

extension PriorityQueue:
    BidirectionalCollection,
    MutableCollection,
    RandomAccessCollection
{
    public typealias Iterator = IndexingIterator<PriorityQueue<Element>>
    
    public typealias Index = Int
    
    public typealias Indices = CountableRange<Int>
    
    public typealias SubSequence = PriorityQueueSlice<Element>
    
    public func index(after i: Int) -> Int {
        i + 1
    }
    
    public func index(before i: Int) -> Int {
        i - 1
    }
    
    public func formIndex(after i: inout Int) {
        i += 1
    }
    
    public func formIndex(before i: inout Int) {
        i -= 1
    }
    
    public func index(_ i: Int, offsetBy distance: Int) -> Int {
        i + distance
    }
    
    public func index(_ i: Int, offsetBy distance: Int, limitedBy limit: Int) -> Int? {
        let l = limit - i
        
        if distance > 0 ? (l >= 0 && l < distance) : (l <= 0 && distance < l) {
            
            return nil
        }
        
        return i + distance
    }
    
    public func distance(from start: Int, to end: Int) -> Int {
        end - start
    }
    
}

extension PriorityQueue: RangeReplaceableCollection {
    public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C : Collection, Self.Element == C.Element {
        let difference = (count - subrange.count + newElements.count) - count
        let additionalCapacity = difference < 0 ? 0 : difference
        _makeUnique(reservingCapacity: additionalCapacity)
        storage!.replace(subrange: subrange, with: newElements)
        _checkForEmptyAtEndOfMutation()
    }
    
    public mutating func reserveCapacity(_ n: Int) {
        let additionalCapacity = n - count > 0 ? n - count : 0
        _makeUnique(reservingCapacity: additionalCapacity)
    }
    
    public mutating func append(_ newElement: Self.Element) {
        _makeUnique()
        storage!.insert(newElement)
    }
    
    public mutating func append<S>(contentsOf newElements: S) where S: Sequence, Self.Element == S.Iterator.Element {
        _makeUnique(reservingCapacity: newElements.underestimatedCount)
        let done = newElements
            .withContiguousStorageIfAvailable { buff in
                guard buff.baseAddress != nil && buff.count > 0 else { return false }
                
                self.storage!.insert(elements: buff, at: self.count)
                
                return true
            } ?? false
        
        if !done {
            for newElement in newElements {
                storage!.insert(newElement)
            }
        }
        _checkForEmptyAtEndOfMutation()
    }
    
    public mutating func insert(_ newElement: Self.Element, at i: Self.Index) {
        _makeUnique()
        storage!.insert(newElement, at: i)
    }
    
    public mutating func insert<C: Collection>(contentsOf newElements: C, at i: Self.Index) where  Self.Element == C.Element {
        _makeUnique(reservingCapacity: newElements.count)
        storage!.insert(elements: newElements, at: i)
        _checkForEmptyAtEndOfMutation()
    }
    
    public mutating func remove(at i: Self.Index) -> Self.Element {
        _makeUnique()
        defer {
            _checkForEmptyAtEndOfMutation()
        }
        
        return storage!.remove(at: i)
    }
    
    public mutating func removeSubrange(_ bounds: Range<Self.Index>) {
        let subrange = bounds.relative(to: indices)
        guard subrange.count > 0 else { return }
        
        _makeUnique()
        storage!.remove(at: subrange.lowerBound, count: subrange.count)
        _checkForEmptyAtEndOfMutation()
    }
    
    public mutating func removeFirst() -> Self.Element {
        _makeUnique()
        defer {
            _checkForEmptyAtEndOfMutation()
        }
        
        return storage!.remove(at:0, count: 1, keepingCapacity: false).first!
    }
    
    public mutating func removeFirst(_ k: Int) {
        _makeUnique()
        storage!.remove(at:0, count: k, keepingCapacity: false)
        _checkForEmptyAtEndOfMutation()
    }
    
    @available(*, deprecated, renamed: "removeAll(keepingCapacity:)")
    public mutating func removeAll(keepCapacity: Bool) {
        self.removeAll(keepingCapacity: keepCapacity)
    }
    
    public mutating func removeAll(keepingCapacity keepCapacity: Bool) {
        guard storage != nil else { return }
        
        _makeUnique()
        guard keepCapacity else {
            storage = nil
            
            return
        }
        
        storage!.remove(at: 0, count: count, keepingCapacity: keepCapacity)
    }
    
    @discardableResult
    public mutating func popLast() -> Element? {
        _makeUnique()
        defer {
            _checkForEmptyAtEndOfMutation()
        }
        
        guard !isEmpty else { return nil }
        
        return storage!.remove(at: count - 1)
    }
    
    @discardableResult
    public mutating func popFirst() -> Element? {
        dequeue()
    }
    
    public mutating func removeLast() -> Self.Element {
        _makeUnique()
        defer {
            _checkForEmptyAtEndOfMutation()
        }
        
        return storage!.remove(at: endIndex - 1)
    }
    
    public mutating func removeLast(_ k: Int) {
        _makeUnique()
        
        storage!.remove(at: count - k, count: k)
        _checkForEmptyAtEndOfMutation()
    }
}

extension PriorityQueue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
    
}

// MARK: - Queue operations
extension PriorityQueue {
    @discardableResult
    public func peek() -> Element? {
        storage?.peek()
    }
    
    public mutating func enqueue(_ newElement: Element) {
        _makeUnique()
        storage!.insert(newElement)
    }
    
    public mutating func enqueue<S: Sequence>(elements newElements: S) where S.Iterator.Element == Element {
        _makeUnique(reservingCapacity: newElements.underestimatedCount)
        let done = newElements
            .withContiguousStorageIfAvailable { buff in
                storage!.insert(elements: buff, at: count)
                    
                return true
                } ?? false
        if !done {
            for newElement in newElements {
                enqueue(newElement)
            }
        }
        
        _checkForEmptyAtEndOfMutation()
    }
    
    @discardableResult
    public mutating func dequeue() -> Element? {
        _makeUnique()
        defer {
            _checkForEmptyAtEndOfMutation()
        }
        
        return storage!.extract()
    }
    
    @discardableResult
    public mutating func enqueueDequeue(_ newElement: Element) -> Element {
        _makeUnique()
        defer {
            _checkForEmptyAtEndOfMutation()
        }
        
        return storage!.pushPop(newElement)
    }
    
    @discardableResult
    public mutating func replace(_ newElement: Element) -> Element {
        _makeUnique()
        
        return storage!.replace(newElement)
    }
    
}

extension PriorityQueue: Equatable {
    public static func == (lhs: PriorityQueue<Element>, rhs: PriorityQueue<Element>) -> Bool {
        guard lhs.storage !== rhs.storage else { return true }
        
        guard lhs.count == rhs.count else { return false }
        
        for (lhsElement, rhsElement) in zip(lhs, rhs) where lhsElement != rhsElement {
            
            return false
        }
        
        return true
    }
    
}

extension PriorityQueue: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        forEach { hasher.combine($0) }
    }
    
}

extension PriorityQueue: Codable where Element: Codable {
    enum CodingKeys: String, CodingKey {
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
