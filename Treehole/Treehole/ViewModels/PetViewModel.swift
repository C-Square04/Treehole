import Foundation
import SwiftData
import Observation

@Observable
final class PetViewModel {
    var showFeedingAnimation: Bool = false

    func feed(pet: Pet) {
        guard pet.hungerLevel < 100 else { return }
        pet.feed()
        showFeedingAnimation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.showFeedingAnimation = false
        }
    }

    func updateHunger(pet: Pet) {
        pet.updateHunger()
    }

    func ensurePetExists(context: ModelContext, pets: [Pet]) -> Pet {
        if let existing = pets.first { return existing }
        let newPet = Pet(name: "Companion")
        context.insert(newPet)
        return newPet
    }
}
