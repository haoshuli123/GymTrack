import Foundation
import GRDB

final class DatabaseService {
    // Shared instance (Singleton pattern)
    static let shared = DatabaseService()

    // The DatabaseQueue manages concurrent access to the database.
    let dbQueue: DatabaseQueue

    private init() {
        do {
            // 1. Find a location for the database file
            let fileManager = FileManager.default
            // Use the Application Support directory, which is appropriate for user data.
            let appSupportURL = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let dbURL = appSupportURL.appendingPathComponent("gymtrack.sqlite")
            print("Database path: \(dbURL.path)") // Good for debugging

            // 2. Create the DatabaseQueue
            dbQueue = try DatabaseQueue(path: dbURL.path)

            // 3. Define and run migrations to create the schema
            try migrator.migrate(dbQueue)
            print("Database migration check completed.")

        } catch {
            // TODO: Handle errors appropriately (e.g., log, show alert)
            fatalError("Failed to initialize database: \(error)")
        }
    }

    // Define the database schema migrations
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        // Speed up development by erasing the database if migrations change
        // See https://github.com/groue/GRDB.swift/blob/master/Documentation/Migrations.md#the-erasedatabaseonschemachange-option
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v1") { db in
            print("Running database migration v1...")
            // Create tables based on your schema design
            // Use `IF NOT EXISTS` for safety, although eraseDatabaseOnSchemaChange handles it in DEBUG

            // ExerciseDefinition Table
            try db.create(table: ExerciseDefinition.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text).notNull()
                t.column("name", .text).notNull().indexed()
                t.column("category", .text).notNull() // Storing Enum rawValue
                t.column("targetRM", .integer)
                t.column("referenceWeight", .double)
                t.column("notes", .text)
                t.column("restInterval", .double)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            print("Created/Checked table: \(ExerciseDefinition.databaseTableName)")

            // WorkoutTemplate Table
             try db.create(table: WorkoutTemplate.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text).notNull()
                t.column("name", .text).notNull()
                t.column("notes", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("lastUsed", .datetime)
             }
             print("Created/Checked table: \(WorkoutTemplate.databaseTableName)")

            // TemplateExercise Join Table
             try db.create(table: TemplateExercise.databaseTableName, ifNotExists: true) { t in
                 t.primaryKey("id", .text).notNull()
                 t.column("templateId", .text).notNull().indexed().references(WorkoutTemplate.databaseTableName, onDelete: .cascade)
                 t.column("exerciseId", .text).notNull().indexed().references(ExerciseDefinition.databaseTableName, onDelete: .cascade)
                 t.column("orderIndex", .integer).notNull()
             }
             print("Created/Checked table: \(TemplateExercise.databaseTableName)")

            // WorkoutSession Table
            try db.create(table: WorkoutSession.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text).notNull()
                t.column("templateId", .text).references(WorkoutTemplate.databaseTableName, onDelete: .setNull)
                t.column("title", .text).notNull()
                t.column("date", .date).notNull().indexed()
                t.column("status", .text).notNull() // Store enum rawValue
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            print("Created/Checked table: \(WorkoutSession.databaseTableName)")

            // PerformedSet Table
            try db.create(table: PerformedSet.databaseTableName, ifNotExists: true) { t in
                t.primaryKey("id", .text).notNull()
                t.column("sessionId", .text).notNull().indexed().references(WorkoutSession.databaseTableName, onDelete: .cascade)
                t.column("exerciseId", .text).notNull().indexed().references(ExerciseDefinition.databaseTableName, onDelete: .cascade)
                t.column("setOrder", .integer).notNull()
                t.column("weight", .double).notNull()
                t.column("reps", .integer).notNull()
                t.column("rpe", .integer)
                t.column("notes", .text)
                t.column("completedAt", .datetime).notNull()
            }
            print("Created/Checked table: \(PerformedSet.databaseTableName)")
            print("Database migration v1 finished.")
        }

        // Add future migrations here:
        // migrator.registerMigration("v2") { db in ... }

        return migrator
    }
} 