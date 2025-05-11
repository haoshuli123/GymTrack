import Foundation

class ExerciseStore: ObservableObject {
    @Published private(set) var exercises: [ExerciseDefinition] = []
    @Published private(set) var history: [UUID: [ExerciseHistory]] = [:]
    
    static let shared = ExerciseStore()
    
    private init() {
        loadExercises()
        loadHistory()
    }
    
    func updateExercise(_ exercise: ExerciseDefinition) {
        if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
            exercises[index] = exercise
            saveExercises()
        }
    }
    
    func addHistory(_ history: ExerciseHistory) {
        var exerciseHistory = self.history[history.exerciseId] ?? []
        exerciseHistory.append(history)
        self.history[history.exerciseId] = exerciseHistory
        saveHistory()
        
        // Update exercise reference weight and target RM if needed
        if var exercise = exercises.first(where: { $0.id == history.exerciseId }) {
            let maxWeight = history.sets.max(by: { $0.weight < $1.weight })?.weight ?? exercise.referenceWeight ?? 0
            if maxWeight > (exercise.referenceWeight ?? 0) {
                exercise.referenceWeight = maxWeight
                // 如果完成的组数中有超过目标RM的，增加目标RM
                let targetRM = exercise.targetRM ?? 0
                if targetRM > 0 && history.sets.contains(where: { $0.reps > targetRM }) {
                    exercise.targetRM = targetRM + 1
                }
                updateExercise(exercise)
            }
        }
    }
    
    func getHistory(for exerciseId: UUID) -> [ExerciseHistory] {
        return history[exerciseId] ?? []
    }
    
    private func loadExercises() {
        if let data = UserDefaults.standard.data(forKey: "Exercises"),
           let decoded = try? JSONDecoder().decode([ExerciseDefinition].self, from: data) {
            exercises = decoded
        }
    }
    
    private func saveExercises() {
        if let encoded = try? JSONEncoder().encode(exercises) {
            UserDefaults.standard.set(encoded, forKey: "Exercises")
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "ExerciseHistory"),
           let decoded = try? JSONDecoder().decode([UUID: [ExerciseHistory]].self, from: data) {
            history = decoded
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "ExerciseHistory")
        }
    }
} 