import Foundation

struct WorkoutSet: Identifiable, Codable {
    let id: UUID
    var weight: Double
    var targetReps: Int
    var completedReps: Int
    var rpe: Int?
    var notes: String?
    
    init(id: UUID = UUID(), weight: Double, targetReps: Int, completedReps: Int = 0, rpe: Int? = nil, notes: String? = nil) {
        self.id = id
        self.weight = weight
        self.targetReps = targetReps
        self.completedReps = completedReps
        self.rpe = rpe
        self.notes = notes
    }
} 