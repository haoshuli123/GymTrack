import SwiftUI

struct WorkoutSetEditor: View {
    @Binding var set: WorkoutSet
    @State private var isEditing = false
    @State private var weight: String
    @State private var reps: String
    
    init(set: Binding<WorkoutSet>) {
        self._set = set
        self._weight = State(initialValue: set.wrappedValue.weight > 0 ? String(format: "%.1f", set.wrappedValue.weight) : "")
        self._reps = State(initialValue: set.wrappedValue.completedReps > 0 ? "\(set.wrappedValue.completedReps)" : "")
    }
    
    var body: some View {
        HStack {
            if isEditing {
                TextField("Weight", text: $weight)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                
                Text("kg ×")
                    .foregroundColor(.secondary)
                
                TextField("Reps", text: $reps)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)
                
                Button("Save") {
                    saveChanges()
                }
                .buttonStyle(.bordered)
            } else {
                Button(action: { isEditing = true }) {
                    if set.weight > 0 && set.completedReps > 0 {
                        Text("\(Int(set.weight))kg × \(set.completedReps)")
                            .foregroundColor(.primary)
                    } else {
                        Text("Add Weight & Reps")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        if let weightValue = Double(weight), let repsValue = Int(reps) {
            set.weight = weightValue
            set.completedReps = repsValue
            set.targetReps = repsValue
        }
        isEditing = false
    }
} 