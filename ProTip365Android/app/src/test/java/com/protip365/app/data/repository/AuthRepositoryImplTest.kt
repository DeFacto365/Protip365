package com.protip365.app.data.repository

import com.protip365.app.data.models.User
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.auth.user.UserInfo
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.SupabaseClient
import io.mockk.*
import kotlinx.coroutines.runBlocking
import org.junit.Before
import org.junit.Test
import org.junit.Assert.*
import java.util.*

class AuthRepositoryImplTest {
    
    private lateinit var authRepository: AuthRepositoryImpl
    private lateinit var supabaseClient: SupabaseClient
    private lateinit var auth: Auth
    private lateinit var postgrest: Postgrest
    
    @Before
    fun setup() {
        supabaseClient = mockk()
        auth = mockk()
        postgrest = mockk()
        
        every { supabaseClient.auth } returns auth
        every { supabaseClient.postgrest } returns postgrest
        
        authRepository = AuthRepositoryImpl(supabaseClient)
    }
    
    @Test
    fun `signIn should return success when authentication succeeds`() = runBlocking {
        // Given
        val email = "test@example.com"
        val password = "password123"
        val userInfo = mockk<UserInfo> {
            every { id } returns "user123"
            every { email } returns email
            every { userMetadata } returns mapOf("name" to "Test User")
            every { createdAt } returns "2024-01-01T00:00:00Z"
        }
        
        val authResponse = mockk<io.github.jan.supabase.auth.AuthResponse> {
            every { user } returns userInfo
        }
        
        coEvery { auth.signInWith(Email) {
            this.email = email
            this.password = password
        } } returns authResponse
        
        val mockUser = User(
            userId = "user123",
            email = email,
            name = "Test User",
            phone = null,
            createdAt = "2024-01-01T00:00:00Z",
            useMultipleEmployers = false
        )
        
        coEvery { postgrest.from("users").select {
            filter { eq("id", "user123") }
        }.decodeSingleOrNull<User>() } returns mockUser
        
        // When
        val result = authRepository.signIn(email, password)
        
        // Then
        assertTrue(result.isSuccess)
        val user = result.getOrNull()
        assertNotNull(user)
        assertEquals("user123", user?.userId)
        assertEquals(email, user?.email)
        assertEquals("Test User", user?.name)
    }
    
    @Test
    fun `signIn should return failure when authentication fails`() = runBlocking {
        // Given
        val email = "test@example.com"
        val password = "wrongpassword"
        val exception = Exception("Invalid credentials")
        
        coEvery { auth.signInWith(Email) {
            this.email = email
            this.password = password
        } } throws exception
        
        // When
        val result = authRepository.signIn(email, password)
        
        // Then
        assertTrue(result.isFailure)
        assertEquals(exception.message, result.exceptionOrNull()?.message)
    }
    
    @Test
    fun `signUp should return success when registration succeeds`() = runBlocking {
        // Given
        val name = "Test User"
        val email = "test@example.com"
        val password = "password123"
        val userInfo = mockk<UserInfo> {
            every { id } returns "user123"
            every { email } returns email
            every { userMetadata } returns mapOf("name" to name)
            every { createdAt } returns "2024-01-01T00:00:00Z"
        }
        
        val authResponse = mockk<io.github.jan.supabase.auth.AuthResponse> {
            every { user } returns userInfo
        }
        
        coEvery { auth.signUpWith(Email) {
            this.email = email
            this.password = password
            this.data = mapOf("name" to name)
        } } returns authResponse
        
        val mockUser = User(
            userId = "user123",
            email = email,
            name = name,
            phone = null,
            createdAt = "2024-01-01T00:00:00Z",
            useMultipleEmployers = false
        )
        
        coEvery { postgrest.from("users").upsert(mockUser) } returns Unit
        
        // When
        val result = authRepository.signUp(name, email, password)
        
        // Then
        assertTrue(result.isSuccess)
        val user = result.getOrNull()
        assertNotNull(user)
        assertEquals("user123", user?.userId)
        assertEquals(email, user?.email)
        assertEquals(name, user?.name)
    }
    
    @Test
    fun `signOut should return success when logout succeeds`() = runBlocking {
        // Given
        coEvery { auth.signOut() } returns Unit
        
        // When
        val result = authRepository.signOut()
        
        // Then
        assertTrue(result.isSuccess)
    }
    
    @Test
    fun `resetPassword should return success when reset email is sent`() = runBlocking {
        // Given
        val email = "test@example.com"
        coEvery { auth.resetPasswordForEmail(email) } returns Unit
        
        // When
        val result = authRepository.resetPassword(email)
        
        // Then
        assertTrue(result.isSuccess)
    }
    
    @Test
    fun `getCurrentUser should return user when authenticated`() = runBlocking {
        // Given
        val userInfo = mockk<UserInfo> {
            every { id } returns "user123"
            every { email } returns "test@example.com"
            every { userMetadata } returns mapOf("name" to "Test User")
            every { createdAt } returns "2024-01-01T00:00:00Z"
        }
        
        coEvery { auth.currentUserOrNull() } returns userInfo
        
        val mockUser = User(
            userId = "user123",
            email = "test@example.com",
            name = "Test User",
            phone = null,
            createdAt = "2024-01-01T00:00:00Z",
            useMultipleEmployers = false
        )
        
        coEvery { postgrest.from("users").select {
            filter { eq("id", "user123") }
        }.decodeSingleOrNull<User>() } returns mockUser
        
        // When
        val user = authRepository.getCurrentUser()
        
        // Then
        assertNotNull(user)
        assertEquals("user123", user?.userId)
        assertEquals("test@example.com", user?.email)
        assertEquals("Test User", user?.name)
    }
    
    @Test
    fun `getCurrentUser should return null when not authenticated`() = runBlocking {
        // Given
        coEvery { auth.currentUserOrNull() } returns null
        
        // When
        val user = authRepository.getCurrentUser()
        
        // Then
        assertNull(user)
    }
}


