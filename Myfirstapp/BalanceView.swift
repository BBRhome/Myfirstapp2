import SwiftUI

struct BalanceView: View {
    @EnvironmentObject private var store: TransactionStore

    // Смещение относительно текущего месяца: 0 — текущий, -1 — прошлый, +1 — следующий
    @State private var selectedMonthOffset: Int = 0

    // Анимируемые значения для выбранного месяца
    @State private var animatedIncome: Double = 0
    @State private var animatedExpense: Double = 0
    @State private var animatedSaldo: Double = 0
    @State private var appear = false

    // Общие суммы (всё время) — оставим как дополнительный блок
    private var totalAllTime: Double {
        store.transactions.reduce(0) { $0 + $1.amount }
    }
    private var incomeAllTime: Double {
        store.transactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }
    private var expenseAllTime: Double {
        -store.transactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount }
    }

    // Интервал выбранного месяца
    private var selectedMonthInterval: DateInterval {
        let cal = Calendar.current
        let now = Date()
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let shiftedStart = cal.date(byAdding: .month, value: selectedMonthOffset, to: monthStart)!
        // Конец — последний день месяца 23:59:59
        let startOfNext = cal.date(byAdding: .month, value: 1, to: shiftedStart)!
        let end = cal.date(byAdding: .second, value: -1, to: startOfNext)!
        return DateInterval(start: shiftedStart, end: end)
    }

    private var monthTransactions: [Transaction] {
        store.transactions.filter { selectedMonthInterval.contains($0.date) }
    }
    private var monthIncome: Double {
        monthTransactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }
    private var monthExpense: Double {
        -monthTransactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount }
    }
    private var monthSaldo: Double {
        monthIncome - monthExpense
    }

    var body: some View {
        ZStack {
            backgroundGradient().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    monthSummaryCard()

                    // Дополнительная аналитика за всё время
                    VStack(spacing: 12) {
                        statRow(title: "Баланс (всё время)", value: totalAllTime, color: .primary, icon: "circle.grid.2x2")
                        statRow(title: "Доходы (всё время)", value: incomeAllTime, color: .green, icon: "arrow.down.left.circle.fill")
                        statRow(title: "Расходы (всё время)", value: -expenseAllTime, color: .red, icon: "arrow.up.right.circle.fill")
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
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                appear = true
            }
            animateNumbers()
        }
        .onChange(of: store.transactions) { _, _ in
            animateNumbers()
        }
        .onChange(of: selectedMonthOffset) { _, _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            animateNumbers()
        }
    }

    // MARK: - Анимация чисел

    private func animateNumbers() {
        withAnimation(.interpolatingSpring(stiffness: 140, damping: 18)) {
            animatedIncome = monthIncome
        }
        withAnimation(.interpolatingSpring(stiffness: 140, damping: 18).delay(0.02)) {
            animatedExpense = monthExpense
        }
        withAnimation(.interpolatingSpring(stiffness: 120, damping: 16).delay(0.04)) {
            animatedSaldo = monthSaldo
        }
    }

    // MARK: - Карточка месяца

    private func monthSummaryCard() -> some View {
        VStack(spacing: 14) {
            // Переключатель месяцев
            HStack {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        selectedMonthOffset -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(radius: 2)
                }

                Spacer()

                Text(monthTitle(forOffset: selectedMonthOffset))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.opacity)
                    .id(selectedMonthOffset) // для красивого cross-fade при смене
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        selectedMonthOffset += 1
                    }
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(radius: 2)
                }
            }

            // Большое сальдо
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: animatedSaldo >= 0 ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                    .foregroundStyle(.white.opacity(0.9))
                    .font(.title2)
                    .symbolEffect(.bounce, options: .repeating, value: Int(animatedSaldo) % 2 == 0)
                Text(format(animatedSaldo))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: animatedSaldo))
                    .animation(.spring(response: 0.35, dampingFraction: 0.88), value: animatedSaldo)
                Spacer()
            }
            .padding(.top, 2)

            // Доход и Расход
            HStack(spacing: 12) {
                miniPill(title: "Доход", value: animatedIncome, icon: "arrow.down.left", color: .green)
                    .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                            removal: .opacity))
                miniPill(title: "Расход", value: -animatedExpense, icon: "arrow.up.right", color: .red)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .opacity))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.85),
                            Color.purple.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blendMode(.plusLighter)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15))
        )
        .scaleEffect(appear ? 1 : 0.98)
        .opacity(appear ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: appear)
    }

    private func miniPill(title: String, value: Double, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                Text(format(value))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: value))
                    .animation(.spring(response: 0.35, dampingFraction: 0.88), value: value)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18))
                )
        )
    }

    private func statRow(title: String, value: Double, color: Color, icon: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(color == .primary ? .blue : color)
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

    // MARK: - Helpers

    private func monthTitle(forOffset offset: Int) -> String {
        let cal = Calendar.current
        let now = Date()
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let shifted = cal.date(byAdding: .month, value: offset, to: monthStart)!

        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.setLocalizedDateFormatFromTemplate("LLLL yyyy")
        let title = df.string(from: shifted).capitalized
        return title
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
