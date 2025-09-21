import Foundation

struct Transaction: Identifiable, Hashable, Codable {
    let id: UUID
    let date: Date
    let amount: Double
    let categoryKey: String?
    let note: String?
    let payment: String?

    init(id: UUID = UUID(),
         date: Date,
         amount: Double,
         categoryKey: String?,
         note: String? = nil,
         payment: String? = nil) {
        self.id = id
        self.date = date
        self.amount = amount
        self.categoryKey = categoryKey
        self.note = note
        self.payment = payment
    }
}

