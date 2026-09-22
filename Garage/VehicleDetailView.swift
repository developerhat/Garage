import SwiftUI
import SwiftData

struct VehicleDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allTasks: [MaintenanceTask]
    @Query private var allRecords: [ServiceRecord]
    let vehicle: Vehicle
    @State private var showingEditVehicle = false
    @State private var showingAddTask = false
    @State private var showingAddRecord = false
    @State private var taskToComplete: MaintenanceTask?
    @State private var showingDeleteConfirmation = false

    private var tasks: [MaintenanceTask] {
        allTasks.filter { $0.vehicleID == vehicle.id }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private var records: [ServiceRecord] {
        allRecords.filter { $0.vehicleID == vehicle.id }.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section("Vehicle") {
                LabeledContent("Odometer", value: "\(vehicle.mileage.formatted()) mi")
                if let value = vehicle.estimatedValue {
                    LabeledContent("Estimated value", value: value.formatted(.currency(code: "USD")))
                }
                if !vehicle.trim.isEmpty { LabeledContent("Trim", value: vehicle.trim) }
                if !vehicle.notes.isEmpty { Text(vehicle.notes).foregroundStyle(.secondary) }
                Button("Edit Vehicle") { showingEditVehicle = true }
            }

            Section {
                if tasks.isEmpty { Text("No maintenance scheduled").foregroundStyle(.secondary) }
                ForEach(tasks) { task in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: task.isDue(currentMileage: vehicle.mileage) ? "exclamationmark.circle.fill" : "clock")
                            .foregroundStyle(task.isDue(currentMileage: vehicle.mileage) ? .orange : .secondary)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(task.name).font(.headline)
                            if task.dueDate == nil && task.dueMileage == nil {
                                Text("No next interval set").foregroundStyle(.secondary)
                            }
                            if let date = task.dueDate {
                                Text("Due \(date.formatted(date: .abbreviated, time: .omitted))").foregroundStyle(.secondary)
                            }
                            if let miles = task.dueMileage {
                                Text("Due at \(miles.formatted()) mi").foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline)
                        Spacer()
                        Button("Log") { taskToComplete = task }.buttonStyle(.bordered)
                    }
                    .padding(.vertical, 3)
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(tasks[index]) }
                }
                Button("Add Maintenance", systemImage: "plus") { showingAddTask = true }
            } header: {
                Text("Maintenance")
            } footer: {
                Text("A task is due when its date or mileage target is reached. Swipe a task to delete it.")
            }

            Section("Service History") {
                if records.isEmpty { Text("No service recorded yet").foregroundStyle(.secondary) }
                ForEach(records) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(record.name).font(.headline)
                            Spacer()
                            if let cost = record.cost {
                                Text(cost.formatted(.currency(code: "USD"))).foregroundStyle(.secondary)
                            }
                        }
                        Text("\(record.date.formatted(date: .abbreviated, time: .omitted)) · \(record.mileage.formatted()) mi")
                            .font(.subheadline).foregroundStyle(.secondary)
                        if !record.notes.isEmpty { Text(record.notes).font(.subheadline) }
                    }
                    .padding(.vertical, 3)
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(records[index]) }
                }
                Button("Log Service", systemImage: "plus") { showingAddRecord = true }
            }

            Section {
                Button("Delete Vehicle", role: .destructive) { showingDeleteConfirmation = true }
            }
        }
        .navigationTitle(vehicle.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditVehicle) { VehicleFormView(vehicle: vehicle) }
        .sheet(isPresented: $showingAddTask) { MaintenanceFormView(vehicle: vehicle) }
        .sheet(isPresented: $showingAddRecord) { ServiceFormView(vehicle: vehicle) }
        .sheet(item: $taskToComplete) { task in ServiceFormView(vehicle: vehicle, task: task) }
        .confirmationDialog("Delete \(vehicle.name)?", isPresented: $showingDeleteConfirmation) {
            Button("Delete Vehicle and Its Records", role: .destructive) {
                for task in tasks { context.delete(task) }
                for record in records { context.delete(record) }
                context.delete(vehicle)
                dismiss()
            }
        } message: {
            Text("This also deletes its maintenance schedule and service history.")
        }
    }
}
