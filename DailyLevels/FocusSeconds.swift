//
//  FocusSeconds.swift
//  Daily Levels
//
//  Overflow-safe arithmetic for nonnegative focus counters.
//

enum FocusSeconds {
    static func adding(_ lhs: Int, _ rhs: Int) -> Int {
        let left = max(0, lhs)
        let right = max(0, rhs)
        let (sum, overflow) = left.addingReportingOverflow(right)
        return overflow ? Int.max : sum
    }

    static func sum<S: Sequence>(_ values: S) -> Int where S.Element == Int {
        values.reduce(0, adding)
    }
}
