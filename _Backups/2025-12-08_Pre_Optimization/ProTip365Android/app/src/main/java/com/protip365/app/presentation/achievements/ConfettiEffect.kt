package com.protip365.app.presentation.achievements

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import kotlin.math.cos
import kotlin.math.sin
import kotlin.random.Random

data class ConfettiParticle(
    val id: Int,
    val startX: Float,
    val startY: Float,
    val color: Color,
    val size: Float,
    val velocity: Float,
    val angle: Float,
    val rotation: Float
)

@Composable
fun ConfettiEffect(
    modifier: Modifier = Modifier
) {
    val particles = remember {
        List(50) { index ->
            val colors = listOf(
                Color(0xFFE53935), // Red
                Color(0xFF1E88E5), // Blue
                Color(0xFF43A047), // Green
                Color(0xFFFDD835), // Yellow
                Color(0xFFFF6F00), // Orange
                Color(0xFF8E24AA), // Purple
                Color(0xFFEC407A)  // Pink
            )
            
            ConfettiParticle(
                id = index,
                startX = Random.nextFloat(),
                startY = Random.nextFloat() * -0.2f,
                color = colors.random(),
                size = Random.nextFloat() * 8f + 4f,
                velocity = Random.nextFloat() * 0.5f + 0.5f,
                angle = Random.nextFloat() * 360f,
                rotation = Random.nextFloat() * 360f
            )
        }
    }
    
    val infiniteTransition = rememberInfiniteTransition(label = "confetti")
    
    val animationProgress by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(3000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "confetti_progress"
    )
    
    Canvas(modifier = modifier.fillMaxSize()) {
        val canvasWidth = size.width
        val canvasHeight = size.height
        
        particles.forEach { particle ->
            val progress = animationProgress
            
            val x = canvasWidth * particle.startX + 
                    sin(particle.angle + progress * 360) * 50f
            val y = canvasHeight * particle.startY + 
                    (canvasHeight * 1.2f * progress * particle.velocity)
            
            if (y < canvasHeight + particle.size) {
                val alpha = (1f - progress).coerceIn(0f, 1f)
                
                drawCircle(
                    color = particle.color.copy(alpha = alpha),
                    radius = particle.size,
                    center = Offset(x, y)
                )
            }
        }
    }
}

