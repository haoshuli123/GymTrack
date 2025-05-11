import Foundation
import GRDB

// Represents a single set performed during a workout session.
struct PerformedSet: Identifiable, Codable, Equatable {
    var id: UUID
    var sessionId: UUID // Foreign Key to WorkoutSession
    var exerciseId: UUID // Foreign Key to ExerciseDefinition
    var setOrder: Int // Order within the exercise for this session
    var weight: Double
    var reps: Int
    var rpe: Int?
    var notes: String?
    var completedAt: Date // Timestamp for when the set was done

    // Default initializer
    init(id: UUID = UUID(), sessionId: UUID, exerciseId: UUID, setOrder: Int, weight: Double, reps: Int, rpe: Int? = nil, notes: String? = nil, completedAt: Date = Date()) {
        self.id = id
        self.sessionId = sessionId
        self.exerciseId = exerciseId
        self.setOrder = setOrder
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.notes = notes
        self.completedAt = completedAt
    }
}

// MARK: - GRDB Conformance
extension PerformedSet: FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "performedSet" }

    // Define columns if needed for clarity or if names differ
    enum Columns: String, ColumnExpression {
        case id, sessionId, exerciseId, setOrder, weight, reps, rpe, notes, completedAt
    }
    
    // Define the relationship back to WorkoutSession
    static let workoutSession = belongsTo(WorkoutSession.self)
} 