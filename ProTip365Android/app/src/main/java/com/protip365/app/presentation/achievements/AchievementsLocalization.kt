package com.protip365.app.presentation.achievements

class AchievementsLocalization(private val language: String) {
    
    val achievementsText: String
        get() = when (language) {
            "fr" -> "Succès"
            "es" -> "Logros"
            else -> "Achievements"
        }
    
    val achievementProgressText: String
        get() = when (language) {
            "fr" -> "Progrès des succès"
            "es" -> "Progreso de logros"
            else -> "Achievement Progress"
        }
    
    val achievementsUnlockedText: String
        get() = when (language) {
            "fr" -> "succès débloqués"
            "es" -> "logros desbloqueados"
            else -> "achievements unlocked"
        }
    
    val achievementUnlockedText: String
        get() = when (language) {
            "fr" -> "🎉 Succès débloqué! 🎉"
            "es" -> "🎉 ¡Logro desbloqueado! 🎉"
            else -> "🎉 Achievement Unlocked! 🎉"
        }
    
    val continueText: String
        get() = when (language) {
            "fr" -> "Continuer"
            "es" -> "Continuar"
            else -> "Continue"
        }
    
    val backText: String
        get() = when (language) {
            "fr" -> "Retour"
            "es" -> "Atrás"
            else -> "Back"
        }
    
    val ofText: String
        get() = when (language) {
            "fr" -> "sur"
            "es" -> "de"
            else -> "of"
        }
    
    fun getAchievementTitle(achievementId: String): String {
        return when (achievementId) {
            "tip_master" -> when (language) {
                "fr" -> "Maître des pourboires"
                "es" -> "Maestro de propinas"
                else -> "Tip Master"
            }
            "consistency_king" -> when (language) {
                "fr" -> "Roi de la constance"
                "es" -> "Rey de la constancia"
                else -> "Consistency King"
            }
            "tip_target_crusher" -> when (language) {
                "fr" -> "Destructeur d'objectifs"
                "es" -> "Destructor de objetivos"
                else -> "Target Crusher"
            }
            "high_earner" -> when (language) {
                "fr" -> "Gros salaire"
                "es" -> "Alto ingreso"
                else -> "High Earner"
            }
            "elite_server" -> when (language) {
                "fr" -> "Serveur d'élite"
                "es" -> "Servidor de élite"
                else -> "Elite Server"
            }
            "tip_champion" -> when (language) {
                "fr" -> "Champion des pourboires"
                "es" -> "Campeón de propinas"
                else -> "Tip Champion"
            }
            "steady_tracker" -> when (language) {
                "fr" -> "Suivi régulier"
                "es" -> "Seguimiento constante"
                else -> "Steady Tracker"
            }
            "dedicated_logger" -> when (language) {
                "fr" -> "Enregistreur dédié"
                "es" -> "Registrador dedicado"
                else -> "Dedicated Logger"
            }
            "tracking_legend" -> when (language) {
                "fr" -> "Légende du suivi"
                "es" -> "Leyenda del seguimiento"
                else -> "Tracking Legend"
            }
            "top_performer" -> when (language) {
                "fr" -> "Meilleur performeur"
                "es" -> "Mejor desempeño"
                else -> "Top Performer"
            }
            "sales_star" -> when (language) {
                "fr" -> "Étoile des ventes"
                "es" -> "Estrella de ventas"
                else -> "Sales Star"
            }
            "target_crusher" -> when (language) {
                "fr" -> "Écraseur de cibles"
                "es" -> "Triturador de metas"
                else -> "Target Crusher"
            }
            "goal_getter" -> when (language) {
                "fr" -> "Atteinte d'objectifs"
                "es" -> "Cumplidor de metas"
                else -> "Goal Getter"
            }
            "perfect_month" -> when (language) {
                "fr" -> "Mois parfait"
                "es" -> "Mes perfecto"
                else -> "Perfect Month"
            }
            else -> achievementId
        }
    }
    
    fun getAchievementDescription(achievementId: String): String {
        return when (achievementId) {
            "tip_master" -> when (language) {
                "fr" -> "Atteindre 20%+ de moyenne de pourboires"
                "es" -> "Lograr un promedio de propinas del 20%+"
                else -> "Achieve 20%+ tip average"
            }
            "consistency_king" -> when (language) {
                "fr" -> "Entrer des données pendant 7 jours consécutifs"
                "es" -> "Ingresar datos durante 7 días consecutivos"
                else -> "Enter data for 7 consecutive days"
            }
            "tip_target_crusher" -> when (language) {
                "fr" -> "Dépasser l'objectif de pourboires de 50%"
                "es" -> "Superar el objetivo de propinas en un 50%"
                else -> "Exceed tip target by 50%"
            }
            "high_earner" -> when (language) {
                "fr" -> "Gagner 30$/heure en moyenne"
                "es" -> "Ganar \$30+/hora en promedio"
                else -> "Earn \$30+/hour average"
            }
            "elite_server" -> when (language) {
                "fr" -> "Atteindre 25%+ de moyenne de pourboires"
                "es" -> "Lograr un promedio de propinas del 25%+"
                else -> "Achieve 25%+ tip average"
            }
            "tip_champion" -> when (language) {
                "fr" -> "Atteindre 30%+ de moyenne de pourboires"
                "es" -> "Lograr un promedio de propinas del 30%+"
                else -> "Achieve 30%+ tip average"
            }
            "steady_tracker" -> when (language) {
                "fr" -> "Suivre 7 jours consécutifs"
                "es" -> "Seguir 7 días consecutivos"
                else -> "Track 7 consecutive days"
            }
            "dedicated_logger" -> when (language) {
                "fr" -> "Suivre 30 jours consécutifs"
                "es" -> "Seguir 30 días consecutivos"
                else -> "Track 30 consecutive days"
            }
            "tracking_legend" -> when (language) {
                "fr" -> "Suivre 100 jours consécutifs"
                "es" -> "Seguir 100 días consecutivos"
                else -> "Track 100 consecutive days"
            }
            "top_performer" -> when (language) {
                "fr" -> "Gagner 50$/heure en moyenne"
                "es" -> "Ganar \$50+/hora en promedio"
                else -> "Earn \$50+/hour average"
            }
            "sales_star" -> when (language) {
                "fr" -> "Servir 1000\$+ en un seul quart"
                "es" -> "Servir \$1000+ en un turno"
                else -> "Serve \$1000+ in one shift"
            }
            "target_crusher" -> when (language) {
                "fr" -> "Dépasser l'objectif de 50%"
                "es" -> "Superar el objetivo en un 50%"
                else -> "Exceed goal by 50%"
            }
            "goal_getter" -> when (language) {
                "fr" -> "Atteindre tous les objectifs hebdomadaires"
                "es" -> "Cumplir todas las metas semanales"
                else -> "Meet all weekly targets"
            }
            "perfect_month" -> when (language) {
                "fr" -> "Atteindre tous les objectifs mensuels"
                "es" -> "Cumplir todas las metas mensuales"
                else -> "Meet all monthly targets"
            }
            else -> ""
        }
    }
    
    fun getAchievementMessage(achievementId: String): String {
        return when (achievementId) {
            "tip_master" -> when (language) {
                "fr" -> "20%+ de moyenne de pourboires atteinte!"
                "es" -> "¡Promedio de propinas del 20%+ alcanzado!"
                else -> "Achieved 20%+ tip average!"
            }
            "consistency_king" -> when (language) {
                "fr" -> "Série de 7 jours atteinte!"
                "es" -> "¡Racha de 7 días alcanzada!"
                else -> "7-day entry streak achieved!"
            }
            "tip_target_crusher" -> when (language) {
                "fr" -> "Objectif de pourboires dépassé de 50%!"
                "es" -> "¡Objetivo de propinas superado en un 50%!"
                else -> "Exceeded tip target by 50%!"
            }
            "high_earner" -> when (language) {
                "fr" -> "Moyenne de 30\$/heure atteinte!"
                "es" -> "¡Promedio de \$30+/hora alcanzado!"
                else -> "Achieved \$30+/hour average!"
            }
            "elite_server" -> when (language) {
                "fr" -> "25%+ de moyenne de pourboires atteinte!"
                "es" -> "¡Promedio de propinas del 25%+ alcanzado!"
                else -> "Achieved 25%+ tip average!"
            }
            "tip_champion" -> when (language) {
                "fr" -> "30%+ de moyenne de pourboires atteinte!"
                "es" -> "¡Promedio de propinas del 30%+ alcanzado!"
                else -> "Achieved 30%+ tip average!"
            }
            "steady_tracker" -> when (language) {
                "fr" -> "Série de 7 jours de suivi!"
                "es" -> "¡Racha de 7 días de seguimiento!"
                else -> "7-day tracking streak!"
            }
            "dedicated_logger" -> when (language) {
                "fr" -> "Série de 30 jours de suivi!"
                "es" -> "¡Racha de 30 días de seguimiento!"
                else -> "30-day tracking streak!"
            }
            "tracking_legend" -> when (language) {
                "fr" -> "Série de 100 jours de suivi!"
                "es" -> "¡Racha de 100 días de seguimiento!"
                else -> "100-day tracking streak!"
            }
            "top_performer" -> when (language) {
                "fr" -> "Moyenne de 50\$/heure atteinte!"
                "es" -> "¡Promedio de \$50+/hora alcanzado!"
                else -> "Achieved \$50+/hour average!"
            }
            "sales_star" -> when (language) {
                "fr" -> "1000\$+ de ventes en un quart!"
                "es" -> "¡\$1000+ de ventas en un turno!"
                else -> "\$1000+ in sales in one shift!"
            }
            "target_crusher" -> when (language) {
                "fr" -> "Objectif dépassé de 50%!"
                "es" -> "¡Objetivo superado en un 50%!"
                else -> "Exceeded goal by 50%!"
            }
            "goal_getter" -> when (language) {
                "fr" -> "Tous les objectifs hebdomadaires atteints!"
                "es" -> "¡Todas las metas semanales cumplidas!"
                else -> "All weekly targets met!"
            }
            "perfect_month" -> when (language) {
                "fr" -> "Tous les objectifs mensuels atteints!"
                "es" -> "¡Todas las metas mensuales cumplidas!"
                else -> "All monthly targets met!"
            }
            else -> when (language) {
                "fr" -> "Félicitations!"
                "es" -> "¡Felicitaciones!"
                else -> "Congratulations!"
            }
        }
    }
}

