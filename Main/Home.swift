
import SwiftUI
import LocalAuthentication
import WebKit
import Network
import AppsFlyerLib
import FirebaseMessaging
import FirebaseCore
import Combine

struct AppKeys {
    static let devkey = "brXcPmQsjZDcmwaaDVBxUa"
    static let appId = "6753987614"
}

// Data Model
struct PasswordEntry: Identifiable, Equatable, Codable {
    let id: UUID
    var service: String
    var username: String
    var password: String
    var isFavorite: Bool = false
    var usageCount: Int = 0
    var allowFaceID: Bool = false
    
    init(id: UUID = UUID(), service: String, username: String, password: String, isFavorite: Bool = false, usageCount: Int = 0, allowFaceID: Bool = false) {
        self.id = id
        self.service = service
        self.username = username
        self.password = password
        self.isFavorite = isFavorite
        self.usageCount = usageCount
        self.allowFaceID = allowFaceID
    }
}

// Colors
let darkGradient = LinearGradient(gradient: Gradient(colors: [Color(hex: "#0D0D1A"), Color(hex: "#1A0D2E")]), startPoint: .top, endPoint: .bottom)
let bubbleGradient = LinearGradient(gradient: Gradient(colors: [Color(hex: "#FF4FBF"), Color(hex: "#B84FFF")]), startPoint: .topLeading, endPoint: .bottomTrailing)
let glowColor = Color(hex: "#4FFFE0")
let highlightColor = Color.white.opacity(0.3)
let backgroundBubbleColor1 = Color(hex: "#FF4FBF").opacity(0.2)
let backgroundBubbleColor2 = Color(hex: "#B84FFF").opacity(0.2)
let backgroundBubbleColor3 = Color(hex: "#4FFFE0").opacity(0.2)

// Extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Conditional modifier extension
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// Floating Bubbles Background
struct FloatingBubbles: View {
    @State private var positions: [CGPoint] = []
    let bubbleCount = 20
    let bubbleSizes: [CGFloat] = [20, 30, 40, 50, 60]
    let colors: [Color] = [backgroundBubbleColor1, backgroundBubbleColor2, backgroundBubbleColor3]
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<bubbleCount, id: \.self) { index in
                Circle()
                    .fill(colors.randomElement()!)
                    .frame(width: bubbleSizes.randomElement()!, height: bubbleSizes.randomElement()!)
                    .position(positions.count > index ? positions[index] : randomPosition(in: geometry.size))
                    .opacity(0.5)
                    .blur(radius: 2)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            positions = (0..<bubbleCount).map { _ in CGPoint.zero }
            animateBubbles(in: UIScreen.main.bounds.size)
        }
    }
    
    private func randomPosition(in size: CGSize) -> CGPoint {
        CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat.random(in: 0...size.height))
    }
    
    private func animateBubbles(in size: CGSize) {
        for index in 0..<bubbleCount {
            withAnimation(Animation.linear(duration: Double.random(in: 10...20)).repeatForever(autoreverses: true)) {
                positions[index] = randomPosition(in: size)
            }
        }
    }
}

// Bubble View
struct BubbleView: View {
    var size: CGFloat = 80
    var content: String?
    var icon: String?
    var onTap: (() -> Void)?
    @State private var isBouncing = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(bubbleGradient)
                .frame(width: size, height: size)
                .shadow(color: glowColor.opacity(0.8), radius: 8, x: 0, y: 4)
            
            // Glossy highlight
            Circle()
                .fill(highlightColor)
                .frame(width: size * 0.5, height: size * 0.5)
                .offset(x: -size * 0.25, y: -size * 0.25)
                .blendMode(.overlay)
            
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: size * 0.35, weight: .bold))
            } else if let content = content {
                Text(content)
                    .foregroundColor(.white)
                    .font(.system(size: size * 0.25, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(10)
            }
        }
        .scaleEffect(isBouncing ? 1.1 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.4), value: isBouncing)
        .if(onTap != nil) { view in
            view.onTapGesture {
                withAnimation {
                    isBouncing = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isBouncing = false
                    onTap?()
                }
            }
        }
    }
}

// Password Card View
struct PasswordCard: View {
    let entry: PasswordEntry
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(bubbleGradient)
                    .frame(width: 60, height: 60)
                    .shadow(color: glowColor.opacity(0.6), radius: 4)
                
                if let icon = serviceIcon(for: entry.service) {
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: 24, weight: .bold))
                } else {
                    Text(entry.service.first.map { String($0) } ?? "?")
                        .foregroundColor(.white)
                        .font(.system(size: 28, weight: .bold))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.service)
                    .foregroundColor(.white)
                    .font(.headline.bold())
                
                Text(entry.username)
                    .foregroundColor(glowColor.opacity(0.8))
                    .font(.subheadline)
            }
            
            Spacer()
            
            if entry.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05).gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(glowColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: glowColor.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    func serviceIcon(for service: String) -> String? {
        switch service.lowercased() {
        case "facebook": return "f.square"
        case "gmail": return "envelope"
        case "amazon": return "a.square"
        default: return nil
        }
    }
}

// Main View with Tabs
struct MainView: View {
    @State private var passwords: [PasswordEntry]
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "savedPasswords"),
           let decoded = try? JSONDecoder().decode([PasswordEntry].self, from: data) {
            _passwords = State(initialValue: decoded)
        } else {
            _passwords = State(initialValue: [])
        }
    }
    
    var body: some View {
        ZStack {
            FloatingBubbles()
            
            TabView {
                HomeView(passwords: $passwords)
                    .tabItem {
                        Label("Vault", systemImage: "lock.circle")
                    }
                
                StatisticsView(passwords: passwords)
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
            .accentColor(glowColor)
            .preferredColorScheme(.dark)
            .onChange(of: passwords) { newValue in
                if let encoded = try? JSONEncoder().encode(newValue) {
                    UserDefaults.standard.set(encoded, forKey: "savedPasswords")
                }
            }
        }
    }
}

// Home View (Vault Overview)
struct HomeView: View {
    @Binding var passwords: [PasswordEntry]
    @State private var selectedFilter: String = "All"
    @State private var showingAdd = false
    
    var filteredPasswords: [PasswordEntry] {
        var filtered = passwords
        switch selectedFilter {
        case "Most used":
            filtered = filtered.sorted { $0.usageCount > $1.usageCount }
        case "Favorites":
            filtered = filtered.filter { $0.isFavorite }
        default:
            break
        }
        return filtered
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Rectangle()
                    .fill(darkGradient)
                    .ignoresSafeArea()
                
                FloatingBubbles()
                
                VStack(spacing: 20) {
                    // Top section
                    Text("My Bubble Vault")
                        .foregroundColor(.white)
                        .font(.largeTitle.bold())
                        .padding(.top, 20)
                    
                    HStack(spacing: 12) {
                        FilterBubble(title: "All", selected: $selectedFilter)
                        FilterBubble(title: "Most used", selected: $selectedFilter)
                        FilterBubble(title: "Favorites", selected: $selectedFilter)
                    }
                    .padding(.horizontal)
                    
                    // Middle section
                    ScrollView {
                        if filteredPasswords.isEmpty {
                            VStack(spacing: 20) {
                                Spacer()
                                BubbleView(size: 180, content: "No passwords yet\nTap + to add")
                                Spacer()
                            }
                        } else {
                            LazyVStack(spacing: 15) {
                                ForEach(filteredPasswords) { entry in
                                    NavigationLink(destination: PasswordDetailView(entry: binding(for: entry), passwords: $passwords)) {
                                        PasswordCard(entry: entry)
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 16)
                            .animation(.easeInOut(duration: 0.3), value: filteredPasswords)
                        }
                    }
                    
                    // Bottom section
                    HStack {
                        Spacer()
                        BubbleView(size: 70, icon: "plus", onTap: {
                            showingAdd = true
                        })
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAdd) {
                AddPasswordView(passwords: $passwords, isPresented: $showingAdd)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func binding(for entry: PasswordEntry) -> Binding<PasswordEntry> {
        guard let index = passwords.firstIndex(where: { $0.id == entry.id }) else {
            fatalError("Entry not found")
        }
        return $passwords[index]
    }
    
    func serviceIcon(for service: String) -> String? {
        switch service.lowercased() {
        case "facebook": return "f.square"
        case "gmail": return "envelope"
        case "amazon": return "a.square"
        default: return nil
        }
    }
}

struct FilterBubble: View {
    let title: String
    @Binding var selected: String
    
    var body: some View {
        Button(action: { selected = title }) {
            Text(title)
                .foregroundColor(selected == title ? .black : .white)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .background {
            if selected == title {
                Color.white
            } else {
                bubbleGradient
            }
        }
        .clipShape(Capsule())
        .shadow(color: glowColor.opacity(0.5), radius: 4)
    }
}

struct PasswordDetailView: View {
    @Binding var entry: PasswordEntry
    @Binding var passwords: [PasswordEntry]
    @State private var showingPassword = false
    @State private var isDeleted = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(darkGradient)
                .ignoresSafeArea()
            
            FloatingBubbles()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text(entry.service)
                        .foregroundColor(.white)
                        .font(.largeTitle.bold())
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(glowColor)
                            Text("Username: \(entry.username)")
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(glowColor)
                            Text("Password: \(showingPassword ? entry.password : "••••••••")")
                                .foregroundColor(.white)
                            Spacer()
                            Button("Show") {
                                if entry.allowFaceID {
                                    authenticateWithBiometrics {
                                        showingPassword.toggle()
                                    }
                                } else {
                                    showingPassword.toggle()
                                }
                            }
                            .foregroundColor(glowColor)
                            .font(.subheadline.bold())
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    HStack(spacing: 20) {
                        BubbleView(size: 70, icon: "doc.on.doc", onTap: {
                            UIPasteboard.general.string = entry.password
                            entry.usageCount += 1
                        })
                        
                        BubbleView(size: 70, icon: entry.isFavorite ? "heart.fill" : "heart", onTap: {
                            entry.isFavorite.toggle()
                        })
                    }
                    
                    HStack(spacing: 20) {
                        Button("Edit") {
                            
                        }
                        .foregroundColor(glowColor)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button("Delete") {
                            if let index = passwords.firstIndex(where: { $0.id == entry.id }) {
                                withAnimation {
                                    passwords.remove(at: index)
                                }
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button("Share") {
                            
                        }
                        .foregroundColor(glowColor)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    func authenticateWithBiometrics(completion: @escaping () -> Void) {
        let context = LAContext()
        var error: NSError? = nil
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to view password"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        completion()
                    } else {
                        print("Authentication failed")
                    }
                }
            }
        } else {
            completion()
        }
    }
}

// Add Password View
struct AddPasswordView: View {
    @Binding var passwords: [PasswordEntry]
    @Binding var isPresented: Bool
    @State private var service = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isFavorite = false
    @State private var allowFaceID = false
    @State private var showingGenerator = false
    
    var isFormValid: Bool {
        !service.isEmpty && !username.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Rectangle()
                    .fill(darkGradient)
                    .ignoresSafeArea()
                
                FloatingBubbles()
                
                Form {
                    Section(header: Text("Details").foregroundColor(glowColor)) {
                        TextField("Service name", text: $service)
                            .foregroundColor(.white)
                        
                        TextField("Username/Email", text: $username)
                            .foregroundColor(.white)
                        
                        HStack {
                            TextField("Password", text: $password)
                                .foregroundColor(.white)
                            Button("Generate") {
                                showingGenerator = true
                            }
                            .foregroundColor(glowColor)
                        }
                    }
                    
                    Section(header: Text("Options").foregroundColor(glowColor)) {
                        Toggle("Favorite", isOn: $isFavorite)
                            .toggleStyle(SwitchToggleStyle(tint: glowColor))
                            .foregroundColor(.white)
                        
                        Toggle("Allow Face ID / Touch ID", isOn: $allowFaceID)
                            .toggleStyle(SwitchToggleStyle(tint: glowColor))
                            .foregroundColor(.white)
                    }
                    
                    Section {
                        HStack(spacing: 20) {
                            Button("Cancel") {
                                isPresented = false
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Button("Create") {
                                if isFormValid {
                                    passwords.append(PasswordEntry(service: service, username: username, password: password, isFavorite: isFavorite, allowFaceID: allowFaceID))
                                    isPresented = false
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background {
                                if isFormValid {
                                    bubbleGradient
                                } else {
                                    Color.gray
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .disabled(!isFormValid)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Add Password")
                .navigationBarTitleDisplayMode(.inline)
            }
            .sheet(isPresented: $showingGenerator) {
                GeneratorView(onGenerate: { generated in
                    password = generated
                })
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Generator View
struct GeneratorView: View {
    @State private var includeUppercase = true
    @State private var includeLowercase = true
    @State private var includeNumbers = true
    @State private var includeSymbols = true
    @State private var length: Double = 12
    @State private var generatedPassword = ""
    var onGenerate: ((String) -> Void)?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Rectangle()
                    .fill(darkGradient)
                    .ignoresSafeArea()
                
                FloatingBubbles()
                
                Form {
                    Section(header: Text("Character Types").foregroundColor(glowColor)) {
                        Toggle("Uppercase", isOn: $includeUppercase)
                            .toggleStyle(SwitchToggleStyle(tint: glowColor))
                            .foregroundColor(.white)
                        Toggle("Lowercase", isOn: $includeLowercase)
                            .toggleStyle(SwitchToggleStyle(tint: glowColor))
                            .foregroundColor(.white)
                        Toggle("Numbers", isOn: $includeNumbers)
                            .toggleStyle(SwitchToggleStyle(tint: glowColor))
                            .foregroundColor(.white)
                        Toggle("Symbols", isOn: $includeSymbols)
                            .toggleStyle(SwitchToggleStyle(tint: glowColor))
                            .foregroundColor(.white)
                    }
                    
                    Section(header: Text("Length").foregroundColor(glowColor)) {
                        Slider(value: $length, in: 8...20, step: 1)
                            .accentColor(glowColor)
                        Text("Length: \(Int(length))")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    if !generatedPassword.isEmpty {
                        Section(header: Text("Generated Password").foregroundColor(glowColor)) {
                            Text(generatedPassword)
                                .foregroundColor(.white)
                                .font(.system(size: 24, weight: .bold))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    
                    Section {
                        Button("Generate") {
                            generatedPassword = generatePassword()
                            onGenerate?(generatedPassword)
                        }
                        .foregroundColor(glowColor)
                        .frame(maxWidth: .infinity)
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Password Generator")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(glowColor)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    func generatePassword() -> String {
        var characters = ""
        if includeUppercase { characters += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        if includeLowercase { characters += "abcdefghijklmnopqrstuvwxyz" }
        if includeNumbers { characters += "0123456789" }
        if includeSymbols { characters += "!@#$%^&*()_+-=[]{}|;:,.<>?" }
        
        guard !characters.isEmpty else { return "" }
        
        return String((0..<Int(length)).map { _ in characters.randomElement()! })
    }
}

// Statistics View
struct StatisticsView: View {
    let passwords: [PasswordEntry]
    
    var strongCount: Int { passwords.filter { $0.password.count > 12 }.count }
    var mediumCount: Int { passwords.filter { 8 <= $0.password.count && $0.password.count <= 12 }.count }
    var weakCount: Int { passwords.filter { $0.password.count < 8 }.count }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(darkGradient)
                .ignoresSafeArea()
            
            FloatingBubbles()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Statistics")
                        .foregroundColor(.white)
                        .font(.largeTitle.bold())
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        StatRow(title: "Total passwords", value: "\(passwords.count)", color: .white)
                        StatRow(title: "Strong", value: "\(strongCount)", color: .green)
                        StatRow(title: "Medium", value: "\(mediumCount)", color: .yellow)
                        StatRow(title: "Weak", value: "\(weakCount)", color: .red)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    // Placeholder for pyramid chart
                    Text("Password Strength Pyramid")
                        .foregroundColor(glowColor)
                        .font(.headline)
                        .padding(.top, 20)
                    
                    // Simple bar chart placeholder
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(.red)
                            .frame(width: 50, height: CGFloat(weakCount * 20))
                            .cornerRadius(4)
                        Rectangle()
                            .fill(.yellow)
                            .frame(width: 50, height: CGFloat(mediumCount * 20))
                            .cornerRadius(4)
                        Rectangle()
                            .fill(.green)
                            .frame(width: 50, height: CGFloat(strongCount * 20))
                            .cornerRadius(4)
                    }
                    .frame(height: 200)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .foregroundColor(color)
                .bold()
        }
    }
}

// Settings View
struct SettingsView: View {
    @State private var enableBiometrics = true
    @State private var enableMasterPassword = false
    @State private var enableiCloudSync = true
    
    @State var openPrivacyPolicy = false
    @State var openContactUs = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(darkGradient)
                .ignoresSafeArea()
            
            FloatingBubbles()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Settings")
                        .foregroundColor(.white)
                        .font(.largeTitle.bold())
                        .padding(.top, 20)
                    
                    BubbleView(size: 120, icon: "person.circle")
                        .padding(.bottom, 8)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Face ID / Touch ID", isOn: $enableBiometrics)
                            .toggleStyle(SwitchToggleStyle(tint: glowColor))
                            .foregroundColor(.white)
                        
                        Toggle("Master Password", isOn: $enableMasterPassword)
                            .toggleStyle(SwitchToggleStyle(tint: glowColor))
                            .foregroundColor(.white)
                        
                        Toggle("iCloud Sync", isOn: $enableiCloudSync)
                            .toggleStyle(SwitchToggleStyle(tint: glowColor))
                            .foregroundColor(.white)
                        
                        Button {
                            openPrivacyPolicy = true
                        } label: {
                            HStack {
                                Text("Privacy Policy")
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                        
                        Button {
                            openContactUs = true
                        } label: {
                            HStack {
                                Text("Contact Us")
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
                .sheet(isPresented: $openPrivacyPolicy, content: {
                    VStack {
                        HStack {
                            Button {
                                openPrivacyPolicy = false
                            } label: {
                                Image(systemName: "xmark")
                            }
                            Spacer()
                            Text("Privacy Policy")
                            Spacer()
                            
                            Image(systemName: "close").opacity(0)
                        }
                        .padding()
                        ViewForPolicies(destination: URL(string: "https://bubbllepasswords.com/privacy-policy.html")!)
                    }
                })
                .sheet(isPresented: $openContactUs, content: {
                    HStack {
                        Button {
                            openContactUs = false
                        } label: {
                            Image(systemName: "xmark")
                        }
                        Spacer()
                        Text("Contact Us")
                        Spacer()
                        
                        Image(systemName: "close").opacity(0)
                    }
                    .padding()
                    ViewForPolicies(destination: URL(string: "https://bubbllepasswords.com/support.html")!)
                })
                .preferredColorScheme(.dark)
            }
        }
    }
}

struct ViewForPolicies: UIViewRepresentable {
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
    init(destination: URL) {
        self.destination = destination
    }
    
    var destination: URL
    
    func makeUIView(context: Context) -> some UIView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        let mainWebView = WKWebView(frame: .zero, configuration: config)
        mainWebView.load(URLRequest(url: destination))
        return mainWebView
    }
    
}

class WebNavigationController: NSObject, WKNavigationDelegate, WKUIDelegate {
    private let sessionTracker: WebSessionTracker
    private var redirectCount: Int = 0
    private let maxRedirectLimit: Int = 70
    private var lastValidUrl: URL?

    init(tracker: WebSessionTracker) {
        self.sessionTracker = tracker
        super.init()
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let protectionSpace = challenge.protectionSpace
        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let serverTrust = protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }

        let newWebView = WebViewFactory.createWebView(with: configuration)
        configureWebView(newWebView)
        attachWebView(newWebView)

        sessionTracker.secondaryWebViews.append(newWebView)
        if validateRequest(for: navigationAction.request, in: newWebView) {
            newWebView.load(navigationAction.request)
        }
        return newWebView
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let injectionScript = """
            var metaTag = document.createElement('meta');
            metaTag.name = 'viewport';
            metaTag.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.head.appendChild(metaTag);
            var styleTag = document.createElement('style');
            styleTag.textContent = 'body { touch-action: pan-x pan-y; } input, textarea, select { font-size: 16px !important; maximum-scale=1.0; }';
            document.head.appendChild(styleTag);
            document.addEventListener('gesturestart', (event) => event.preventDefault());
        """
        webView.evaluateJavaScript(injectionScript) { _, error in
            if let error = error {
                print("JavaScript injection error: \(error)")
            }
        }
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirectLimit {
            webView.stopLoading()
            if let fallbackUrl = lastValidUrl {
                webView.load(URLRequest(url: fallbackUrl))
            }
            return
        }
        lastValidUrl = webView.url
        persistSession(from: webView)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let fallbackUrl = lastValidUrl {
            webView.load(URLRequest(url: fallbackUrl))
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if url.absoluteString.starts(with: "http") || url.absoluteString.starts(with: "https") {
            lastValidUrl = url
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        }
    }

    private func configureWebView(_ webView: WKWebView) {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        sessionTracker.mainWebView.addSubview(webView)

        let edgeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        edgeGesture.edges = .left
        webView.addGestureRecognizer(edgeGesture)
    }

    private func attachWebView(_ webView: WKWebView) {
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: sessionTracker.mainWebView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: sessionTracker.mainWebView.trailingAnchor),
            webView.topAnchor.constraint(equalTo: sessionTracker.mainWebView.topAnchor),
            webView.bottomAnchor.constraint(equalTo: sessionTracker.mainWebView.bottomAnchor)
        ])
    }

    private func validateRequest(for request: URLRequest, in webView: WKWebView) -> Bool {
        guard let urlString = request.url?.absoluteString, !urlString.isEmpty, urlString != "about:blank" else {
            return false
        }
        return true
    }

    private func persistSession(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            var cookieMap: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieMap[cookie.domain] ?? [:]
                domainCookies[cookie.name] = cookie.properties
                cookieMap[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieMap, forKey: "session_cookies")
        }
    }

    @objc private func handleSwipeGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard gesture.state == .ended, let webView = gesture.view as? WKWebView else { return }
        if webView.canGoBack {
            webView.goBack()
        } else if let lastWebView = sessionTracker.secondaryWebViews.last, webView == lastWebView {
            sessionTracker.clearSecondaryWebViews(currentUrl: nil)
        }
    }
}

struct WebViewFactory {
    static func createWebView(with configuration: WKWebViewConfiguration? = nil) -> WKWebView {
        let config = configuration ?? buildConfiguration()
        return WKWebView(frame: .zero, configuration: config)
    }

    private static func buildConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.preferences = createPreferences()
        config.defaultWebpagePreferences = createWebpagePreferences()
        config.requiresUserActionForMediaPlayback = false
        return config
    }

    private static func createPreferences() -> WKPreferences {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        return preferences
    }

    private static func createWebpagePreferences() -> WKWebpagePreferences {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        return preferences
    }

    static func clearSecondaryWebViews(_ mainWebView: WKWebView, _ secondaryWebViews: [WKWebView], currentUrl: URL?) -> Bool {
        if !secondaryWebViews.isEmpty {
            secondaryWebViews.forEach { $0.removeFromSuperview() }
            if let url = currentUrl {
                mainWebView.load(URLRequest(url: url))
            }
            return true
        } else if mainWebView.canGoBack {
            mainWebView.goBack()
            return false
        }
        return false
    }
}

class WebSessionTracker: ObservableObject {
    
    @Published var mainWebView: WKWebView!
    @Published var secondaryWebViews: [WKWebView] = []

    func initializeMainWebView() {
        mainWebView = WebViewFactory.createWebView()
        mainWebView.scrollView.minimumZoomScale = 1.0
        mainWebView.scrollView.maximumZoomScale = 1.0
        mainWebView.scrollView.bouncesZoom = false
        mainWebView.allowsBackForwardNavigationGestures = true
    }

    func restoreSession() {
        guard let cookieData = UserDefaults.standard.dictionary(forKey: "session_cookies") as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = mainWebView.configuration.websiteDataStore.httpCookieStore

        cookieData.values.flatMap { $0.values }.forEach { cookieProps in
            if let cookie = HTTPCookie(properties: cookieProps as! [HTTPCookiePropertyKey: Any]) {
                cookieStore.setCookie(cookie)
            }
        }
    }

    func reloadMainWebView() {
        mainWebView.reload()
    }

    func clearSecondaryWebViews(currentUrl: URL?) {
        if let lastWebView = secondaryWebViews.last {
            lastWebView.removeFromSuperview()
            secondaryWebViews.removeLast()
            if let url = currentUrl {
                mainWebView.load(URLRequest(url: url))
            }
        } else if mainWebView.canGoBack {
            mainWebView.goBack()
        }
    }

    func closeLastSecondaryWebView() {
        if let lastWebView = secondaryWebViews.last {
            lastWebView.removeFromSuperview()
            secondaryWebViews.removeLast()
        }
    }
}

struct WebViewContainer: UIViewRepresentable {
    let targetUrl: URL
    @StateObject private var tracker = WebSessionTracker()

    func makeUIView(context: Context) -> WKWebView {
        tracker.initializeMainWebView()
        tracker.mainWebView.uiDelegate = context.coordinator
        tracker.mainWebView.navigationDelegate = context.coordinator
        tracker.restoreSession()
        tracker.mainWebView.load(URLRequest(url: targetUrl))
        return tracker.mainWebView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> WebNavigationController {
        WebNavigationController(tracker: tracker)
    }
}

struct WebInterface: View {
    @State private var urlString: String = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            if let url = URL(string: urlString) {
                WebViewContainer(targetUrl: url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            urlString = UserDefaults.standard.string(forKey: "temp_url") ?? UserDefaults.standard.string(forKey: "persistent_url") ?? ""
            if UserDefaults.standard.string(forKey: "temp_url") != nil {
                UserDefaults.standard.set(nil, forKey: "temp_url")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .webNavigation)) { _ in
            if let tempUrl = UserDefaults.standard.string(forKey: "temp_url"), !tempUrl.isEmpty {
                urlString = tempUrl
                UserDefaults.standard.set(nil, forKey: "temp_url")
            }
        }
    }
}

class AppLauncher: ObservableObject {
    @Published var currentPhase: AppPhase = .initializing
    @Published var targetUrl: URL?
    @Published var showNotificationPrompt = false

    private var analyticsData: [AnyHashable: Any] = [:]
    private var isFirstLaunch: Bool {
        !UserDefaults.standard.bool(forKey: "has_launched")
    }

    enum AppPhase {
        case initializing
        case webDisplay
        case fallback
        case offline
    }

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(processAnalytics(_:)), name: .analyticsReceived, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAnalyticsError(_:)), name: .analyticsFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePushToken(_:)), name: .pushTokenUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(retryConfiguration), name: .retryConfig, object: nil)
        monitorNetwork()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func monitorNetwork() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status != .satisfied {
                    self.handleOfflineState()
                }
            }
        }
        monitor.start(queue: .global())
    }

    @objc private func processAnalytics(_ notification: Notification) {
        analyticsData = notification.userInfo?["analytics"] as? [AnyHashable: Any] ?? [:]
        handleAnalyticsData()
    }

    @objc private func handleAnalyticsError(_ notification: Notification) {
        handleConfigurationError()
    }

    @objc private func updatePushToken(_ notification: Notification) {
        if let token = notification.object as? String {
            UserDefaults.standard.set(token, forKey: "push_token")
            configureApp()
        }
    }

    @objc private func retryConfiguration() {
        monitorNetwork()
    }

    private func handleAnalyticsData() {
        if UserDefaults.standard.string(forKey: "app_mode") == "Fallback" {
            DispatchQueue.main.async {
                self.currentPhase = .fallback
            }
            return
        }

        if isFirstLaunch {
            if let status = analyticsData["af_status"] as? String, status == "Organic" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    Task {
                        await self.checkOrganicInstall()
                    }
                }
                return
            }
        }

        if let tempUrl = UserDefaults.standard.string(forKey: "temp_url"), !tempUrl.isEmpty {
            targetUrl = URL(string: tempUrl)
            currentPhase = .webDisplay
            return
        }

        if targetUrl == nil {
            if !UserDefaults.standard.bool(forKey: "notifications_allowed") && !UserDefaults.standard.bool(forKey: "notifications_denied") {
                promptForNotifications()
            } else {
                configureApp()
            }
        }
    }

    private func checkOrganicInstall() async {
        do {
            let baseUrl = URL(string: "https://gcdsdk.appsflyer.com/install_data/v4.0/id\(AppKeys.appId)")!
            var components = URLComponents(url: baseUrl, resolvingAgainstBaseURL: true)!
            components.queryItems = [
                URLQueryItem(name: "devkey", value: AppKeys.devkey),
                URLQueryItem(name: "device_id", value: AppsFlyerLib.shared().getAppsFlyerUID())
            ]

            var request = URLRequest(url: components.url!)
            request.httpMethod = "GET"
            request.timeoutInterval = 10
            request.setValue("application/json", forHTTPHeaderField: "accept")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.switchToFallback()
                return
            }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                analyticsData = json
                configureApp()
            } else {
                print("JSON decoding failed")
                switchToFallback()
            }
        } catch {
            print("Error fetching organic install: \(error)")
            switchToFallback()
        }
    }

    func configureApp() {
        guard let configUrl = URL(string: "https://bubbllepasswords.com/config.php") else {
            handleConfigurationError()
            return
        }

        var request = URLRequest(url: configUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var payload = analyticsData
        payload["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        payload["bundle_id"] = Bundle.main.bundleIdentifier ?? "com.example.app"
        payload["os"] = "iOS"
        payload["store_id"] = "id\(AppKeys.appId)"
        payload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        payload["push_token"] = UserDefaults.standard.string(forKey: "push_token") ?? Messaging.messaging().fcmToken
        payload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            handleConfigurationError()
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard error == nil, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                    self.handleConfigurationError()
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any], let isValid = json["ok"] as? Bool, isValid {
                        if let urlString = json["url"] as? String, let expires = json["expires"] as? TimeInterval {
                            self.saveConfigData(url: urlString, expires: expires)
                            self.targetUrl = URL(string: urlString)
                            self.currentPhase = .webDisplay
                        }
                    } else {
                        self.switchToFallback()
                    }
                } catch {
                    self.handleConfigurationError()
                }
            }
        }.resume()
    }

    private func saveConfigData(url: String, expires: TimeInterval) {
        UserDefaults.standard.set(url, forKey: "persistent_url")
        UserDefaults.standard.set(expires, forKey: "url_expires")
        UserDefaults.standard.set("WebDisplay", forKey: "app_mode")
        UserDefaults.standard.set(true, forKey: "has_launched")
    }

    private func handleConfigurationError() {
        if let savedUrl = UserDefaults.standard.string(forKey: "persistent_url"), let validUrl = URL(string: savedUrl) {
            targetUrl = validUrl
            currentPhase = .webDisplay
        } else {
            switchToFallback()
        }
    }

    private func switchToFallback() {
        UserDefaults.standard.set("Fallback", forKey: "app_mode")
        UserDefaults.standard.set(true, forKey: "has_launched")
        DispatchQueue.main.async {
            self.currentPhase = .fallback
        }
    }

    private func handleOfflineState() {
        if UserDefaults.standard.string(forKey: "app_mode") == "WebDisplay" {
            DispatchQueue.main.async {
                self.currentPhase = .offline
            }
        } else {
            switchToFallback()
        }
    }

    private func promptForNotifications() {
        if let lastPrompt = UserDefaults.standard.object(forKey: "last_prompt_date") as? Date, Date().timeIntervalSince(lastPrompt) < 259200 {
            configureApp()
            return
        }
        showNotificationPrompt = true
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                UserDefaults.standard.set(granted, forKey: "notifications_allowed")
                UserDefaults.standard.set(!granted, forKey: "notifications_denied")
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                self.showNotificationPrompt = false
                self.configureApp()
                if let error = error {
                    print("Notification permission error: \(error)")
                }
            }
        }
    }
}

struct NotificationPromptView: View {
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                Image(isLandscape ? "push_bg_l" : "push_bg")
                    .resizable()
                    .frame(width: geometry.size.width)
                    .scaledToFit()
                    .ignoresSafeArea()

                VStack(spacing: isLandscape ? 5 : 10) {
                    Spacer()
                    Text("Allow notifications about bonuses and promos".uppercased())
                        .font(.custom("Buyan-Bold", size: 34))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(red: 255/255, green: 221/255, blue: 0))
                        .padding(.horizontal, 30)

                    Text("Stay tuned with best offers from our casino")
                        .font(.custom("Buyan-Regular", size: 20))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(red: 255/255, green: 221/255, blue: 0))
                        .padding(.horizontal, 72)
                        .padding(.top, 4)

                    Button(action: onAccept) {
                        Image("yes")
                            .resizable()
                            .frame(height: 60)
                    }
                    .frame(width: 350)
                    .padding(.top, 24)

                    Button(action: onDecline) {
                        Text("SKIP")
                            .font(.custom("Buyan-Regular", size: 16))
                            .foregroundColor(Color(red: 255/255, green: 221/255, blue: 0))
                    }
                    .padding(.top)

                    Spacer()
                        .frame(height: isLandscape ? 30 : 70)
                }
                .padding(.horizontal, isLandscape ? 20 : 0)
            }
        }
        .ignoresSafeArea()
    }
}

struct MultiBarInfiniteProgress: View {
    @State private var positions: [CGFloat] = [0, -50, -100]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: geometry.size.width, height: 8)
                    .clipShape(Capsule())
                
                ForEach(0..<3, id: \.self) { index in
                    Rectangle()
                        .fill(Color(red: 255/255, green: 221/255, blue: 0).opacity(0.7))
                        .frame(width: 40, height: 8)
                        .clipShape(Capsule())
                        .offset(x: positions[index])
                }
            }
            .clipShape(Capsule())
            .onAppear {
                withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: true)) {
                    positions = positions.map { $0 + geometry.size.width + 50 }
                }
            }
        }
        .frame(height: 8)
        .padding(.horizontal, 32)
    }
}

struct AppLaunchView: View {
    @StateObject private var launcher = AppLauncher()
    @State private var isLoading = false
    

    private var loadingView: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                Image(isLandscape ? "push_bg_l" : "push_bg")
                    .resizable()
                    .frame(width: geometry.size.width)
                    .scaledToFit()
                    .ignoresSafeArea()
                
                
                VStack {
                    Spacer()
                    Text("INITIALIZING APP...")
                        .font(.custom("Buyan-Bold", size: 42))
                        .foregroundColor(Color(red: 255/255, green: 221/255, blue: 0))
                    
                    MultiBarInfiniteProgress()
                        .padding(.horizontal, 32)
                    
                    Spacer()
                        .frame(height: 70)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    var body: some View {
        ZStack {
            if launcher.currentPhase == .initializing || launcher.showNotificationPrompt {
                loadingView
            }

            if launcher.showNotificationPrompt {
                NotificationPromptView(
                    onAccept: { launcher.requestNotificationPermission() },
                    onDecline: {
                        UserDefaults.standard.set(Date(), forKey: "last_prompt_date")
                        launcher.showNotificationPrompt = false
                        launcher.configureApp()
                    }
                )
            } else {
                switch launcher.currentPhase {
                case .initializing:
                    EmptyView()
                case .webDisplay:
                    if let _ = launcher.targetUrl {
                        WebInterface()
                    } else {
                        MainView()
                    }
                case .fallback:
                    MainView()
                case .offline:
                    offlineView
                }
            }
            
            loadingView
        }
    }
    
    private var offlineView: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                Image(isLandscape ? "push_bg_l" : "push_bg")
                    .resizable()
                    .frame(width: geometry.size.width)
                    .scaledToFit()
                    .ignoresSafeArea()


                VStack {
                    Spacer()
                    Text("NO INTERNET CONNECTION! PLEASE CHECK YOUR NETWORK AND TRY AGAIN!")
                        .font(.custom("Buyan-Bold", size: 32))
                        .foregroundColor(Color(red: 255/255, green: 221/255, blue: 0))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            Rectangle()
                                .fill(Color(red: 13/255, green: 21/255, blue: 45/255))
                        )
                        .padding(.horizontal, 24)
                    Spacer()
                        .frame(height: 240)
                }
            }
        }
        .ignoresSafeArea()
    }
    
}

extension Notification.Name {
    static let webNavigation = Notification.Name("web_navigation")
    static let analyticsReceived = Notification.Name("analytics_received")
    static let analyticsFailed = Notification.Name("analytics_failed")
    static let pushTokenUpdated = Notification.Name("push_token_updated")
    static let retryConfig = Notification.Name("retry_config")
}


#Preview {
    SettingsView()
    // AppLaunchView()
}
