package com.iraqsouq.app.ui

import java.util.concurrent.TimeUnit

object Format {
    /** 18500000 -> "18,500,000 د.ع" */
    fun price(value: Long): String {
        val grouped = "%,d".format(value)
        return "$grouped د.ع"
    }

    fun timeAgo(millis: Long): String {
        val diff = System.currentTimeMillis() - millis
        val minutes = TimeUnit.MILLISECONDS.toMinutes(diff)
        val hours = TimeUnit.MILLISECONDS.toHours(diff)
        val days = TimeUnit.MILLISECONDS.toDays(diff)
        return when {
            minutes < 1 -> "الآن"
            minutes < 60 -> "قبل $minutes دقيقة"
            hours < 24 -> "قبل $hours ساعة"
            days < 30 -> "قبل $days يوم"
            else -> "قبل ${days / 30} شهر"
        }
    }
}
