//
//  ExerciseRow.swift
//  GymTrack
//
//  Created by 郝大力 on 4/10/25.
//

import SwiftUI

// This row now displays an ExerciseDefinition
struct ExerciseRow: View {
    // Use ExerciseDefinition
    let exercise: ExerciseDefinition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            
            HStack {
                // Use category from ExerciseDefinition
                Label(exercise.category.rawValue, systemImage: "tag.fill") 
                Spacer()
                // Display targetRM and referenceWeight if they exist
                if let targetRM = exercise.targetRM {
                    Text("\(targetRM)RM")
                        .foregroundColor(.blue)
                }
                if let refWeight = exercise.referenceWeight, refWeight > 0 {
                    Text("(\(refWeight, specifier: "%.1f")kg)")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// Preview needs ExerciseDefinition
#Preview {
    ExerciseRow(exercise: ExerciseDefinition( // Use ExerciseDefinition
        id: UUID(),
        name: "Bench Press",
        category: .chest,
        targetRM: 8,
        referenceWeight: 60.0
    ))
    .previewLayout(.sizeThatFits)
    .padding()
} 