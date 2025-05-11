//
//  WorkoutTemplate.swift
//  GymTrack
//
//  Created by 郝大力 on 4/10/25.
//

import Foundation
import SwiftUI
import GRDB

// Represents the definition of an exercise
public struct ExerciseDefinition: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var category: ExerciseCategory // Store rawValue in DB
    public var targetRM: Int?
    public var referenceWeight: Double?
    public var notes: String?
    public var restInterval: TimeInterval?
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(),
         name: String,
         category: ExerciseCategory,
         targetRM: Int? = nil, // Made optional
         referenceWeight: Double? = nil, // Made optional
         notes: String? = nil,
         restInterval: TimeInterval? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.category = category
        self.targetRM = targetRM
        self.referenceWeight = referenceWeight
        self.notes = notes
        self.restInterval = restInterval
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Equatable conformance
    public static func == (lhs: ExerciseDefinition, rhs: ExerciseDefinition) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - GRDB Conformance for ExerciseDefinition
extension ExerciseDefinition: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "exerciseDefinition" }

    // Define columns for clarity and potential mapping
    enum Columns: String, ColumnExpression {
        case id, name, category, targetRM, referenceWeight, notes, restInterval, createdAt, updatedAt
    }
}

// Represents a workout template
public struct WorkoutTemplate: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var lastUsed: Date?

    // Note: The 'exercises' array is handled via the TemplateExercise join table
    // We don't store it directly in the WorkoutTemplate table.

    public init(id: UUID = UUID(), name: String, notes: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date(), lastUsed: Date? = nil) {
        self.id = id
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastUsed = lastUsed
    }

    // Equatable conformance
    public static func == (lhs: WorkoutTemplate, rhs: WorkoutTemplate) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - GRDB Conformance for WorkoutTemplate
extension WorkoutTemplate: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "workoutTemplate" }

    enum Columns: String, ColumnExpression {
        case id, name, notes, createdAt, updatedAt, lastUsed
    }
    
    // Define the relationship to the join table
    static let templateExercises = hasMany(TemplateExercise.self)
    
    // Define the relationship *through* the join table to ExerciseDefinition
    static let exercises = hasMany(ExerciseDefinition.self, through: templateExercises, using: TemplateExercise.exerciseDefinition)
    
    // Define a NEW association that includes ordering based on the join table
    static let orderedExercises = exercises.order(TemplateExercise.Columns.orderIndex.asc)
}

// Join Table Struct: Links WorkoutTemplate and ExerciseDefinition
struct TemplateExercise: Identifiable, Codable, Equatable {
    var id: UUID // Primary key for the join record itself
    var templateId: UUID
    var exerciseId: UUID
    var orderIndex: Int // To maintain order

    init(id: UUID = UUID(), templateId: UUID, exerciseId: UUID, orderIndex: Int) {
        self.id = id
        self.templateId = templateId
        self.exerciseId = exerciseId
        self.orderIndex = orderIndex
    }
}

// MARK: - GRDB Conformance for TemplateExercise
extension TemplateExercise: FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "templateExercise" }

    enum Columns: String, ColumnExpression {
        case id, templateId, exerciseId, orderIndex
    }
    
    // Define relationships back to the main tables
    static let workoutTemplate = belongsTo(WorkoutTemplate.self)
    static let exerciseDefinition = belongsTo(ExerciseDefinition.self)
}

// Keep ExerciseCategory enum as is (already Codable)
public enum ExerciseCategory: String, Codable, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case core = "Core"
    case cardio = "Cardio"
    case other = "Other"
    
    public var systemImage: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .back: return "figure.walk"
        case .legs: return "figure.run"
        case .shoulders: return "figure.boxing"
        case .arms: return "figure.strengthtraining.traditional"
        case .core: return "figure.core.training"
        case .cardio: return "heart.circle"
        case .other: return "figure.mixed.cardio"
        }
    }
} 