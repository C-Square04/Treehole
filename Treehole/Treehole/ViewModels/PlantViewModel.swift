//
//  PlantViewModel.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import Foundation
import Combine

class PlantViewModel: ObservableObject {
    @Published var plants: [PlantState] = []
    @Published var selectedPlantId: String?

    private var updateTimer: Timer?

    init() {
        loadPlants()
        if plants.isEmpty {
            createDefaultPlant()
        }
        startPeriodicUpdates()
    }

    deinit {
        stopPeriodicUpdates()
    }

    // MARK: - Plant Management

    func createDefaultPlant() {
        let plant = PlantState(
            id: UUID().uuidString,
            name: "My Plant",
            species: .sunflower,
            growthStage: .seed,
            lastWateredAt: Date(),
            createdAt: Date()
        )
        plants.append(plant)
        savePlants()
    }

    func createPlant(species: PlantState.PlantSpecies, name: String) {
        let plant = PlantState(
            id: UUID().uuidString,
            name: name,
            species: species,
            growthStage: .seed,
            createdAt: Date()
        )
        plants.append(plant)
        savePlants()
    }

    func deletePlant(_ plantId: String) {
        plants.removeAll { $0.id == plantId }
        if selectedPlantId == plantId {
            selectedPlantId = plants.first?.id
        }
        savePlants()
    }

    func selectedPlant() -> PlantState? {
        guard let selectedPlantId = selectedPlantId else { return plants.first }
        return plants.first { $0.id == selectedPlantId }
    }

    // MARK: - Plant Actions

    func waterPlant(_ plantId: String) -> Bool {
        guard let index = plants.firstIndex(where: { $0.id == plantId }) else {
            return false
        }
        // Copy struct, mutate copy, then reassign to trigger @Published
        var plant = plants[index]
        plant.water()
        plants[index] = plant
        savePlants()
        // Trigger change notification for SwiftUI to update views
        objectWillChange.send()
        return true
    }

    func addExperienceTo(_ plantId: String, amount: Int) {
        guard let index = plants.firstIndex(where: { $0.id == plantId }) else {
            return
        }
        plants[index].experience += amount
        savePlants()
        objectWillChange.send()
    }

    func waterSelectedPlant() -> Bool {
        guard let selectedId = selectedPlantId else { return false }
        return waterPlant(selectedId)
    }

    // MARK: - Decoration Management

    func addDecoration(_ decorationId: String, to plantId: String) {
        guard let index = plants.firstIndex(where: { $0.id == plantId }) else {
            return
        }
        if !plants[index].decorations.contains(decorationId) {
            plants[index].decorations.append(decorationId)
            savePlants()
            objectWillChange.send()
        }
    }

    // MARK: - Periodic Updates

    private func startPeriodicUpdates() {
        stopPeriodicUpdates() // Stop any existing timer first
        updateTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.updateAllPlants()
        }
    }

    private func stopPeriodicUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func updateAllPlants() {
        for i in 0..<plants.count {
            plants[i].updateHydration()
        }
        savePlants()
        objectWillChange.send()
    }

    // MARK: - Statistics

    var totalPlants: Int {
        plants.count
    }

    var averageHydration: Int {
        guard !plants.isEmpty else { return 100 }
        let totalHydration = plants.reduce(0) { $0 + $1.hydrationLevel }
        return totalHydration / plants.count
    }

    var bloomingPlants: [PlantState] {
        plants.filter { $0.growthStage == .blooming }
    }

    // MARK: - Persistence

    func savePlants() {
        do {
            let encoded = try JSONEncoder().encode(plants)
            UserDefaults.standard.set(encoded, forKey: "plantStates")
        } catch {
            print("ERROR: Failed to encode plants: \(error)")
        }
    }

    func loadPlants() {
        if let data = UserDefaults.standard.data(forKey: "plantStates") {
            do {
                let loaded = try JSONDecoder().decode([PlantState].self, from: data)
                plants = loaded
            } catch {
                print("ERROR: Failed to decode plants: \(error)")
            }
        }
    }
}
