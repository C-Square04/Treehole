//
//  PetViewModel.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import Foundation
import Combine

class PetViewModel: ObservableObject {
    @Published var petState: PetState
    @Published var decorations: [HomeDecoration] = []
    @Published var inventory: [InventoryItem] = []
    @Published var showFeedingAnimation: Bool = false

    private var updateTimer: Timer?

    init(petState: PetState = PetState(id: UUID().uuidString, createdAt: Date())) {
        self.petState = petState
        loadDecorations()
        startPeriodicUpdates()
    }

    deinit {
        stopPeriodicUpdates()
    }

    // MARK: - Pet Actions

    func feed() {
        guard petState.hungerLevel < 100 else { return }
        petState.feed()
        savePetState()
        showFeedingAnimation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showFeedingAnimation = false
        }
    }

    func pet() {
        petState.mood = .happy
        petState.energy = min(100, petState.energy + 5)
        savePetState()
        objectWillChange.send()
    }

    func rest() {
        petState.energy = min(100, petState.energy + 30)
        petState.mood = .neutral
        savePetState()
        objectWillChange.send()
    }

    func addExperience(_ amount: Int) {
        petState.addExperience(amount)
    }

    // MARK: - Decoration Management

    func loadDecorations() {
        // Sample decorations - in a real app, load from backend or database
        decorations = [
            HomeDecoration(
                id: "d1",
                name: "Wooden Chair",
                description: "A cozy wooden chair",
                category: HomeDecoration.DecorCategory.furniture,
                price: 50,
                rarity: HomeDecoration.Rarity.common,
                isObtainable: true,
                isPaid: false
            ),
            HomeDecoration(
                id: "d2",
                name: "Blue Rug",
                description: "A soft blue rug",
                category: HomeDecoration.DecorCategory.floor,
                price: 75,
                rarity: HomeDecoration.Rarity.uncommon,
                isObtainable: true,
                isPaid: false
            ),
            HomeDecoration(
                id: "d3",
                name: "Sunlight Background",
                description: "Bright sunlight streaming through windows",
                category: HomeDecoration.DecorCategory.background,
                price: 100,
                rarity: HomeDecoration.Rarity.rare,
                isObtainable: false,
                isPaid: true
            ),
        ]
    }

    func purchaseDecoration(_ decorationId: String, with economy: inout EconomyLedger) -> Bool {
        guard let decoration = decorations.first(where: { $0.id == decorationId }) else {
            return false
        }

        if economy.removeDecorToken(decoration.price) {
            petState.decorations.append(decorationId)
            savePetState()
            objectWillChange.send()
            return true
        }
        return false
    }

    func unlockSkin(_ skinId: String) {
        if !petState.unlockedSkins.contains(skinId) {
            petState.unlockedSkins.append(skinId)
            savePetState()
            objectWillChange.send()
        }
    }

    func changeHomeTheme(_ theme: PetState.HomeTheme) {
        petState.homeTheme = theme
        savePetState()
        objectWillChange.send()
    }

    // MARK: - Periodic Updates

    private func startPeriodicUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.petState.updateHunger()
            self?.objectWillChange.send()
        }
    }

    private func stopPeriodicUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    // MARK: - Persistence

    func savePetState() {
        if let encoded = try? JSONEncoder().encode(petState) {
            UserDefaults.standard.set(encoded, forKey: "petState")
        }
    }

    func loadPetState() {
        if let data = UserDefaults.standard.data(forKey: "petState"),
           let state = try? JSONDecoder().decode(PetState.self, from: data) {
            petState = state
        }
    }
}
