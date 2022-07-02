package com.jetbrains.kmm.shared

import kotlinx.serialization.builtins.LongAsStringSerializer

data class Position(
    val amount: Long,
    val basePrice: Long,
    val currentPrice: Long,
    val isClosed: Boolean
) {
    fun result(): Long = (amount * currentPrice) - (amount * basePrice)
}


fun buy(price: Long, sum: Long) {

}


fun sell() {

}
