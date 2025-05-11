//
//  WorkoutView.swift
//  GymTrack
//
//  Created by 郝大力 on 4/10/25.
//

import SwiftUI

struct WorkoutView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @StateObject private var templateViewModel = WorkoutTemplateViewModel()
    
    @State private var showingWorkoutOptions = false
    @State private var showingTemplateSelection = false
    @State private var showingCustomWorkout = false
    
    @State private var navigateToSessionId: UUID? = nil
    @State private var isNavigationActive = false
    
    var body: some View {
        NavigationView {
            VStack {
                 // NavigationLink remains here, outside ScrollView/List
                 if let sessionId = navigateToSessionId {
                     NavigationLink(destination: StartWorkoutView(sessionId: sessionId)
                                         .environmentObject(viewModel), // Inject VM
                                    isActive: $isNavigationActive) {
                          EmptyView()
                      }
                      .hidden()
                 }
                
                // Use the extracted list view
                workoutListView 
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingWorkoutOptions = true }) {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
            }
            .confirmationDialog(
                "Choose Workout Type",
                isPresented: $showingWorkoutOptions,
                titleVisibility: .visible
            ) {
                Button("Use Template") {
                    showingTemplateSelection = true
                }
                Button("Custom Workout") {
                    showingCustomWorkout = true
                }
            }
            .sheet(isPresented: $showingTemplateSelection) {
                // TemplateSelectionView now calls startWorkoutFromTemplate
                TemplateSelectionView(didSelectTemplate: { templateWithExercises in
                    showingTemplateSelection = false // Dismiss sheet first
                    // Call ViewModel to start workout, get ID
                    if let sessionId = viewModel.startWorkoutFromTemplate(
                        template: templateWithExercises.template,
                        exercises: templateWithExercises.exercises
                    ) {
                        // Set the ID to trigger navigation
                        navigateToSessionId = sessionId
                        isNavigationActive = true // Activate the NavigationLink
                    } else {
                        // Handle error (e.g., show alert)
                        print("Error starting workout from template")
                    }
                }, templateViewModel: templateViewModel)
            }
            .sheet(isPresented: $showingCustomWorkout) {
                // CustomWorkoutSetupView now calls startCustomWorkout
                CustomWorkoutSetupView(didStartWorkout: { title, exercises in
                    showingCustomWorkout = false // Dismiss sheet first
                    // Call ViewModel to start workout, get ID
                    if let sessionId = viewModel.startCustomWorkout(
                        title: title,
                        exercises: exercises
                    ) {
                        // Set the ID to trigger navigation
                        navigateToSessionId = sessionId
                        isNavigationActive = true // Activate the NavigationLink
                    } else {
                        // Handle error
                        print("Error starting custom workout")
                    }
                }, workoutViewModel: viewModel)
            }
        }
        .onChange(of: isNavigationActive) { isActive in
             // Reset navigateToSessionId when navigation becomes inactive
             if !isActive {
                 navigateToSessionId = nil
             }
         }
    }
    
    // Extracted View for the list of workouts
    private var workoutListView: some View {
        Group { // Use Group to handle the conditional content
            if viewModel.sessions.isEmpty {
                // Need to wrap ContentUnavailableView in something for Group?
                // Or maybe ScrollView is fine here.
                ScrollView { // Keep ScrollView for the empty state
                    ContentUnavailableView(
                        "No Workouts",
                        systemImage: "figure.strengthtraining.traditional",
                        description: Text("Start your first workout to begin tracking your progress")
                    )
                    .padding(.top, 50) // Add some padding
                }
            } else {
                List { // Use List for swipe-to-delete
                    ForEach(viewModel.sessions) { session in
                        NavigationLink(destination: WorkoutSessionDetailView(sessionId: session.id, workoutViewModel: viewModel)) {
                            WorkoutSessionRow(session: session)
                        }
                        // Apply row styling if needed (moved from WorkoutSessionRow?)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: deleteSession)
                }
                .listStyle(.plain) // Use plain style
            }
        }
    }
    
    private func deleteSession(at offsets: IndexSet) {
        offsets.forEach { index in
            let sessionId = viewModel.sessions[index].id
            viewModel.deleteSession(id: sessionId)
        }
    }
}

// MARK: - Supporting Views (Need updates)

// REMOVED Old WorkoutSummary struct as it's replaced by WorkoutSession
/*
struct WorkoutSummary: Identifiable {
    let id: UUID
    var title: String
    var date: Date
    var exercises: [Exercise]
    var status: TrainingStatus
    var sets: [UUID: [WorkoutSet]]
}
*/

// Update WorkoutSessionRow to use WorkoutSession
struct WorkoutSessionRow: View {
    let session: WorkoutSession
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.title2)
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .background(Color(UIColor.systemGray6))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.headline)
                Text(session.status.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(statusColor(session.status))
            }
            
            Spacer()
            
            Text(session.date, style: .date)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func statusColor(_ status: TrainingStatus) -> Color {
        switch status {
        case .completed: .green
        case .inProgress: .blue
        case .cancelled: .red
        case .planned: .orange
        }
    }
}

// This view now shows details of a specific WorkoutSession (completed or in progress)
struct WorkoutSessionDetailView: View {
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let sessionId: UUID
    @State private var showingExercisePicker = false
    // Get session and sets from ViewModel
    private var session: WorkoutSession? {
        workoutViewModel.sessions.first { $0.id == sessionId }
    }
    private var sets: [PerformedSet] {
        workoutViewModel.sessionSets[sessionId] ?? []
    }
    // Group sets by exercise for display
    private var setsByExercise: [UUID: [PerformedSet]] {
        Dictionary(grouping: sets, by: { $0.exerciseId })
    }
    // We need access to exercise definitions
    @StateObject private var exerciseStore = ExerciseStore.shared // Or fetch definitions differently
    @State private var exerciseDefinitions: [UUID: ExerciseDefinition] = [:] // Use ExerciseDefinition
    // State for the exercise picker
    @State private var currentExercises: [ExerciseDefinition] = [] // Use ExerciseDefinition
    
    var body: some View {
        if let session = session {
            List {
                // Section for Session Title/Date (potentially editable if .inProgress)
                Section {
                     if session.status == .inProgress {
                         TextField("Workout Name", text: Binding(
                             get: { session.title },
                             set: { workoutViewModel.updateSessionDetails(id: session.id, title: $0) }
                         ))
                         
                         DatePicker(
                             "Date",
                             selection: Binding(
                                 get: { session.date },
                                 set: { workoutViewModel.updateSessionDetails(id: session.id, date: $0) }
                             ),
                             in: ...Date(),
                             displayedComponents: .date
                         )
                     } else {
                         Text(session.title).font(.headline)
                         Text(session.date, style: .date).foregroundColor(.secondary)
                     }
                 }
                 
                // Section per Exercise
                ForEach(currentExercises.sorted(by: { $0.name < $1.name }), id: \.id) { exercise in // Use currentExercises state
                    Section(header: Text(exercise.name)) {
                        if let exerciseSets = setsByExercise[exercise.id] {
                            ForEach(exerciseSets.sorted(by: { $0.setOrder < $1.setOrder })) { set in
                                HStack {
                                    Text("Set \(set.setOrder + 1)")
                                    Spacer()
                                    Text("\(set.weight, specifier: "%.1f")kg × \(set.reps)")
                                    if let rpe = set.rpe {
                                        Text("RPE \(rpe)")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .foregroundColor(set.reps > 0 ? .primary : .secondary) // Dim sets with 0 reps
                            }
                            .onDelete { offsets in
                                // Delete sets
                                deleteSets(for: exercise.id, at: offsets)
                            }
                        } else {
                            Text("No sets recorded for this exercise.").foregroundColor(.secondary)
                        }
                        // Add Set button only if session is in progress
                        if session.status == .inProgress {
                            Button("Add Set for \(exercise.name)") {
                                addSet(for: exercise.id)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteExerciseSection) // Allow deleting whole exercises from the session
                 
                 // Add Exercise button only if in progress
                 if session.status == .inProgress {
                     Section {
                         Button(action: { showingExercisePicker = true }) {
                             Label("Add Exercise", systemImage: "plus")
                         }
                     }
                 }
                 
                 // Button to mark as complete if in progress
                 if session.status == .inProgress {
                     Section {
                         Button(action: { workoutViewModel.completeSession(id: sessionId) }) {
                             Label("Complete Workout", systemImage: "checkmark.circle.fill")
                         }
                         .foregroundColor(.green)
                     }
                 }
            }
            .navigationTitle("Workout Details") // More generic title
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                 // Edit button only if appropriate (e.g., maybe delete sets/exercises?)
                 if session.status == .inProgress {
                     ToolbarItem(placement: .navigationBarTrailing) {
                         EditButton()
                     }
                 }
            }
            .sheet(isPresented: $showingExercisePicker) {
                // Pass Binding<[ExerciseDefinition]> to the picker
                ExercisePickerView(selectedExercises: $currentExercises)
                    .onChange(of: currentExercises) { newExercises in
                        // Update the session with the new list of exercises
                        // This will likely involve adding/removing sets in the ViewModel/DB
                         updateSessionExercises(newExerciseList: newExercises)
                    }
            }
            .onAppear {
                fetchExerciseDefinitions()
                // Initialize currentExercises state
                currentExercises = exerciseDefinitions.values.map { $0 }
            }
        } else {
            ContentUnavailableView(
                "Session Not Found",
                systemImage: "exclamationmark.triangle",
                description: Text("The workout session could not be found")
            )
        }
    }
    
    private func fetchExerciseDefinitions() {
        let exerciseIds = Set(sets.map { $0.exerciseId }) // Get unique IDs from existing sets
        guard !exerciseIds.isEmpty else { return }
        
        do {
            let definitions = try DatabaseService.shared.dbQueue.read { db in
                try ExerciseDefinition.filter(ids: exerciseIds).fetchAll(db)
            }
            self.exerciseDefinitions = Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0) })
            // Update currentExercises state after fetching
            self.currentExercises = definitions
        } catch {
            print("Error fetching exercise definitions: \(error)")
            self.exerciseDefinitions = [:]
            self.currentExercises = []
        }
    }
    
    private func addSet(for exerciseId: UUID) {
        guard let session = session else { return }
        let currentSets = workoutViewModel.sessionSets[session.id] ?? []
        let setsForThisExercise = currentSets.filter { $0.exerciseId == exerciseId }
        let lastSet = setsForThisExercise.sorted { $0.setOrder < $1.setOrder }.last
        let exerciseDef = exerciseDefinitions[exerciseId]
        
        let newSet = PerformedSet(
            sessionId: session.id,
            exerciseId: exerciseId,
            setOrder: (lastSet?.setOrder ?? -1) + 1,
            weight: lastSet?.weight ?? exerciseDef?.referenceWeight ?? 0,
            reps: 0, // Start with 0 reps
            rpe: nil,
            completedAt: Date()
        )
        
        var updatedSessionSets = currentSets
        updatedSessionSets.append(newSet)
        workoutViewModel.updateSessionSets(sessionId: session.id, setsToUpdate: updatedSessionSets)
    }

    private func deleteSets(for exerciseId: UUID, at offsets: IndexSet) {
        guard let session = session else { return }
        var currentSets = workoutViewModel.sessionSets[session.id] ?? []
        let setsForThisExercise = currentSets.filter { $0.exerciseId == exerciseId }.sorted { $0.setOrder < $1.setOrder }
        
        var setsToDelete = IndexSet()
        for offset in offsets {
            if offset < setsForThisExercise.count {
                let setIdToDelete = setsForThisExercise[offset].id
                if let indexInAllSets = currentSets.firstIndex(where: { $0.id == setIdToDelete }) {
                    setsToDelete.insert(indexInAllSets)
                }
            }
        }
        
        currentSets.remove(atOffsets: setsToDelete)
        workoutViewModel.updateSessionSets(sessionId: session.id, setsToUpdate: currentSets)
    }
    
    // Deletes an entire exercise and its sets from the session
    private func deleteExerciseSection(at offsets: IndexSet) {
        guard let session = session else { return }
        let sortedExercises = currentExercises.sorted(by: { $0.name < $1.name })
        var exercisesToDelete = [ExerciseDefinition]()
        offsets.forEach { index in
            exercisesToDelete.append(sortedExercises[index])
        }
        
        // Update the local state
        currentExercises.removeAll { exercise in exercisesToDelete.contains(where: { $0.id == exercise.id }) }
        
        // Update the ViewModel and Database
        updateSessionExercises(newExerciseList: currentExercises)
    }
    
    private func updateSessionExercises(newExerciseList: [ExerciseDefinition]) {
         guard let session = session else { return }
         var updatedSets = workoutViewModel.sessionSets[session.id] ?? []
         let newExerciseIds = Set(newExerciseList.map { $0.id })
         
         // Remove sets for exercises no longer in the list
         updatedSets.removeAll { !newExerciseIds.contains($0.exerciseId) }
         
         // Add default sets for newly added exercises
         for exercise in newExerciseList {
             if !updatedSets.contains(where: { $0.exerciseId == exercise.id }) {
                 // Add a default empty set for the new exercise
                 updatedSets.append(PerformedSet(
                     sessionId: session.id,
                     exerciseId: exercise.id,
                     setOrder: 0,
                     weight: exercise.referenceWeight ?? 0,
                     reps: 0,
                     rpe: nil,
                     completedAt: Date()
                 ))
             }
         }
         
         // Update the ViewModel
         workoutViewModel.updateSessionSets(sessionId: session.id, setsToUpdate: updatedSets)
         // Note: We might also want a dedicated ViewModel method to update *both* exercises and sets
         // if Exercise <-> Session relationship needs direct management in WorkoutSession table itself.
         // For now, updating sets implicitly handles which exercises are part of the session.
    }
}

// MARK: - Template Selection View

struct TemplateSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    // Callback with the selected template info
    var didSelectTemplate: (WorkoutTemplateViewModel.TemplateWithExercises) -> Void 
    @ObservedObject var templateViewModel: WorkoutTemplateViewModel
    @State private var searchText = ""
    
    var filteredTemplates: [WorkoutTemplateViewModel.TemplateWithExercises] {
        if searchText.isEmpty {
            return templateViewModel.templatesWithExercises
        }
        return templateViewModel.templatesWithExercises.filter { 
            $0.template.name.localizedCaseInsensitiveContains(searchText) 
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if templateViewModel.templatesWithExercises.isEmpty {
                        ContentUnavailableView(
                            "No Templates",
                            systemImage: "list.bullet.clipboard",
                            description: Text("Create a template first to use it in your workout")
                        )
                    } else {
                        ForEach(filteredTemplates) { templateWithExercises in
                            Button(action: {
                                // Execute the callback
                                didSelectTemplate(templateWithExercises) 
                            }) {
                                TemplateRowView(template: templateWithExercises.template)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search templates")
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Custom Workout Setup View (Renamed & Updated)

struct CustomWorkoutSetupView: View { // Renamed from CustomWorkoutView
    @Environment(\.dismiss) private var dismiss
    // Callback with title and exercises when ready to start
    var didStartWorkout: (String, [ExerciseDefinition]) -> Void 
    @ObservedObject var workoutViewModel: WorkoutViewModel // Keep for picker maybe?
    @State private var exercises: [ExerciseDefinition] = [] 
    @State private var showingExercisePicker = false
    @State private var workoutTitle = "Custom Workout"
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Workout Name", text: $workoutTitle)
                }
                
                Section {
                    if exercises.isEmpty {
                        ContentUnavailableView(
                            "No Exercises",
                            systemImage: "dumbbell",
                            description: Text("Add exercises to start your custom workout")
                        )
                    } else {
                        ForEach(exercises) { exercise in
                            ExerciseRow(exercise: exercise)
                        }
                        .onDelete(perform: deleteExercise)
                    }
                    
                    Button(action: { showingExercisePicker = true }) {
                        Label("Add Exercise", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Custom Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start") {
                        // Execute the callback
                        didStartWorkout(workoutTitle, exercises)
                    }
                    .disabled(exercises.isEmpty || workoutTitle.isEmpty)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(selectedExercises: $exercises)
            }
        }
    }
    
    private func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }
}

#Preview {
    WorkoutView()
} 