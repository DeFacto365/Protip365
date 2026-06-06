package com.protip365.app.domain.repository

import com.protip365.app.data.models.Employer
import kotlinx.coroutines.flow.Flow

interface EmployerRepository {
    suspend fun getEmployers(userId: String): List<Employer>
    suspend fun getEmployer(employerId: String): Employer?
    suspend fun createEmployer(employer: Employer): Result<Unit>
    suspend fun updateEmployer(employer: Employer): Result<Unit>
    suspend fun deleteEmployer(employerId: String): Result<Unit>
    suspend fun setEmployerActive(employerId: String, active: Boolean): Result<Unit>
    fun observeEmployers(userId: String): Flow<List<Employer>>
}