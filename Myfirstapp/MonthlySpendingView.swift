import SwiftUI

struct MonthlySpendingView: View {
    @EnvironmentObject private var store: TransactionStore
    @State private var currentMonth: Date = Date() // показываем месяц текущей даты

    private var monthInterval: DateInterval {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth))!
        let end = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? start
        // конец дня
        let endOfDay = cal.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end
        return DateInterval(start: start, end: endOfDay)
    }

    private var monthTitle: String {
        let df = DateFormatter()
        df.locale = Locale.current
        df.setLocalizedDateFormatFromTemplate("LLLL yyyy")
        return df.string(from: monthInterval.start).capitalized
    }

    private var expenseTotal: Double {
        let txs = store.transactions.filter { $0.date >= monthInterval.start && $0.date <= monthInterval.end && $0.amount < 0 }
        return -txs.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ZStack {
            backgroundGradient().ignoresSafeArea()

            VStack(spacing: 16) {
                header()

                // Карточка суммы за месяц
                VStack(spacing: 10) {
                    Text(monthTitle)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(format(expenseTotal))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06))
                )
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 12)
        }
        .navigationTitle("Расходы по месяцам")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header() -> some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .padding(10)
                    .background(Circle().fill(.ultraThinMaterial))
            }

            Spacer()

            Text(monthTitle)
                .font(.title3.bold())

            Spacer()

            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .padding(10)
                    .background(Circle().fill(.ultraThinMaterial))
            }
        }
        .padding(.horizontal, 16)
    }

    private func format(_ value: Double) -> String {
        let sign = value < 0 ? "−" : ""
        return "\(sign)\(String(format: "%.2f", abs(value))) ₽"
    }

    private func backgroundGradient() -> LinearGradient {
        let light = [
            Color(red: 0.95, green: 0.96, blue: 1.00),
            Color(red: 0.92, green: 0.94, blue: 0.99)
        ]
        let dark = [
            Color(red: 0.10, green: 0.12, blue: 0.16),
            Color(red: 0.06, green: 0.07, blue: 0.10)
        ]
        let colors = UITraitCollection.current.userInterfaceStyle == .dark ? dark : light
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#Preview {
    NavigationStack {
        MonthlySpendingView()
            .environmentObject(TransactionStore(seedDemoData: true))
    }
}
