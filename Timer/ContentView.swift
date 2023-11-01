//
//  ContentView.swift
//  Timer
//
//  Created by Taylor Thimmesh on 10/19/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var lootBox = LootBox()
    @ObservedObject private var selectedColorManager = SelectedColorManager()

    var body: some View {
        TabView {
            TimerTab(acquiredColors: $lootBox.acquiredColors, selectedColorManager: selectedColorManager)
                .tabItem {
                    Image(systemName: "hourglass")
                    Text("Timer")
                }
                .tag(0)

            LootBoxTab(lootBox: lootBox)
                .tabItem {
                    Image(systemName: "gift")
                    Text("Loot Box")
                }
                .tag(1)

            InventoryTab(acquiredColors: $lootBox.acquiredColors, selectedColorManager: selectedColorManager)
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Inventory")
                }
                .tag(2)

            ProfileTab()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(3)
        }
        .environmentObject(selectedColorManager)
    }
}

class LootBox: ObservableObject {
    @Published var acquiredColors: [ColorItem] = []

    func randomColor() -> ColorItem? {
        // Here, you can implement logic to select a random color or item
        // For simplicity, I'm using predefined colors
        let predefinedColors = [
            ColorItem(color: .red, name: "Red"),
            ColorItem(color: .blue, name: "Blue"),
            ColorItem(color: .green, name: "Green"),
            ColorItem(color: .yellow, name: "Yellow"),
            ColorItem(color: .orange, name: "Orange"),
            ColorItem(color: .purple, name: "Purple"),
            ColorItem(color: .pink, name: "Pink"),
            ColorItem(color: .gray, name: "Gray"),
            ColorItem(color: .brown, name: "Brown"),
            ColorItem(color: .black, name: "Black"),
        ]

        // Check if the color already exists in acquiredColors
        let uniqueColors = predefinedColors.filter { colorItem in
            !acquiredColors.contains { $0.color == colorItem.color }
        }

        return uniqueColors.randomElement()
    }
}


class SelectedColorManager: ObservableObject {
    @Published var selectedColor: Color?
    @Published var experience: Double = 0
    @Published var level: Int = 1

    // This computed property calculates the maximum experience required for the next level
    var maxExperienceForNextLevel: Double {
        return Double(level) * 20
    }

    // Function to update the level and experience bar
    func updateLevel() {
        if experience >= maxExperienceForNextLevel {
            level += 1
        }
    }
}




struct ColorItem: Identifiable {
    var id = UUID()
    var color: Color
    var name: String
}

struct TimerTab: View {
    @Binding var acquiredColors: [ColorItem]
    @ObservedObject var selectedColorManager: SelectedColorManager
    @State private var time = ""
    @State private var isTimerRunning = false
    @State private var remainingTime = 0
    @State private var timer: Timer?
    @State private var timerFinished = false

    var body: some View {
        ZStack {
            Color(timerFinished ? (selectedColorManager.selectedColor ?? .green) : .black)
                .ignoresSafeArea()

            VStack {
                Text("Timer")
                    .font(.largeTitle)
                    .foregroundColor(.white)

                if !timerFinished {
                    TextField("Enter time in seconds", text: $time)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .foregroundColor(.black)
                        .padding()
                }

                Button(action: {
                    if timerFinished {
                        resetTimer()
                    } else {
                        if isTimerRunning {
                            stopTimer()
                        } else {
                            startTimer()
                        }
                    }
                }) {
                    Text(timerFinished ? "Restart Timer" : (isTimerRunning ? "Stop Timer" : "Start Timer"))
                        .font(.title)
                        .foregroundColor(.white)
                }

                Text(timerFinished ? "Timer Finished!" : "Time remaining: \(remainingTime) seconds")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            if let selectedColor = selectedColorManager.selectedColor {
                acquiredColors.removeAll { $0.color == selectedColor }
                acquiredColors.insert(ColorItem(color: selectedColor, name: ""), at: 0)
            }
        }
        .onDisappear {
            // Calculate and accumulate experience when the timer stops
            if timerFinished {
                let timeUsed = Double(time) ?? 0
                let experienceGained = timeUsed * 0.15 // 0.15 experience per second
                selectedColorManager.experience += experienceGained
                selectedColorManager.updateLevel() // Update the level
            }
        }
    }

    func startTimer() {
        if isTimerRunning {
            return
        }

        if let inputTime = Int(time) {
            remainingTime = inputTime
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if remainingTime > 0 {
                    remainingTime -= 1
                } else {
                    timer?.invalidate()
                    isTimerRunning = false
                    timerFinished = true
                }
            }
            isTimerRunning = true
        }
    }

    func stopTimer() {
        timer?.invalidate()
        isTimerRunning = false
    }

    func resetTimer() {
        stopTimer()
        timerFinished = false
        remainingTime = 0
        time = ""
    }
}

struct ProfileTab: View {
    @EnvironmentObject var selectedColorManager: SelectedColorManager

    // Replace "profileImage" with your user's profile image
    var profileImage: UIImage? = UIImage(named: "lonnie.jpeg")
    var username: String = "@TheWizardProfessor" // Replace with the user's username

    var body: some View {
        VStack {
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .padding()
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .padding()
            }

            Text(username) // Display the username
                .font(.title)
                .padding()

            Divider() // Add a divider line

            Text("Level \(selectedColorManager.level)") // Display the level

            // Experience bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 20)
                    .cornerRadius(10)

                Rectangle()
                    .fill(Color.blue)
                    .frame(width: experienceBarWidth(), height: 20)
                    .cornerRadius(10)
            }
        }
    }

    func experienceBarWidth() -> CGFloat {
        let progress = selectedColorManager.experience / Double(selectedColorManager.level * 20)
        return CGFloat(progress) * 500 // Adjust the width as needed
    }
}

struct InventoryTab: View {
    @Binding var acquiredColors: [ColorItem]
    @ObservedObject var selectedColorManager: SelectedColorManager

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                    ForEach(acquiredColors) { colorItem in
                        let color = colorItem.color
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(color)
                                .frame(maxWidth: .infinity, maxHeight: 100)
                                .cornerRadius(10)
                                .onTapGesture {
                                    selectedColorManager.selectedColor = color
                                }

                            if selectedColorManager.selectedColor == color {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(10)
            }
            .navigationTitle("Inventory")
        }
    }
}

struct LootBoxTab: View {
    @ObservedObject var lootBox: LootBox
    @State private var acquiredColor: ColorItem? = nil
    @State private var showingAcquiredColorAlert = false

    var body: some View {
        VStack {
            // Add your spinning wheel UI or other elements here

            // Spin button
            Button(action: {
                acquiredColor = lootBox.randomColor()
                showingAcquiredColorAlert = true
                if let acquiredColor = acquiredColor {
                    lootBox.acquiredColors.insert(acquiredColor, at: 0)
                }
            }) {
                Text("Spin the Wheel")
                    .font(.title)
                    .foregroundColor(.black)
            }
        }
        .alert(isPresented: $showingAcquiredColorAlert) {
            Alert(
                title: Text("Acquired Color"),
                message: Text(acquiredColor?.name ?? "No color acquired"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

