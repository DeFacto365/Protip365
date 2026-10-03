package com.protip365.app.presentation.localization

class OnboardingLocalization(private val language: String) {

    // MARK: - Welcome and General
    val welcomeTitle: String
        get() = when (language) {
            "fr" -> "Configuration initiale"
            "es" -> "Configuración inicial"
            else -> "Initial Setup"
        }

    val backButtonText: String
        get() = when (language) {
            "fr" -> "Retour"
            "es" -> "Atrás"
            else -> "Back"
        }

    val nextButtonText: String
        get() = when (language) {
            "fr" -> "Suivant"
            "es" -> "Siguiente"
            else -> "Next"
        }

    val finishButtonText: String
        get() = when (language) {
            "fr" -> "Terminer"
            "es" -> "Finalizar"
            else -> "Finish"
        }

    val skipButtonText: String
        get() = when (language) {
            "fr" -> "Passer"
            "es" -> "Omitir"
            else -> "Skip"
        }

    val getStartedText: String
        get() = when (language) {
            "fr" -> "Commencer"
            "es" -> "Comenzar"
            else -> "Get Started"
        }

    // MARK: - Step 1: Language Selection
    val languageStepTitle: String
        get() = when (language) {
            "fr" -> "Choisissez votre langue"
            "es" -> "Elige tu idioma"
            else -> "Choose Your Language"
        }

    val languageStepDescription: String
        get() = when (language) {
            "fr" -> "Sélectionnez votre langue préférée pour l'interface de l'application"
            "es" -> "Selecciona tu idioma preferido para la interfaz de la aplicación"
            else -> "Select your preferred language for the app interface"
        }

    val englishText: String
        get() = when (language) {
            "fr" -> "Anglais"
            "es" -> "Inglés"
            else -> "English"
        }

    val frenchText: String
        get() = when (language) {
            "fr" -> "Français"
            "es" -> "Francés"
            else -> "French"
        }

    val spanishText: String
        get() = when (language) {
            "fr" -> "Espagnol"
            "es" -> "Español"
            else -> "Spanish"
        }

    // MARK: - Step 2: Multiple Employers
    val multipleEmployersStepTitle: String
        get() = when (language) {
            "fr" -> "Employeurs multiples?"
            "es" -> "¿Múltiples empleadores?"
            else -> "Multiple Employers?"
        }

    val multipleEmployersStepDescription: String
        get() = when (language) {
            "fr" -> "Travaillez-vous pour plusieurs employeurs ou entreprises?"
            "es" -> "¿Trabajas para múltiples empleadores o empresas?"
            else -> "Do you work for multiple employers or businesses?"
        }

    val yesMultipleEmployersText: String
        get() = when (language) {
            "fr" -> "Oui, je travaille pour plusieurs employeurs"
            "es" -> "Sí, trabajo para múltiples empleadores"
            else -> "Yes, I work for multiple employers"
        }

    val trackShiftsSeparatelyText: String
        get() = when (language) {
            "fr" -> "Suivre les quarts et pourboires séparément pour chaque employeur"
            "es" -> "Rastrear turnos y propinas por separado para cada empleador"
            else -> "Track shifts and tips separately for each employer"
        }

    val noSingleEmployerText: String
        get() = when (language) {
            "fr" -> "Non, je travaille pour un seul employeur"
            "es" -> "No, trabajo para un solo empleador"
            else -> "No, I work for one employer"
        }

    val simplifiedTrackingText: String
        get() = when (language) {
            "fr" -> "Suivi simplifié pour un seul employeur"
            "es" -> "Seguimiento simplificado para un solo empleador"
            else -> "Simplified tracking for single employer"
        }

    // MARK: - Step 3: Week Start
    val weekStartStepTitle: String
        get() = when (language) {
            "fr" -> "Jour de début de semaine"
            "es" -> "Día de inicio de semana"
            else -> "Week Start Day"
        }

    val weekStartStepDescription: String
        get() = when (language) {
            "fr" -> "Quand commence votre semaine de travail?"
            "es" -> "¿Cuándo comienza tu semana laboral?"
            else -> "When does your work week begin?"
        }

    val sundayText: String
        get() = when (language) {
            "fr" -> "Dimanche"
            "es" -> "Domingo"
            else -> "Sunday"
        }

    val mondayText: String
        get() = when (language) {
            "fr" -> "Lundi"
            "es" -> "Lunes"
            else -> "Monday"
        }

    // MARK: - Step 4: Security
    val securityStepTitle: String
        get() = when (language) {
            "fr" -> "Paramètres de sécurité"
            "es" -> "Configuración de seguridad"
            else -> "Security Settings"
        }

    val securityStepDescription: String
        get() = when (language) {
            "fr" -> "Protégez vos données financières avec les fonctionnalités de sécurité"
            "es" -> "Protege tus datos financieros con funciones de seguridad"
            else -> "Protect your financial data with security features"
        }

    val noSecurityText: String
        get() = when (language) {
            "fr" -> "Aucune sécurité"
            "es" -> "Sin seguridad"
            else -> "No Security"
        }

    val noAdditionalSecurityText: String
        get() = when (language) {
            "fr" -> "Aucune sécurité supplémentaire"
            "es" -> "Sin seguridad adicional"
            else -> "No additional security"
        }

    val pinProtectionText: String
        get() = when (language) {
            "fr" -> "Protection par code PIN"
            "es" -> "Protección con PIN"
            else -> "PIN Protection"
        }

    val protectWithPinText: String
        get() = when (language) {
            "fr" -> "Protéger avec un code PIN à 4 chiffres"
            "es" -> "Proteger con un PIN de 4 dígitos"
            else -> "Protect with a 4-digit PIN"
        }

    val biometricProtectionText: String
        get() = when (language) {
            "fr" -> "Protection biométrique"
            "es" -> "Protección biométrica"
            else -> "Biometric Protection"
        }

    val useBiometricText: String
        get() = when (language) {
            "fr" -> "Utiliser la reconnaissance d'empreinte digitale ou faciale"
            "es" -> "Usar reconocimiento de huella dactilar o facial"
            else -> "Use fingerprint or face recognition"
        }

    // MARK: - Step 5: Variable Schedule
    val scheduleStepTitle: String
        get() = when (language) {
            "fr" -> "Type d'horaire"
            "es" -> "Tipo de horario"
            else -> "Schedule Type"
        }

    val scheduleStepDescription: String
        get() = when (language) {
            "fr" -> "Avez-vous un horaire de travail variable ou fixe?"
            "es" -> "¿Tienes un horario de trabajo variable o fijo?"
            else -> "Do you have a variable or fixed work schedule?"
        }

    val variableScheduleText: String
        get() = when (language) {
            "fr" -> "Horaire variable"
            "es" -> "Horario variable"
            else -> "Variable Schedule"
        }

    val hoursChangeWeeklyText: String
        get() = when (language) {
            "fr" -> "Mes heures de travail changent d'une semaine à l'autre"
            "es" -> "Mis horarios de trabajo cambian de semana a semana"
            else -> "My work hours change from week to week"
        }

    val fixedScheduleText: String
        get() = when (language) {
            "fr" -> "Horaire fixe"
            "es" -> "Horario fijo"
            else -> "Fixed Schedule"
        }

    val consistentHoursText: String
        get() = when (language) {
            "fr" -> "Mes heures de travail sont constantes chaque semaine"
            "es" -> "Mis horarios de trabajo son consistentes cada semana"
            else -> "My work hours are consistent each week"
        }

    // MARK: - Step 6: Targets
    val targetsStepTitle: String
        get() = when (language) {
            "fr" -> "Définissez vos objectifs"
            "es" -> "Establece tus objetivos"
            else -> "Set Your Goals"
        }

    val targetsStepDescription: String
        get() = when (language) {
            "fr" -> "Définissez des objectifs quotidiens pour suivre vos progrès"
            "es" -> "Establece objetivos diarios para rastrear tu progreso"
            else -> "Set daily targets to track your progress"
        }

    val tipTargetPercentText: String
        get() = when (language) {
            "fr" -> "Objectif de pourboire %"
            "es" -> "Objetivo de propina %"
            else -> "Tip Target %"
        }

    val dailySalesTargetText: String
        get() = when (language) {
            "fr" -> "Objectif de ventes quotidien"
            "es" -> "Objetivo de ventas diario"
            else -> "Daily Sales Target"
        }

    val dailyHoursTargetText: String
        get() = when (language) {
            "fr" -> "Objectif d'heures quotidien"
            "es" -> "Objetivo de horas diario"
            else -> "Daily Hours Target"
        }

    // MARK: - Step 7: Completion
    val completionStepTitle: String
        get() = when (language) {
            "fr" -> "🎉 Vous êtes prêt!"
            "es" -> "🎉 ¡Estás listo!"
            else -> "🎉 You're All Set!"
        }

    val completionStepDescription: String
        get() = when (language) {
            "fr" -> "Bienvenue sur ProTip365! Vous êtes prêt à commencer à suivre vos pourboires et gains."
            "es" -> "¡Bienvenido a ProTip365! Estás listo para comenzar a rastrear tus propinas y ganancias."
            else -> "Welcome to ProTip365! You're ready to start tracking your tips and earnings."
        }

    val whatsNextText: String
        get() = when (language) {
            "fr" -> "Et maintenant?"
            "es" -> "¿Qué sigue?"
            else -> "What's Next?"
        }

    val startAddingShiftsText: String
        get() = when (language) {
            "fr" -> "• Commencer à ajouter vos quarts et pourboires"
            "es" -> "• Comenzar a agregar tus turnos y propinas"
            else -> "• Start adding your shifts and tips"
        }

    val viewEarningsDashboardText: String
        get() = when (language) {
            "fr" -> "• Voir vos gains sur le tableau de bord"
            "es" -> "• Ver tus ganancias en el panel"
            else -> "• View your earnings on the dashboard"
        }

    val trackProgressGoalsText: String
        get() = when (language) {
            "fr" -> "• Suivre vos progrès vers les objectifs"
            "es" -> "• Rastrear tu progreso hacia los objetivos"
            else -> "• Track your progress toward goals"
        }

    val exportDataAnytimeText: String
        get() = when (language) {
            "fr" -> "• Exporter vos données à tout moment"
            "es" -> "• Exportar tus datos en cualquier momento"
            else -> "• Export your data anytime"
        }
}






