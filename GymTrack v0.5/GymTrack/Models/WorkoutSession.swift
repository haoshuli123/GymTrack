import Foundation
import GRDB

// Represents a single workout session instance.
struct WorkoutSession: Identifiable, Codable, Equatable {
    var id: UUID
    var templateId: UUID? // Optional link to a WorkoutTemplate
    var title: String // e.g., "Leg Day" or "Custom Workout - Apr 17"
    var date: Date
    var status: TrainingStatus
    var createdAt: Date
    var updatedAt: Date

    // Initializer
    init(id: UUID = UUID(), templateId: UUID? = nil, title: String, date: Date, status: TrainingStatus = .planned, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.templateId = templateId
        self.title = title
        self.date = date
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - GRDB Conformance
extension WorkoutSession: FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "workoutSession" }

    enum Columns: String, ColumnExpression {
        case id, templateId, title, date, status, createdAt, updatedAt
    }
    
    // Define the relationship to PerformedSet
    static let performedSets = hasMany(PerformedSet.self)
    
    // Helper request to fetch sets for this session
    var sets: QueryInterfaceRequest<PerformedSet> {
        request(for: WorkoutSession.performedSets)
            .order(PerformedSet.Columns.setOrder.asc)
    }
}

// Ensure TrainingStatus enum exists and is Codable
// It might be in Models/TrainingRecord.swift or needs its own file
public enum TrainingStatus: String, Codable {
    case planned
    case inProgress
    case completed
    case cancelled
} 