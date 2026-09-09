import Foundation

public struct CategoryTotal: Sendable, Equatable {
    public var categoryID: UUID
    public var categoryName: String
    public var total: Decimal
}

public struct TrendBucket: Sendable, Equatable {
    public var periodStart: Date
    public var total: Decimal
}

public enum TrendGranularity: Sendable {
    case week
    case month

    var calendarComponent: Calendar.Component {
        switch self {
        case .week: return .weekOfYear
        case .month: return .month
        }
    }
}

public struct CategoryDelta: Sendable, Equatable {
    public var categoryID: UUID
    public var categoryName: String
    public var currentTotal: Decimal
    public var previousTotal: Decimal

    /// Percent change vs. the previous period. `nil` when there's no prior spend
    /// to compare against (division by zero would be meaningless, not "infinite").
    public var percentChange: Decimal? {
        guard previousTotal != 0 else { return nil }
        return ((currentTotal - previousTotal) / previousTotal) * 100
    }
}

public struct SpendingSpike: Sendable, Equatable {
    public var categoryID: UUID
    public var categoryName: String
    public var currentTotal: Decimal
    public var historicalMean: Decimal
}

public struct PersonSpend: Sendable, Equatable {
    public var personID: UUID
    public var personName: String
    public var total: Decimal
}

/// Pure, SwiftData-free aggregation functions over plain-struct snapshots.
/// Operates in-memory; at the data volumes a personal expense tracker produces
/// (hundreds to low thousands of line items), simple grouping is fast enough
/// that no incremental/cached aggregation is needed.
public enum InsightsAggregator {

    public static func categoryTotals(lineItems: [LineItemSnapshot]) -> [CategoryTotal] {
        let grouped = Dictionary(grouping: lineItems, by: \.categoryID)
        return grouped.map { categoryID, items in
            CategoryTotal(
                categoryID: categoryID,
                categoryName: items.first?.categoryName ?? "Uncategorized",
                total: items.reduce(Decimal(0)) { $0 + $1.lineTotal }
            )
        }
        .sorted { $0.total > $1.total }
    }

    public static func trend(
        lineItems: [LineItemSnapshot],
        granularity: TrendGranularity,
        calendar: Calendar = .current
    ) -> [TrendBucket] {
        let grouped = Dictionary(grouping: lineItems) { item -> Date in
            calendar.dateInterval(of: granularity.calendarComponent, for: item.documentDate)?.start
                ?? item.documentDate
        }
        return grouped.map { periodStart, items in
            TrendBucket(periodStart: periodStart, total: items.reduce(Decimal(0)) { $0 + $1.lineTotal })
        }
        .sorted { $0.periodStart < $1.periodStart }
    }

    /// Compares two already-computed sets of category totals (e.g. this month vs. last month).
    public static func monthOverMonthDeltas(current: [CategoryTotal], previous: [CategoryTotal]) -> [CategoryDelta] {
        let previousByID = Dictionary(uniqueKeysWithValues: previous.map { ($0.categoryID, $0.total) })
        return current.map { category in
            CategoryDelta(
                categoryID: category.categoryID,
                categoryName: category.categoryName,
                currentTotal: category.total,
                previousTotal: previousByID[category.categoryID] ?? 0
            )
        }
    }

    /// Flags a category as an outlier if its current total exceeds the historical
    /// mean (over the trailing periods supplied) by more than `thresholdStdDevs`
    /// standard deviations. Standard deviation is computed in `Double` since it's
    /// only used for threshold comparison, never stored or displayed as currency.
    public static func detectSpikes(
        categoryID: UUID,
        categoryName: String,
        trailingHistoricalTotals: [Decimal],
        currentTotal: Decimal,
        thresholdStdDevs: Double = 1.5
    ) -> SpendingSpike? {
        guard trailingHistoricalTotals.count >= 2 else { return nil }
        let values = trailingHistoricalTotals.map { NSDecimalNumber(decimal: $0).doubleValue }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        let stdDev = variance.squareRoot()
        let current = NSDecimalNumber(decimal: currentTotal).doubleValue

        guard stdDev > 0, current > mean + thresholdStdDevs * stdDev else { return nil }
        return SpendingSpike(
            categoryID: categoryID,
            categoryName: categoryName,
            currentTotal: currentTotal,
            historicalMean: Decimal(mean)
        )
    }

    public static func personSpend(assignments: [AssignmentSnapshot]) -> [PersonSpend] {
        let grouped = Dictionary(grouping: assignments, by: \.personID)
        return grouped.map { personID, items in
            PersonSpend(
                personID: personID,
                personName: items.first?.personName ?? "Unknown",
                total: items.reduce(Decimal(0)) { $0 + $1.computedAmount }
            )
        }
        .sorted { $0.total > $1.total }
    }

    public static func topExpenses(documents: [ExpenseSnapshot], limit: Int = 5) -> [ExpenseSnapshot] {
        Array(documents.sorted { $0.totalAmount > $1.totalAmount }.prefix(limit))
    }
}
