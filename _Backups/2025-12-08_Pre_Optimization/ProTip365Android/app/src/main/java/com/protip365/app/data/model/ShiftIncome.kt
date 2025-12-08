package com.protip365.app.data.model

import com.protip365.app.data.models.CompletedShift

data class ShiftIncome(
    val id: String,
    val shift_date: String,
    val start_time: String,
    val end_time: String,
    val hours: Double?,
    val hourly_rate: Double,
    val base_income: Double?,
    val sales: Double?,
    val tips: Double?,
    val total_income: Double?,
    val employer_name: String?,
    val employer_id: String?
) {
    companion object {
        fun from(completedShift: CompletedShift): ShiftIncome {
            return ShiftIncome(
                id = completedShift.expectedShift.id,
                shift_date = completedShift.shiftDate,
                start_time = completedShift.expectedShift.startTime,
                end_time = completedShift.expectedShift.endTime,
                hours = completedShift.hours,
                hourly_rate = completedShift.expectedShift.hourlyRate,
                base_income = completedShift.shiftEntry?.getGrossIncome(completedShift.expectedShift.hourlyRate),
                sales = completedShift.sales,
                tips = completedShift.tips,
                total_income = completedShift.shiftEntry?.getTotalIncome(completedShift.expectedShift.hourlyRate),
                employer_name = completedShift.employerName,
                employer_id = completedShift.expectedShift.employerId
            )
        }
        
        fun fromList(completedShifts: List<CompletedShift>): List<ShiftIncome> {
            return completedShifts.map { from(it) }
        }
    }
}

