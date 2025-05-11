//
//  StartWorkoutView.swift
//  GymTrack
//
//  Created by 郝大力 on 4/10/25.
//

import SwiftUI
import GRDB

// Receives a session ID and displays the workout logging interface.
struct StartWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    let sessionId: UUID // Initialized with the ID of the session to work on
    
    // Get ViewModel from Environment or pass it in
    // Using EnvironmentObject for simplicity here, ensure it's injected higher up
    @EnvironmentObject var workoutViewModel: WorkoutViewModel
    
    @State private var currentExerciseIndex = 0
    @State private var showingConfirmation = false
    
    // Data fetched from ViewModel based on sessionId
    private var session: WorkoutSession? {
        workoutViewModel.sessions.first { $0.id == sessionId }
    }
    private var exercises: [ExerciseDefinition] {
        // TODO: Replace with actual fetching logic based on session/template
        // This requires WorkoutViewModel to provide exercises for a session ID.
        // Returning placeholder based on sets for now.
        let exerciseIds = Set((workoutViewModel.sessionSets[sessionId] ?? []).map { $0.exerciseId })
        return workoutViewModel.getExerciseDefinitions(ids: exerciseIds) // Assuming this VM method exists
    }

    var body: some View {
        // Ensure session exists before showing UI
        guard let session = session else {
            // Return the error view directly if session is nil
            return AnyView( // Use AnyView to erase the specific type
                ContentUnavailableView("Workout Ended", systemImage: "exclamationmark.triangle")
                    .navigationTitle("Error")
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") { dismiss() }
                        }
                    }
            )
        }
        
        // If session exists, return the main workout view
        return AnyView(
            VStack(spacing: 0) {
                 // Progress bar
                 GeometryReader { geometry in
                     ZStack(alignment: .leading) {
                         Rectangle().fill(.gray.opacity(0.2))
                         Rectangle().fill(.blue).frame(width: geometry.size.width * progress)
                     }
                     .frame(height: 4)
                 }
                 .frame(height: 4)
                 
                 // Exercise Pager (TabView)
                 exercisePagerView
                 
                 // Navigation Controls
                 navigationControlsView
            }
            .navigationTitle(session.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true) // Keep preventing swipe back
            .toolbar { // Apply toolbar to the VStack
                 ToolbarItem(placement: .navigationBarLeading) {
                     Button("Cancel", role: .destructive) { showingConfirmation = true }
                 }
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button("Finish") { finishWorkout() }
                         .disabled(exercises.isEmpty)
                 }
             }
            .confirmationDialog(
                "End Workout?",
                isPresented: $showingConfirmation,
                titleVisibility: .visible
            ) { 
                Button("End Workout", role: .destructive) { cancelWorkout() }
                Button("Continue Workout", role: .cancel) {}
            } message: {
                Text("Your progress for this session will be saved, but marked as cancelled.")
            }
        )
    }
    
    // Extracted Exercise Pager View - SIMPLIFIED
    // Removed @ViewBuilder
    private var exercisePagerView: some View {
        // Wrap the conditional content in a Group
        Group {
            if !exercises.isEmpty {
                TabView(selection: $currentExerciseIndex) {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        // Pass necessary info to ExerciseLoggingView
                        // ExerciseLoggingView will fetch its own sets using the ViewModel
                        ExerciseLoggingView(sessionId: sessionId, exercise: exercise)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            } else {
                ContentUnavailableView(
                    "No Exercises",
                    systemImage: "dumbbell",
                    description: Text("This workout session has no exercises.")
                )
            }
        }
    }
    
    // Extracted Navigation Controls View
    private var navigationControlsView: some View {
        HStack {
            Button(action: previousExercise) {
                Image(systemName: "chevron.left").imageScale(.large)
            }
            .disabled(currentExerciseIndex == 0)
            
            Spacer()
            Text("\(currentExerciseIndex + 1) of \(exercises.count)")
                .font(.caption).foregroundColor(.secondary)
            Spacer()
            
            Button(action: nextExercise) {
                Image(systemName: "chevron.right").imageScale(.large)
            }
            .disabled(currentExerciseIndex == exercises.count - 1 || exercises.isEmpty)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
    }

    // --- Helper Functions --- 
    
    private var progress: CGFloat {
        guard !exercises.isEmpty else { return 0 }
        return CGFloat(currentExerciseIndex + 1) / CGFloat(exercises.count)
    }
    
    private func previousExercise() {
        // No need to save sets on navigation, binding updates ViewModel directly (or via updateSessionSets)
        withAnimation {
            currentExerciseIndex = max(0, currentExerciseIndex - 1)
        }
    }
    
    private func nextExercise() {
        // No need to save sets on navigation
        withAnimation {
            currentExerciseIndex = min(exercises.count - 1, currentExerciseIndex + 1)
        }
    }
    
    private func finishWorkout() {
        // Simply call the ViewModel method to mark as complete
        print("Finishing workout: \(sessionId)")
        workoutViewModel.completeSession(id: sessionId)
        dismiss()
    }
    
    private func cancelWorkout() {
        print("Cancelling workout: \(sessionId)")
        // Mark as cancelled in DB via ViewModel
        do {
             try dbQueue.write { db in
                 if var sessionToCancel = try WorkoutSession.fetchOne(db, key: sessionId) {
                     sessionToCancel.status = .cancelled
                     sessionToCancel.updatedAt = Date()
                     try sessionToCancel.update(db)
                 } else {
                      print("Session \(sessionId) not found when trying to cancel.")
                 }
             }
         } catch {
             print("Error marking session as cancelled: \(error)")
         }
        dismiss()
    }
    
     // Access dbQueue if needed (e.g., for cancelWorkout)
     private var dbQueue: DatabaseQueue { DatabaseService.shared.dbQueue }
}

// Preview needs to provide sessionId and EnvironmentObject
#Preview {
    // 1. Create a mock session and sets in a temporary DB or ViewModel state
    let previewWorkoutVM = WorkoutViewModel() // Use a real VM for preview state
    let exerciseDefs = [
        ExerciseDefinition(name: "Preview Bench", category: .chest),
        ExerciseDefinition(name: "Preview Squat", category: .legs)
    ]
    // Start a workout to get a session ID for the preview
    let previewSessionId = previewWorkoutVM.startCustomWorkout(title: "Preview Workout", exercises: exerciseDefs) ?? UUID() 
    
    // 2. Create StartWorkoutView with the ID
    return NavigationView {
        StartWorkoutView(sessionId: previewSessionId)
            .environmentObject(previewWorkoutVM) // Inject the ViewModel
    }
} 
