import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Vehicle.createdAt, order: .reverse) private var vehicles: [Vehicle]
    @Query private var tasks: [MaintenanceTask]
    @State private var showingAddVehicle = false

    var body: some View {
        NavigationStack {
            Group {
                if vehicles.isEmpty {
                    ContentUnavailableView {
                        Label("Your garage is empty", systemImage: "car.side")
                    } description: {
                        Text("Add a vehicle to track its mileage, maintenance, and value.")
                    } actions: {
                        Button("Add Vehicle") { showingAddVehicle = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List(vehicles) { vehicle in
                        NavigationLink {
                            VehicleDetailView(vehicle: vehicle)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "car.side.fill")
                                    .font(.title2)
                                    .foregroundStyle(.tint)
                                    .frame(width: 44, height: 44)
                                    .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(vehicle.displayName).font(.headline)
                                    if !vehicle.nickname.isEmpty {
                                        Text(vehicle.name)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Text("\(vehicle.mileage.formatted()) mi")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer()
                                let dueCount = tasks.filter { $0.vehicleID == vehicle.id && $0.isDue(currentMileage: vehicle.mileage) }.count
                                if dueCount > 0 {
                                    Text("\(dueCount) due")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.orange)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Garage")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Vehicle", systemImage: "plus") { showingAddVehicle = true }
                }
            }
            .sheet(isPresented: $showingAddVehicle) { VehicleFormView() }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Vehicle.self, MaintenanceTask.self, ServiceRecord.self], inMemory: true)
}
