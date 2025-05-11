//
//  WorkoutTemplatesView.swift
//  GymTrack
//
//  Created by 郝大力 on 4/10/25.
//

import SwiftUI

struct WorkoutTemplatesView: View {
    @StateObject private var viewModel = WorkoutTemplateViewModel()
    @State private var showingNewTemplate = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.templatesWithExercises) { templateWithExercises in
                    NavigationLink(destination: TemplateDetailView(templateWithExercises: templateWithExercises, viewModel: viewModel)) {
                        TemplateRowView(template: templateWithExercises.template)
                    }
                }
                .onDelete(perform: deleteTemplates)
            }
            .navigationTitle("Workout Templates")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewTemplate = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewTemplate) {
                NewTemplateView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.fetchTemplatesWithExercises()
            }
        }
    }
    
    private func deleteTemplates(at offsets: IndexSet) {
        let idsToDelete = offsets.map { viewModel.templatesWithExercises[$0].template.id }
        idsToDelete.forEach {
            viewModel.deleteTemplate(id: $0)
        }
    }
}

struct TemplateRowView: View {
    let template: WorkoutTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name)
                .font(.headline)
            
            HStack(spacing: 8) {
                if let lastUsed = template.lastUsed {
                    Label(lastUsed.formatted(.relative(presentation: .named)), systemImage: "clock")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

struct TemplateDetailView: View {
    let templateWithExercises: WorkoutTemplateViewModel.TemplateWithExercises
    @ObservedObject var viewModel: WorkoutTemplateViewModel
    @State private var showingEditSheet = false
    
    private var template: WorkoutTemplate { templateWithExercises.template }
    private var exercises: [ExerciseDefinition] { templateWithExercises.exercises }
    
    var body: some View {
        List {
            Section {
                ForEach(exercises) { exercise in
                    ExerciseRow(exercise: exercise)
                }
            } header: {
                Text("Exercises")
            } footer: {
                if exercises.isEmpty {
                    Text("No exercises added yet")
                }
            }
            
            if let notes = template.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }
        }
        .navigationTitle(template.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditSheet = true }) {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                EditTemplateView(templateWithExercises: templateWithExercises, viewModel: viewModel)
            }
        }
    }
}

#Preview {
    WorkoutTemplatesView()
} 