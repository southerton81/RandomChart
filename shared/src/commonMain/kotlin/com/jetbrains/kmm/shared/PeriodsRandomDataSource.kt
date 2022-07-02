package com.jetbrains.kmm.shared

import com.ionspin.kotlin.bignum.decimal.BigDecimal
import com.ionspin.kotlin.bignum.decimal.DecimalMode
import com.ionspin.kotlin.bignum.decimal.RoundingMode
import kotlin.math.max
import kotlin.random.Random


class Rand(seed: Int) {
    val random = Random(seed)
}

fun getRandomAvailablePeriods(
    startPrice: Long = 5000,
    rand: Rand = Rand(0),
    count: Int = 100,
    indexFrom: Int = 0,
    basePrice: Long = 5000 // Base price to keep fluctuations in same range
): List<PeriodDto> {
    var price = startPrice
    return (0 until count).map {
        val high = price + randomChangeByPercent(basePrice, rand.random, 0.0, 3.0)
        val low = price - randomChangeByPercent(basePrice, rand.random, 0.0, 3.0)
        val open = price
        val close = rand.random.nextLong(low, high + 1)
        price = close

        PeriodDto(
            indexFrom + it.toLong(),
            high,
            low,
            open,
            close,
            0
        )
    }
}

private fun randomChangeByPercent(price: Long, random: Random, rangeFrom: Double, rangeTo: Double): Long {
    val mode = DecimalMode(8, RoundingMode.ROUND_HALF_TO_EVEN, 0)
    val randomPercent = random.nextDouble(rangeFrom, rangeTo)
    return max(0L, ((BigDecimal.fromLong(price, mode) / BigDecimal.fromInt(100, mode)) *
                BigDecimal.fromDouble(randomPercent, mode)).longValue())
}