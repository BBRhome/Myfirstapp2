import SwiftUI

struct ExpenseEntryView: View {
    @EnvironmentObject private var store: TransactionStore

    @State private var amountText: String = ""
    @State private var selectedCategory: Category? = allCategories.first
    @State private var note: String = ""
    @State private var payment: String = "Карта"
    @State private var date: Date = .now

    @FocusState private var isAmountFocused: Bool
    @State private var showDetails: Bool = false

    private var canSave: Bool {
        canSaveExpense(amountText: amountText, categoryKey: selectedCategory?.key, isIncome: false)
    }

    var body: some View {
        ZStack {
            backgroundGradient().ignoresSafeArea()

            VStack(spacing: 0) {
                header()

                // Категории сверху (без подписи под сеткой)
                HoneycombGrid(
                    items: allCategories,
                    selected: selectedCategory,
                    select: { cat in
                        selectedCategory = cat
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .opacity(showDetails ? 0.0 : 1.0)
                .animation(.spring(response: 0.28, dampingFraction: 0.92), value: showDetails)

                Spacer(minLength: 0)
            }

            // Кнопка-инициатор
            VStack {
                Spacer()
                if !showDetails {
                    amountStarter()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20 + bottomSafeInset())
                }
            }

            // Детали снизу
            if showDetails {
                VStack {
                    Spacer(minLength: 0)
                    detailCard()
                        .offset(y: isAmountFocused ? -min(220, UIScreen.main.bounds.height * 0.28) : 0)
                        .animation(.spring(response: 0.30, dampingFraction: 0.92), value: isAmountFocused)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") {
                    if canSave {
                        save()
                    } else {
                        closeDetails()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private func header() -> some View {
        HStack {
            Text("Траты")
                .font(.title2.bold())
                .foregroundColor(.primary)
            Spacer()
            HStack(spacing: 8) {
                NavigationLink(destination: MonthlySpendingView().environmentObject(store)) {
                    Image(systemName: "calendar")
                        .font(.subheadline.weight(.semibold))
                        .padding(8)
                        .background(Capsule().fill(.ultraThinMaterial))
                }
                NavigationLink(destination: HistoryView().environmentObject(store)) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.subheadline.weight(.semibold))
                        .padding(8)
                        .background(Capsule().fill(.ultraThinMaterial))
                }
            }
            .tint(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 6)
    }

    // MARK: - Amount Starter

    private func amountStarter() -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                showDetails = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isAmountFocused = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Добавить сумму")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Добавить сумму")
    }

    // MARK: - Detail Card

    private func detailCard() -> some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(Color.primary.opacity(0.15))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            // Сумма
            VStack(alignment: .leading, spacing: 6) {
                Text("Сумма")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    Text("₽")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .focused($isAmountFocused)
                        .multilineTextAlignment(.leading)
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
            }

            // Дата и Способ оплаты
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Дата")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $date, displayedComponents: [.date])
                        .labelsHidden()
                        .datePickerStyle(.compact)
                }

                Spacer(minLength: 8)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Способ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Menu {
                        Button("Карта") { payment = "Карта" }
                        Button("Наличные") { payment = "Наличные" }
                        Button("Счёт") { payment = "Счёт" }
                    } label: {
                        HStack {
                            Image(systemName: paymentIcon())
                            Text(payment)
                                .font(.body.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                    .tint(.primary)
                }
            }

            // Заметка
            VStack(alignment: .leading, spacing: 6) {
                Text("Заметка")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Комментарий", text: $note)
                    .textInputAutocapitalization(.sentences)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
            }

            // Кнопка Сохранить
            Button(action: save) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Сохранить")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(buttonGradient())
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!canSave)
            .padding(.top, 2)

        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14 + bottomSafeInset())
        .padding(.top, 10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.05))
        )
        .padding(.horizontal, 10)
    }

    // MARK: - Helpers

    private func closeDetails() {
        isAmountFocused = false
        withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
            showDetails = false
        }
    }

    private func paymentIcon() -> String {
        switch payment {
        case "Карта": return "creditcard.fill"
        case "Наличные": return "banknote.fill"
        case "Счёт": return "building.columns.fill"
        default: return "creditcard"
        }
    }

    private func backgroundGradient() -> LinearGradient {
        let light = [
            Color(red: 0.96, green: 0.97, blue: 1.00),
            Color(red: 0.93, green: 0.95, blue: 0.99)
        ]
        let dark = [
            Color(red: 0.11, green: 0.12, blue: 0.16),
            Color(red: 0.07, green: 0.08, blue: 0.11)
        ]
        let colors = UITraitCollection.current.userInterfaceStyle == .dark ? dark : light
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func buttonGradient() -> LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.95), Color.purple.opacity(0.95)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func bottomSafeInset() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .safeAreaInsets.bottom ?? 0
    }

    private func save() {
        guard let amount = parseAmount(amountText), amount > 0 else { return }
        let tx = Transaction(
            date: date,
            amount: -abs(amount),
            categoryKey: selectedCategory?.key,
            note: note.isEmpty ? nil : note,
            payment: payment.isEmpty ? nil : payment
        )
        store.add(tx)

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        amountText = ""
        note = ""
        payment = "Карта"
        selectedCategory = allCategories.first
        closeDetails()
    }
}

#Preview {
    NavigationStack {
        ExpenseEntryView()
            .environmentObject(TransactionStore(seedDemoData: true))
    }
}
