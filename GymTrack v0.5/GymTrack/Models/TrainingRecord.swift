import Foundation

public struct TrainingRecord: Identifiable, Codable {
    public var id: UUID
    public var exerciseId: UUID
    public var date: Date
    public var weight: Double
    public var rm: Int
    public var reps: Int
    public var notes: String?
    
    public init(id: UUID = UUID(), exerciseId: UUID, weight: Double, rm: Int, reps: Int, notes: String? = nil) {
        self.id = id
        self.exerciseId = exerciseId
        self.date = Date()
        self.weight = weight
        self.rm = rm
        self.reps = reps
        self.notes = notes
    }
}

public struct TrainingSession: Identifiable, Codable {
    public var id: UUID
    public var templateId: UUID?
    public var date: Date
    public var records: [TrainingRecord]
    public var status: TrainingStatus
    
    public init(id: UUID = UUID(), templateId: UUID? = nil, date: Date = Date(), records: [TrainingRecord] = [], status: TrainingStatus = .planned) {
        self.id = id
        self.templateId = templateId
        self.date = date
        self.records = records
        self.status = status
    }
} 