import Foundation

// MARK: - Onboarding Localization

struct OnboardingLocalization {
    private let language: String

    init(language: String) {
        self.language = language
    }

    // MARK: - Welcome and General

    var welcomeTitle: String {
        switch language {
        case "fr": return "Configuration initiale"
        case "es": return "Configuración inicial"
        default: return "Initial Setup"
        }
    }

    var backButtonText: String {
        switch language {
        case "fr": return "Retour"
        case "es": return "Atrás"
        default: return "Back"
        }
    }

    var nextButtonText: String {
        switch language {
        case "fr": return "Suivant"
        case "es": return "Siguiente"
        default: return "Next"
        }
    }

    var finishButtonText: String {
        switch language {
        case "fr": return "Terminer"
        case "es": return "Finalizar"
        default: return "Finish"
        }
    }

    var skipButtonText: String {
        switch language {
        case "fr": return "Passer"
        case "es": return "Omitir"
        default: return "Skip"
        }
    }

    var cancelButtonText: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }

    func stepTitle(currentStep: Int, totalSteps: Int) -> String {
        switch language {
        case "fr": return "Étape \(currentStep) sur \(totalSteps)"
        case "es": return "Paso \(currentStep) de \(totalSteps)"
        default: return "Step \(currentStep) of \(totalSteps)"
        }
    }

    // MARK: - Step 1: Language

    var languageSelectionTitle: String {
        switch language {
        case "fr": return "Choisissez votre langue"
        case "es": return "Elige tu idioma"
        default: return "Choose Your Language"
        }
    }

    var languageStepDescription: String {
        switch language {
        case "fr": return "Dans quelle langue préférez-vous utiliser l'application?"
        case "es": return "¿En qué idioma prefieres usar la aplicación?"
        default: return "What language would you prefer to use the app in?"
        }
    }

    // MARK: - Step 2: Multiple Employers

    var multipleEmployersTitle: String {
        switch language {
        case "fr": return "Employeurs multiples"
        case "es": return "Múltiples empleadores"
        default: return "Multiple Employers"
        }
    }

    var multipleEmployersQuestion: String {
        switch language {
        case "fr": return "Travaillez-vous pour plusieurs employeurs?"
        case "es": return "¿Trabajas para múltiples empleadores?"
        default: return "Do you work for multiple employers?"
        }
    }

    var multipleEmployersStepDescription: String {
        switch language {
        case "fr": return "Aidez-nous à personnaliser l'application pour votre situation de travail"
        case "es": return "Ayúdanos a personalizar la aplicación para tu situación laboral"
        default: return "Help us customize the app for your work situation"
        }
    }

    var multipleEmployersExplanationTitle: String {
        switch language {
        case "fr": return "Pourquoi cette question?"
        case "es": return "¿Por qué esta pregunta?"
        default: return "Why this question?"
        }
    }

    var multipleEmployersExplanation: String {
        switch language {
        case "fr": return "Si vous avez plusieurs employeurs, vous pourrez créer des quarts de travail et définir des entrées par employeur. Cela vous permettra de mieux organiser et analyser vos revenus par source."
        case "es": return "Si tienes múltiples empleadores, podrás crear turnos y definir entradas por empleador. Esto te permitirá organizar y analizar mejor tus ingresos por fuente."
        default: return "If you have multiple employers, you'll be able to create shifts and define entries per employer. This will help you better organize and analyze your income by source."
        }
    }

    var employerNameLabel: String {
        switch language {
        case "fr": return "Nom de votre employeur"
        case "es": return "Nombre de su empleador"
        default: return "Your employer's name"
        }
    }

    var employerNamePlaceholder: String {
        switch language {
        case "fr": return "Ex: Restaurant ABC"
        case "es": return "Ej: Restaurante ABC"
        default: return "e.g. ABC Restaurant"
        }
    }

    var setupEmployersTitle: String {
        switch language {
        case "fr": return "Configurer les employeurs"
        case "es": return "Configurar empleadores"
        default: return "Set Up Employers"
        }
    }

    var doneButtonText: String {
        switch language {
        case "fr": return "Terminé"
        case "es": return "Hecho"
        default: return "Done"
        }
    }

    // MARK: - Step 3: Week Start

    var weekStartTitle: String {
        switch language {
        case "fr": return "Début de semaine"
        case "es": return "Inicio de semana"
        default: return "Week Start Day"
        }
    }

    var weekStartStepDescription: String {
        switch language {
        case "fr": return "Quel jour commence votre semaine de travail? Cela affectera vos rapports hebdomadaires."
        case "es": return "¿Qué día comienza tu semana laboral? Esto afectará tus reportes semanales."
        default: return "What day does your work week start? This will affect your weekly reports."
        }
    }

    var weekStartExplanationTitle: String {
        switch language {
        case "fr": return "Pourquoi cette question?"
        case "es": return "¿Por qué esta pregunta?"
        default: return "Why this matters"
        }
    }

    var weekStartExplanation: String {
        switch language {
        case "fr": return "Ceci définira comment vos rapports hebdomadaires sont calculés et organisés."
        case "es": return "Esto definirá cómo se calculan y organizan tus reportes semanales."
        default: return "This will define how your weekly reports are calculated and organized."
        }
    }

    func localizedWeekDay(_ index: Int) -> String {
        let weekDays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        switch language {
        case "fr":
            return ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"][index]
        case "es":
            return ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"][index]
        default:
            return weekDays[index]
        }
    }

    // MARK: - Step 4: Security

    var securityTitle: String {
        switch language {
        case "fr": return "Sécurité"
        case "es": return "Seguridad"
        default: return "Security"
        }
    }

    var securityStepDescription: String {
        switch language {
        case "fr": return "Sécurisez l'accès à vos données financières sensibles"
        case "es": return "Asegura el acceso a tus datos financieros sensibles"
        default: return "Secure access to your sensitive financial data"
        }
    }

    var securityExplanationTitle: String {
        switch language {
        case "fr": return "Sécurité supplémentaire"
        case "es": return "Seguridad adicional"
        default: return "Additional Security"
        }
    }

    var securityExplanation: String {
        switch language {
        case "fr": return "En plus de votre nom d'utilisateur et mot de passe, vous pouvez ajouter une couche de sécurité supplémentaire pour restreindre l'accès à l'application."
        case "es": return "Además de tu nombre de usuario y contraseña, puedes agregar una capa adicional de seguridad para restringir el acceso a la aplicación."
        default: return "On top of your username and password, you can add an additional layer of security to restrict access to the app."
        }
    }

    var faceIDText: String {
        switch language {
        case "fr": return "Face ID / Touch ID"
        case "es": return "Face ID / Touch ID"
        default: return "Face ID / Touch ID"
        }
    }

    var pinCodeText: String {
        switch language {
        case "fr": return "Code PIN"
        case "es": return "Código PIN"
        default: return "PIN Code"
        }
    }

    var noSecurityText: String {
        switch language {
        case "fr": return "Aucune"
        case "es": return "Ninguna"
        default: return "None"
        }
    }

    // MARK: - Step 5: Variable Schedule

    var variableScheduleTitle: String {
        switch language {
        case "fr": return "Horaire variable"
        case "es": return "Horario variable"
        default: return "Variable Schedule"
        }
    }

    var variableScheduleQuestion: String {
        switch language {
        case "fr": return "Avez-vous un horaire de travail variable?"
        case "es": return "¿Tienes un horario de trabajo variable?"
        default: return "Do you have a variable work schedule?"
        }
    }

    var variableScheduleStepDescription: String {
        switch language {
        case "fr": return "Aidez-nous à configurer vos objectifs en fonction de votre horaire"
        case "es": return "Ayúdanos a configurar tus objetivos según tu horario"
        default: return "Help us set up your goals based on your schedule"
        }
    }

    var variableScheduleExplanationTitle: String {
        switch language {
        case "fr": return "Pourquoi cette question?"
        case "es": return "¿Por qué esta pregunta?"
        default: return "Why this question?"
        }
    }

    var variableScheduleExplanation: String {
        switch language {
        case "fr": return "Si vous avez un horaire variable, nous ne configurerons que des objectifs quotidiens au lieu d'objectifs hebdomadaires et mensuels, car ceux-ci sont plus pertinents pour les horaires fixes et définis."
        case "es": return "Si tienes un horario variable, solo configuraremos objetivos diarios en lugar de objetivos semanales y mensuales, ya que estos son más relevantes para horarios fijos y definidos."
        default: return "If you have a variable schedule, we will only set daily targets instead of weekly and monthly targets, as those are more relevant for fixed, defined schedules."
        }
    }

    // MARK: - Step 6: Sales and Tip Targets

    var salesAndTipTargetsTitle: String {
        switch language {
        case "fr": return "Objectifs et cibles"
        case "es": return "Objetivos y metas"
        default: return "Goals & Targets"
        }
    }

    var salesAndTipTargetsStepDescription: String {
        switch language {
        case "fr": return "Définissez vos objectifs quotidiens pour les pourboires, les ventes et les heures"
        case "es": return "Establece tus objetivos diarios para propinas, ventas y horas"
        default: return "Set your daily goals for tips, sales, and hours"
        }
    }

    var tipPercentageTargetLabel: String {
        switch language {
        case "fr": return "Pourcentage de pourboire cible"
        case "es": return "Porcentaje objetivo de propinas"
        default: return "Target Tip Percentage"
        }
    }

    var tipPercentageNoteTitle: String {
        switch language {
        case "fr": return "Pourcentage des ventes"
        case "es": return "Porcentaje de ventas"
        default: return "Percentage of Sales"
        }
    }

    var tipPercentageNoteMessage: String {
        switch language {
        case "fr": return "Définissez votre objectif de pourboire en pourcentage de vos ventes totales. Par exemple, 15% signifie que vous visez 15% de vos ventes en pourboires."
        case "es": return "Establezca su objetivo de propinas como porcentaje de sus ventas totales. Por ejemplo, 15% significa que apunta a 15% de sus ventas en propinas."
        default: return "Set your tip goal as a percentage of your total sales. For example, 15% means you aim for 15% of your sales in tips."
        }
    }

    var averageDeductionPercentageLabel: String {
        switch language {
        case "fr": return "Taux d'impôt moyen"
        case "es": return "Tasa de impuestos promedio"
        default: return "Average Income Tax Rate"
        }
    }

    var averageDeductionPercentageNoteTitle: String {
        switch language {
        case "fr": return "Impôt sur le revenu"
        case "es": return "Impuesto sobre la renta"
        default: return "Income Tax"
        }
    }

    var averageDeductionPercentageNoteMessage: String {
        switch language {
        case "fr": return "Taux d'impôt moyen sur votre revenu total. Utilisé pour calculer votre revenu net estimé après impôts."
        case "es": return "Tasa promedio de impuestos sobre sus ingresos totales. Se usa para calcular sus ingresos netos estimados después de impuestos."
        default: return "Average income tax rate on your total income. Used to calculate your estimated net income after taxes."
        }
    }

    var dailySalesTargetLabel: String {
        switch language {
        case "fr": return "Ventes prévue/jour"
        case "es": return "Ventas diarias"
        default: return "Daily Sales"
        }
    }

    var weeklySalesTargetLabel: String {
        switch language {
        case "fr": return "Ventes hebdomadaires"
        case "es": return "Ventas semanales"
        default: return "Weekly Sales"
        }
    }

    var monthlySalesTargetLabel: String {
        switch language {
        case "fr": return "Ventes mensuelles"
        case "es": return "Ventas mensuales"
        default: return "Monthly Sales"
        }
    }

    var dailyHoursTargetLabel: String {
        switch language {
        case "fr": return "# d'heures/jour"
        case "es": return "Horas diarias"
        default: return "Daily Hours"
        }
    }

    var weeklyHoursTargetLabel: String {
        switch language {
        case "fr": return "Heures hebdomadaires"
        case "es": return "Horas semanales"
        default: return "Weekly Hours"
        }
    }

    var monthlyHoursTargetLabel: String {
        switch language {
        case "fr": return "Heures mensuelles"
        case "es": return "Horas mensuales"
        default: return "Monthly Hours"
        }
    }

    var variableScheduleNoteTitle: String {
        switch language {
        case "fr": return "Horaire variable"
        case "es": return "Horario variable"
        default: return "Variable Schedule"
        }
    }

    var variableScheduleNoteMessage: String {
        switch language {
        case "fr": return "Puisque vous avez un horaire variable, seuls les objectifs quotidiens sont affichés car ils sont plus pertinents pour votre situation."
        case "es": return "Como tienes un horario variable, solo se muestran los objetivos diarios ya que son más relevantes para tu situación."
        default: return "Since you have a variable schedule, only daily targets are shown as they're more relevant for your situation."
        }
    }

    // MARK: - Step 7: How to Use

    var howToUseTitle: String {
        switch language {
        case "fr": return "Comment utiliser l'app"
        case "es": return "Cómo usar la app"
        default: return "How to Use the App"
        }
    }

    var howToUseStepDescription: String {
        switch language {
        case "fr": return "Apprenez le processus étape par étape pour suivre vos pourboires"
        case "es": return "Aprende el proceso paso a paso para rastrear tus propinas"
        default: return "Learn the step-by-step process to track your tips"
        }
    }

    var step1EmployersTitle: String {
        switch language {
        case "fr": return "Créer vos employeurs"
        case "es": return "Crear tus empleadores"
        default: return "Create Your Employers"
        }
    }

    var step1EmployersDescription: String {
        switch language {
        case "fr": return "Commencez par ajouter vos employeurs dans l'onglet Employeurs. Cela vous aidera à organiser vos quarts et revenus par lieu de travail."
        case "es": return "Comienza agregando tus empleadores en la pestaña Empleadores. Esto te ayudará a organizar tus turnos e ingresos por lugar de trabajo."
        default: return "Start by adding your employers in the Employers tab. This helps organize your shifts and income by workplace."
        }
    }

    var step2CalendarTitle: String {
        switch language {
        case "fr": return "Créer vos quarts dans le calendrier"
        case "es": return "Crear turnos en el calendario"
        default: return "Create Shifts in Calendar"
        }
    }

    var step2CalendarDescription: String {
        switch language {
        case "fr": return "Utilisez l'onglet Calendrier pour créer des quarts de travail. Définissez vos heures, dates et employeur pour chaque quart."
        case "es": return "Usa la pestaña Calendario para crear turnos de trabajo. Define tus horas, fechas y empleador para cada turno."
        default: return "Use the Calendar tab to create work shifts. Set your hours, dates, and employer for each shift."
        }
    }

    var step3EntriesTitle: String {
        switch language {
        case "fr": return "Ajouter des entrées de pourboires"
        case "es": return "Agregar entradas de propinas"
        default: return "Add Tip Entries"
        }
    }

    var step3EntriesDescription: String {
        switch language {
        case "fr": return "Pour chaque quart, tapez dessus pour ajouter vos pourboires, ventes et heures réelles. C'est ici que vous enregistrez vos gains quotidiens."
        case "es": return "Para cada turno, tócalo para agregar tus propinas, ventas y horas reales. Aquí es donde registras tus ganancias diarias."
        default: return "For each shift, tap it to add your tips, sales, and actual hours. This is where you record your daily earnings."
        }
    }

    var step4DashboardTitle: String {
        switch language {
        case "fr": return "Voir vos statistiques dans le tableau de bord"
        case "es": return "Ver estadísticas en el panel"
        default: return "View Stats in Dashboard"
        }
    }

    var step4DashboardDescription: String {
        switch language {
        case "fr": return "Le tableau de bord vous montre un résumé de vos gains par jour, semaine, mois et année. Suivez vos progrès et vos tendances facilement."
        case "es": return "El panel te muestra un resumen de tus ganancias por día, semana, mes y año. Rastrea tu progreso y tendencias fácilmente."
        default: return "The dashboard shows you a rollup of your earnings by day, week, month, and year. Track your progress and trends easily."
        }
    }

    var syncFeaturesTitle: String {
        switch language {
        case "fr": return "Synchronisation multi-appareils"
        case "es": return "Sincronización multi-dispositivo"
        default: return "Multi-Device Sync"
        }
    }

    var syncFeaturesDescription: String {
        switch language {
        case "fr": return "Connectez-vous depuis iPhone, iPad, ou bientôt Android. Toutes vos données se synchronisent automatiquement entre vos appareils."
        case "es": return "Inicia sesión desde iPhone, iPad, o pronto Android. Todos tus datos se sincronizan automáticamente entre dispositivos."
        default: return "Log in from iPhone, iPad, or soon Android. All your data syncs automatically across your devices."
        }
    }

    // MARK: - Step Descriptions

    func currentStepDescription(for step: Int) -> String {
        switch step {
        case 1: return languageStepDescription
        case 2: return multipleEmployersStepDescription
        case 3: return weekStartStepDescription
        case 4: return securityStepDescription
        case 5: return variableScheduleStepDescription
        case 6: return salesAndTipTargetsStepDescription
        case 7: return howToUseStepDescription
        default: return ""
        }
    }

    var defaultEmployerLabel: String {
        switch language {
        case "fr": return "Employeur par défaut"
        case "es": return "Empleador predeterminado"
        default: return "Default Employer"
        }
    }

    var selectEmployerPlaceholder: String {
        switch language {
        case "fr": return "Sélectionner un employeur"
        case "es": return "Seleccionar empleador"
        default: return "Select Employer"
        }
    }
}