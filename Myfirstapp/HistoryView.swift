import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: TransactionStore

    var body: some View {
        List {
            ForEach(grouped.keys.sorted(by: >), id: \.self) { day in
                Section(sectionTitle(for: day)) {
                    ForEach(grouped[day] ?? []) { tx in
                        row(tx)
                    }
                }
            }
        }
    }

    private var grouped: [Date: [Transaction]] {
        let cal = Calendar.current
        let normalized = store.transactions.map { tx in
            (cal.startOfDay(for: tx.date), tx)
        }
        return Dictionary(grouping: normalized, by: { $0.0 }).mapValues { $0.map { $0.1 } }
    }

    private func sectionTitle(for day: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateStyle = .medium
        return df.string(from: day)
    }

    private func row(_ tx: Transaction) -> some View {
        HStack(spacing: 12) {
            let cat = tx.categoryKey.flatMap { categoriesByKey[$0] }
            ZStack {
                Circle()
                    .fill((cat != nil ? Color.blue : Color.green).opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: cat?.symbol ?? "arrow.down.circle.fill")
                    .foregroundColor(cat != nil ? .blue : .green)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(cat?.label ?? "Доход")
                    .fontWeight(.medium)
                if let note = tx.note, !note.isEmpty {
                    Text(note).foregroundStyle(.secondary).font(.caption)
                } else if let p = tx.payment, !p.isEmpty {
                    Text(p).foregroundStyle(.secondary).font(.caption)
                }
            }

            Spacer()

            Text(amountString(tx.amount))
                .font(.subheadline).bold()
                .foregroundColor(tx.amount < 0 ? .primary : .green)
        }
    }

    private func amountString(_ value: Double) -> String {
        let formatted = String(format: "%.2f", abs(value))
        return (value < 0 ? "−" : "+") + formatted + " ₽"
    }
}
