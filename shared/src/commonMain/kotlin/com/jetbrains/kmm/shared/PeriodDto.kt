package com.jetbrains.kmm.shared

data class PeriodDto(
    val index: Long,
    val high: Long,
    val low: Long,
    val open: Long,
    val close: Long,
    val volume: Long
)