package com.protip365.app.presentation.export

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.Composable
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ExportManager @Inject constructor() {
    
    private val _isExporting = MutableStateFlow(false)
    val isExporting: StateFlow<Boolean> = _isExporting.asStateFlow()
    
    private val _exportProgress = MutableStateFlow(0f)
    val exportProgress: StateFlow<Float> = _exportProgress.asStateFlow()
    
    private val _exportStatus = MutableStateFlow("")
    val exportStatus: StateFlow<String> = _exportStatus.asStateFlow()
    
    suspend fun exportToCSV(
        context: Context,
        shifts: List<com.protip365.app.data.models.Shift>,
        entries: List<com.protip365.app.data.models.Entry>,
        fileName: String? = null
    ): Uri? {
        _isExporting.value = true
        _exportProgress.value = 0f
        _exportStatus.value = "Preparing export..."
        
        try {
            val dateFormat = SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.getDefault())
            val defaultFileName = "protip365_export_${dateFormat.format(Date())}.csv"
            val finalFileName = fileName ?: defaultFileName
            
            _exportProgress.value = 0.2f
            _exportStatus.value = "Creating CSV file..."
            
            val csvContent = buildCSVContent(shifts, entries)
            
            _exportProgress.value = 0.6f
            _exportStatus.value = "Writing to file..."
            
            val file = File(context.getExternalFilesDir(null), finalFileName)
            FileWriter(file).use { writer ->
                writer.write(csvContent)
            }
            
            _exportProgress.value = 0.8f
            _exportStatus.value = "Finalizing..."
            
            val uri = Uri.fromFile(file)
            
            _exportProgress.value = 1f
            _exportStatus.value = "Export completed!"
            
            return uri
            
        } catch (e: Exception) {
            _exportStatus.value = "Export failed: ${e.message}"
            return null
        } finally {
            _isExporting.value = false
        }
    }
    
    suspend fun exportToPDF(
        context: Context,
        shifts: List<com.protip365.app.data.models.Shift>,
        entries: List<com.protip365.app.data.models.Entry>,
        fileName: String? = null
    ): Uri? {
        _isExporting.value = true
        _exportProgress.value = 0f
        _exportStatus.value = "Preparing PDF export..."
        
        try {
            val dateFormat = SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.getDefault())
            val defaultFileName = "protip365_export_${dateFormat.format(Date())}.pdf"
            val finalFileName = fileName ?: defaultFileName
            
            _exportProgress.value = 0.2f
            _exportStatus.value = "Generating PDF content..."
            
            // For now, create a simple text file as PDF
            // In a real implementation, you'd use a PDF library like iText or PDFBox
            val pdfContent = buildPDFContent(shifts, entries)
            
            _exportProgress.value = 0.6f
            _exportStatus.value = "Writing PDF file..."
            
            val file = File(context.getExternalFilesDir(null), finalFileName)
            FileWriter(file).use { writer ->
                writer.write(pdfContent)
            }
            
            _exportProgress.value = 0.8f
            _exportStatus.value = "Finalizing PDF..."
            
            val uri = Uri.fromFile(file)
            
            _exportProgress.value = 1f
            _exportStatus.value = "PDF export completed!"
            
            return uri
            
        } catch (e: Exception) {
            _exportStatus.value = "PDF export failed: ${e.message}"
            return null
        } finally {
            _isExporting.value = false
        }
    }
    
    fun shareData(
        context: Context,
        shifts: List<com.protip365.app.data.models.Shift>,
        entries: List<com.protip365.app.data.models.Entry>
    ): Intent {
        val shareText = buildShareText(shifts, entries)
        
        return Intent().apply {
            action = Intent.ACTION_SEND
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, shareText)
            putExtra(Intent.EXTRA_SUBJECT, "ProTip365 Data Export")
        }
    }
    
    private fun buildCSVContent(
        shifts: List<com.protip365.app.data.models.Shift>,
        entries: List<com.protip365.app.data.models.Entry>
    ): String {
        val csv = StringBuilder()
        
        // CSV Header
        csv.appendLine("Date,Type,Start Time,End Time,Hours,Tips,Sales,Wages,Total Revenue,Notes")
        
        // Add shifts
        shifts.forEach { shift ->
            csv.appendLine(
                "${shift.shiftDate}," +
                "Shift," +
                "${shift.startTime ?: ""}," +
                "${shift.endTime ?: ""}," +
                "${shift.hours}," +
                "${shift.tips}," +
                "${shift.sales}," +
                "${shift.hourlyRate ?: 0.0}," +
                "${shift.totalEarnings}," +
                "\"${shift.notes ?: ""}\""
            )
        }
        
        // Add entries
        entries.forEach { entry ->
            csv.appendLine(
                "${entry.entryDate}," +
                "Entry," +
                "N/A," +
                "N/A," +
                "0," +
                "${entry.tips}," +
                "${entry.sales}," +
                "${entry.hourlyRate ?: 0.0}," +
                "${entry.totalEarnings}," +
                "\"${entry.notes ?: ""}\""
            )
        }
        
        return csv.toString()
    }
    
    private fun buildPDFContent(
        shifts: List<com.protip365.app.data.models.Shift>,
        entries: List<com.protip365.app.data.models.Entry>
    ): String {
        val content = StringBuilder()
        
        content.appendLine("ProTip365 Data Export")
        content.appendLine("Generated: ${SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())}")
        content.appendLine("")
        
        // Summary
        val totalShifts = shifts.size
        val totalEntries = entries.size
        val totalHours = shifts.sumOf { it.hours }
        val totalTips = shifts.sumOf { it.tips } + entries.sumOf { it.tips }
        val totalSales = shifts.sumOf { it.sales } + entries.sumOf { it.sales }
        val totalRevenue = shifts.sumOf { it.totalEarnings } + entries.sumOf { it.totalEarnings }
        
        content.appendLine("SUMMARY")
        content.appendLine("Total Shifts: $totalShifts")
        content.appendLine("Total Entries: $totalEntries")
        content.appendLine("Total Hours: ${String.format("%.2f", totalHours)}")
        content.appendLine("Total Tips: $${String.format("%.2f", totalTips)}")
        content.appendLine("Total Sales: $${String.format("%.2f", totalSales)}")
        content.appendLine("Total Revenue: $${String.format("%.2f", totalRevenue)}")
        content.appendLine("")
        
        // Detailed data
        content.appendLine("DETAILED RECORDS")
        content.appendLine("")
        
        shifts.forEach { shift ->
            content.appendLine("SHIFT - ${shift.shiftDate}")
            content.appendLine("  Start: ${shift.startTime ?: "N/A"}")
            content.appendLine("  End: ${shift.endTime ?: "N/A"}")
            content.appendLine("  Hours: ${shift.hours}")
            content.appendLine("  Tips: $${String.format("%.2f", shift.tips)}")
            content.appendLine("  Sales: $${String.format("%.2f", shift.sales)}")
            content.appendLine("  Revenue: $${String.format("%.2f", shift.totalEarnings)}")
            if (shift.notes?.isNotEmpty() == true) {
                content.appendLine("  Notes: ${shift.notes}")
            }
            content.appendLine("")
        }
        
        entries.forEach { entry ->
            content.appendLine("ENTRY - ${entry.entryDate}")
            content.appendLine("  Tips: $${String.format("%.2f", entry.tips)}")
            content.appendLine("  Sales: $${String.format("%.2f", entry.sales)}")
            content.appendLine("  Revenue: $${String.format("%.2f", entry.totalEarnings)}")
            if (entry.notes?.isNotEmpty() == true) {
                content.appendLine("  Notes: ${entry.notes}")
            }
            content.appendLine("")
        }
        
        return content.toString()
    }
    
    private fun buildShareText(
        shifts: List<com.protip365.app.data.models.Shift>,
        entries: List<com.protip365.app.data.models.Entry>
    ): String {
        val totalShifts = shifts.size
        val totalEntries = entries.size
        val totalHours = shifts.sumOf { it.hours }
        val totalTips = shifts.sumOf { it.tips } + entries.sumOf { it.tips }
        val totalSales = shifts.sumOf { it.sales } + entries.sumOf { it.sales }
        val totalRevenue = shifts.sumOf { it.totalEarnings } + entries.sumOf { it.totalEarnings }
        
        return """
            📊 ProTip365 Summary
            
            📅 Total Shifts: $totalShifts
            📝 Total Entries: $totalEntries
            ⏰ Total Hours: ${String.format("%.2f", totalHours)}
            💰 Total Tips: $${String.format("%.2f", totalTips)}
            📈 Total Sales: $${String.format("%.2f", totalSales)}
            💵 Total Revenue: $${String.format("%.2f", totalRevenue)}
            
            Generated by ProTip365
        """.trimIndent()
    }
    
    fun clearExportStatus() {
        _exportStatus.value = ""
        _exportProgress.value = 0f
    }
}

enum class ExportFormat {
    CSV,
    PDF,
    SHARE
}

data class ExportOptions(
    val format: ExportFormat,
    val includeShifts: Boolean = true,
    val includeEntries: Boolean = true,
    val dateRange: DateRange? = null,
    val fileName: String? = null
)

data class DateRange(
    val startDate: java.time.LocalDate,
    val endDate: java.time.LocalDate
)
