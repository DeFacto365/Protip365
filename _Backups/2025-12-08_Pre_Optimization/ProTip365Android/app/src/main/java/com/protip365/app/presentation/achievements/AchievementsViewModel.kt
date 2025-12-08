package com.protip365.app.presentation.achievements

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.protip365.app.domain.repository.AchievementRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class AchievementsState(
    val isLoading: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class AchievementsViewModel @Inject constructor(
    private val achievementRepository: AchievementRepository
) : ViewModel() {
    
    private val _state = MutableStateFlow(AchievementsState())
    val state: StateFlow<AchievementsState> = _state.asStateFlow()
    
    private val _achievements = MutableStateFlow<List<com.protip365.app.data.models.AchievementDefinition>>(emptyList())
    val achievements: StateFlow<List<com.protip365.app.data.models.AchievementDefinition>> = _achievements.asStateFlow()
    
    private val _userAchievements = MutableStateFlow<List<com.protip365.app.data.models.UserAchievement>>(emptyList())
    val userAchievements: StateFlow<List<com.protip365.app.data.models.UserAchievement>> = _userAchievements.asStateFlow()
    
    init {
        loadAchievements()
    }
    
    private fun loadAchievements() {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true, error = null)
            
            try {
                val achievementsList = achievementRepository.getAllAchievements()
                val userAchievementsList = achievementRepository.getUserAchievements("dummy_user_id")
                
                _achievements.value = achievementsList
                _userAchievements.value = userAchievementsList
                
                _state.value = _state.value.copy(isLoading = false)
            } catch (e: Exception) {
                _state.value = _state.value.copy(
                    isLoading = false,
                    error = e.message ?: "Failed to load achievements"
                )
            }
        }
    }
    
    fun refresh() {
        loadAchievements()
    }
}