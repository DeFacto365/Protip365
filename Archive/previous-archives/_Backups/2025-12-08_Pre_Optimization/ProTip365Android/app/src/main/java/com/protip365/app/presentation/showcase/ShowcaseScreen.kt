package com.protip365.app.presentation.showcase

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController

@Composable
fun ShowcaseScreen(navController: NavController) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF8F9FA)),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        // Header Section
        item {
            ShowcaseHeader()
        }
        
        // Accordion Showcase Section
        item {
            AccordionShowcaseSection()
        }
        
        // App Screens Section
        item {
            AppScreensSection()
        }
        
        // Features Grid
        item {
            FeaturesGridSection()
        }
        
        // Download Section
        item {
            DownloadSection()
        }
    }
}

@Composable
fun ShowcaseHeader() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6)
                    )
                )
            )
            .clip(RoundedCornerShape(16.dp))
            .padding(24.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "ProTip365",
                fontSize = 32.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
            Text(
                text = "Track Your Tips & Maximize Your Earnings",
                fontSize = 18.sp,
                color = Color.White.copy(alpha = 0.9f),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
            Button(
                onClick = { },
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.White,
                    contentColor = Color(0xFF6366F1)
                ),
                modifier = Modifier.padding(top = 8.dp)
            ) {
                Text("Learn More", fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
fun AccordionShowcaseSection() {
    Column(
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "Awesome Features",
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFF1F2937)
        )
        Text(
            text = "Discover how ProTip365 helps you track, manage, and maximize your tip earnings with powerful features designed for service professionals.",
            fontSize = 16.sp,
            color = Color(0xFF6B7280)
        )
        
        // Accordion Items
        AccordionItem(
            title = "Smart Tip Tracking",
            content = "Automatically track your daily, weekly, and monthly tip earnings with intelligent categorization by employer and shift type.",
            icon = Icons.Default.AttachMoney,
            isExpanded = true
        )
        
        AccordionItem(
            title = "Multi-Employer Management",
            content = "Manage multiple employers and jobs simultaneously. Track earnings by location, compare performance, and optimize your schedule.",
            icon = Icons.Default.Business,
            isExpanded = false
        )
        
        AccordionItem(
            title = "Advanced Analytics",
            content = "Get detailed insights into your earning patterns, peak hours, and seasonal trends to maximize your income potential.",
            icon = Icons.Default.Analytics,
            isExpanded = false
        )
        
        AccordionItem(
            title = "Secure & Private",
            content = "Your financial data is encrypted and stored securely. Biometric authentication ensures only you can access your earnings information.",
            icon = Icons.Default.Security,
            isExpanded = false
        )
    }
}

@Composable
fun AccordionItem(
    title: String,
    content: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    isExpanded: Boolean
) {
    var expanded by remember { mutableStateOf(isExpanded) }
    
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Column {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = Color(0xFF6366F1),
                    modifier = Modifier.size(24.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = title,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color(0xFF1F2937),
                    modifier = Modifier.weight(1f)
                )
                Icon(
                    imageVector = if (expanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                    contentDescription = if (expanded) "Collapse" else "Expand",
                    tint = Color(0xFF6B7280)
                )
            }
            
            if (expanded) {
                HorizontalDivider(color = Color(0xFFE5E7EB))
                Text(
                    text = content,
                    fontSize = 14.sp,
                    color = Color(0xFF6B7280),
                    modifier = Modifier.padding(16.dp)
                )
            }
        }
    }
}

@Composable
fun AppScreensSection() {
    Column(
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "App Screens",
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFF1F2937)
        )
        Text(
            text = "Experience the intuitive interface designed for service professionals who need quick access to their earning data.",
            fontSize = 16.sp,
            color = Color(0xFF6B7280)
        )
        
        // App Screens Carousel
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            contentPadding = PaddingValues(horizontal = 8.dp)
        ) {
            items(getAppScreens()) { screen ->
                AppScreenCard(screen)
            }
        }
    }
}

@Composable
fun AppScreenCard(screen: AppScreen) {
    Card(
        modifier = Modifier
            .width(200.dp)
            .height(360.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Screen Preview
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
                    .background(
                        brush = screen.gradient,
                        shape = RoundedCornerShape(12.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = screen.icon,
                    contentDescription = screen.title,
                    tint = Color.White,
                    modifier = Modifier.size(48.dp)
                )
            }
            
            Text(
                text = screen.title,
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color(0xFF1F2937)
            )
            
            Text(
                text = screen.description,
                fontSize = 12.sp,
                color = Color(0xFF6B7280),
                lineHeight = 16.sp
            )
        }
    }
}

@Composable
fun FeaturesGridSection() {
    Column(
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            text = "Key Features",
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFF1F2937)
        )
        
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            contentPadding = PaddingValues(horizontal = 8.dp)
        ) {
            items(getKeyFeatures()) { feature ->
                FeatureCard(feature)
            }
        }
    }
}

@Composable
fun FeatureCard(feature: KeyFeature) {
    Card(
        modifier = Modifier
            .width(160.dp)
            .height(180.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Icon(
                imageVector = feature.icon,
                contentDescription = feature.title,
                tint = feature.color,
                modifier = Modifier.size(32.dp)
            )
            
            Text(
                text = feature.title,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color(0xFF1F2937),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
            
            Text(
                text = feature.description,
                fontSize = 12.sp,
                color = Color(0xFF6B7280),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                lineHeight = 14.sp
            )
        }
    }
}

@Composable
fun DownloadSection() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 8.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF1F2937)
        )
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Download ProTip365 Now",
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
            
            Text(
                text = "Start tracking your tips and maximizing your earnings today. Available on both iOS and Android platforms.",
                fontSize = 16.sp,
                color = Color.White.copy(alpha = 0.8f),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
            
            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Button(
                    onClick = { },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color.White,
                        contentColor = Color(0xFF1F2937)
                    ),
                    modifier = Modifier.height(48.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.PhoneAndroid,
                        contentDescription = "Android",
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Google Play", fontWeight = FontWeight.Bold)
                }
                
                Button(
                    onClick = { },
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color.White,
                        contentColor = Color(0xFF1F2937)
                    ),
                    modifier = Modifier.height(48.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.PhoneIphone,
                        contentDescription = "iOS",
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("App Store", fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

// Data Classes
data class AppScreen(
    val title: String,
    val description: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector,
    val gradient: Brush
)

data class KeyFeature(
    val title: String,
    val description: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector,
    val color: Color
)

// Sample Data
fun getAppScreens(): List<AppScreen> {
    return listOf(
        AppScreen(
            title = "Dashboard",
            description = "Overview of your daily earnings and performance metrics",
            icon = Icons.Default.Dashboard,
            gradient = Brush.verticalGradient(listOf(Color(0xFF6366F1), Color(0xFF8B5CF6)))
        ),
        AppScreen(
            title = "Calendar",
            description = "Track your shifts and earnings by date with visual calendar",
            icon = Icons.Default.CalendarToday,
            gradient = Brush.verticalGradient(listOf(Color(0xFFEC4899), Color(0xFFF97316)))
        ),
        AppScreen(
            title = "Employers",
            description = "Manage multiple employers and compare earnings by location",
            icon = Icons.Default.Business,
            gradient = Brush.verticalGradient(listOf(Color(0xFF10B981), Color(0xFF059669)))
        ),
        AppScreen(
            title = "Calculator",
            description = "Quick tip calculations and earnings projections",
            icon = Icons.Default.Calculate,
            gradient = Brush.verticalGradient(listOf(Color(0xFF8B5CF6), Color(0xFF7C3AED)))
        ),
        AppScreen(
            title = "Analytics",
            description = "Detailed insights and earning trend analysis",
            icon = Icons.Default.Analytics,
            gradient = Brush.verticalGradient(listOf(Color(0xFFF59E0B), Color(0xFFD97706)))
        )
    )
}

fun getKeyFeatures(): List<KeyFeature> {
    return listOf(
        KeyFeature(
            title = "Clean Design",
            description = "Intuitive interface designed for quick tip entry",
            icon = Icons.Default.Palette,
            color = Color(0xFF6366F1)
        ),
        KeyFeature(
            title = "Smart Analytics",
            description = "AI-powered insights to maximize your earnings",
            icon = Icons.AutoMirrored.Filled.TrendingUp,
            color = Color(0xFF10B981)
        ),
        KeyFeature(
            title = "Multi-Platform",
            description = "Seamless sync between iOS and Android devices",
            icon = Icons.Default.Sync,
            color = Color(0xFF8B5CF6)
        ),
        KeyFeature(
            title = "Secure Storage",
            description = "Bank-level encryption for your financial data",
            icon = Icons.Default.Security,
            color = Color(0xFFEF4444)
        )
    )
}
