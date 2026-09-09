import Foundation

/// Plain-struct view of a `LineItem`, mapped by the view model from SwiftData so
/// `InsightsAggregator` stays free of any persistence dependency and is easy to
/// unit test with hand-built fixtures.
public struct LineItemSnapshot: Sendable, Equatable {
    public var id: UUID
    public var categoryID: UUID
    public var categoryName: String
    public var lineTotal: Decimal
    public var documentDate: Date

    public init(id: UUID, categoryID: UUID, categoryName: String, lineTotal: Decimal, documentDate: Date) {
        self.id = id
        self.categoryID = categoryID
        self.categoryName = categoryName
        self.lineTotal = lineTotal
        self.documentDate = documentDate
    }
}

/// Plain-struct view of an `ItemAssignment`.
public struct AssignmentSnapshot: Sendable, Equatable {
    public var personID: UUID
    public var personName: String
    public var computedAmount: Decimal

    public init(personID: UUID, personName: String, computedAmount: Decimal) {
        self.personID = personID
        self.personName = personName
        self.computedAmount = computedAmount
    }
}

/// Plain-struct view of an `ExpenseDocument`.
public struct ExpenseSnapshot: Sendable, Equatable {
    public var id: UUID
    public var merchantName: String
    public var totalAmount: Decimal
    public var date: Date

    public init(id: UUID, merchantName: String, totalAmount: Decimal, date: Date) {
        self.id = id
        self.merchantName = merchantName
        self.totalAmount = totalAmount
        self.date = date
    }
}
