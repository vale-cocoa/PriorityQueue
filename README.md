# PriorityQueue

A queue data structure — with value semantics— whose elements are dequeued by priority order.

Priority of one element over another is defined via a *strict ordering function* given at creation time and
invariable during the life time of an instance.
Such that given `sort` as the ordering function, then for any elements `a`, `b`, and `c`,
the following conditions must hold:

 -   `sort(a, a)` is always `false`. (Irreflexivity)
 -   If `sort(a, b)` and `sort(b, c)` are both `true`, then `sort(a, c)` is also `true`.
    ( Transitive comparability)
 -   Two elements are *incomparable* if neither is ordered before the other according to the sort function.
    If `a` and `b` are incomparable, and `b` and `c` are incomparable, then `a` and `c` are also incomparable.
    (Transitive incomparability)
