import Foundation
import Combine

final class TransactionStore: ObservableObject {
    @Published private(set) var transactions: [Transaction] = [] {
        didSet { persistDebounced() }
    }

    private let fileURL: URL
    private var saveWorkItem: DispatchWorkItem?

    init(seedDemoData: Bool = false) {
        self.fileURL = Self.makeFileURL()
        if loadFromDisk() == false, seedDemoData {
            seedRandomData()
            saveToDisk()
        }
    }

    func add(_ tx: Transaction) {
        transactions.append(tx)
        sortInPlace()
    }

    func addIncome(amount: Double, note: String? = nil, date: Date = .now) {
        let tx = Transaction(date: date, amount: abs(amount), categoryKey: nil, note: note, payment: nil)
        add(tx)
    }

    // MARK: - Persistence

    private static func makeFileURL() -> URL {
        let fm = FileManager.default
        let appSupport = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = appSupport ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        // Создадим подпапку для приложения
        let bundleID = Bundle.main.bundleIdentifier ?? "Myfirstapp"
        let folder = dir.appendingPathComponent(bundleID, isDirectory: true)
        if !fm.fileExists(atPath: folder.path) {
            try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder.appendingPathComponent("transactions.json")
    }

    private func persistDebounced() {
        // Дебаунс чтобы не писать на диск слишком часто
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.saveToDisk() }
        saveWorkItem = work
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    @discardableResult
    private func loadFromDisk() -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: fileURL.path) else { return false }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([Transaction].self, from: data)
            self.transactions = decoded
            sortInPlace()
            return true
        } catch {
            print("Load transactions error: \(error)")
            return false
        }
    }

    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(transactions)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Save transactions error: \(error)")
        }
    }

    // MARK: - Helpers

    private func sortInPlace() {
        transactions.sort { a, b in
            if a.date == b.date { return a.id.uuidString < b.id.uuidString }
            return a.date > b.date
        }
    }

    private func seedRandomData() {
        var rng = SystemRandomNumberGenerator()
        let categories = allCategories.filter { !$0.key.contains("2") && !$0.key.contains("3") }
        let start = Calendar.current.date(byAdding: .day, value: -120, to: Date())!
        var arr: [Transaction] = []
        for _ in 0..<120 {
            let dayOffset = Int.random(in: 0...120, using: &rng)
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: start)!
            if Bool.random(using: &rng) {
                let cat = categories.randomElement(using: &rng)!
                let amount = -Double(Int.random(in: 100...7000, using: &rng))
                arr.append(.init(date: date, amount: amount, categoryKey: cat.key, note: nil, payment: "Карта"))
            } else {
                let amount = Double(Int.random(in: 3000...40000, using: &rng))
                arr.append(.init(date: date, amount: amount, categoryKey: nil, note: "Зарплата", payment: nil))
            }
        }
        self.transactions = arr
        sortInPlace()
    }
}

