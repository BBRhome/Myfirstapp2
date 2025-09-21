import SwiftUI

struct CashbackView: View {
    var body: some View {
        ZStack {
            backgroundGradient().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerCard()

                    VStack(alignment: .leading, spacing: 12) {
                        infoRow(icon: "percent", title: "Категории месяца", subtitle: "Повышенный кэшбэк на выбранные категории.")
                        infoRow(icon: "giftcard.fill", title: "Бонусы", subtitle: "Собирайте баллы и обменивайте на скидки.")
                        infoRow(icon: "creditcard.and.123", title: "Условия", subtitle: "Кэшбэк начисляется на безналичные покупки.")
                    }
                    .padding(16)
                    .background(cardBackground())
                    .overlay(cardStroke())
                    .clipShape(cardShape())

                    VStack(spacing: 10) {
                        Text("Раздел в разработке")
                            .font(.headline)
                        Text("Здесь появится информация о категориях и процентах.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(cardBackground())
                    .overlay(cardStroke())
                    .clipShape(cardShape())
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Кэшбэк")
    }

    private func headerCard() -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.pink.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: "giftcard.fill")
                    .foregroundColor(.pink)
                    .font(.title2)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Кэшбэк")
                    .font(.title3.weight(.bold))
                Text("Возвращайте часть потраченного")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            Spacer()
        }
        .padding(16)
        .background(cardBackground())
        .overlay(cardStroke())
        .clipShape(cardShape())
    }

    private func infoRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(.blue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
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
        CashbackView()
    }
}
