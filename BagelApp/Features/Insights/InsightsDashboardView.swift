import SwiftUI
import SwiftData
import Charts
import BagelCore

struct InsightsDashboardView: View {
    @Query private var documents: [ExpenseDocument]

    private var lineItemSnapshots: [LineItemSnapshot] {
        documents.flatMap { document in
            document.lineItems.map { item in
                LineItemSnapshot(
                    id: item.id,
                    categoryID: item.category?.id ?? UUID(),
                    categoryName: item.category?.name ?? "Uncategorized",
                    lineTotal: item.lineTotal,
                    documentDate: document.documentDate
                )
            }
        }
    }

    private var categoryTotals: [CategoryTotal] {
        InsightsAggregator.categoryTotals(lineItems: lineItemSnapshots)
    }

    private var monthlyTrend: [TrendBucket] {
        InsightsAggregator.trend(lineItems: lineItemSnapshots, granularity: .month)
    }

    var body: some View {
        NavigationStack {
            List {
                if !categoryTotals.isEmpty {
                    Section("Spending by Category") {
                        Chart(categoryTotals, id: \.categoryID) { category in
                            SectorMark(angle: .value("Total", NSDecimalNumber(decimal: category.total).doubleValue))
                                .foregroundStyle(by: .value("Category", category.categoryName))
                        }
                        .frame(height: 220)

                        ForEach(categoryTotals, id: \.categoryID) { category in
                            HStack {
                                Text(category.categoryName)
                                Spacer()
                                Text(Money.format(category.total))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !monthlyTrend.isEmpty {
                    Section("Spending Over Time") {
                        Chart(monthlyTrend, id: \.periodStart) { bucket in
                            BarMark(
                                x: .value("Month", bucket.periodStart, unit: .month),
                                y: .value("Total", NSDecimalNumber(decimal: bucket.total).doubleValue)
                            )
                        }
                        .frame(height: 180)
                    }
                }
            }
            .navigationTitle("Insights")
            .overlay {
                if lineItemSnapshots.isEmpty {
                    ContentUnavailableView(
                        "No Insights Yet",
                        systemImage: "chart.pie",
                        description: Text("Insights will appear once you've scanned and categorized some expenses.")
                    )
                }
            }
        }
    }
}

#Preview {
    InsightsDashboardView()
        .modelContainer(ModelContainerFactory.makeContainer(inMemory: true))
}
