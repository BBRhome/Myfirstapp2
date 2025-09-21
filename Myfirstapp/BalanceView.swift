import SwiftUI

struct BalanceView: View {
    @EnvironmentObject private var store: TransactionStore

    private var total: Double {
        store.transactions.reduce(0) { $0 + $1.amount }
    }
    private var incomeTotal: Double {
        store.transactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }
    private var expenseTotal: Double {
        -store.transactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ZStack {
            backgroundGradient().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerCard()

                    VStack(spacing: 12) {
                        statRow(title: "Баланс", value: total, color: .primary, icon: "circle.grid.2x2")
                        statRow(title: "Доходы", value: incomeTotal, color: .green, icon: "arrow.down.left.circle.fill")
                        statRow(title: "Расходы", value: -expenseTotal, color: .red, icon: "arrow.up.right.circle.fill")
                    }
                    .padding(16)
                    .background(cardBackground())
                    .overlay(cardStroke())
                    .clipShape(cardShape())

                    NavigationLink {
                        HistoryView()
                            .environmentObject(store)
                            .navigationTitle("История")
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title3)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("История операций")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Список всех транзакций")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(cardBackground())
                        .overlay(cardStroke())
                        .clipShape(cardShape())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Баланс")
    }

    private func headerCard() -> some View {
        VStack(spacing: 10) {
            Text("Текущий баланс")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(format(total))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(total >= 0 ? .primary : .red)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(cardBackground())
        .overlay(cardStroke())
        .clipShape(cardShape())
    }

    private func statRow(title: String, value: Double, color: Color, icon: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(format(value))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(color == .primary ? .primary : color)
            }
            Spacer()
        }
    }

    private func format(_ value: Double) -> String {
        let sign = value < 0 ? "−" : ""
        return "\(sign)\(String(format: "%.2f", abs(value))) ₽"
    }

    // MARK: - Style helpers

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

    private func cardBackground() -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.ultraThinMaterial)
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func cardShape() -> some Shape {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
    }

    private func cardStroke() -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.06))
    }
}

#Preview {
    NavigationStack {
        BalanceView()
            .environmentObject(TransactionStore(seedDemoData: true))
    }
}
