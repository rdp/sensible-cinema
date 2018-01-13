package com.example.rdp.myfirstapplication;

import android.content.Intent;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;
import android.widget.EditText;

public class MainActivity extends AppCompatActivity {
    public static final String EXTRA_MESSAGE = "com.example.rdp.myfirstapplication.MESSAGE";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
    }

    /**
     * Called when the user taps the "all" button
     */
    public void sendMessage(View view) {
        Intent intent = new Intent(this, DisplayMessageActivity.class);
        intent.putExtra(EXTRA_MESSAGE, ""); // meaning "all"
        startActivity(intent);
    }

    public void sendMessageBigBuck(View view) {
        Intent intent = new Intent(this, DisplayMessageActivity.class);
        intent.putExtra(EXTRA_MESSAGE, "https://playitmyway.org/test_movie_for_showing_off_edits.html");
        startActivity(intent);
    }

    public void sendMessageAdmin(View view) {
        Intent intent = new Intent(this, AdminActivity.class);
        startActivity(intent);
    }
}