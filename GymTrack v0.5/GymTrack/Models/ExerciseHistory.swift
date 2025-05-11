import Foundation

struct ExerciseHistory: Identifiable, Codable {
    let id: UUID
    let exerciseId: UUID
    let date: Date
    let sets: [SetRecord]
    let notes: String?
    
    struct SetRecord: Identifiable, Codable {
        let id: UUID
        let weight: Double
        let reps: Int
        let rpe: Int?  // Rate of Perceived Exertion (1-10)
    }
}

struct ExerciseStats {
    let maxWeight: Double
    let maxReps: Int
    let totalVolume: Double
    let averageRPE: Double?
    
    // 计算一段时间内的进步
    var progressPercentage: Double?
    var volumeProgress: Double?
} 