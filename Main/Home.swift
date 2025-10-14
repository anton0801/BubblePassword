
import SwiftUI
import LocalAuthentication

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

// Password Detail View
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
                            // Add flash feedback
                            withAnimation {
                                // Optional: add a flash view
                            }
                        })
                        
                        BubbleView(size: 70, icon: entry.isFavorite ? "heart.fill" : "heart", onTap: {
                            entry.isFavorite.toggle()
                        })
                    }
                    
                    HStack(spacing: 20) {
                        Button("Edit") {
                            // Edit logic placeholder
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
                            // Share logic placeholder
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
                    }
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

#Preview {
    MainView()
}
