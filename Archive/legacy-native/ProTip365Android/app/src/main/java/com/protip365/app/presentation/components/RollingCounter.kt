package com.protip365.app.presentation.components

import androidx.compose.animation.*
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign

@OptIn(ExperimentalAnimationApi::class)
@Composable
fun RollingCounter(
    value: Double,
    modifier: Modifier = Modifier,
    style: TextStyle = LocalTextStyle.current,
    prefix: String = "$"
) {
    // Breakdown the value into digits for animation
    // Ideally we animate each digit. For simplicity and robustness in this iteration,
    // we will use slideIn/slideOut on the whole text which gives a "slot machine" feel
    // if we update it frequently, or we can simply use AnimatedContent on the number.
    
    // True "Odometer" is complex. Let's do a reliable "Animated Number"
    // that slides up/down when value changes.
    
    val countString = "%.2f".format(value)
    
    Row(modifier = modifier) {
        Text(text = prefix, style = style)
        
        // Simple Slide Animation for the whole number
        // For per-digit, we'd need to map each char.
        // Let's try per-char for that "Premium" feel.
        
        countString.forEach { char ->
            AnimatedContent(
                targetState = char,
                transitionSpec = {
                    // Slide up if new number is higher? 
                    // Hard to know per digit direction easily without previous state tracking per char.
                    // Default to slide up.
                    slideInVertically { height -> height } + fadeIn() with
                    slideOutVertically { height -> -height } + fadeOut()
                },
                label = "char"
            ) { targetChar ->
                Text(
                    text = targetChar.toString(),
                    style = style,
                    textAlign = TextAlign.Center,
                    softWrap = false
                )
            }
        }
    }
}
