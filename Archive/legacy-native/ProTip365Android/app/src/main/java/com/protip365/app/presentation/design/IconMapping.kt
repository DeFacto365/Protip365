package com.protip365.app.presentation.design

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.ui.graphics.vector.ImageVector

/**
 * Maps iOS SF Symbols to Android Material Icons for consistency across platforms
 * Based on the iOS app's IconNames structure
 */
object IconMapping {
    
    // MARK: - Navigation (Tab Bar & Sidebar)
    object Navigation {
        val dashboard: ImageVector = Icons.Default.BarChart
        val dashboardFill: ImageVector = Icons.Filled.BarChart
        val calendar: ImageVector = Icons.Default.CalendarMonth
        val calendarFill: ImageVector = Icons.Filled.CalendarMonth
        val employers: ImageVector = Icons.Default.Business
        val employersFill: ImageVector = Icons.Filled.Business
        val calculator: ImageVector = Icons.Default.Calculate
        val calculatorFill: ImageVector = Icons.Filled.Calculate
        val settings: ImageVector = Icons.Default.Settings
        val settingsFill: ImageVector = Icons.Filled.Settings
    }

    // MARK: - Actions
    object Actions {
        val add: ImageVector = Icons.Default.AddCircle
        val edit: ImageVector = Icons.Default.Edit
        val delete: ImageVector = Icons.Default.Delete
        val save: ImageVector = Icons.Default.CheckCircle
        val cancel: ImageVector = Icons.Default.Cancel
        val share: ImageVector = Icons.Default.Share
        val export: ImageVector = Icons.Default.FileDownload
        val refresh: ImageVector = Icons.Default.Refresh
        val more: ImageVector = Icons.Default.MoreVert
        val close: ImageVector = Icons.Default.Close
    }

    // MARK: - Financial
    object Financial {
        val money: ImageVector = Icons.Default.AttachMoney
        val tips: ImageVector = Icons.Default.Paid
        val sales: ImageVector = Icons.Default.ShoppingCart
        val salary: ImageVector = Icons.Default.AccountBalance
        val hours: ImageVector = Icons.Default.Schedule
        val percentage: ImageVector = Icons.Default.Percent
        val income: ImageVector = Icons.AutoMirrored.Filled.TrendingUp
        val expense: ImageVector = Icons.AutoMirrored.Filled.TrendingDown
    }

    // MARK: - Status
    object Status {
        val success: ImageVector = Icons.Default.CheckCircle
        val error: ImageVector = Icons.Default.Error
        val warning: ImageVector = Icons.Default.Warning
        val info: ImageVector = Icons.Default.Info
        val help: ImageVector = Icons.AutoMirrored.Filled.Help
        val pending: ImageVector = Icons.Default.HourglassEmpty
        val complete: ImageVector = Icons.Default.Verified
    }

    // MARK: - Form Controls
    object Form {
        val dropdown: ImageVector = Icons.Default.KeyboardArrowDown
        val expand: ImageVector = Icons.Default.ExpandMore
        val collapse: ImageVector = Icons.Default.ExpandLess
        val next: ImageVector = Icons.Default.ChevronRight
        val back: ImageVector = Icons.Default.ChevronLeft
        val increment: ImageVector = Icons.Default.Add
        val decrement: ImageVector = Icons.Default.Remove
        val calendar: ImageVector = Icons.Default.CalendarMonth
        val time: ImageVector = Icons.Default.Schedule
    }

    // MARK: - Security
    object Security {
        val locked: ImageVector = Icons.Default.Lock
        val unlocked: ImageVector = Icons.Default.LockOpen
        val faceID: ImageVector = Icons.Default.Face
        val touchID: ImageVector = Icons.Default.Fingerprint
        val pin: ImageVector = Icons.Default.Pin
        val shield: ImageVector = Icons.Default.Security
        val key: ImageVector = Icons.Default.Key
    }

    // MARK: - Communication
    object Communication {
        val email: ImageVector = Icons.Default.Email
        val notification: ImageVector = Icons.Default.Notifications
        val notificationBadge: ImageVector = Icons.Default.NotificationImportant
        val notificationOff: ImageVector = Icons.Default.NotificationsOff
        val support: ImageVector = Icons.Default.Support
        val feedback: ImageVector = Icons.Default.Lightbulb
        val link: ImageVector = Icons.Default.Link
        val language: ImageVector = Icons.Default.Language
    }

    // MARK: - Achievements
    object Achievements {
        val trophy: ImageVector = Icons.Default.EmojiEvents
        val star: ImageVector = Icons.Default.Star
        val medal: ImageVector = Icons.Default.MilitaryTech
        val crown: ImageVector = Icons.Default.Diamond
        val target: ImageVector = Icons.Default.GpsFixed
        val flame: ImageVector = Icons.Default.LocalFireDepartment
        val badge: ImageVector = Icons.Default.WorkspacePremium
    }

    // MARK: - Data States
    object DataStates {
        val empty: ImageVector = Icons.Default.Inbox
        val error: ImageVector = Icons.Default.CloudOff
        val loading: ImageVector = Icons.Default.HourglassEmpty
        val offline: ImageVector = Icons.Default.WifiOff
        val sync: ImageVector = Icons.Default.Sync
    }
}
