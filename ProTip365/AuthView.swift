import SwiftUI
import Supabase

struct AuthView: View {
    @Binding var isAuthenticated: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @AppStorage("language") private var language = "en"
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Language selector at top
                HStack {
                    Spacer()
                    Menu {
                        Button("English") { language = "en" }
                        Button("Français") { language = "fr" }
                        Button("Español") { language = "es" }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                            Text(languageLabel)
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    }
                }
                .padding()
                
                Spacer()
                
                // Logo and title
                VStack(spacing: 12) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .symbolRenderingMode(.hierarchical)
                    
                    Text("ProTip365")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(welcomeText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // Input fields
                VStack(spacing: 16) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(emailPlaceholder)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField(emailPlaceholder, text: $email)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .password
                            }
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(passwordPlaceholder)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField(passwordPlaceholder, text: $password)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .textContentType(isSignUp ? .newPassword : .password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.done)
                            .onSubmit {
                                authenticate()
                            }
                    }
                }
                .padding(.horizontal)
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: authenticate) {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text(isSignUp ? signUpButton : signInButton)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSignUp.toggle()
                        }
                    }) {
                        Text(isSignUp ? switchToSignIn : switchToSignUp)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                Spacer()
            }
            .background(Color(.systemBackground))
            .onTapGesture {
                focusedField = nil
            }
        }
        .alert(errorText, isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    func authenticate() {
        guard !email.isEmpty, !password.isEmpty else { return }
        
        isLoading = true
        focusedField = nil
        
        Task {
            do {
                if isSignUp {
                    // Sign up the user
                    let response = try await SupabaseManager.shared.client.auth.signUp(
                        email: email,
                        password: password
                    )
                    
                    // After successful signup, automatically sign them in
                    if response.user != nil {
                        try await SupabaseManager.shared.client.auth.signIn(
                            email: email,
                            password: password
                        )
                        await MainActor.run {
                            isAuthenticated = true
                            isLoading = false
                        }
                    }
                } else {
                    // Just sign in
                    try await SupabaseManager.shared.client.auth.signIn(
                        email: email,
                        password: password
                    )
                    await MainActor.run {
                        isAuthenticated = true
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    // Localization
    var languageLabel: String {
        switch language {
        case "fr": return "FR"
        case "es": return "ES"
        default: return "EN"
        }
    }
    
    var welcomeText: String {
        switch language {
        case "fr": return "Suivez vos pourboires facilement"
        case "es": return "Rastrea tus propinas fácilmente"
        default: return "Track your tips easily"
        }
    }
    
    var emailPlaceholder: String {
        switch language {
        case "fr": return "Courriel"
        case "es": return "Correo electrónico"
        default: return "Email"
        }
    }
    
    var passwordPlaceholder: String {
        switch language {
        case "fr": return "Mot de passe"
        case "es": return "Contraseña"
        default: return "Password"
        }
    }
    
    var signInButton: String {
        switch language {
        case "fr": return "Se connecter"
        case "es": return "Iniciar sesión"
        default: return "Sign In"
        }
    }
    
    var signUpButton: String {
        switch language {
        case "fr": return "Créer un compte"
        case "es": return "Crear cuenta"
        default: return "Create Account"
        }
    }
    
    var switchToSignUp: String {
        switch language {
        case "fr": return "Pas de compte? Créer un compte"
        case "es": return "¿Sin cuenta? Crear cuenta"
        default: return "No account? Create one"
        }
    }
    
    var switchToSignIn: String {
        switch language {
        case "fr": return "Déjà un compte? Se connecter"
        case "es": return "¿Ya tienes cuenta? Iniciar sesión"
        default: return "Have an account? Sign in"
        }
    }
    
    var errorText: String {
        switch language {
        case "fr": return "Erreur"
        case "es": return "Error"
        default: return "Error"
        }
    }
}
