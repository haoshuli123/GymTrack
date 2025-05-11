import Foundation
import GRDB
import Combine

class WorkoutViewModel: ObservableObject {
    // Use WorkoutSession directly fetched from DB
    @Published private(set) var sessions: [WorkoutSession] = []
    // Store the fetched sets separately for easy access by views, keyed by sessionId
    @Published private(set) var sessionSets: [UUID: [PerformedSet]] = [:]
    
    // Keep ExerciseStore for exercise definitions and history aggregation if needed
    private let store = ExerciseStore.shared
    private var dbQueue: DatabaseQueue { DatabaseService.shared.dbQueue }
    private var cancellables: Set<AnyCancellable> = []

    init() {
        // Observe database changes for sessions
        observeWorkoutSessions()
    }
    
    private func observeWorkoutSessions() {
        // Create a ValueObservation that tracks sessions ordered by date
        let observation = ValueObservation.tracking { db in
            try WorkoutSession.order(WorkoutSession.Columns.date.desc).fetchAll(db)
        }
        
        // Start the observation
        observation
            .publisher(in: dbQueue) // Observe in the database queue
            .receive(on: DispatchQueue.main) // Deliver results on the main thread
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error observing workout sessions: \(error)")
                    // Handle error
                }
            }, receiveValue: { [weak self] fetchedSessions in
                guard let self = self else { return }
                let addedOrModifiedSessions = fetchedSessions.filter { session in
                    !self.sessions.contains(where: { $0.id == session.id && $0.updatedAt == session.updatedAt })
                }
                self.sessions = fetchedSessions // Update the main list
                if !addedOrModifiedSessions.isEmpty {
                    // Fetch sets only for new/updated sessions to be more efficient
                    self.fetchSets(for: addedOrModifiedSessions)
                }
                 // Consider removing sets for deleted sessions if needed
                 let fetchedIds = Set(fetchedSessions.map { $0.id })
                 self.sessionSets = self.sessionSets.filter { fetchedIds.contains($0.key) }
            })
            .store(in: &cancellables)
    }
    
    private func fetchSets(for sessionsToFetch: [WorkoutSession]) {
        let sessionIds = sessionsToFetch.map { $0.id }
        guard !sessionIds.isEmpty else { return }
        
        do {
            let fetchedSets = try dbQueue.read { db in
                // Fetch all sets belonging to the observed sessions
                try PerformedSet
                    .filter(sessionIds.contains(PerformedSet.Columns.sessionId))
                    .order(PerformedSet.Columns.setOrder.asc)
                    .fetchAll(db)
            }
            
            // Group sets by sessionId
            let groupedSets = Dictionary(grouping: fetchedSets, by: { $0.sessionId })
            
            // Update the published property on the main thread
            DispatchQueue.main.async {
                var updatedSessionSets = self.sessionSets
                for (sessionId, sets) in groupedSets {
                    updatedSessionSets[sessionId] = sets // Update/add sets for fetched sessions
                }
                self.sessionSets = updatedSessionSets
            }
            
        } catch {
            print("Error fetching sets for sessions: \(error)")
            // Handle error
        }
    }
    
    // Keep sortedSessions computed property if views rely on it
    var sortedSessions: [WorkoutSession] {
        sessions // Observation already sorts by date desc
    }
    
    // Helper to get sets for a specific exercise within a specific session, ordered
    func setsForExercise(_ exerciseId: UUID, inSession sessionId: UUID) -> [PerformedSet] {
        return (sessionSets[sessionId] ?? [])
            .filter { $0.exerciseId == exerciseId }
            .sorted { $0.setOrder < $1.setOrder }
    }
    
    // TODO: Implement efficient fetching of ExerciseDefinitions by IDs
    func getExerciseDefinitions(ids: Set<UUID>) -> [ExerciseDefinition] {
        print("Warning: getExerciseDefinitions needs implementation.")
        return [] // Placeholder
    }
    
    // MARK: - Workout Session Management
    
    // Starts a workout from a template, saves it, and returns the new Session ID
    func startWorkoutFromTemplate(template: WorkoutTemplate, exercises: [ExerciseDefinition], date: Date = Date()) -> UUID? {
        let newSession = WorkoutSession(
            templateId: template.id,
            title: template.name,
            date: date,
            status: .inProgress
        )
        return createSessionAndInitialSets(session: newSession, exercises: exercises)
    }

    // Starts a custom workout, saves it, and returns the new Session ID
    func startCustomWorkout(title: String, date: Date = Date(), exercises: [ExerciseDefinition]) -> UUID? {
        let newSession = WorkoutSession(
            title: title,
            date: date,
            status: .inProgress
        )
        return createSessionAndInitialSets(session: newSession, exercises: exercises)
    }

    // Private helper: Creates session, finds history, creates initial sets, saves all to DB
    private func createSessionAndInitialSets(session: WorkoutSession, exercises: [ExerciseDefinition]) -> UUID? {
        var initialSetsForDB: [PerformedSet] = []
        do {
            // Query history and create initial sets for each exercise
             for exercise in exercises {
                 var historySets: [PerformedSet]? = nil
                 let lastSessionId = try? dbQueue.read { db -> UUID? in
                     return try WorkoutSession
                         .filter(WorkoutSession.Columns.status == TrainingStatus.completed.rawValue)
                         .joining(required: WorkoutSession.performedSets.filter(PerformedSet.Columns.exerciseId == exercise.id.uuidString))
                         .order(WorkoutSession.Columns.date.desc)
                         .limit(1)
                         .fetchOne(db)?.id
                 }
                 
                 if let id = lastSessionId {
                     historySets = try? dbQueue.read { db in
                         return try PerformedSet
                             .filter(sql: "sessionId = ?", arguments: [id.uuidString])
                             .filter(sql: "exerciseId = ?", arguments: [exercise.id.uuidString])
                             .order(PerformedSet.Columns.setOrder.asc)
                             .fetchAll(db)
                     }
                 }
                 
                 if let lastPerformedSets = historySets, !lastPerformedSets.isEmpty {
                     // Create sets based on last workout
                     for (setIndex, lastSet) in lastPerformedSets.enumerated() {
                         initialSetsForDB.append(PerformedSet(
                             sessionId: session.id,
                             exerciseId: exercise.id,
                             setOrder: setIndex,
                             weight: lastSet.weight,
                             reps: 0, // Start reps at 0 for new session
                             rpe: nil,
                             completedAt: Date() // Use current date as placeholder
                         ))
                     }
                 } else {
                     // Create one default/empty set if no history
                     initialSetsForDB.append(PerformedSet(
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

            // Save the new session and all its initial sets in one transaction
            try dbQueue.write { db in
                try session.save(db)
                for set in initialSetsForDB {
                    try set.save(db)
                }
            }
            // Observation will automatically update the UI shortly after write
            // Return the new session's ID so the view can potentially navigate
            print("Successfully created session \(session.id) and initial sets.")
            return session.id
        } catch {
            print("Error creating session and initial sets: \(error)")
            return nil // Return nil on failure
        }
    }
    
    // Update specific fields of a session
    func updateSessionDetails(id: UUID, title: String? = nil, date: Date? = nil) {
        do {
            try dbQueue.write { db in
                if var session = try WorkoutSession.fetchOne(db, key: id) {
                    if let title = title { session.title = title }
                    if let date = date { session.date = date }
                    session.updatedAt = Date()
                    try session.update(db)
                } else {
                    print("Session not found for update: \(id)")
                }
            }
        } catch {
            print("Error updating session details: \(error)")
        }
    }
    
    // Update the exercises associated with a session (if customization is allowed)
    // This requires adding/removing PerformedSet records.
    func updateSessionExercises(id: UUID, exercises: [ExerciseDefinition]) {
        // TODO: Implement logic to compare old/new exercises,
        // add/remove PerformedSet records accordingly in a transaction.
        // Also needs to update the WorkoutSession updatedAt timestamp.
        print("updateSessionExercises not fully implemented yet.")
    }
    
    // Replaces all sets for a given session
    func updateSessionSets(sessionId: UUID, setsToUpdate: [PerformedSet]) {
        do {
            try dbQueue.write { db in
                // Delete existing sets for the session first
                _ = try PerformedSet.filter(sql: "sessionId = ?", arguments: [sessionId.uuidString]).deleteAll(db)
                
                // Insert the new sets
                for set in setsToUpdate {
                    // Ensure sessionId is correct, just in case
                    var setToSave = set 
                    setToSave.sessionId = sessionId
                    try setToSave.save(db) 
                }
                
                // Update the session's updatedAt timestamp
                if var session = try WorkoutSession.fetchOne(db, key: sessionId) {
                    session.updatedAt = Date()
                    try session.update(db)
                }
            }
            // Observation should handle UI update. 
            // Can manually update local state if needed: 
            // DispatchQueue.main.async { self.sessionSets[sessionId] = setsToUpdate }
        } catch {
            print("Error updating session sets: \(error)")
        }
    }
    
    // Mark a session as completed
    func completeSession(id: UUID) {
         do {
             try dbQueue.write { db in
                 if var session = try WorkoutSession.fetchOne(db, key: id) {
                     session.status = .completed
                     session.updatedAt = Date()
                     try session.update(db)
                     // TODO: Optionally trigger ExerciseStore aggregation/update based on completed sets
                 } else {
                     print("Session not found for completion: \(id)")
                 }
             }
         } catch {
             print("Error completing session: \(error)")
         }
     }
     
     // Delete a session (cascades to delete sets)
     func deleteSession(id: UUID) {
        do {
            _ = try dbQueue.write { db in
                try WorkoutSession.deleteOne(db, key: id)
            }
        } catch {
            print("Error deleting session: \(error)")
        }
     }

    // MARK: - Performed Set Management (NEW METHODS)

    func addSet(exerciseId: UUID, to sessionId: UUID) {
        // Get existing sets for the exercise to determine the next order and last weight/reps
        let existingSets = setsForExercise(exerciseId, inSession: sessionId)
        let lastSet = existingSets.last
        let exerciseDef = getExerciseDefinitions(ids: [exerciseId]).first // TODO: Replace with real fetch
        let nextOrder = existingSets.count // Order is 0-based index

        let newSet = PerformedSet(
            sessionId: sessionId,
            exerciseId: exerciseId,
            setOrder: nextOrder,
            weight: lastSet?.weight ?? exerciseDef?.referenceWeight ?? 0,
            reps: 0, // Start new sets with 0 reps
            rpe: nil,
            completedAt: Date()
        )
        
        // Save the new set to the database
        do {
            try dbQueue.write { db in
                try newSet.save(db)
                // Update session timestamp
                if var session = try WorkoutSession.fetchOne(db, key: sessionId) {
                    session.updatedAt = Date()
                    try session.update(db)
                }
            }
            // Observation will update the @Published properties
        } catch {
            print("Error adding set: \(error)")
        }
    }

    // Update an existing set
    func updateSet(_ set: PerformedSet) { // Pass the modified set
        // The sessionId is already on the set object!
        let sessionId = set.sessionId 
        do {
            try dbQueue.write { db in
                var mutableSet = set // Create mutable copy 
                // Update completedAt when the set is modified
                mutableSet.completedAt = Date() 
                try mutableSet.update(db) // Assumes set already exists
                
                // Update session timestamp
                 if var session = try WorkoutSession.fetchOne(db, key: sessionId) {
                     session.updatedAt = Date()
                     try session.update(db)
                 }
            }
        } catch {
            print("Error updating set \(set.id): \(error)")
        }
    }
    
    // Delete specific sets by their IDs
    func deleteSets(ids: [UUID], from sessionId: UUID) {
         guard !ids.isEmpty else { return }
         do {
             try dbQueue.write { db in
                 _ = try PerformedSet.filter(ids: ids).deleteAll(db)
                 // Update session timestamp
                 if var session = try WorkoutSession.fetchOne(db, key: sessionId) {
                     session.updatedAt = Date()
                     try session.update(db)
                 }
             }
         } catch {
             print("Error deleting sets: \(error)")
         }
     }
} 