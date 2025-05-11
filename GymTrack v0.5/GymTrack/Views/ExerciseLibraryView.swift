//
//  ExerciseLibraryView.swift
//  GymTrack
//
//  Created by 郝大力 on 4/10/25.
//

import SwiftUI

struct ExerciseLibraryView: View {
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var showingSidebar: Bool = false
    
    // Use ExerciseDefinition for the library
    let exerciseLibrary: [ExerciseCategory: [ExerciseDefinition]] = [
        .chest: [
            // Use ExerciseDefinition initializer
            ExerciseDefinition(name: "Bench Press", category: .chest, targetRM: 8, referenceWeight: 60.0),
            ExerciseDefinition(name: "Incline Bench Press", category: .chest, targetRM: 8, referenceWeight: 50.0),
            ExerciseDefinition(name: "Dumbbell Press", category: .chest, targetRM: 10, referenceWeight: 24.0),
            ExerciseDefinition(name: "Push-ups", category: .chest, targetRM: 12),
            ExerciseDefinition(name: "Cable Flyes", category: .chest, targetRM: 12, referenceWeight: 15.0)
        ],
        .back: [
            ExerciseDefinition(name: "Deadlift", category: .back, targetRM: 5, referenceWeight: 100.0),
            ExerciseDefinition(name: "Pull-ups", category: .back, targetRM: 8),
            ExerciseDefinition(name: "Barbell Row", category: .back, targetRM: 8, referenceWeight: 60.0),
            ExerciseDefinition(name: "Lat Pulldown", category: .back, targetRM: 10, referenceWeight: 50.0),
            ExerciseDefinition(name: "Face Pull", category: .back, targetRM: 15, referenceWeight: 20.0)
        ],
        .legs: [
            ExerciseDefinition(name: "Squat", category: .legs, targetRM: 5, referenceWeight: 100.0),
            ExerciseDefinition(name: "Romanian Deadlift", category: .legs, targetRM: 8, referenceWeight: 80.0),
            ExerciseDefinition(name: "Leg Press", category: .legs, targetRM: 10, referenceWeight: 120.0),
            ExerciseDefinition(name: "Lunges", category: .legs, targetRM: 12, referenceWeight: 40.0),
            ExerciseDefinition(name: "Calf Raises", category: .legs, targetRM: 15, referenceWeight: 60.0)
        ],
        .shoulders: [
            ExerciseDefinition(name: "Overhead Press", category: .shoulders, targetRM: 8, referenceWeight: 40.0),
            ExerciseDefinition(name: "Lateral Raises", category: .shoulders, targetRM: 12, referenceWeight: 10.0),
            ExerciseDefinition(name: "Front Raises", category: .shoulders, targetRM: 12, referenceWeight: 10.0),
            ExerciseDefinition(name: "Face Pulls", category: .shoulders, targetRM: 15, referenceWeight: 20.0)
        ],
        .arms: [
            ExerciseDefinition(name: "Bicep Curls", category: .arms, targetRM: 10, referenceWeight: 15.0),
            ExerciseDefinition(name: "Tricep Extensions", category: .arms, targetRM: 12, referenceWeight: 20.0),
            ExerciseDefinition(name: "Hammer Curls", category: .arms, targetRM: 10, referenceWeight: 12.0),
            ExerciseDefinition(name: "Skull Crushers", category: .arms, targetRM: 12, referenceWeight: 25.0)
        ],
        .core: [
            ExerciseDefinition(name: "Plank", category: .core, targetRM: 60), // Assuming targetRM here means seconds for Plank
            ExerciseDefinition(name: "Crunches", category: .core, targetRM: 15),
            ExerciseDefinition(name: "Russian Twists", category: .core, targetRM: 20),
            ExerciseDefinition(name: "Leg Raises", category: .core, targetRM: 15)
        ]
        // Add other categories if needed
    ]
    
    // Filtered exercises should be [ExerciseDefinition]
    var filteredExercises: [ExerciseDefinition] {
        let allExercises: [ExerciseDefinition]
        if let category = selectedCategory {
            allExercises = exerciseLibrary[category] ?? []
        } else {
            // Flatten all exercises if no category is selected
            allExercises = exerciseLibrary.values.flatMap { $0 }
        }
        
        if searchText.isEmpty {
            return allExercises
        }
        return allExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            // Use the filteredExercises which are [ExerciseDefinition]
            ForEach(filteredExercises) { exercise in // exercise is now ExerciseDefinition
                NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                    // ExerciseCategoryRow likely needs ExerciseDefinition too
                    ExerciseCategoryRow(exercise: exercise)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search exercises")
        .navigationTitle(selectedCategory?.rawValue ?? "All Exercises")
        .toolbar {
            // Toolbar for category selection (example)
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("All Categories") { selectedCategory = nil }
                    ForEach(ExerciseCategory.allCases, id: \.self) { category in
                        Button(category.rawValue) { selectedCategory = category }
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
}

/*
// CategoryDetailView might not be needed if filtering is done in main view
struct CategoryDetailView: View {
    let category: ExerciseCategory
    let exercises: [ExerciseDefinition] // Use ExerciseDefinition
    @State private var searchText = ""
    
    var filteredExercises: [ExerciseDefinition] { // Use ExerciseDefinition
        if searchText.isEmpty {
            return exercises
        }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            ForEach(filteredExercises) { exercise in // exercise is ExerciseDefinition
                NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                    ExerciseCategoryRow(exercise: exercise)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search \(category.rawValue) exercises")
        .navigationTitle(category.rawValue)
    }
}
*/

// Update ExerciseCategoryRow to accept ExerciseDefinition
struct ExerciseCategoryRow: View {
    let exercise: ExerciseDefinition // Use ExerciseDefinition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            
            HStack {
                // Display targetRM and referenceWeight if available
                if let targetRM = exercise.targetRM {
                    Label("\(targetRM)RM", systemImage: "repeat")
                }
                if let refWeight = exercise.referenceWeight, refWeight > 0 {
                    Text("•")
                    Label("\(refWeight, specifier: "%.1f")kg", systemImage: "scalemass")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView { // Wrap in NavigationView for preview
        ExerciseLibraryView()
    }
} 