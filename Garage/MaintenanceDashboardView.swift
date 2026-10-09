import SwiftUI
import SwiftData
import UIKit

struct MaintenanceDashboardView: View {
    @Query(sort: \Vehicle.createdAt) private var vehicles: [Vehicle]
    @Query private var tasks: [MaintenanceTask]
    @Query(sort: \ServiceRecord.date, order: .reverse) private var records: [ServiceRecord]
    @State private var logSheet: MaintenanceLogSheet?
    @State private var choosingVehicle = false

    private var scheduledMaintenance: [ScheduledMaintenance] {
        let vehiclesByID = Dictionary(uniqueKeysWithValues: vehicles.map { ($0.id, $0) })
        return tasks.compactMap { task in
            guard let vehicle = vehiclesByID[task.vehicleID] else { return nil }
            return ScheduledMaintenance(task: task, vehicle: vehicle)
        }
        .sorted {
            if $0.status != $1.status { return $0.status < $1.status }
            return $0.task.name.localizedStandardCompare($1.task.name) == .orderedAscending
        }
    }

    private var overdue: [ScheduledMaintenance] {
        scheduledMaintenance.filter { $0.status == .overdue }
    }

    private var dueSoon: [ScheduledMaintenance] {
        scheduledMaintenance.filter { $0.status == .dueSoon }
    }

    private var upcoming: [ScheduledMaintenance] {
        scheduledMaintenance.filter { $0.status == .upcoming }
    }

    private var totalSpent: Double {
        records.compactMap(\.cost).reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            Group {
                if vehicles.isEmpty {
                    ContentUnavailableView {
                        Label("No vehicles yet", systemImage: "wrench.and.screwdriver")
                    } description: {
                        Text("Add a vehicle in Garage before logging maintenance.")
                    }
                } else {
                    List {
                        Section {
                            HStack(spacing: 0) {
                                MaintenanceMetric(value: overdue.count, label: "Overdue", color: .red)
                                Divider()
                                MaintenanceMetric(value: dueSoon.count, label: "Due Soon", color: .orange)
                                Divider()
                                MaintenanceMetric(value: records.count, label: "Records", color: .blue)
                            }
                            .frame(height: 58)

                            if !records.isEmpty {
                                LabeledContent("Recorded spending", value: totalSpent.formatted(.currency(code: "USD")))
                            }
                        }

                        maintenanceSection("Overdue", items: overdue, color: .red)
                        maintenanceSection("Due Soon", items: dueSoon, color: .orange)
                        maintenanceSection("Upcoming", items: upcoming, color: .secondary)

                        Section("Maintenance History") {
                            if records.isEmpty {
                                Text("No maintenance recorded yet")
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(records) { record in
                                if let vehicle = vehicle(for: record.vehicleID) {
                                    NavigationLink {
                                        ServiceRecordDetailView(record: record, vehicle: vehicle)
                                    } label: {
                                        ServiceRecordRow(record: record, vehicle: vehicle)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Maintenance")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Log Maintenance", systemImage: "plus") { beginLoggingMaintenance() }
                        .disabled(vehicles.isEmpty)
                }
            }
            .confirmationDialog("Choose a Vehicle", isPresented: $choosingVehicle) {
                ForEach(vehicles) { vehicle in
                    Button(vehicle.displayName) {
                        logSheet = MaintenanceLogSheet(vehicle: vehicle)
                    }
                }
            }
            .sheet(item: $logSheet) { target in
                ServiceFormView(vehicle: target.vehicle, task: target.task)
            }
        }
    }

    @ViewBuilder
    private func maintenanceSection(_ title: String, items: [ScheduledMaintenance], color: Color) -> some View {
        if !items.isEmpty {
            Section(title) {
                ForEach(items) { item in
                    ScheduledMaintenanceRow(item: item, color: color) {
                        logSheet = MaintenanceLogSheet(vehicle: item.vehicle, task: item.task)
                    }
                }
            }
        }
    }

    private func vehicle(for id: UUID) -> Vehicle? {
        vehicles.first { $0.id == id }
    }

    private func beginLoggingMaintenance() {
        if vehicles.count == 1, let vehicle = vehicles.first {
            logSheet = MaintenanceLogSheet(vehicle: vehicle)
        } else {
            choosingVehicle = true
        }
    }
}

private struct MaintenanceMetric: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(value.formatted())
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct ScheduledMaintenanceRow: View {
    let item: ScheduledMaintenance
    let color: Color
    let log: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.status == .overdue ? "exclamationmark.circle.fill" : "clock.fill")
                .foregroundStyle(color)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.task.name).font(.headline)
                Text(item.vehicle.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let dueText = item.dueText {
                    Text(dueText)
                        .font(.caption)
                        .foregroundStyle(color)
                }
            }
            Spacer()
            Button("Log", action: log)
                .buttonStyle(.bordered)
        }
        .padding(.vertical, 3)
    }
}

private struct ServiceRecordRow: View {
    let record: ServiceRecord
    let vehicle: Vehicle

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(record.name).font(.headline)
                Spacer()
                if let cost = record.cost {
                    Text(cost.formatted(.currency(code: "USD")))
                        .foregroundStyle(.secondary)
                }
            }
            Text(vehicle.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(record.date.formatted(date: .abbreviated, time: .omitted)) · \(record.mileage.formatted()) mi")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }
}

struct ServiceRecordDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allReceipts: [MaintenanceReceipt]
    let record: ServiceRecord
    let vehicle: Vehicle
    @State private var confirmingDelete = false

    private var receipts: [MaintenanceReceipt] {
        allReceipts.filter { $0.serviceRecordID == record.id }.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        List {
            Section("Maintenance") {
                LabeledContent("Vehicle", value: vehicle.displayName)
                LabeledContent("Date", value: record.date.formatted(date: .long, time: .omitted))
                LabeledContent("Mileage", value: "\(record.mileage.formatted()) mi")
                if let cost = record.cost {
                    LabeledContent("Cost", value: cost.formatted(.currency(code: "USD")))
                }
            }

            if !record.notes.isEmpty {
                Section("Notes") { Text(record.notes) }
            }

            if !receipts.isEmpty {
                Section("Receipts") {
                    ForEach(receipts) { receipt in
                        if let image = UIImage(data: receipt.imageData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .accessibilityLabel("Receipt for \(record.name)")
                        }
                    }
                }
            }

            Section {
                Button("Delete Maintenance Record", role: .destructive) { confirmingDelete = true }
            }
        }
        .navigationTitle(record.name)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this maintenance record?", isPresented: $confirmingDelete) {
            Button("Delete Record", role: .destructive) {
                for receipt in receipts { context.delete(receipt) }
                context.delete(record)
                dismiss()
            }
        } message: {
            Text("Its receipt images will also be deleted.")
        }
    }
}

private struct ScheduledMaintenance: Identifiable {
    let task: MaintenanceTask
    let vehicle: Vehicle

    var id: UUID { task.id }
    var status: MaintenanceStatus { task.status(currentMileage: vehicle.mileage) }

    var dueText: String? {
        var parts: [String] = []
        if let date = task.dueDate {
            parts.append("\(status == .overdue ? "Was due" : "Due") \(date.formatted(date: .abbreviated, time: .omitted))")
        }
        if let mileage = task.dueMileage {
            parts.append("\(status == .overdue ? "due" : "at") \(mileage.formatted()) mi")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

private struct MaintenanceLogSheet: Identifiable {
    let id = UUID()
    let vehicle: Vehicle
    let task: MaintenanceTask?

    init(vehicle: Vehicle, task: MaintenanceTask? = nil) {
        self.vehicle = vehicle
        self.task = task
    }
}
