import Foundation
import SwiftData

enum MaintenanceStatus: Int, Comparable {
    case overdue
    case dueSoon
    case upcoming

    static func < (lhs: MaintenanceStatus, rhs: MaintenanceStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

@Model
final class Vehicle {
    var id: UUID
    var year: Int
    var make: String
    var model: String
    var trim: String
    var nickname: String = ""
    var vin: String = ""
    var licensePlate: String = ""
    @Attribute(.externalStorage) var photoData: Data?
    var mileage: Int
    var estimatedValue: Double?
    var notes: String
    var createdAt: Date

    init(year: Int, make: String, model: String, trim: String = "", nickname: String = "",
         vin: String = "", licensePlate: String = "", mileage: Int = 0,
         estimatedValue: Double? = nil, notes: String = "", photoData: Data? = nil) {
        id = UUID()
        self.year = year
        self.make = make
        self.model = model
        self.trim = trim
        self.nickname = nickname
        self.vin = vin
        self.licensePlate = licensePlate
        self.photoData = photoData
        self.mileage = mileage
        self.estimatedValue = estimatedValue
        self.notes = notes
        createdAt = .now
    }

    var name: String { "\(year) \(make) \(model)" }
    var displayName: String { nickname.isEmpty ? name : nickname }
}

@Model
final class MaintenanceTask {
    var id: UUID
    var vehicleID: UUID
    var name: String
    var dueDate: Date?
    var dueMileage: Int?
    var intervalMonths: Int?
    var intervalMiles: Int?
    var lastServiceDate: Date?
    var lastServiceMileage: Int?

    init(vehicleID: UUID, name: String, dueDate: Date? = nil, dueMileage: Int? = nil, intervalMonths: Int? = nil, intervalMiles: Int? = nil) {
        id = UUID()
        self.vehicleID = vehicleID
        self.name = name
        self.dueDate = dueDate
        self.dueMileage = dueMileage
        self.intervalMonths = intervalMonths
        self.intervalMiles = intervalMiles
    }

    func isDue(currentMileage: Int, on date: Date = .now) -> Bool {
        status(currentMileage: currentMileage, on: date) == .overdue
    }

    func status(currentMileage: Int, on date: Date = .now) -> MaintenanceStatus {
        let startOfToday = Calendar.current.startOfDay(for: date)
        let dateIsOverdue = dueDate.map { $0 < startOfToday } ?? false
        let mileageIsOverdue = dueMileage.map { $0 <= currentMileage } ?? false
        if dateIsOverdue || mileageIsOverdue { return .overdue }

        let dueSoonDate = Calendar.current.date(byAdding: .day, value: 30, to: startOfToday) ?? date
        let dateIsSoon = dueDate.map { $0 <= dueSoonDate } ?? false
        let mileageIsSoon = dueMileage.map { $0 - currentMileage <= 1_000 } ?? false
        return dateIsSoon || mileageIsSoon ? .dueSoon : .upcoming
    }

    func complete(on date: Date, at mileage: Int) {
        lastServiceDate = date
        lastServiceMileage = mileage
        dueDate = intervalMonths.flatMap { Calendar.current.date(byAdding: .month, value: $0, to: date) }
        dueMileage = intervalMiles.map { mileage + $0 }
    }
}

@Model
final class ServiceRecord {
    var id: UUID
    var vehicleID: UUID
    var name: String
    var date: Date
    var mileage: Int
    var cost: Double?
    var notes: String

    init(vehicleID: UUID, name: String, date: Date, mileage: Int, cost: Double? = nil, notes: String = "") {
        id = UUID()
        self.vehicleID = vehicleID
        self.name = name
        self.date = date
        self.mileage = mileage
        self.cost = cost
        self.notes = notes
    }
}

@Model
final class MaintenanceReceipt {
    var id: UUID
    var serviceRecordID: UUID
    @Attribute(.externalStorage) var imageData: Data
    var createdAt: Date

    init(serviceRecordID: UUID, imageData: Data) {
        id = UUID()
        self.serviceRecordID = serviceRecordID
        self.imageData = imageData
        createdAt = .now
    }
}
