import SwiftUI
import SwiftData

struct VehicleFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let vehicle: Vehicle?
    @State private var year: String
    @State private var make: String
    @State private var model: String
    @State private var trim: String
    @State private var nickname: String
    @State private var vin: String
    @State private var licensePlate: String
    @State private var mileage: String
    @State private var value: String
    @State private var notes: String
    @State private var isLookingUpVIN = false
    @State private var vinLookupError: String?

    init(vehicle: Vehicle? = nil) {
        self.vehicle = vehicle
        _year = State(initialValue: vehicle.map { String($0.year) } ?? "")
        _make = State(initialValue: vehicle?.make ?? "")
        _model = State(initialValue: vehicle?.model ?? "")
        _trim = State(initialValue: vehicle?.trim ?? "")
        _nickname = State(initialValue: vehicle?.nickname ?? "")
        _vin = State(initialValue: vehicle?.vin ?? "")
        _licensePlate = State(initialValue: vehicle?.licensePlate ?? "")
        _mileage = State(initialValue: vehicle.map { String($0.mileage) } ?? "")
        _value = State(initialValue: vehicle?.estimatedValue.map { String($0) } ?? "")
        _notes = State(initialValue: vehicle?.notes ?? "")
    }

    private var valid: Bool {
        let currentYear = Calendar.current.component(.year, from: .now)
        guard let vehicleYear = Int(year), (1886...(currentYear + 2)).contains(vehicleYear),
              !make.trimmed.isEmpty, !model.trimmed.isEmpty,
              let odometer = Int(mileage), odometer >= 0 else { return false }
        return value.trimmed.isEmpty || (Double(value).map { $0 >= 0 } ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("17-character VIN", text: $vin)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .onChange(of: vin) { _, newValue in
                            vin = String(newValue.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(17))
                            vinLookupError = nil
                        }
                    Button {
                        Task { await lookupVIN() }
                    } label: {
                        if isLookingUpVIN {
                            Label("Looking Up VIN…", systemImage: "progress.indicator")
                        } else {
                            Label("Look Up VIN", systemImage: "magnifyingglass")
                        }
                    }
                    .disabled(vin.count != 17 || isLookingUpVIN)
                    if let vinLookupError {
                        Text(vinLookupError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("VIN")
                } footer: {
                    Text("VIN lookup uses the U.S. National Highway Traffic Safety Administration database. You can still enter or change every field manually.")
                }
                Section("Vehicle") {
                    TextField("Nickname (optional)", text: $nickname)
                    TextField("Year", text: $year).keyboardType(.numberPad)
                    TextField("Make", text: $make)
                    TextField("Model", text: $model)
                    TextField("Trim (optional)", text: $trim)
                    TextField("License plate (optional)", text: $licensePlate)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                Section("Tracking") {
                    TextField("Current mileage", text: $mileage).keyboardType(.numberPad)
                    TextField("Estimated value in USD (optional)", text: $value).keyboardType(.decimalPad)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(vehicle == nil ? "Add Vehicle" : "Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!valid) }
            }
        }
    }

    private func save() {
        guard valid, let vehicleYear = Int(year), let odometer = Int(mileage) else { return }
        if let vehicle {
            vehicle.year = vehicleYear
            vehicle.make = make.trimmed
            vehicle.model = model.trimmed
            vehicle.trim = trim.trimmed
            vehicle.nickname = nickname.trimmed
            vehicle.vin = vin
            vehicle.licensePlate = licensePlate.trimmed.uppercased()
            vehicle.mileage = odometer
            vehicle.estimatedValue = Double(value)
            vehicle.notes = notes.trimmed
        } else {
            context.insert(Vehicle(year: vehicleYear, make: make.trimmed, model: model.trimmed,
                                   trim: trim.trimmed, nickname: nickname.trimmed, vin: vin,
                                   licensePlate: licensePlate.trimmed.uppercased(), mileage: odometer,
                                   estimatedValue: Double(value), notes: notes.trimmed))
        }
        dismiss()
    }

    @MainActor
    private func lookupVIN() async {
        isLookingUpVIN = true
        vinLookupError = nil
        defer { isLookingUpVIN = false }

        do {
            let details = try await VINLookupService().decode(vin)
            if let decodedYear = details.year { year = String(decodedYear) }
            if !details.make.isEmpty { make = details.make.capitalized }
            if !details.model.isEmpty { model = details.model.capitalized }
            if !details.trim.isEmpty { trim = details.trim }
        } catch {
            vinLookupError = error.localizedDescription
        }
    }
}

struct MaintenanceFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let vehicle: Vehicle
    @State private var name = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date.now
    @State private var dueMileage = ""
    @State private var intervalMonths = ""
    @State private var intervalMiles = ""

    private var valid: Bool {
        !name.trimmed.isEmpty &&
        (dueMileage.trimmed.isEmpty || (Int(dueMileage).map { $0 >= 0 } ?? false)) &&
        (intervalMonths.trimmed.isEmpty || (Int(intervalMonths).map { $0 > 0 } ?? false)) &&
        (intervalMiles.trimmed.isEmpty || (Int(intervalMiles).map { $0 > 0 } ?? false))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") { TextField("For example, oil change", text: $name) }
                Section("Next due") {
                    Toggle("Use a due date", isOn: $hasDueDate)
                    if hasDueDate { DatePicker("Due date", selection: $dueDate, displayedComponents: .date) }
                    TextField("Due mileage (optional)", text: $dueMileage).keyboardType(.numberPad)
                }
                Section {
                    TextField("Repeat every N months (optional)", text: $intervalMonths).keyboardType(.numberPad)
                    TextField("Repeat every N miles (optional)", text: $intervalMiles).keyboardType(.numberPad)
                } footer: {
                    Text("When you log this task, its next due date or mileage is calculated from the service date and odometer.")
                }
            }
            .navigationTitle("Add Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        context.insert(MaintenanceTask(vehicleID: vehicle.id, name: name.trimmed,
                                                       dueDate: hasDueDate ? dueDate : nil,
                                                       dueMileage: Int(dueMileage),
                                                       intervalMonths: Int(intervalMonths),
                                                       intervalMiles: Int(intervalMiles)))
                        dismiss()
                    }
                    .disabled(!valid)
                }
            }
        }
    }
}

struct ServiceFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let vehicle: Vehicle
    let task: MaintenanceTask?
    @State private var name: String
    @State private var date = Date.now
    @State private var mileage: String
    @State private var cost = ""
    @State private var notes = ""

    init(vehicle: Vehicle, task: MaintenanceTask? = nil) {
        self.vehicle = vehicle
        self.task = task
        _name = State(initialValue: task?.name ?? "")
        _mileage = State(initialValue: String(vehicle.mileage))
    }

    private var valid: Bool {
        !name.trimmed.isEmpty && (Int(mileage).map { $0 >= 0 } ?? false) &&
        (cost.trimmed.isEmpty || (Double(cost).map { $0 >= 0 } ?? false))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Service") {
                    TextField("What was done?", text: $name)
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                    TextField("Odometer", text: $mileage).keyboardType(.numberPad)
                    TextField("Cost in USD (optional)", text: $cost).keyboardType(.decimalPad)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                }
                if task != nil {
                    Section {
                        Text("Saving this record updates the task's next due date and mileage.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(task == nil ? "Log Service" : "Complete Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!valid) }
            }
        }
    }

    private func save() {
        guard valid, let odometer = Int(mileage) else { return }
        context.insert(ServiceRecord(vehicleID: vehicle.id, name: name.trimmed, date: date,
                                     mileage: odometer, cost: Double(cost), notes: notes.trimmed))
        task?.complete(on: date, at: odometer)
        if odometer > vehicle.mileage { vehicle.mileage = odometer }
        dismiss()
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
