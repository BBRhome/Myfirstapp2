//
//  MyfirstappApp.swift
//  Myfirstapp
//
//  Created by Алексей А on 21.09.2025.
//

import SwiftUI
#if os(iOS)
import PhotosUI
import UIKit
import AuthenticationServices
#endif

// MARK: - Helpers
func parseAmount(_ input: String) -> Double? {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    let normalized = trimmed
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: ",", with: ".")

    var hasDot = false
    var result = ""
    for (i, ch) in normalized.enumerated() {
        if ch.isNumber {
            result.append(ch)
        } else if ch == "." {
            if hasDot { continue }
            hasDot = true
            result.append(ch)
        } else if ch == "-" {
            if i == 0 { result.append(ch) }
        }
    }

    guard !result.isEmpty, result != "-", result != "." else { return nil }
    return Double(result)
}

func canSaveExpense(amountText: String, categoryKey: String?, isIncome: Bool) -> Bool {
    guard let amount = parseAmount(amountText), amount > 0 else { return false }
    guard let key = categoryKey, !key.isEmpty else { return false }
    return true
}

// MARK: - Model
struct Category: Identifiable, Hashable, Equatable {
    let id = UUID()
    let key: String
    let label: String
    let symbol: String
}

let allCategories: [Category] = [
    .init(key: "groceries", label: "Продукты", symbol: "cart"),
    .init(key: "food", label: "Кафе", symbol: "fork.knife"),
    .init(key: "transport", label: "Транспорт", symbol: "bus"),
    .init(key: "car", label: "Авто", symbol: "car"),
    .init(key: "home", label: "Дом", symbol: "house"),
    .init(key: "health", label: "Здоровье", symbol: "cross.case"),
    .init(key: "games", label: "Игры", symbol: "gamecontroller"),
    .init(key: "travel", label: "Путешествия", symbol: "airplane"),
    .init(key: "phone", label: "Связь", symbol: "phone"),
    .init(key: "savings", label: "Сбереж.", symbol: "banknote"),
    .init(key: "food2", label: "Кафе", symbol: "fork.knife"),
    .init(key: "transport2", label: "Транспорт", symbol: "bus"),
    .init(key: "home2", label: "Дом", symbol: "house"),
    .init(key: "games2", label: "Игры", symbol: "gamecontroller"),
    .init(key: "health2", label: "Здоровье", symbol: "cross.case"),
    .init(key: "car2", label: "Авто", symbol: "car"),
    .init(key: "groceries2", label: "Продукты", symbol: "cart"),
    .init(key: "phone2", label: "Связь", symbol: "phone"),
    .init(key: "travel2", label: "Путешествия", symbol: "airplane"),
    .init(key: "savings2", label: "Сбереж.", symbol: "banknote"),
    .init(key: "food3", label: "Кафе", symbol: "fork.knife"),
    .init(key: "transport3", label: "Транспорт", symbol: "bus")
]

let incomeCategories: [Category] = [
    .init(key: "salary", label: "Зарплата", symbol: "banknote"),
    .init(key: "bonus", label: "Бонус", symbol: "gift.fill"),
    .init(key: "freelance", label: "Фриланс", symbol: "laptopcomputer"),
    .init(key: "investment", label: "Инвестиции", symbol: "chart.line.uptrend.xyaxis"),
    .init(key: "other_income", label: "Другое", symbol: "circle.grid.2x2")
]

let categoriesByKey: [String: Category] = {
    let all = allCategories + incomeCategories
    return Dictionary(uniqueKeysWithValues: all.map { ($0.key, $0) })
}()

// MARK: - Bubble
struct CategoryBubble: View {
    let category: Category
    let isActive: Bool
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.black : Color(.systemGray5))
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(isActive ? 0.25 : 0.1), radius: isActive ? 8 : 4, x: 0, y: isActive ? 4 : 2)
                Image(systemName: category.symbol)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundColor(isActive ? .white : .primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(category.label))
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// MARK: - Honeycomb Grid
struct HoneycombGrid: View {
    let items: [Category]
    let selected: Category?
    let select: (Category) -> Void

    private let cols: Int = 6
    private let spacing: CGFloat = 14
    private let shift: CGFloat = 36

    var body: some View {
        GeometryReader { geo in
            let layout = computeLayout(size: geo.size)
            content(layout: layout)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func content(layout: (rows: [[Category]], small: CGFloat, big: CGFloat, totalHeight: CGFloat)) -> some View {
        VStack(spacing: spacing) {
            ForEach(0..<layout.rows.count, id: \.self) { ri in
                rowView(items: layout.rows[ri], rowIndex: ri, small: layout.small, big: layout.big)
            }
        }
        .frame(height: layout.totalHeight, alignment: .top)
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: selected?.key)
    }

    private func computeLayout(size: CGSize) -> (rows: [[Category]], small: CGFloat, big: CGFloat, totalHeight: CGFloat) {
        let availableWidth: CGFloat = max(size.width - 16, 320)
        let totalSpacing: CGFloat = CGFloat(cols - 1) * spacing
        let maxRowWidth: CGFloat = availableWidth - shift
        let idealSize: CGFloat = floor((maxRowWidth - totalSpacing) / CGFloat(cols))
        let small: CGFloat = min(max(idealSize, 40), 56)
        let big: CGFloat = min(max(idealSize * 1.2, 48), 68)
        let rows = self.rows
        let rowCount = rows.count
        let rowHeight: CGFloat = max(big, small) + spacing
        let totalHeight: CGFloat = CGFloat(rowCount) * rowHeight - spacing
        return (rows, small, big, totalHeight)
    }

    @ViewBuilder
    private func rowView(items: [Category], rowIndex: Int, small: CGFloat, big: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(0..<items.count, id: \.self) { ci in
                let idx: Int = rowIndex * cols + ci
                let item: Category = items[ci]
                let isBig: Bool = bigIndices.contains(idx)
                let size = isBig ? big : small
                CategoryBubble(category: item,
                               isActive: selected?.key == item.key,
                               size: size,
                               action: { select(item) })
            }
        }
        .padding(.leading, rowIndex % 2 == 1 ? shift : 0)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var rows: [[Category]] {
        stride(from: 0, to: items.count, by: cols).map { start in
            Array(items[start ..< min(start + cols, items.count)])
        }
    }

    private var bigIndices: Set<Int> { [7, 8, 13, 14] }
}

// MARK: - Профиль (переведён на @AppStorage)
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("profile_name") private var name: String = "Алексей"
    @AppStorage("profile_email") private var email: String = "user@example.com"
    @AppStorage("profile_notifications") private var notificationsEnabled: Bool = true
    @AppStorage("profile_biometrics") private var biometricsEnabled: Bool = true
    @AppStorage("profile_currency") private var currency: String = "RUB"
    @AppStorage("profile_analytics") private var analyticsEnabled: Bool = true

    @EnvironmentObject private var auth: AuthManager

    var body: some View {
        NavigationStack {
            List {
                Section("Аккаунт") {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.blue.opacity(0.15)).frame(width: 44, height: 44)
                            Image(systemName: "person.fill").foregroundStyle(.blue)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name).font(.headline)
                            Text(email).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    NavigationLink {
                        Form {
                            TextField("Имя", text: $name)
                                .textInputAutocapitalization(.words)
                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                        }
                        .navigationTitle("Профиль")
                    } label: {
                        Label("Редактировать профиль", systemImage: "пїЅ")
                    }

                    if auth.isAuthenticated {
                        Button(role: .destructive) {
                            auth.signOut()
                        } label: {
                            Label("Выйти из аккаунта", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }

                Section("Безопасность") {
                    Toggle(isOn: $biometricsEnabled) {
                        Label("Face ID / Touch ID", systemImage: "faceid")
                    }
                    NavigationLink {
                        Form {
                            SecureField("Текущий пароль", text: .constant(""))
                            SecureField("Новый пароль", text: .constant(""))
                            SecureField("Повторите пароль", text: .constant(""))
                            Button("Сохранить") { /* change password locally */ }
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .navigationTitle("Смена пароля")
                    } label: {
                        Label("Сменить пароль", systemImage: "key.fill")
                    }
                }

                Section("Уведомления") {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Включить уведомления", systemImage: "bell.badge.fill")
                    }
                }

                Section("Предпочтения") {
                    Picker(selection: $currency) {
                        Text("RUB ₽").tag("RUB")
                        Text("USD $").tag("USD")
                        Text("EUR €").tag("EUR")
                    } label: {
                        Label("Валюта", systemImage: "rublesign.circle")
                    }
                    Toggle(isOn: $analyticsEnabled) {
                        Label("Аналитика использования", systemImage: "chart.bar.fill")
                    }
                }

                Section("О приложении") {
                    HStack {
                        Label("Версия", systemImage: "info.circle.fill")
                        Spacer()
                        Text(appVersionString).foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Разработчик", systemImage: "person.crop.square.fill")
                        Spacer()
                        Text("Алексей А").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Профиль")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private var appVersionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

// MARK: - Экран входа (красивый стартовый экран без Sign in with Apple)
struct SignInView: View {
    @EnvironmentObject private var auth: AuthManager

    var body: some View {
        ZStack {
            // Фон: "hero" из ассетов или градиент
            if UIImage(named: "hero") != nil {
                Image("hero")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.12, blue: 0.30),
                        Color(red: 0.17, green: 0.45, blue: 0.92),
                        Color(red: 0.95, green: 0.67, blue: 0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }

            // Вуаль
            LinearGradient(
                colors: [Color.black.opacity(0.05), Color.black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Логотип
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 84, height: 84)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                    Image(systemName: "creditcard.and.123")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                }
                .padding(.bottom, 8)

                VStack(spacing: 8) {
                    Text("Добро пожаловать")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .shadow(radius: 6)

                    Text("Следите за расходами, балансом и кэшбэком. Войдите, чтобы продолжить.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 24)
                }

                Spacer()

                // Две простые кнопки без Sign in with Apple
                VStack(spacing: 12) {
                    Button {
                        // Простая локальная "авторизация"
                        auth.continueWithoutSignIn()
                    } label: {
                        Text("Войти")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.9))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 24)

                    Button {
                        auth.continueWithoutSignIn()
                    } label: {
                        Text("Продолжить без входа")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.18))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 24)
                }

                // Необязательная подпись
                Text("Ваши данные хранятся локально на устройстве.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.bottom, 28)
            }
        }
        .statusBarHidden(true)
    }
}

// MARK: - Корневой контейнер
struct RootView: View {
    @StateObject private var store = TransactionStore(seedDemoData: false)
    @StateObject private var auth = AuthManager()
    @AppStorage("firstCleanDone") private var firstCleanDone: Bool = false

    var body: some View {
        Group {
            if auth.isAuthenticated {
                TabView {
                    NavigationStack {
                        ExpenseEntryView()
                    }
                    .environmentObject(store)
                    .tabItem { Label("Траты", systemImage: "creditcard") }

                    NavigationStack {
                        BalanceView()
                    }
                    .environmentObject(store)
                    .tabItem { Label("Баланс", systemImage: "chart.pie.fill") }

                    NavigationStack {
                        CashbackView()
                    }
                    .tabItem { Label("Кэшбэк", systemImage: "giftcard.fill") }

                    NavigationStack {
                        ProfileView()
                    }
                    .environmentObject(auth)
                    .tabItem { Label("Профиль", systemImage: "person.crop.circle") }
                }
                .environmentObject(auth)
            } else {
                SignInView()
                    .environmentObject(auth)
            }
        }
        .onAppear {
            // Один раз очищаем, чтобы начать с нуля
            if !firstCleanDone {
                store.reset()
                firstCleanDone = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    RootView()
}

@main
struct MyfirstappApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
