import SwiftUI
import Charts

struct ExerciseHistoryChart: View {
    let history: [ExerciseHistory]
    @State private var showingFullDashboard = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 简要图表
            VStack(alignment: .leading, spacing: 8) {
                Text("Training History")
                    .font(.headline)
                
                if history.isEmpty {
                    ContentUnavailableView(
                        "No Data Available",
                        systemImage: "chart.line.downtrend.xyaxis",
                        description: Text("Start training to see your progress")
                    )
                } else {
                    Chart {
                        ForEach(history) { record in
                            ForEach(record.sets) { set in
                                LineMark(
                                    x: .value("Date", record.date),
                                    y: .value("Weight", set.weight)
                                )
                                .foregroundStyle(by: .value("Type", "Weight"))
                                
                                PointMark(
                                    x: .value("Date", record.date),
                                    y: .value("Weight", set.weight)
                                )
                                .foregroundStyle(by: .value("Type", "Weight"))
                            }
                        }
                    }
                    .frame(height: 200)
                    
                    Button(action: { showingFullDashboard = true }) {
                        Text("Show More Data")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .sheet(isPresented: $showingFullDashboard) {
            ExerciseDashboard(history: history)
        }
    }
}

struct ExerciseDashboard: View {
    let history: [ExerciseHistory]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeRange: TimeRange = .month
    
    enum TimeRange: String, CaseIterable {
        case week = "W"
        case month = "M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case year = "Y"
        case all = "All"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 时间范围选择器
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // 主要统计数据
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(title: "Max Weight", value: "100kg", trend: "+5%")
                        StatCard(title: "Volume", value: "2000kg", trend: "+8%")
                        StatCard(title: "Sessions", value: "12", trend: nil)
                    }
                    .padding(.horizontal)
                    
                    // 重量进展图表
                    ChartSection(title: "Weight Progress") {
                        Chart {
                            ForEach(history) { record in
                                ForEach(record.sets) { set in
                                    LineMark(
                                        x: .value("Date", record.date),
                                        y: .value("Weight", set.weight)
                                    )
                                }
                            }
                        }
                        .frame(height: 200)
                    }
                    
                    // 容量图表
                    ChartSection(title: "Volume Trend") {
                        Chart {
                            ForEach(history) { record in
                                let volume = record.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
                                LineMark(
                                    x: .value("Date", record.date),
                                    y: .value("Volume", volume)
                                )
                            }
                        }
                        .frame(height: 200)
                    }
                    
                    // RPE 分布
                    if history.contains(where: { $0.sets.contains(where: { $0.rpe != nil }) }) {
                        ChartSection(title: "RPE Distribution") {
                            Chart {
                                ForEach(history) { record in
                                    ForEach(record.sets) { set in
                                        if let rpe = set.rpe {
                                            BarMark(
                                                x: .value("RPE", rpe),
                                                y: .value("Count", 1)
                                            )
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Exercise Analytics")
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

struct StatCard: View {
    let title: String
    let value: String
    let trend: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .bold()
            
            if let trend = trend {
                Text(trend)
                    .font(.caption)
                    .foregroundColor(trend.hasPrefix("-") ? .red : .green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct ChartSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            content()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    ExerciseHistoryChart(history: [
        ExerciseHistory(
            id: UUID(),
            exerciseId: UUID(),
            date: Date(),
            sets: [
                ExerciseHistory.SetRecord(id: UUID(), weight: 60, reps: 8, rpe: 7),
                ExerciseHistory.SetRecord(id: UUID(), weight: 60, reps: 8, rpe: 8)
            ],
            notes: nil
        )
    ])
} 