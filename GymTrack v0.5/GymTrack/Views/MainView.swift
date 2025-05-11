//
//  MainView.swift
//  GymTrack
//
//  Created by 郝大力 on 4/10/25.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            WorkoutTemplatesView()
                .tabItem {
                    Label("Templates", systemImage: "list.bullet")
                }
            
            WorkoutView()
                .tabItem {
                    Label("Workout", systemImage: "figure.walk")
                }
            
            NavigationView {
                ExerciseLibraryView()
            }
            .tabItem {
                Label("Exercises", systemImage: "dumbbell.fill")
            }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

#Preview {
    MainView()
} 