import SwiftUI

struct ExerciseLoggingView: View {
    let sessionId: UUID // Passed in
    let exercise: ExerciseDefinition // Passed in
    
    // Get ViewModel from Environment
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    
    @State private var showingTimer = false

    // Fetch sets directly from ViewModel based on passed IDs
    private var sets: [PerformedSet] {
        workoutViewModel.setsForExercise(exercise.id, inSession: sessionId)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name)
                        .font(.title2)
                        .bold()
                    Label(exercise.category.rawValue, systemImage: exercise.category.systemImage)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section("Reference") {
                HStack {
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
            
            Section {
                // Iterate over the fetched sets
                ForEach(sets) { set in
                    // Use a non-binding editor, maybe pass update/delete closures? 
                    // Or, simpler: Have editor call VM methods on save/delete.
                    // For now, using WorkoutSetEditor which uses @Binding internally,
                    // but we need to make WorkoutSetEditor call VM methods on save.
                    // This requires refactoring WorkoutSetEditor.
                    // TEMPORARY: Keep using WorkoutSetEditor but it won't save correctly yet.
                    WorkoutSetEditor(set: temporaryBinding(for: set))
                }
                .onDelete(perform: deleteSetAction)
                
                Button {
                    // Call ViewModel to add a set
                    workoutViewModel.addSet(exerciseId: exercise.id, to: sessionId)
                } label: {
                    Label("Add Set", systemImage: "plus")
                }
            } header: {
                Text("Sets")
            } footer: {
                if let restInterval = exercise.restInterval {
                    Button(action: { showingTimer = true }) {
                        Label("Start Rest Timer (\(Int(restInterval))s)", systemImage: "timer")
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingTimer) {
            if let interval = exercise.restInterval {
                RestTimerView(duration: interval) // Assuming RestTimerView exists
            }
        }
    }
    
    // Action for swipe-to-delete
    private func deleteSetAction(at offsets: IndexSet) {
        let idsToDelete = offsets.map { sets[$0].id }
        workoutViewModel.deleteSets(ids: idsToDelete, from: sessionId)
    }
    
    // --- TEMPORARY WORKAROUND FOR WorkoutSetEditor Binding --- 
    // This allows using the existing WorkoutSetEditor which expects a Binding<WorkoutSet>.
    // IMPORTANT: The 'set' part of this binding DOES NOT WORK correctly for saving.
    // WorkoutSetEditor needs refactoring to call `workoutViewModel.updateSet(modifiedSet)`
    private func temporaryBinding(for performedSet: PerformedSet) -> Binding<WorkoutSet> {
        // Create a temporary WorkoutSet (loss of some PerformedSet info)
        let workoutSet = WorkoutSet(
            id: performedSet.id,
            weight: performedSet.weight,
            targetReps: performedSet.reps, // Use completed reps as target? Needs review.
            completedReps: performedSet.reps,
            rpe: performedSet.rpe,
            notes: performedSet.notes
        )
        
        return Binding(
            get: { workoutSet }, // Always return the current value from PerformedSet
            set: { modifiedWorkoutSet in
                // This setter is the problem - it doesn't update the ViewModel correctly.
                // It tries to modify a temporary struct.
                print("Attempted to update set via temporary binding (needs WorkoutSetEditor refactor): \(modifiedWorkoutSet)")
                // Ideally, WorkoutSetEditor would call:
                // let updatedPerformedSet = PerformedSet(from: modifiedWorkoutSet, sessionId: sessionId, exerciseId: exercise.id, setOrder: ...) // Need order
                // workoutViewModel.updateSet(updatedPerformedSet)
            }
        )
    }
    // --- END TEMPORARY WORKAROUND --- 
}

// Preview needs adjustment - Provide EnvironmentObject
struct ExerciseLoggingView_Previews: PreviewProvider {
    // Use a real VM for preview state
    @StateObject static var previewWorkoutVM = WorkoutViewModel() 
    // Create mock session/exercise/sets for preview
    static let previewSessionId = UUID()
    static let previewExercise = ExerciseDefinition(name: "Preview Bench", category: .chest, targetRM: 8, referenceWeight: 60)
    // TODO: Add mock sets to previewWorkoutVM.sessionSets for this preview session/exercise
    
    static var previews: some View {
        NavigationView {
            ExerciseLoggingView(
                sessionId: previewSessionId,
                exercise: previewExercise
            )
            .environmentObject(previewWorkoutVM) // Inject VM
        }
    }
} 