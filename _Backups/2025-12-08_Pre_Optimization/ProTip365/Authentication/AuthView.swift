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
    @State private var showPasswordReset = false
    @State private var resetEmail = ""
    @State private var showResetSuccess = false
    @State private var showWelcomeSignUp = false
    @State private var keepMeSignedIn = true // Default to true for convenience
    @AppStorage("language") private var language = "en"
    @AppStorage("keepMeSignedIn") private var persistedKeepMeSignedIn = true
    @FocusState private var focusedField: Field?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()

                // Gradient overlay
                LinearGradient(
                    colors: [
                        Color(red: 0.6, green: 0.8, blue: 1.0),     // Light blue
                        Color(red: 1.0, green: 0.7, blue: 0.9),     // Light pink
                        Color(red: 0.8, green: 0.7, blue: 1.0)      // Light purple
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.2)
                .ignoresSafeArea()

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
                        .foregroundStyle(.tint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                    }
                }
                .padding()
                
                Spacer()
                
                // Logo and title
                VStack(spacing: 16) {
                    // App Icon/Logo
                    Image("Logo2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(radius: 10)

                    VStack(spacing: 8) {
                        Text("ProTip365")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(welcomeText)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Text(taglineText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 30)
                
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
                            .foregroundColor(.primary)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
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
                            .foregroundColor(.primary)
                            .background(Color(.systemBackground))

                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                            .textContentType(isSignUp ? .newPassword : .password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.done)
                            .onSubmit {
                                authenticate()
                            }
                    }

                    // Keep me signed in - Only show when signing in
                    if !isSignUp {
                        HStack(spacing: 8) {
                            Toggle(isOn: $keepMeSignedIn) {
                                Text(keepMeSignedInText)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                            .toggleStyle(CheckboxToggleStyle())
                        }
                        .padding(.top, 4)
                    }

                    // Forgot Password - Only show when signing in
                    if !isSignUp {
                        HStack {
                            Spacer()
                            Button(action: {
                                resetEmail = email // Pre-fill with current email if available
                                showPasswordReset = true
                            }) {
                                Text(forgotPasswordText)
                                    .font(.caption)
                                    .foregroundStyle(.tint)
                            }
                        }
                        .padding(.top, -8)
                    }
                }
                .padding(.horizontal, horizontalSizeClass == .regular ? 32 : 16)
                .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
                
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
                        if isSignUp {
                            // If we're in sign-up mode, go back to sign-in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSignUp = false
                                password = "" // Clear password when switching modes
                            }
                        } else {
                            // If we're in sign-in mode, show the welcome sign-up flow
                            showWelcomeSignUp = true
                        }
                    }) {
                        Text(isSignUp ? switchToSignIn : switchToSignUp)
                            .font(.subheadline)
                            .foregroundStyle(.tint)
                    }
                }
                .padding(.horizontal, horizontalSizeClass == .regular ? 32 : 16)
                .padding(.top, 20)
                .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
                
                Spacer()
                Spacer()
                }
                .onTapGesture {
                    focusedField = nil
                }
            }
        }
        .alert(errorText, isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showPasswordReset) {
            NavigationStack {
                VStack(spacing: 20) {
                    // Icon
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 50))
                        .foregroundStyle(.tint)
                        .padding(.top, 40)
                    
                    // Title
                    Text(resetPasswordTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Description
                    Text(resetPasswordDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(emailPlaceholder)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField(emailPlaceholder, text: $resetEmail)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .padding()
                            .foregroundColor(.primary)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                    }
                    .padding(.horizontal)
                    
                    // Send button
                    Button(action: sendPasswordReset) {
                        Text(sendResetLinkButton)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(resetEmail.isEmpty)
                    .opacity(resetEmail.isEmpty ? 0.6 : 1.0)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(cancelButton) {
                            showPasswordReset = false
                            resetEmail = ""
                        }
                    }
                }
            }
        }
        .alert(successTitle, isPresented: $showResetSuccess) {
            Button("OK") {
                showPasswordReset = false
                resetEmail = ""
            }
        } message: {
            Text(resetSuccessMessage)
        }
        .fullScreenCover(isPresented: $showWelcomeSignUp) {
            WelcomeSignUpView(isAuthenticated: $isAuthenticated)
        }
    }
    
    func authenticate() {
        print("🔐 Starting authentication process...")
        print("   Email: \(email)")
        print("   Password length: \(password.count)")
        print("   Is Sign Up: \(isSignUp)")

        guard !email.isEmpty, !password.isEmpty else {
            print("❌ ERROR: Email or password is empty")
            return
        }

        isLoading = true
        focusedField = nil

        Task {
            do {
                print("📡 Attempting to authenticate with Supabase...")

                if isSignUp {
                    print("📝 Starting sign up process...")
                    // Sign up the user
                    _ = try await SupabaseManager.shared.client.auth.signUp(
                        email: email,
                        password: password
                    )
                    print("✅ Sign up successful, attempting automatic sign in...")

                    // After successful signup, automatically sign them in
                    // No need to check if user is nil - if we got here without error, signup succeeded
                    _ = try await SupabaseManager.shared.client.auth.signIn(
                        email: email,
                        password: password
                    )
                    print("✅ Sign in after signup successful")

                    // Give the session time to establish and load products
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay

                    await MainActor.run {
                        isAuthenticated = true
                        isLoading = false
                        print("🎉 User authenticated successfully!")
                    }
                } else {
                    print("🔑 Starting sign in process...")
                    // Just sign in
                    _ = try await SupabaseManager.shared.client.auth.signIn(
                        email: email,
                        password: password
                    )
                    print("✅ Sign in successful")

                    await MainActor.run {
                        // Save the "keep me signed in" preference
                        persistedKeepMeSignedIn = keepMeSignedIn
                        isAuthenticated = true
                        isLoading = false
                        print("🎉 User authenticated successfully! Keep signed in: \(keepMeSignedIn)")
                    }
                }
            } catch {
                print("❌ Authentication failed with error:")
                print("   Error type: \(type(of: error))")
                print("   Error description: \(error.localizedDescription)")
                print("   Error debug description: \(String(describing: error))")

                // Try to get more specific error information
                if let authError = error as? AuthError {
                    print("   AuthError details: \(authError)")
                }

                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                    print("🚨 Authentication error displayed to user: \(errorMessage)")
                }
            }
        }
    }
    
    func sendPasswordReset() {
        guard !resetEmail.isEmpty else { return }
        
        Task {
            do {
                try await SupabaseManager.shared.client.auth.resetPasswordForEmail(
                    resetEmail,
                    redirectTo: URL(string: "protip365://reset-password")
                )
                await MainActor.run {
                    showResetSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
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
        case "fr": return "Suivez vos pourboires"
        case "es": return "Rastrea tus propinas"
        default: return "Track Your Tips"
        }
    }

    var taglineText: String {
        switch language {
        case "fr": return "Suivez chaque pourboire.\nGérez chaque quart.\nAccédez à vos données partout."
        case "es": return "Rastrea cada propina.\nGestiona cada turno.\nAccede a tus datos en cualquier lugar."
        default: return "Track Every Tip.\nManage Every Shift.\nAccess Your Data Anywhere."
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
    
    var forgotPasswordText: String {
        switch language {
        case "fr": return "Mot de passe oublié?"
        case "es": return "¿Olvidaste tu contraseña?"
        default: return "Forgot Password?"
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
    
    var resetPasswordTitle: String {
        switch language {
        case "fr": return "Réinitialiser le mot de passe"
        case "es": return "Restablecer contraseña"
        default: return "Reset Password"
        }
    }
    
    var resetPasswordDescription: String {
        switch language {
        case "fr": return "Entrez votre adresse e-mail et nous vous enverrons un lien pour réinitialiser votre mot de passe."
        case "es": return "Ingrese su correo electrónico y le enviaremos un enlace para restablecer su contraseña."
        default: return "Enter your email address and we'll send you a link to reset your password."
        }
    }
    
    var sendResetLinkButton: String {
        switch language {
        case "fr": return "Envoyer le lien"
        case "es": return "Enviar enlace"
        default: return "Send Reset Link"
        }
    }
    
    var cancelButton: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }
    
    var successTitle: String {
        switch language {
        case "fr": return "Succès"
        case "es": return "Éxito"
        default: return "Success"
        }
    }
    
    var resetSuccessMessage: String {
        switch language {
        case "fr": return "Si un compte existe avec cette adresse e-mail, vous recevrez un lien de réinitialisation."
        case "es": return "Si existe una cuenta con este correo, recibirá un enlace de restablecimiento."
        default: return "If an account exists with this email, you'll receive a reset link."
        }
    }

    var keepMeSignedInText: String {
        switch language {
        case "fr": return "Rester connecté"
        case "es": return "Mantenerme conectado"
        default: return "Keep me signed in"
        }
    }
}

// Custom checkbox toggle style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .font(.system(size: 20))
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture {
                    configuration.isOn.toggle()
                }

            configuration.label
        }
    }
}
