package com.jetbrains.kmm.shared

import kotlin.math.roundToLong
import kotlin.random.Random
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class CalculatorTest {

    @Test
    fun testRandomness() {
        val buckets = mutableMapOf<Long, Long>()
        val closes = mutableListOf<Long>()
        (0..1000).forEach {
            var close = 0L
            getRandomAvailablePeriods(5000, Random.nextInt(), 100).forEach {
                assertTrue(it.high >= it.low)
                assertTrue(it.high >= it.open)
                assertTrue(it.high >= it.close)
                assertTrue(it.low <= it.open)
                assertTrue(it.low <= it.close)
                close = (it.close / 100f).roundToLong()
            }
            closes += close
            val last = buckets.getOrPut(close, { 0 })
            buckets[close] = last + 1
        }

        println("> 50 count:" + closes.filter { it > 50 }.size.toString())
        println("< 50 count:" + closes.filter { it < 50 }.size.toString())

        buckets.keys.sorted().forEach {
            println("key: " + it + " value: " + buckets[it])
        }
    }

    @Test
    fun testNext() {
        val periodsDto = getRandomAvailablePeriods(5000, 190, 1)
        val periodDto = getRandomAvailablePeriods(periodsDto.last().close, 190, 1)[0]
        println("< 50 count:")
    }

    @Test
    fun testZoom() {
        val periodDto = getRandomAvailablePeriods(5000, 190, 300)
        val offset = calculateOffsetForZoom(periodDto, 376, periodDto[20], 400f)
        assertEquals(offset, 0f)
    }

    @Test
    fun testScreenConvertOffset() {
        val periodDto = getRandomAvailablePeriods(5000, 190, 300)
        val periodsScreen = convertToScreen(periodDto, 150, 0f, 400f, 320f)
        assertEquals(periodsScreen.size, 151)
    }

    @Test
    fun testScreenConvertHorizontal() {
        val periodDto = getRandomAvailablePeriods(5000, 190, 100)
        val periodsScreen = convertToScreen(periodDto, 2, 50f, 400f, 320f)
        assertEquals(periodsScreen.size, 3)

        assertEquals(periodsScreen[0].x, -50f)
        assertEquals(periodsScreen[0].w, 200f)

        assertEquals(periodsScreen[1].x, 150f)
        assertEquals(periodsScreen[0].w, 200f)

        assertEquals(periodsScreen[2].x, 350f)
        assertEquals(periodsScreen[0].w, 200f)
    }

    @Test
    fun testScreenConvertVertical() {
        val screenHeight = 320f
        val periodDto = getRandomAvailablePeriods(5000, Random.nextInt(), 200)
        val periodsScreen = convertToScreen(periodDto, 100, 0f, 400f, screenHeight)
        assertEquals(periodsScreen.size, 101)

        periodsScreen.forEach {
            assertTrue(it.y + it.h <= screenHeight)
        }
    }
}