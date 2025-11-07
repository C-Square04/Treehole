//
//  PlantGardenView.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import SwiftUI

struct PlantGardenView: View {
    @ObservedObject var viewModel: PlantViewModel
    @ObservedObject var economyViewModel: EconomyViewModel
    @State private var selectedPlantId: String?
    @State private var showCreatePlant: Bool = false

    var selectedPlant: PlantState? {
        if let selectedId = selectedPlantId {
            return viewModel.plants.first { $0.id == selectedId }
        }
        return viewModel.plants.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.6, green: 0.9, blue: 0.6),
                        Color(red: 0.9, green: 0.95, blue: 0.85)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("My Garden")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("\(viewModel.totalPlants) plant\(viewModel.totalPlants != 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: { showCreatePlant = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.95))

                    if viewModel.plants.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("Plant something")
                                .font(.headline)
                            Text("Start your garden journey")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Button(action: { showCreatePlant = true }) {
                                Text("Create Plant")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                        }
                        .frame(maxHeight: .infinity)
                        .padding()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                // Main plant display
                                if let plant = selectedPlant {
                                    PlantDetailCardView(plant: plant)
                                        .padding()

                                    // Water button
                                    Button(action: {
                                        _ = viewModel.waterPlant(plant.id)
                                        economyViewModel.addFood(5)
                                    }) {
                                        HStack {
                                            Image(systemName: "drop.fill")
                                                .foregroundColor(.blue)
                                            Text("Water Plant")
                                            Spacer()
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                    .padding(.horizontal)
                                    .foregroundColor(.blue)
                                }

                                // Other plants list
                                if viewModel.plants.count > 1 {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Your Plants")
                                            .font(.headline)
                                            .padding(.horizontal)

                                        VStack(spacing: 8) {
                                            ForEach(viewModel.plants) { plant in
                                                PlantListItemView(
                                                    plant: plant,
                                                    isSelected: selectedPlantId == plant.id,
                                                    action: { selectedPlantId = plant.id }
                                                )
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreatePlant) {
                CreatePlantView(viewModel: viewModel, isPresented: $showCreatePlant)
            }
        }
    }
}

struct PlantDetailCardView: View {
    let plant: PlantState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.name)
                        .font(.headline)
                    Text(plant.species.emoji + " " + plant.species.description)
                        .font(.caption)
                }
                Spacer()
                Text(plant.growthStage.icon)
                    .font(.title2)
            }

            // Status bars
            VStack(spacing: 8) {
                StatusBar(label: "Hydration", value: plant.hydrationLevel, maxValue: 100, color: .blue)
                StatusBar(label: "Experience", value: plant.experience, maxValue: 100, color: .green)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stage")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(plant.growthStage.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Health")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(plant.hydrationStatus.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PlantListItemView: View {
    let plant: PlantState
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(plant.species.emoji)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(plant.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(plant.species.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color.white)
            .cornerRadius(8)
        }
        .foregroundColor(.primary)
    }
}

struct CreatePlantView: View {
    @ObservedObject var viewModel: PlantViewModel
    @Binding var isPresented: Bool
    @State private var plantName: String = "My Plant"
    @State private var selectedSpecies: PlantState.PlantSpecies = .sunflower

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.98, green: 0.95, blue: 0.97)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    HStack {
                        Text("Create Plant")
                            .font(.headline)
                        Spacer()
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.white)

                    ScrollView {
                        VStack(spacing: 16) {
                            // Name input
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Plant Name", systemImage: "pencil")
                                    .font(.headline)
                                TextField("My Plant", text: $plantName)
                                    .padding()
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)

                            // Species selector
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Choose Species", systemImage: "leaf.fill")
                                    .font(.headline)
                                VStack(spacing: 8) {
                                    ForEach(PlantState.PlantSpecies.allCases, id: \.self) { species in
                                        Button(action: { selectedSpecies = species }) {
                                            HStack {
                                                Text(species.emoji)
                                                    .font(.title2)
                                                VStack(alignment: .leading) {
                                                    Text(species.description)
                                                        .fontWeight(.semibold)
                                                }
                                                Spacer()
                                                if selectedSpecies == species {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.green)
                                                }
                                            }
                                            .padding()
                                            .background(selectedSpecies == species ? Color.green.opacity(0.1) : Color(UIColor.systemGray6))
                                            .cornerRadius(8)
                                        }
                                        .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)

                            Spacer()
                        }
                        .padding()
                    }

                    Button(action: {
                        viewModel.createPlant(species: selectedSpecies, name: plantName)
                        isPresented = false
                    }) {
                        Text("Create Plant")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    PlantGardenView(viewModel: PlantViewModel(), economyViewModel: EconomyViewModel())
}
