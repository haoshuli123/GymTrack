//
//  EditTemplateView.swift
//  GymTrack
//
//  Created by 郝大力 on 4/10/25.
//

import SwiftUI

struct EditTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    let templateWithExercises: WorkoutTemplateViewModel.TemplateWithExercises
    @ObservedObject var viewModel: WorkoutTemplateViewModel
    
    @State private var name: String
    @State private var notes: String
    @State private var exercises: [ExerciseDefinition]
    @State private var showingExercisePicker = false
    
    init(templateWithExercises: WorkoutTemplateViewModel.TemplateWithExercises, viewModel: WorkoutTemplateViewModel) {
        self.templateWithExercises = templateWithExercises
        self.viewModel = viewModel
        _name = State(initialValue: templateWithExercises.template.name)
        _notes = State(initialValue: templateWithExercises.template.notes ?? "")
        _exercises = State(initialValue: templateWithExercises.exercises)
    }
    
    var body: some View {
        Form {
            Section("Template Info") {
                TextField("Template Name", text: $name)
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            
            Section {
                ForEach(exercises) { exercise in
                    ExerciseRow(exercise: exercise)
                }
                .onMove { from, to in
                    exercises.move(fromOffsets: from, toOffset: to)
                }
                .onDelete { indexSet in
                    exercises.remove(atOffsets: indexSet)
                }
                
                Button(action: { showingExercisePicker = true }) {
                    Label("Add Exercise", systemImage: "plus")
                }
            } header: {
                Text("Exercises")
            } footer: {
                if exercises.isEmpty {
                    Text("Add some exercises to your template")
                }
            }
        }
        .navigationTitle("Edit Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveTemplate()
                }
                .disabled(name.isEmpty)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(selectedExercises: $exercises)
        }
    }
    
    private func saveTemplate() {
        var updatedTemplate = templateWithExercises.template
        updatedTemplate.name = name
        updatedTemplate.notes = notes.isEmpty ? nil : notes
        updatedTemplate.updatedAt = Date()
        
        viewModel.updateTemplate(updatedTemplate, exercises: exercises)
        dismiss()
    }
}

#Preview {
    // Create mock data conforming to the new structure
    let mockTemplate = WorkoutTemplate(
        name: "Sample Template"
        // No exercises array here in the template initializer
    )
    let mockExercises = [
        ExerciseDefinition(name: "Bench Press", category: .chest),
        ExerciseDefinition(name: "Squat", category: .legs)
    ]
    let mockTemplateWithExercises = WorkoutTemplateViewModel.TemplateWithExercises(
        template: mockTemplate,
        exercises: mockExercises // Pass exercises here for the combined struct
    )
    
    return NavigationView {
        EditTemplateView(
            templateWithExercises: mockTemplateWithExercises,
            viewModel: WorkoutTemplateViewModel() // Using default initializer for preview
        )
    }
} 