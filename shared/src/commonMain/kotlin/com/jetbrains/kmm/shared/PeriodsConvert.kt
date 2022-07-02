package com.jetbrains.kmm.shared

import kotlin.math.*


data class PeriodScreen(
    val x: Float,
    val y: Float,
    val w: Float,
    val h: Float,
    val o: Int,
    val c: Int,
    val periodDto: PeriodDto
)


fun convertToScreen(
    allPeriods: List<PeriodDto>,
    periodsOnScreen: Int,
    offset: Float,
    w: Float,
    h: Float
): List<PeriodScreen> {
    if (periodsOnScreen < 1) {
        return emptyList()
    }

    val periodWidth = calculatePeriodWidth(w, periodsOnScreen)

    val maxOffset = periodWidth * allPeriods.size
    val coercedOffset = offset.coerceIn(0f, maxOffset)

    val startPeriod = floor(coercedOffset / periodWidth).toInt()
    val endPeriod = floor((coercedOffset + w) / periodWidth).toInt()
    val offsetX = coercedOffset % periodWidth

    val coercedStart = startPeriod.coerceIn(0, allPeriods.size - 1)
    val coercedEnd = endPeriod.coerceIn(0, allPeriods.size - 1)
    val screenSlice = allPeriods.slice(IntRange(coercedStart, coercedEnd))

    var yMin: Long = Long.MAX_VALUE
    var yMax: Long = Long.MIN_VALUE
    screenSlice.forEach {
        if (it.high > yMax) yMax = it.high
        if (it.low < yMin) yMin = it.low
    }

    val priceRange = yMax - yMin
    val pixelPrice = h / (priceRange + (priceRange / 10))

    val screenPeriods = screenSlice.mapIndexed { i, periodDto ->
        val topPrice = periodDto.high - yMin
        val bottomPrice = periodDto.low - yMin
        val openPrice = periodDto.open - yMin
        val closePrice = periodDto.close - yMin

        PeriodScreen(
            (-offsetX + (i * periodWidth)),
            (h - (pixelPrice * topPrice)),
            periodWidth,
            (pixelPrice * (topPrice - bottomPrice)),
            (h - (pixelPrice * openPrice)).roundToInt(),
            (h - (pixelPrice * closePrice)).roundToInt(),
            periodDto
        )
    }

    return screenPeriods
}

fun calculateOffsetForZoom(
    allPeriods: List<PeriodDto>,
    periodsOnScreen: Int,
    centerAroundPeriod: PeriodDto,
    w: Float
): Float {
    val periodsCount = periodsOnScreen.coerceAtLeast(10)
    val periodWidth = calculatePeriodWidth(w, periodsCount)
    val startPeriodIndex = (centerAroundPeriod.index - (periodsCount / 2))
        .coerceIn(0, allPeriods.size - 1L)
    return startPeriodIndex * periodWidth
}

private fun calculatePeriodWidth(w: Float, periodsOnScreen: Int): Float = max(1f, w / periodsOnScreen)