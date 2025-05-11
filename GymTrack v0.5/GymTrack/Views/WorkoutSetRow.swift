import SwiftUI

struct WorkoutSetRow: View {
    @Binding var set: WorkoutSet
    @State private var showingRPEPicker = false
    
    var body: some View {
        HStack {
            TextField("Weight", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            
            Text("kg")
                .foregroundColor(.secondary)
            
            Spacer()
            
            Stepper(
                "\(set.completedReps)/\(set.targetReps)",
                value: $set.completedReps,
                in: 0...set.targetReps
            )
            
            Button(action: { showingRPEPicker = true }) {
                Text(set.rpe.map { "RPE \($0)" } ?? "RPE")
                    .foregroundColor(set.rpe == nil ? .secondary : .blue)
            }
            .sheet(isPresented: $showingRPEPicker) {
                NavigationView {
                    List(1...10, id: \.self) { rpe in
                        Button(action: {
                            set.rpe = rpe
                            showingRPEPicker = false
                        }) {
                            HStack {
                                Text("RPE \(rpe)")
                                Spacer()
                                if set.rpe == rpe {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .navigationTitle("Select RPE")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingRPEPicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
} 