package com.protip365.app.presentation.auth

import com.protip365.app.domain.repository.AuthRepository
import com.protip365.app.domain.repository.UserRepository
import io.mockk.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.*
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.Assert.*

@OptIn(ExperimentalCoroutinesApi::class)
class AuthViewModelTest {
    
    private lateinit var authViewModel: AuthViewModel
    private lateinit var authRepository: AuthRepository
    private lateinit var userRepository: UserRepository
    private val testDispatcher = StandardTestDispatcher()
    
    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        authRepository = mockk()
        userRepository = mockk()
        authViewModel = AuthViewModel(authRepository, userRepository)
    }
    
    @After
    fun tearDown() {
        Dispatchers.resetMain()
        clearAllMocks()
    }
    
    @Test
    fun `signIn with valid credentials should update state correctly`() = runTest {
        // Given
        val email = "test@example.com"
        val password = "password123"
        val mockUser = com.protip365.app.data.models.User(
            userId = "user123",
            email = email,
            name = "Test User",
            phone = null,
            createdAt = "2024-01-01T00:00:00",
            useMultipleEmployers = false
        )
        
        coEvery { authRepository.signIn(email, password) } returns Result.success(mockUser)
        
        // When
        authViewModel.signIn(email, password)
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Then
        val state = authViewModel.authState.value
        assertFalse(state.isLoading)
        assertTrue(state.isAuthenticated)
        assertNull(state.error)
        assertEquals(email, state.email)
    }
    
    @Test
    fun `signIn with invalid credentials should show error`() = runTest {
        // Given
        val email = "test@example.com"
        val password = "wrongpassword"
        val errorMessage = "Invalid credentials"
        
        coEvery { authRepository.signIn(email, password) } returns Result.failure(Exception(errorMessage))
        
        // When
        authViewModel.signIn(email, password)
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Then
        val state = authViewModel.authState.value
        assertFalse(state.isLoading)
        assertFalse(state.isAuthenticated)
        assertEquals(errorMessage, state.error)
    }
    
    @Test
    fun `signUp with valid data should create user successfully`() = runTest {
        // Given
        val name = "Test User"
        val email = "test@example.com"
        val password = "password123"
        val mockUser = com.protip365.app.data.models.User(
            userId = "user123",
            email = email,
            name = name,
            phone = null,
            createdAt = "2024-01-01T00:00:00",
            useMultipleEmployers = false
        )
        
        coEvery { authRepository.signUp(name, email, password) } returns Result.success(mockUser)
        
        // When
        authViewModel.signUp(name, email, password)
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Then
        val state = authViewModel.authState.value
        assertFalse(state.isLoading)
        assertTrue(state.isAuthenticated)
        assertNull(state.error)
        assertEquals(email, state.email)
        assertEquals(name, state.name)
    }
    
    @Test
    fun `signOut should clear authentication state`() = runTest {
        // Given
        coEvery { authRepository.signOut() } returns Result.success(Unit)
        
        // When
        authViewModel.signOut()
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Then
        val state = authViewModel.authState.value
        assertFalse(state.isAuthenticated)
        assertNull(state.email)
        assertNull(state.name)
        assertNull(state.error)
    }
    
    @Test
    fun `resetPassword with valid email should succeed`() = runTest {
        // Given
        val email = "test@example.com"
        coEvery { authRepository.resetPassword(email) } returns Result.success(Unit)
        
        // When
        authViewModel.resetPassword(email)
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Then
        val state = authViewModel.authState.value
        assertFalse(state.isLoading)
        assertNull(state.error)
    }
    
    @Test
    fun `checkAuthState should load current user if authenticated`() = runTest {
        // Given
        val mockUser = com.protip365.app.data.models.User(
            userId = "user123",
            email = "test@example.com",
            name = "Test User",
            phone = null,
            createdAt = "2024-01-01T00:00:00",
            useMultipleEmployers = false
        )
        
        coEvery { authRepository.getCurrentUser() } returns mockUser
        
        // When
        authViewModel.checkAuthState()
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Then
        val state = authViewModel.authState.value
        assertTrue(state.isAuthenticated)
        assertEquals("test@example.com", state.email)
        assertEquals("Test User", state.name)
        assertFalse(state.isLoading)
    }
    
    @Test
    fun `checkAuthState should not authenticate if no current user`() = runTest {
        // Given
        coEvery { authRepository.getCurrentUser() } returns null
        
        // When
        authViewModel.checkAuthState()
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Then
        val state = authViewModel.authState.value
        assertFalse(state.isAuthenticated)
        assertNull(state.email)
        assertFalse(state.isLoading)
    }
}


