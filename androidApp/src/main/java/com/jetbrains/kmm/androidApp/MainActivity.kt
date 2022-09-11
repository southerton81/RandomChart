package com.jetbrains.kmm.androidApp

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.widget.EditText
import com.jetbrains.kmm.shared.Greeting
import com.jetbrains.kmm.shared.Calculator
import android.widget.TextView
import com.jetbrains.androidApp.R

fun greet(): String {
    return Greeting().greeting()
}

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }
}
