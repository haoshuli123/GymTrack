import Foundation
import Combine
import GRDB // Make sure GRDB is imported if DB operations happen here later

class WorkoutTemplateViewModel: ObservableObject {
    @Published var templates: [WorkoutTemplate] = []
    @Published var selectedTemplate: WorkoutTemplate?
    
    // Structure to hold template and its associated exercises
    struct TemplateWithExercises: Identifiable {
        var id: UUID { template.id }
        var template: WorkoutTemplate
        var exercises: [ExerciseDefinition]
    }
    @Published var templatesWithExercises: [TemplateWithExercises] = []
    
    private var dbQueue: DatabaseQueue { DatabaseService.shared.dbQueue } // Access the DB queue
    
    init() {
        // loadTemplates() // Replace UserDefaults loading with DB loading
        fetchTemplatesWithExercises()
    }
    
    func fetchTemplatesWithExercises() {
        do {
            let fetchedData = try dbQueue.read { db -> [TemplateWithExercises] in // Explicit return type
                // Fetch all templates
                let templates = try WorkoutTemplate.fetchAll(db)
                
                // For each template, fetch its ordered exercises
                var result: [TemplateWithExercises] = []
                for template in templates {
                    // Use the NEW pre-ordered association
                    let request = template.request(for: WorkoutTemplate.orderedExercises)
                    
                    let exercises = try request.fetchAll(db)
                    result.append(TemplateWithExercises(template: template, exercises: exercises))
                }
                return result
            }
            // Update the published property on the main thread
            DispatchQueue.main.async {
                self.templatesWithExercises = fetchedData // Use fetchedData
                // Update the old templates array if needed elsewhere, though it's better to use templatesWithExercises
                self.templates = fetchedData.map { $0.template } // Use fetchedData
            }
        } catch {
            print("Error fetching templates with exercises: \(error)")
            // Handle error appropriately (e.g., show an alert)
        }
    }
    
    func createTemplate(name: String, exercises: [ExerciseDefinition]) {
        var template = WorkoutTemplate(name: name)
        do {
            try dbQueue.write { db in
                // Save the template first
                try template.save(db)
                
                // Save the association in the join table
                for (index, exercise) in exercises.enumerated() {
                    // Ensure the exercise definition exists (or save it)
                    var dbExercise = exercise // Make mutable if it needs saving/updating
                    try? dbExercise.save(db) // Save exercise definition if not already in DB
                    
                    let templateExercise = TemplateExercise(templateId: template.id, exerciseId: exercise.id, orderIndex: index)
                    try templateExercise.save(db)
                }
            }
            // Refetch data to update the UI
            fetchTemplatesWithExercises()
        } catch {
            print("Error creating template: \(error)")
            // Handle error
        }
    }
    
    func updateTemplate(_ template: WorkoutTemplate, exercises: [ExerciseDefinition]) {
         do {
             try dbQueue.write { db in
                 // Update the template record
                 try template.update(db)
                 
                 // Remove existing associations for this template
                 _ = try TemplateExercise.filter(TemplateExercise.Columns.templateId == template.id).deleteAll(db)
                 
                 // Add new associations
                 for (index, exercise) in exercises.enumerated() {
                     var dbExercise = exercise
                     try? dbExercise.save(db)
                     let templateExercise = TemplateExercise(templateId: template.id, exerciseId: exercise.id, orderIndex: index)
                     try templateExercise.save(db)
                 }
             }
             fetchTemplatesWithExercises()
         } catch {
             print("Error updating template: \(error)")
             // Handle error
         }
     }
    
    func deleteTemplate(id: UUID) { // Pass ID instead of object
        do {
            _ = try dbQueue.write { db in
                // Deleting the template will cascade delete TemplateExercise records due to foreign key constraint
                try WorkoutTemplate.deleteOne(db, id: id)
            }
            fetchTemplatesWithExercises()
        } catch {
             print("Error deleting template: \(error)")
             // Handle error
         }
    }
    
    // Remove UserDefaults save/load methods
    /*
    private func saveTemplates() {
        // TODO: Implement persistence
        if let encoded = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(encoded, forKey: "WorkoutTemplates")
        }
    }
    
    private func loadTemplates() {
        if let data = UserDefaults.standard.data(forKey: "WorkoutTemplates"),
           let decoded = try? JSONDecoder().decode([WorkoutTemplate].self, from: data) {
            templates = decoded
        }
    }
    */
} 