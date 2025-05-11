import SwiftUI

struct NewTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WorkoutTemplateViewModel
    @State private var templateName = ""
    @State private var selectedExercises: [ExerciseDefinition] = []
    @State private var showingExercisePicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Template Info")) {
                    TextField("Template Name", text: $templateName)
                }
                
                Section(header: Text("Exercises")) {
                    ForEach(selectedExercises) { exercise in
                        ExerciseRow(exercise: exercise)
                    }
                    .onDelete(perform: deleteExercise)
                    
                    Button(action: { showingExercisePicker = true }) {
                        Label("Add Exercise", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("New Template")
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
                    .disabled(templateName.isEmpty || selectedExercises.isEmpty)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(selectedExercises: $selectedExercises)
            }
        }
    }
    
    private func deleteExercise(at offsets: IndexSet) {
        selectedExercises.remove(atOffsets: offsets)
    }
    
    private func saveTemplate() {
        viewModel.createTemplate(name: templateName, exercises: selectedExercises)
        dismiss()
    }
}

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedExercises: [ExerciseDefinition]
    @State private var searchText = ""
    
    let exercises: [ExerciseDefinition] = [
        ExerciseDefinition(name: "Bench Press", category: .chest),
        ExerciseDefinition(name: "Squat", category: .legs),
        ExerciseDefinition(name: "Deadlift", category: .back),
        ExerciseDefinition(name: "Shoulder Press", category: .shoulders)
    ]
    
    var filteredExercises: [ExerciseDefinition] {
        if searchText.isEmpty {
            return exercises
        }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            List(filteredExercises) { exercise in
                Button(action: {
                    if !selectedExercises.contains(where: { $0.id == exercise.id }) {
                        selectedExercises.append(exercise)
                    }
                }) {
                    ExerciseRow(exercise: exercise)
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NewTemplateView(viewModel: WorkoutTemplateViewModel())
} 