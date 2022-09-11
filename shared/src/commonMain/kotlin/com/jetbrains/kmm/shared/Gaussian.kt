package com.jetbrains.kmm.shared

import kotlin.math.ln
import kotlin.math.sqrt
import kotlin.random.Random

class Gaussian {
    private var haveNextNextGaussian: Boolean = false
    private var nextNextGaussian: Double = 0.0

    fun nextGaussian(random: Random): Double {
        if (haveNextNextGaussian) {
            haveNextNextGaussian = false
            return nextNextGaussian
        }
        var v1: Double
        var v2: Double
        var s: Double
        do {
            v1 = 2 * random.nextDouble() - 1
            v2 = 2 * random.nextDouble() - 1
            s = v1 * v1 + v2 * v2
        } while (s >= 1)
        val norm: Double = sqrt(-2 * ln(s) / s)
        nextNextGaussian = v2 * norm
        haveNextNextGaussian = true
        return v1 * norm
    }
}