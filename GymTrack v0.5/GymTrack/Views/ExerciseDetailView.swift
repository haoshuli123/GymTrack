import SwiftUI
import Charts // Import Charts

struct ExerciseDetailView: View {
    // Use ExerciseDefinition
    let exercise: ExerciseDefinition
    // Use ExerciseStore to fetch history related to this definition
    @StateObject private var store = ExerciseStore.shared // Reintroduce store if needed for history
    @State private var history: [ExerciseHistory] = [] // Keep using ExerciseHistory for chart data
    
    // Removed @State private var sets: [WorkoutSet] - This view doesn't manage active sets
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Exercise Info using ExerciseDefinition
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name)
                        .font(.title)
                        .bold()
                    
                    Label(exercise.category.rawValue, systemImage: exercise.category.systemImage)
                        .foregroundColor(.secondary)
                    
                    if let notes = exercise.notes, !notes.isEmpty {
                        Text(notes)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        // Display targetRM and referenceWeight if they exist
                        if let targetRM = exercise.targetRM {
                             Label("\(targetRM)RM Target", systemImage: "repeat")
                        }
                        if let refWeight = exercise.referenceWeight, refWeight > 0 {
                            Text("•")
                            Label("\(refWeight, specifier: "%.1f")kg Ref", systemImage: "scalemass")
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(12)
                
                // History Chart Section
                Text("Training History")
                    .font(.title2)
                    .bold()
                    .padding(.bottom, -8) // Adjust spacing
                
                if history.isEmpty {
                    ContentUnavailableView(
                        "No Training History",
                        systemImage: "chart.line.downtrend.xyaxis",
                        description: Text("Complete workouts including this exercise to see history")
                    )
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
                } else {
                    // Use the ExerciseHistoryChart component created earlier
                    ExerciseHistoryChart(history: history)
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadExerciseHistory()
        }
    }
    
    private func loadExerciseHistory() {
        // Fetch history using ExerciseStore (assuming it's adapted for GRDB)
        // For now, we might need to adjust ExerciseStore or use mock data again
        // until ExerciseStore is fully refactored.
        // history = store.getHistory(for: exercise.id) // Ideal state with refactored ExerciseStore
        
        // Temporary: Use mock data for previewing the chart, similar to before
        // Remove this when ExerciseStore provides real data from GRDB
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || history.isEmpty {
             history = [
                 ExerciseHistory(
                     id: UUID(),
                     exerciseId: exercise.id,
                     date: Date().addingTimeInterval(-7*24*3600),
                     sets: [
                         .init(id: UUID(), weight: 60, reps: 8, rpe: 7),
                         .init(id: UUID(), weight: 60, reps: 8, rpe: 7),
                         .init(id: UUID(), weight: 60, reps: 8, rpe: 8)
                     ],
                     notes: nil
                 ),
                 ExerciseHistory(
                     id: UUID(),
                     exerciseId: exercise.id,
                     date: Date(),
                     sets: [
                         .init(id: UUID(), weight: 62.5, reps: 8, rpe: 7),
                         .init(id: UUID(), weight: 62.5, reps: 8, rpe: 8),
                         .init(id: UUID(), weight: 62.5, reps: 8, rpe: 8)
                     ],
                     notes: "Feeling stronger today"
                 )
             ]
         }
        #endif
    }
}

// Preview needs ExerciseDefinition
#Preview {
    NavigationView {
        ExerciseDetailView(
            exercise: ExerciseDefinition( // Use ExerciseDefinition
                id: UUID(),
                name: "Barbell Bench Press",
                category: .chest,
                targetRM: 8,
                referenceWeight: 60.0,
                notes: "A compound exercise that primarily targets the chest muscles.",
                restInterval: 90
            )
        )
    }
} 