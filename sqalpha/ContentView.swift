import SwiftUI
import HealthKit
import UserNotifications
import Combine

// Global Data Model for User State
class UserData: ObservableObject {
    @Published var username: String = UserDefaults.standard.string(forKey: "username") ?? ""
    @Published var steps: Int = UserDefaults.standard.integer(forKey: "steps")
    @Published var level: Int = UserDefaults.standard.integer(forKey: "level") == 0 ? 1 : UserDefaults.standard.integer(forKey: "level")

    func saveUserData() {
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(level, forKey: "level")
        UserDefaults.standard.set(steps, forKey: "steps")
        print("Saved data: username = \(username), level = \(level), steps = \(steps)")
    }

    func loadUserData() {
        username = UserDefaults.standard.string(forKey: "username") ?? ""
        level = UserDefaults.standard.integer(forKey: "level") == 0 ? 1 : UserDefaults.standard.integer(forKey: "level")
        steps = UserDefaults.standard.integer(forKey: "steps")
        print("Loaded data: username = \(username), level = \(level), steps = \(steps)")
    }
}

struct ContentView: View {
    @AppStorage("hasSignedUp") private var hasSignedUp = false
    @StateObject private var userData = UserData()

    var body: some View {
        if hasSignedUp {
            DashboardView()
                .environmentObject(userData)
        } else {
            NavigationStack {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    Text("Sidequest")
                        .font(.custom("Silkscreen-Bold", size: 30))
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Spacer().frame(height: 5)

                    // Lines of Text
                    Text("Hey.")
                        .font(.custom("Silkscreen-Regular", size: 18))
                    Text("You live in a world where human vitality is fleeting.")
                        .font(.custom("Silkscreen-Regular", size: 18))
                    Text("It's up to you to better your own health.")
                        .font(.custom("Silkscreen-Regular", size: 18))
                    Text("From now on, every step you take will earn you 1 experience point (XP).")
                        .font(.custom("Silkscreen-Regular", size: 18))
                    Text("Walk to level up your character.")
                        .font(.custom("Silkscreen-Regular", size: 18))
                    Text("You will improve your health, energy, and well-being.")
                        .font(.custom("Silkscreen-Regular", size: 18))
                    Text("Start your Sidequest now.")
                        .font(.custom("Silkscreen-Regular", size: 18))

                    Spacer().frame(height: 5)

                    // Buttons with Arrow Selection
                    VStack(alignment: .leading, spacing: 20) {
                        NavigationLink(destination: CreateUsernameView().environmentObject(userData)) {
                            HStack {
                                Text("▶")
                                    .foregroundColor(.blue)
                                Text("Create Username")
                                    .font(.custom("Silkscreen-Regular", size: 18))
                                    .foregroundColor(.blue)
                                    .underline()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: ExitGameView()) {
                            HStack {
                                Text("▶")
                                    .foregroundColor(.blue)
                                Text("Read Me")
                                    .font(.custom("Silkscreen-Regular", size: 18))
                                    .foregroundColor(.blue)
                                    .underline()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.leading, 5)
                }
                .padding(.horizontal, 30)
            }
        }
    }
}

struct CreateUsernameView: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.presentationMode) var presentationMode
    private let healthStore = HKHealthStore()
    @FocusState private var isUsernameFocused: Bool  // Focus state for the text field

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sidequest")
                .font(.custom("Silkscreen-Bold", size: 30))
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text("Create Username")
                .font(.custom("Silkscreen-Regular", size: 24))
                .padding(.top, 20)
            
            // Updated TextField with focus management
            TextField("Enter username", text: $userData.username)
                .font(.custom("Silkscreen-Regular", size: 16))
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(5)
                .keyboardType(.default)
                .disableAutocorrection(true)
                .focused($isUsernameFocused)  // Use focus state here
                .onSubmit {
                    // Automatically dismiss the keyboard when the user submits
                    isUsernameFocused = false
                    requestHealthKitAuthorization()
                }

            // Button to continue with authorization and save
            Button(action: {
                isUsernameFocused = false  // Dismiss the keyboard on button tap
                requestHealthKitAuthorization()
            }) {
                HStack {
                    Text("▶")
                        .foregroundColor(.blue)
                    Text("Continue")
                        .font(.custom("Silkscreen-Regular", size: 18))
                        .foregroundColor(.blue)
                        .underline()
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
        .padding(.horizontal, 30)
        .onAppear {
            isUsernameFocused = true  // Auto-focus when view appears
        }
    }

    
    private func requestHealthKitAuthorization() {
        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        
        healthStore.requestAuthorization(toShare: nil, read: [stepCountType]) { success, error in
            if success {
                DispatchQueue.main.async {
                    // Save user data and update UI
                    userData.saveUserData()
                    UserDefaults.standard.set(true, forKey: "hasSignedUp")
                    
                    // Set DashboardView as root if authorization succeeds
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        windowScene.windows.first?.rootViewController = UIHostingController(rootView: DashboardView().environmentObject(userData))
                        windowScene.windows.first?.makeKeyAndVisible()
                    }
                    
                    // Enable background delivery
                    self.enableBackgroundDelivery(for: stepCountType)
                }
            } else {
                print("HealthKit authorization failed: \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    private func enableBackgroundDelivery(for type: HKQuantityType) {
        healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
            if success {
                print("Background delivery enabled for step count.")
            } else {
                print("Failed to enable background delivery: \(String(describing: error?.localizedDescription))")
            }
        }
    }
}

struct ExitGameView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Version: Alpha 1.0")
                .font(.custom("Silkscreen-Bold", size: 20))
                .padding(.top, 20)
                .foregroundColor(.blue)
            
            Text("Quick Instructions")
                .font(.custom("Silkscreen-Bold", size: 20))
                .padding(.top, 20)

            Text("Hey, thanks for helping to test this app.")
                .font(.system(size: 14))
                .padding(.top, 20)
            
            Text("1. If you find any bugs, please report them using TestFlight. Other than that, you may now go 'back' to create your username.")
                .font(.system(size: 14))
                .padding(.top, 5)
            
            Text("Note: All data is currently saved locally. Deleting the app will erase all progress.")
                .font(.system(size: 14))
                .padding(.top, 5)

            Spacer()
        }
        .padding(.horizontal, 5)
    }
}

struct DashboardView: View {
    @EnvironmentObject var userData: UserData
    private let healthStore = HKHealthStore()
    @State private var animatedProgress: Double = 0.0
    @State private var lastQueriedSteps: Int = UserDefaults.standard.integer(forKey: "lastQueriedSteps")
    @State private var lastQueriedDate: Date = UserDefaults.standard.object(forKey: "lastQueriedDate") as? Date ?? Calendar.current.startOfDay(for: Date())
    @State private var healthAuthorized: Bool = false
    @State private var hasQueriedOnAppear: Bool = false
    @State private var isQueryInProgress: Bool = false // Track query state to prevent duplicates
    @State private var isBackgroundQueryRunning: Bool = false // Track background query state




    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            
            Text(userData.username)
                .font(.custom("Silkscreen-Regular", size: 20))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, -10)
            
            Text("LEVEL \(String(format: "%02d", userData.level))")
                .font(.custom("Silkscreen-Regular", size: 20))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, -10)
            
            VStack(alignment: .trailing) {
                ProgressView(value: animatedProgress, total: totalXPNeeded())
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .frame(height: 10)
                    .animation(.easeInOut(duration: 1.0), value: animatedProgress)
                
                HStack {
                    Text(levelTitle(for: userData.level))
                        .font(.custom("Silkscreen-Regular", size: 14))
                        .foregroundStyle(levelColor(for: userData.level))
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("\(xpNeeded()) XP NEEDED")
                        .font(.custom("Silkscreen-Regular", size: 14))
                        .frame(alignment: .trailing)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 30)
        .onAppear {
            userData.loadUserData()
            checkHealthKitAuthorization()
        }
        .onChange(of: healthAuthorized) {
            if healthAuthorized && !hasQueriedOnAppear {
                print("Initial query after HealthKit authorization.")
                queryStepCount()
                startBackgroundStepMonitoring()
                hasQueriedOnAppear = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkForNewDayAndQuery()
        }
    }

    private func checkForNewDayAndQuery() {
        let today = Calendar.current.startOfDay(for: Date())
        if lastQueriedDate != today {
            print("New day detected. Resetting lastQueriedSteps.")
            lastQueriedSteps = 0
            lastQueriedDate = today
            UserDefaults.standard.set(0, forKey: "lastQueriedSteps")
            UserDefaults.standard.set(today, forKey: "lastQueriedDate")
        }
        queryStepCount()
    }
    
    private func queryStepCount() {
        guard healthAuthorized, !isQueryInProgress else { return }
        isQueryInProgress = true  // Mark query as in progress
        print("Starting queryStepCount")
        
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            DispatchQueue.main.async {
                defer { self.isQueryInProgress = false }  // Ensure query status is reset
                guard let result = result, let sum = result.sumQuantity() else {
                    print("No step count data available.")
                    return
                }

                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                if steps > self.lastQueriedSteps {
                    let newSteps = steps - self.lastQueriedSteps
                    print("New steps since last query: \(newSteps)")
                    self.updateProgress(with: newSteps)
                    self.lastQueriedSteps = steps
                    UserDefaults.standard.set(steps, forKey: "lastQueriedSteps")
                    UserDefaults.standard.set(Calendar.current.startOfDay(for: Date()), forKey: "lastQueriedDate")
                } else {
                    print("No new steps since last query.")
                }

                self.animatedProgress = self.progressValue()
            }
        }
        
        healthStore.execute(query)
    }
    
    private func updateProgress(with newSteps: Int) {
        print("Updating progress. New steps added: \(newSteps), Current level: \(userData.level), Previous steps: \(userData.steps)")
        
        userData.steps += newSteps
        calculateLevel() // Adjust level based on updated steps
        DispatchQueue.main.async {
            userData.saveUserData()
        }
    }

    private func calculateLevel() {
        let previousLevel = userData.level
        var totalXPNeeded = self.totalXPNeeded()
        
        while Double(userData.steps) >= totalXPNeeded, userData.level < 25 {
            print("Leveling up! Current level: \(userData.level), Steps before leveling: \(userData.steps)")
            
            userData.steps -= Int(totalXPNeeded)
            userData.level += 1
            totalXPNeeded = self.totalXPNeeded()
            
            sendLevelUpNotificationIfNeeded()
        }
        
        if userData.level > previousLevel {
            DispatchQueue.main.async {
                userData.saveUserData()
            }
        }
    }

    private func totalXPNeeded() -> Double {
        return userData.level < 25 ? 100.0 + 50.0 * Double(userData.level - 1) : 0
    }
    
    private func progressValue() -> Double {
        return min(Double(userData.steps), totalXPNeeded())
    }
    
    private func xpNeeded() -> Int {
        return max(Int(totalXPNeeded()) - userData.steps, 0)
    }

    private func checkHealthKitAuthorization() {
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let authorizationStatus = healthStore.authorizationStatus(for: stepCountType)
        
        if authorizationStatus == .sharingAuthorized {
            healthAuthorized = true
        } else {
            healthStore.requestAuthorization(toShare: nil, read: [stepCountType]) { success, error in
                DispatchQueue.main.async {
                    self.healthAuthorized = success
                }
            }
        }
    }

    private func startBackgroundStepMonitoring() {
        guard healthAuthorized, !isBackgroundQueryRunning else { return }
        isBackgroundQueryRunning = true // Prevent additional queries from starting

        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let observerQuery = HKObserverQuery(sampleType: stepCountType, predicate: nil) { [self] _, completionHandler, error in
            guard error == nil else {
                print("Error in observer query: \(error!.localizedDescription)")
                isBackgroundQueryRunning = false // Reset on error
                return
            }
            
            // Start anchored query to fetch new data in the background
            fetchStepDataInBackground()
            completionHandler() // Important to call to avoid termination by iOS
        }
        
        healthStore.execute(observerQuery)
    }


    
    private func fetchStepDataInBackground() {
        guard healthAuthorized, !isBackgroundQueryRunning else { return }
        isBackgroundQueryRunning = true

        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let query = HKAnchoredObjectQuery(
            type: stepCountType,
            predicate: nil,
            anchor: getQueryAnchor(),
            limit: HKObjectQueryNoLimit
        ) { _, samplesOrNil, _, newAnchor, _ in
            DispatchQueue.main.async {
                self.handleNewSteps(from: samplesOrNil, with: newAnchor)
                self.isBackgroundQueryRunning = false
            }
        }

        query.updateHandler = { _, samplesOrNil, _, newAnchor, _ in
            DispatchQueue.main.async {
                self.handleNewSteps(from: samplesOrNil, with: newAnchor)
                self.isBackgroundQueryRunning = false
            }
        }

        healthStore.execute(query)
    }








    private func handleNewSteps(from samplesOrNil: [HKSample]?, with newAnchor: HKQueryAnchor?) {
        DispatchQueue.main.async {
            guard let samples = samplesOrNil as? [HKQuantitySample] else {
                self.isBackgroundQueryRunning = false
                return
            }

            let totalNewSteps = samples.reduce(0) { $0 + Int($1.quantity.doubleValue(for: .count())) }
            if totalNewSteps > 0 {
                self.processNewSteps(totalNewSteps)
                self.saveQueryAnchor(newAnchor)
            }

            self.isBackgroundQueryRunning = false
        }
    }




    private func processNewSteps(_ newSteps: Int) {
        guard newSteps > 0 else { return }
        
        let previousLevel = userData.level
        updateProgress(with: newSteps)

        if userData.level > previousLevel {
            sendLevelUpNotificationIfNeeded()
        }
    }



    private func sendLevelUpNotificationIfNeeded() {
        let content = UNMutableNotificationContent()
        content.title = "Congratulations!"
        content.body = "You've leveled up to level \(userData.level)!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "levelUp-\(userData.level)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            } else {
                print("Level up notification sent: You've leveled up to level \(userData.level)!")
            }
        }
    }

    // Retrieves the saved query anchor for the anchored object query
    private func getQueryAnchor() -> HKQueryAnchor? {
        guard let data = UserDefaults.standard.data(forKey: "stepQueryAnchor") else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
    }

    // Saves the new query anchor to maintain progress for the next background update
    private func saveQueryAnchor(_ anchor: HKQueryAnchor?) {
        guard let anchor = anchor else { return }
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true) {
            UserDefaults.standard.set(data, forKey: "stepQueryAnchor")
        }
    }
}

    
    
    // MARK: - Level Title and Color Functions
    
    private func levelTitle(for level: Int) -> String {
        switch level {
        case 1...4:
            return "Bronze"
        case 5...9:
            return "Silver"
        case 10...14:
            return "Gold"
        case 15...19:
            return "Platinum"
        case 20...24:
            return "Diamond"
        case 25:
            return "MAXED"
        default:
            return ""
        }
    }

    private func levelColor(for level: Int) -> LinearGradient {
        switch level {
        case 1...4:
            return LinearGradient(colors: [.brown.opacity(0.8), .brown], startPoint: .top, endPoint: .bottom)
        case 5...9:
            return LinearGradient(colors: [.gray, .gray.opacity(0.6)], startPoint: .top, endPoint: .bottom)
        case 10...14:
            return LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
        case 15...19:
            return LinearGradient(colors: [.green, .green.opacity(0.6)], startPoint: .top, endPoint: .bottom)
        case 20...24:
            return LinearGradient(colors: [.blue, .blue.opacity(0.6)], startPoint: .top, endPoint: .bottom)
        case 25:
            return LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .top, endPoint: .bottom)
        default:
            return LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
        }
    }
