import SwiftUI

struct ExpenseEntryView: View {
    @EnvironmentObject private var store: TransactionStore

    // Режим: расход / доход
    @State private var isIncome: Bool = false

    // Поля ввода
    @State private var amountText: String = ""
    @State private var selectedCategory: Category? = allCategories.first
    @State private var note: String = ""
    @State private var payment: String = "Карта"       // для расхода
    @State private var incomeSource: String = "Зарплата" // для дохода
    @State private var date: Date = .now

    // Управление UI
    @FocusState private var isAmountFocused: Bool
    @State private var showDetails: Bool = false

    // Текущий список категорий по режиму
    private var currentCategories: [Category] {
        isIncome ? incomeCategories : allCategories
    }

    // Валидация
    private var canSave: Bool {
        canSaveExpense(amountText: amountText, categoryKey: selectedCategory?.key, isIncome: isIncome)
    }

    var body: some View {
        ZStack {
            // Фон
            backgroundGradient()
                .ignoresSafeArea()

            // Содержимое
            VStack(spacing: 0) {
                header()

                // Тумблер режимов
                modeToggle()
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 2)

                // Категории сверху — по тапу открываем детали
                HoneycombGrid(
                    items: currentCategories,
                    selected: selectedCategory,
                    select: { cat in
                        selectedCategory = cat
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        openDetailsWithFocus()
                    }
                )
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .opacity(showDetails ? 0.0 : 1.0)
                .animation(.spring(response: 0.28, dampingFraction: 0.92), value: showDetails)

                Spacer(minLength: 0)
            }

            // Кнопка-инициатор, когда деталей нет
            VStack {
                Spacer()
                if !showDetails {
                    amountStarter()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20 + bottomSafeInset())
                }
            }

            // Диммер + Детали
            if showDetails {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { closeDetails() }

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
        .onChange(of: isIncome) { _, newValue in
            // При смене режима — сбросить категорию на первую подходящую
            selectedCategory = (newValue ? incomeCategories : allCategories).first
            // Сбросить поля источника/способа под режим
            if newValue {
                incomeSource = "Зарплата"
            } else {
                payment = "Карта"
            }
        }
    }

    // MARK: - Header

    private func header() -> some View {
        HStack {
            Text(isIncome ? "Доход" : "Траты")
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

    // MARK: - Mode Toggle (Расход / Доход)

    private func modeToggle() -> some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let thumbWidth = (totalWidth - 4) / 2
            ZStack(alignment: isIncome ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isIncome ? incomeGradient() : expenseGradient())
                    .frame(width: thumbWidth, height: 32)
                    .padding(4)
                    .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 3)

                HStack(spacing: 0) {
                    segmentLabel(title: "Расход", systemImage: "arrow.up.right.circle.fill", active: !isIncome)
                    segmentLabel(title: "Доход", systemImage: "arrow.down.left.circle.fill", active: isIncome)
                }
            }
            .frame(height: 40)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    isIncome.toggle()
                }
            }
        }
        .frame(height: 40)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Режим ввода")
        .accessibilityValue(isIncome ? "Доход" : "Расход")
    }

    private func segmentLabel(title: String, systemImage: String, active: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundColor(active ? .white : .secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                isIncome = (title == "Доход")
            }
        }
    }

    // MARK: - Amount Starter

    private func amountStarter() -> some View {
        Button {
            openDetailsWithFocus()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isIncome ? "plus.circle.fill" : "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(isIncome ? .green : .blue)
                Text(isIncome ? "Добавить доход" : "Добавить сумму")
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
        .accessibilityLabel(isIncome ? "Добавить доход" : "Добавить сумму")
    }

    private func openDetailsWithFocus() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            showDetails = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isAmountFocused = true
        }
    }

    // MARK: - Detail Card

    private func detailCard() -> some View {
        VStack(spacing: 12) {
            // Верхняя строка с хэндлом и крестиком
            HStack {
                Capsule()
                    .fill(Color.primary.opacity(0.15))
                    .frame(width: 40, height: 5)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityHidden(true)

                Button {
                    closeDetails()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 2)
                .accessibilityLabel("Закрыть")
            }

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

            // Дата и Источник/Способ
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
                    Text(isIncome ? "Источник" : "Способ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Menu {
                        if isIncome {
                            Button("Зарплата") { incomeSource = "Зарплата" }
                            Button("Бонус") { incomeSource = "Бонус" }
                            Button("Фриланс") { incomeSource = "Фриланс" }
                            Button("Инвест.") { incomeSource = "Инвест." }
                            Button("Другое") { incomeSource = "Другое" }
                        } else {
                            Button("Карта") { payment = "Карта" }
                            Button("Наличные") { payment = "Наличные" }
                            Button("Счёт") { payment = "Счёт" }
                        }
                    } label: {
                        HStack {
                            Image(systemName: isIncome ? "arrow.down.left.circle.fill" : paymentIcon())
                            Text(isIncome ? incomeSource : payment)
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
                TextField(isIncome ? "Например: зарплата, бонус…" : "Комментарий", text: $note)
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
                .background(isIncome ? incomeGradient() : expenseGradient())
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!canSave)
            .padding(.top, 2)

        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14 + bottomSafeInset())
        .padding(.top, 6)
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

    private func expenseGradient() -> LinearGradient {
        LinearGradient(
            colors: [Color.blue.opacity(0.95), Color.purple.opacity(0.95)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func incomeGradient() -> LinearGradient {
        LinearGradient(
            colors: [Color.green.opacity(0.95), Color.teal.opacity(0.95)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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

    private func bottomSafeInset() -> CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .safeAreaInsets.bottom ?? 0
    }

    // MARK: - Save

    private func save() {
        guard let amount = parseAmount(amountText), amount > 0 else { return }
        let signedAmount = isIncome ? abs(amount) : -abs(amount)
        let tx = Transaction(
            date: date,
            amount: signedAmount,
            categoryKey: selectedCategory?.key,
            note: note.isEmpty ? nil : note,
            payment: isIncome ? (incomeSource.isEmpty ? nil : incomeSource) : (payment.isEmpty ? nil : payment)
        )
        store.add(tx)

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Сброс и возврат к категориям
        amountText = ""
        note = ""
        if isIncome {
            incomeSource = "Зарплата"
        } else {
            payment = "Карта"
        }
        selectedCategory = currentCategories.first
        closeDetails()
    }
}

#Preview {
    NavigationStack {
        ExpenseEntryView()
            .environmentObject(TransactionStore(seedDemoData: true))
    }
}
