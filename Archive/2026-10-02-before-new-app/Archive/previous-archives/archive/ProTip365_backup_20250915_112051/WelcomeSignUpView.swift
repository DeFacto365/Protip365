import SwiftUI
import Supabase

struct WelcomeSignUpView: View {
    @Binding var isAuthenticated: Bool
    @State private var currentStep = 1
    @State private var showOnboarding = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var userName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var emailError = ""
    @State private var passwordError = ""
    @State private var isCheckingEmail = false
    @State private var emailIsValid = false
    @State private var emailAlreadyExists = false
    @AppStorage("language") private var language = "en"
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    enum Field {
        case email, password, confirmPassword, userName
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Consistent app background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    ProgressBar(currentStep: currentStep, totalSteps: 3)
                        .padding()

                    ScrollView {
                        VStack(spacing: 30) {
                            // App Logo and Welcome
                            VStack(spacing: 20) {
                                Image("Logo2")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)

                                VStack(spacing: 8) {
                                    Text(welcomeToProTip365Text)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)

                                    Text(currentStep == 1 ? letsGetStartedText :
                                         currentStep == 2 ? secureYourAccountText :
                                         almostThereText)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 20)

                            // Step Content
                            Group {
                                switch currentStep {
                                case 1:
                                    emailStepView
                                case 2:
                                    passwordStepView
                                case 3:
                                    profileStepView
                                default:
                                    EmptyView()
                                }
                            }
                            .padding(.horizontal)

                            // Navigation Buttons
                            HStack(spacing: 16) {
                                if currentStep > 1 {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            currentStep -= 1
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "chevron.left")
                                            Text(backButtonText)
                                        }
                                        .foregroundStyle(.tint)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }

                                Button(action: handleNextStep) {
                                    Group {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            HStack {
                                                Text(currentStep == 3 ? createAccountButtonText : nextButtonText)
                                                if currentStep < 3 {
                                                    Image(systemName: "chevron.right")
                                                }
                                            }
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .opacity(isStepValid ? 1.0 : 0.6)
                                }
                                .disabled(!isStepValid || isLoading)
                            }
                            .padding(.horizontal, horizontalSizeClass == .regular ? 32 : 16)
                            .padding(.vertical, 20)
                            .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(cancelButtonText) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(stepTitleText)
                        .font(.headline)
                }
            }
        }
        .alert(errorTitleText, isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isAuthenticated: $isAuthenticated, showOnboarding: $showOnboarding)
        }
    }

    // MARK: - Step Views

    private var emailStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Label(emailAddressText, systemImage: "envelope.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                TextField(enterEmailText, text: $email)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(emailError.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                    )
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .focused($focusedField, equals: .email)
                    .onChange(of: focusedField) { _, newValue in
                        if newValue != .email && !email.isEmpty {
                            validateEmail()
                        }
                    }

                if isCheckingEmail {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(checkingEmailText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if !emailError.isEmpty {
                    Label(emailError, systemImage: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if emailIsValid && !emailAlreadyExists {
                    Label(emailAvailableText, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            // Email format hints
            VStack(alignment: .leading, spacing: 8) {
                Label(emailRequirementsText, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(emailRequirement1Text)
                    Text(emailRequirement2Text)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var passwordStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Label(createPasswordText, systemImage: "lock.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                SecureField(enterPasswordText, text: $password)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .password)
                    .onChange(of: password) { _, _ in
                        validatePasswords()
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Label(confirmPasswordText, systemImage: "lock.badge.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                SecureField(reenterPasswordText, text: $confirmPassword)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(passwordError.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                    )
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .onChange(of: confirmPassword) { _, _ in
                        validatePasswords()
                    }

                if !passwordError.isEmpty {
                    Label(passwordError, systemImage: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword {
                    Label(passwordsMatchText, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            // Password requirements
            VStack(alignment: .leading, spacing: 8) {
                Label(passwordRequirementsText, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: password.count >= 6 ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(password.count >= 6 ? .green : .secondary)
                            .font(.caption)
                        Text(passwordRequirement1Text)
                    }

                    HStack {
                        Image(systemName: password == confirmPassword && !password.isEmpty ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(password == confirmPassword && !password.isEmpty ? .green : .secondary)
                            .font(.caption)
                        Text(passwordRequirement2Text)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var profileStepView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Label(yourNameText, systemImage: "person.fill")
                    .font(.headline)
                    .foregroundColor(.primary)

                TextField(enterNameText, text: $userName)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .textContentType(.name)
                    .focused($focusedField, equals: .userName)
            }

            // Summary
            VStack(alignment: .leading, spacing: 12) {
                Label(accountSummaryText, systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.tint)
                            .frame(width: 20)
                        Text(email)
                            .font(.body)
                    }

                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.tint)
                            .frame(width: 20)
                        Text(String(repeating: "•", count: password.count))
                            .font(.body)
                    }

                    if !userName.isEmpty {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.tint)
                                .frame(width: 20)
                            Text(userName)
                                .font(.body)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Helper Functions

    private var isStepValid: Bool {
        switch currentStep {
        case 1:
            return !email.isEmpty && emailIsValid && !emailAlreadyExists
        case 2:
            return !password.isEmpty && !confirmPassword.isEmpty &&
                   password == confirmPassword && password.count >= 6
        case 3:
            return !userName.isEmpty
        default:
            return false
        }
    }

    private var stepTitleText: String {
        switch currentStep {
        case 1:
            switch language {
            case "fr": return "Étape 1 sur 3"
            case "es": return "Paso 1 de 3"
            default: return "Step 1 of 3"
            }
        case 2:
            switch language {
            case "fr": return "Étape 2 sur 3"
            case "es": return "Paso 2 de 3"
            default: return "Step 2 of 3"
            }
        case 3:
            switch language {
            case "fr": return "Étape 3 sur 3"
            case "es": return "Paso 3 de 3"
            default: return "Step 3 of 3"
            }
        default:
            return ""
        }
    }

    private func validateEmail() {
        emailError = ""
        emailIsValid = false
        emailAlreadyExists = false

        // Check email format
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        if !emailPredicate.evaluate(with: email) {
            emailError = invalidEmailFormatText
            return
        }

        // Check if email exists in database
        isCheckingEmail = true
        Task {
            do {
                // Try to check if user exists - this is a workaround
                // In production, you'd have a proper endpoint for this
                _ = try await SupabaseManager.shared.client.auth.signIn(
                    email: email,
                    password: "dummy_check_password_12345"
                )

                // If we get here without error, email exists
                await MainActor.run {
                    emailAlreadyExists = true
                    emailError = emailAlreadyExistsText
                    isCheckingEmail = false
                }
            } catch {
                // If error contains "Invalid login credentials", email doesn't exist (good!)
                // If error contains "Email not confirmed", email exists but not verified
                let errorString = error.localizedDescription.lowercased()

                await MainActor.run {
                    if errorString.contains("email not confirmed") ||
                       errorString.contains("user already registered") {
                        emailAlreadyExists = true
                        emailError = emailAlreadyExistsText
                    } else {
                        emailIsValid = true
                        emailAlreadyExists = false
                    }
                    isCheckingEmail = false
                }
            }
        }
    }

    private func validatePasswords() {
        passwordError = ""

        if !password.isEmpty && password.count < 6 {
            passwordError = passwordTooShortText
        } else if !confirmPassword.isEmpty && password != confirmPassword {
            passwordError = passwordsDontMatchText
        }
    }

    private func handleNextStep() {
        if currentStep < 3 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            createAccount()
        }
    }

    private func createAccount() {
        isLoading = true

        Task {
            do {
                // Sign up the user
                let response = try await SupabaseManager.shared.client.auth.signUp(
                    email: email,
                    password: password,
                    data: ["name": .string(userName)]
                )

                // Create user profile
                let userId = response.user.id
                struct ProfileInsert: Encodable {
                        let user_id: UUID
                        let name: String
                        let default_hourly_rate: Double
                        let language: String
                    }

                    let profile = ProfileInsert(
                        user_id: userId,
                        name: userName,
                        default_hourly_rate: 15.0,
                        language: language
                    )

                try await SupabaseManager.shared.client
                    .from("users_profile")
                    .insert(profile)
                    .execute()

                // Sign in automatically
                _ = try await SupabaseManager.shared.client.auth.signIn(
                    email: email,
                    password: password
                )

                await MainActor.run {
                    isAuthenticated = true
                    isLoading = false
                    showOnboarding = true
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

    // MARK: - Localization

    private var welcomeToProTip365Text: String {
        switch language {
        case "fr": return "Bienvenue à ProTip365"
        case "es": return "Bienvenido a ProTip365"
        default: return "Welcome to ProTip365"
        }
    }

    private var letsGetStartedText: String {
        switch language {
        case "fr": return "Commençons par créer votre compte"
        case "es": return "Empecemos creando tu cuenta"
        default: return "Let's get started by creating your account"
        }
    }

    private var secureYourAccountText: String {
        switch language {
        case "fr": return "Sécurisez votre compte avec un mot de passe"
        case "es": return "Asegura tu cuenta con una contraseña"
        default: return "Secure your account with a password"
        }
    }

    private var almostThereText: String {
        switch language {
        case "fr": return "Presque terminé! Personnalisons votre profil"
        case "es": return "¡Casi listo! Personalicemos tu perfil"
        default: return "Almost there! Let's personalize your profile"
        }
    }

    private var emailAddressText: String {
        switch language {
        case "fr": return "Adresse courriel"
        case "es": return "Correo electrónico"
        default: return "Email Address"
        }
    }

    private var enterEmailText: String {
        switch language {
        case "fr": return "Entrez votre courriel"
        case "es": return "Ingrese su correo"
        default: return "Enter your email"
        }
    }

    private var checkingEmailText: String {
        switch language {
        case "fr": return "Vérification..."
        case "es": return "Verificando..."
        default: return "Checking..."
        }
    }

    private var emailAvailableText: String {
        switch language {
        case "fr": return "Cette adresse est disponible"
        case "es": return "Esta dirección está disponible"
        default: return "This email is available"
        }
    }

    private var emailAlreadyExistsText: String {
        switch language {
        case "fr": return "Cette adresse est déjà utilisée"
        case "es": return "Este correo ya está en uso"
        default: return "This email is already in use"
        }
    }

    private var invalidEmailFormatText: String {
        switch language {
        case "fr": return "Format de courriel invalide"
        case "es": return "Formato de correo inválido"
        default: return "Invalid email format"
        }
    }

    private var emailRequirementsText: String {
        switch language {
        case "fr": return "Exigences du courriel"
        case "es": return "Requisitos del correo"
        default: return "Email Requirements"
        }
    }

    private var emailRequirement1Text: String {
        switch language {
        case "fr": return "• Doit être une adresse valide"
        case "es": return "• Debe ser una dirección válida"
        default: return "• Must be a valid email address"
        }
    }

    private var emailRequirement2Text: String {
        switch language {
        case "fr": return "• Ne doit pas être déjà enregistrée"
        case "es": return "• No debe estar ya registrada"
        default: return "• Must not be already registered"
        }
    }

    private var createPasswordText: String {
        switch language {
        case "fr": return "Créer un mot de passe"
        case "es": return "Crear una contraseña"
        default: return "Create a Password"
        }
    }

    private var enterPasswordText: String {
        switch language {
        case "fr": return "Entrez votre mot de passe"
        case "es": return "Ingrese su contraseña"
        default: return "Enter your password"
        }
    }

    private var confirmPasswordText: String {
        switch language {
        case "fr": return "Confirmer le mot de passe"
        case "es": return "Confirmar contraseña"
        default: return "Confirm Password"
        }
    }

    private var reenterPasswordText: String {
        switch language {
        case "fr": return "Entrez à nouveau votre mot de passe"
        case "es": return "Ingrese su contraseña nuevamente"
        default: return "Re-enter your password"
        }
    }

    private var passwordsMatchText: String {
        switch language {
        case "fr": return "Les mots de passe correspondent"
        case "es": return "Las contraseñas coinciden"
        default: return "Passwords match"
        }
    }

    private var passwordsDontMatchText: String {
        switch language {
        case "fr": return "Les mots de passe ne correspondent pas"
        case "es": return "Las contraseñas no coinciden"
        default: return "Passwords don't match"
        }
    }

    private var passwordTooShortText: String {
        switch language {
        case "fr": return "Le mot de passe doit contenir au moins 6 caractères"
        case "es": return "La contraseña debe tener al menos 6 caracteres"
        default: return "Password must be at least 6 characters"
        }
    }

    private var passwordRequirementsText: String {
        switch language {
        case "fr": return "Exigences du mot de passe"
        case "es": return "Requisitos de la contraseña"
        default: return "Password Requirements"
        }
    }

    private var passwordRequirement1Text: String {
        switch language {
        case "fr": return "Au moins 6 caractères"
        case "es": return "Al menos 6 caracteres"
        default: return "At least 6 characters"
        }
    }

    private var passwordRequirement2Text: String {
        switch language {
        case "fr": return "Les deux mots de passe doivent correspondre"
        case "es": return "Ambas contraseñas deben coincidir"
        default: return "Both passwords must match"
        }
    }

    private var yourNameText: String {
        switch language {
        case "fr": return "Votre nom"
        case "es": return "Tu nombre"
        default: return "Your Name"
        }
    }

    private var enterNameText: String {
        switch language {
        case "fr": return "Entrez votre nom"
        case "es": return "Ingrese su nombre"
        default: return "Enter your name"
        }
    }

    private var accountSummaryText: String {
        switch language {
        case "fr": return "Résumé du compte"
        case "es": return "Resumen de la cuenta"
        default: return "Account Summary"
        }
    }

    private var backButtonText: String {
        switch language {
        case "fr": return "Retour"
        case "es": return "Atrás"
        default: return "Back"
        }
    }

    private var nextButtonText: String {
        switch language {
        case "fr": return "Suivant"
        case "es": return "Siguiente"
        default: return "Next"
        }
    }

    private var createAccountButtonText: String {
        switch language {
        case "fr": return "Créer le compte"
        case "es": return "Crear cuenta"
        default: return "Create Account"
        }
    }

    private var cancelButtonText: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }

    private var errorTitleText: String {
        switch language {
        case "fr": return "Erreur"
        case "es": return "Error"
        default: return "Error"
        }
    }
}

// MARK: - Progress Bar Component
struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ?
                          AnyShapeStyle(Color.blue) :
                          AnyShapeStyle(Color(.systemGray5)))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
}