package com.protip365.app.presentation.localization

class AuthLocalization(private val language: String) {

    // MARK: - Welcome Messages
    val welcomeBackText: String
        get() = when (language) {
            "fr" -> "Bon retour!"
            "es" -> "¡Bienvenido de vuelta!"
            else -> "Welcome Back!"
        }

    val createYourAccountText: String
        get() = when (language) {
            "fr" -> "Créez votre compte"
            "es" -> "Crea tu cuenta"
            else -> "Create Your Account"
        }

    val signInToContinueText: String
        get() = when (language) {
            "fr" -> "Connectez-vous pour continuer"
            "es" -> "Inicia sesión para continuar"
            else -> "Sign in to continue"
        }

    val joinProTip365Text: String
        get() = when (language) {
            "fr" -> "Rejoignez ProTip365 pour suivre vos gains"
            "es" -> "Únete a ProTip365 para rastrear tus ganancias"
            else -> "Join ProTip365 to track your earnings"
        }

    // MARK: - Form Labels
    val nameText: String
        get() = when (language) {
            "fr" -> "Nom"
            "es" -> "Nombre"
            else -> "Name"
        }

    val emailText: String
        get() = when (language) {
            "fr" -> "E-mail"
            "es" -> "Correo electrónico"
            else -> "Email"
        }

    val passwordText: String
        get() = when (language) {
            "fr" -> "Mot de passe"
            "es" -> "Contraseña"
            else -> "Password"
        }

    val confirmPasswordText: String
        get() = when (language) {
            "fr" -> "Confirmer le mot de passe"
            "es" -> "Confirmar contraseña"
            else -> "Confirm Password"
        }

    // MARK: - Buttons
    val signInText: String
        get() = when (language) {
            "fr" -> "Se connecter"
            "es" -> "Iniciar sesión"
            else -> "Sign In"
        }

    val signUpText: String
        get() = when (language) {
            "fr" -> "S'inscrire"
            "es" -> "Registrarse"
            else -> "Sign Up"
        }

    val createAccountText: String
        get() = when (language) {
            "fr" -> "Créer un compte"
            "es" -> "Crear cuenta"
            else -> "Create Account"
        }

    // MARK: - Toggle Messages
    val alreadyHaveAccountText: String
        get() = when (language) {
            "fr" -> "Vous avez déjà un compte? Se connecter"
            "es" -> "¿Ya tienes una cuenta? Iniciar sesión"
            else -> "Already have an account? Sign In"
        }

    val dontHaveAccountText: String
        get() = when (language) {
            "fr" -> "Vous n'avez pas de compte? S'inscrire"
            "es" -> "¿No tienes una cuenta? Registrarse"
            else -> "Don't have an account? Sign Up"
        }

    val forgotPasswordText: String
        get() = when (language) {
            "fr" -> "Mot de passe oublié?"
            "es" -> "¿Olvidaste tu contraseña?"
            else -> "Forgot Password?"
        }

    // MARK: - Validation Messages
    val nameRequiredText: String
        get() = when (language) {
            "fr" -> "Le nom est requis"
            "es" -> "El nombre es requerido"
            else -> "Name is required"
        }

    val invalidEmailText: String
        get() = when (language) {
            "fr" -> "Adresse e-mail invalide"
            "es" -> "Dirección de correo inválida"
            else -> "Invalid email address"
        }

    val passwordMinLengthText: String
        get() = when (language) {
            "fr" -> "Le mot de passe doit contenir au moins 6 caractères"
            "es" -> "La contraseña debe tener al menos 6 caracteres"
            else -> "Password must be at least 6 characters"
        }

    val passwordsDoNotMatchText: String
        get() = when (language) {
            "fr" -> "Les mots de passe ne correspondent pas"
            "es" -> "Las contraseñas no coinciden"
            else -> "Passwords do not match"
        }

    val emailAlreadyRegisteredText: String
        get() = when (language) {
            "fr" -> "E-mail déjà enregistré"
            "es" -> "Correo electrónico ya registrado"
            else -> "Email already registered"
        }

    // MARK: - Icons and Accessibility
    val nameIconDescription: String
        get() = when (language) {
            "fr" -> "Nom"
            "es" -> "Nombre"
            else -> "Name"
        }

    val emailIconDescription: String
        get() = when (language) {
            "fr" -> "E-mail"
            "es" -> "Correo electrónico"
            else -> "Email"
        }

    val passwordIconDescription: String
        get() = when (language) {
            "fr" -> "Mot de passe"
            "es" -> "Contraseña"
            else -> "Password"
        }

    val showPasswordText: String
        get() = when (language) {
            "fr" -> "Afficher le mot de passe"
            "es" -> "Mostrar contraseña"
            else -> "Show password"
        }

    val hidePasswordText: String
        get() = when (language) {
            "fr" -> "Masquer le mot de passe"
            "es" -> "Ocultar contraseña"
            else -> "Hide password"
        }

    // MARK: - App Branding
    val trackYourTipsAchieveGoalsText: String
        get() = when (language) {
            "fr" -> "Suivez vos pourboires, atteignez vos objectifs"
            "es" -> "Rastrea tus propinas, alcanza tus objetivos"
            else -> "Track Your Tips, Achieve Your Goals"
        }
}



