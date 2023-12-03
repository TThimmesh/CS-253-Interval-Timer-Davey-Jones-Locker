//
//  ContentView.swift
//  Timer
//
//  Created by Taylor Thimmesh on 10/19/23.
//
import AVFoundation
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

import SwiftUI
import AVFoundation

struct TimerTab: View {
    @Binding var acquiredColors: [ColorItem]
    @ObservedObject var selectedColorManager: SelectedColorManager

    // Interval Timer States
    @State private var initialMinutes = ""
    @State private var initialSeconds = ""
    @State private var breakMinutes = ""
    @State private var breakSeconds = ""
    @State private var finalMinutes = ""
    @State private var finalSeconds = ""
    @State private var isTimerRunning = false
    @State private var timerFinished = false
    @State private var remainingTime = 0
    @State private var timer: Timer?
    @State private var currentTimerLabel = ""

    // Enum for Timer Phase
    enum TimerPhase {
        case initial, `break`, final, finished
    }
    @State private var currentPhase: TimerPhase = .initial

    // Audio player property
    private var audioPlayer: AVAudioPlayer?

    init(acquiredColors: Binding<[ColorItem]>, selectedColorManager: SelectedColorManager) {
        self._acquiredColors = acquiredColors
        self.selectedColorManager = selectedColorManager

        // Initialize the audio player with a sound file
        if let soundURL = Bundle.main.url(forResource: "alarmsound", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Error: Couldn't load sound file.")
            }
        }
    }

    var body: some View {
        ZStack {
            Color(timerFinished ? (selectedColorManager.selectedColor ?? .green) : .black)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Timer")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.top, 50)

                if !isTimerRunning && !timerFinished {
                    Group {
                        HStack {
                            TextField("Minutes", text: $initialMinutes)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(5)

                            TextField("Seconds", text: $initialSeconds)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(5)
                        }
                        HStack {
                            TextField("Minutes", text: $breakMinutes)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(5)

                            TextField("Seconds", text: $breakSeconds)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(5)
                        }
                        HStack {
                            TextField("Minutes", text: $finalMinutes)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(5)

                            TextField("Seconds", text: $finalSeconds)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(5)
                        }
                    }
                }

                Button(action: {
                    if timerFinished {
                        resetTimer()
                    } else {
                        if isTimerRunning {
                            stopTimer()
                        } else {
                            startTimer(phase: currentPhase)
                        }
                    }
                }) {
                    Text(isTimerRunning ? "Pause Timer" : (timerFinished ? "Reset Timer" : "Start Timer"))
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(timerFinished ? Color.blue : (isTimerRunning ? Color.red : Color.green))
                        .cornerRadius(10)
                }

                if isTimerRunning || timerFinished {
                    Text("\(remainingTime)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                        .transition(.scale)
                }

                // Display which timer is currently active
                Text(currentTimerLabel)
                    .font(.headline)
                    .foregroundColor(.white)
                    .opacity(isTimerRunning ? 1 : 0)
            }
        }
        .onAppear {
            // Handle on appear logic
            if let selectedColor = selectedColorManager.selectedColor {
                acquiredColors.removeAll { $0.color == selectedColor }
                acquiredColors.insert(ColorItem(color: selectedColor, name: ""), at: 0)
            }
        }
        .onDisappear {
            // Handle on disappear logic
            if timerFinished {
                let experienceGained = calculateExperience()
                selectedColorManager.experience += experienceGained
                selectedColorManager.updateLevel() // Update the level
            }
        }
    }

    func startTimer(phase: TimerPhase) {
        var minutesInput = 0
        var secondsInput = 0

        switch phase {
        case .initial:
            minutesInput = Int(initialMinutes) ?? 0
            secondsInput = Int(initialSeconds) ?? 0
            currentTimerLabel = "Initial Time"
        case .break:
            minutesInput = Int(breakMinutes) ?? 0
            secondsInput = Int(breakSeconds) ?? 0
            currentTimerLabel = "Break Time"
        case .final:
            minutesInput = Int(finalMinutes) ?? 0
            secondsInput = Int(finalSeconds) ?? 0
            currentTimerLabel = "Final Time"
        case .finished:
            return
        }

        let totalSeconds = (minutesInput * 60) + secondsInput

        if totalSeconds > 0 {
            remainingTime = totalSeconds
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if remainingTime > 0 {
                    remainingTime -= 1
                } else {
                    timer?.invalidate()
                    isTimerRunning = false

                    switch currentPhase {
                    case .initial:
                        currentPhase = .break
                        startTimer(phase: .break)
                    case .break:
                        currentPhase = .final
                        startTimer(phase: .final)
                    case .final:
                        currentPhase = .finished
                        timerFinished = true
                        currentTimerLabel = ""
                        audioPlayer?.play() // Play sound when final phase finishes
                    case .finished:
                        break
                    }
                }
            }
            isTimerRunning = true
        }
    }

    func stopTimer() {
        timer?.invalidate()
        isTimerRunning = false
        currentTimerLabel = ""
    }

    func resetTimer() {
        stopTimer()
        timerFinished = false
        remainingTime = 0
        initialMinutes = ""
        initialSeconds = ""
        breakMinutes = ""
        breakSeconds = ""
        finalMinutes = ""
        finalSeconds = ""
        currentPhase = .initial
        currentTimerLabel = ""
    }

    // Function to calculate experience based on your logic
    func calculateExperience() -> Double {
        // Your logic for calculating experience
        let initialExperience = (Double((Int(initialMinutes) ?? 0) * 60 + (Int(initialSeconds) ?? 0)) * 0.15)
        let breakExperience = (Double((Int(breakMinutes) ?? 0) * 60 + (Int(breakSeconds) ?? 0)) * 0.1) // Assuming less experience for break
        let finalExperience = (Double((Int(finalMinutes) ?? 0) * 60 + (Int(finalSeconds) ?? 0)) * 0.15)

        return initialExperience + breakExperience + finalExperience
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

