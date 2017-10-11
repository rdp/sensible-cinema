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
     * Called when the user taps the Send button
     */
    public void sendMessage(View view) {
        Intent intent = new Intent(this, DisplayMessageActivity.class);
        /*EditText editText = (EditText) findViewById(R.id.editText);
        String message = editText.getText().toString(); */
        intent.putExtra(EXTRA_MESSAGE, ""); // meaning "all"
        startActivity(intent);
    }

    public void sendMessageShaka(View view) {
        Intent intent = new Intent(this, DisplayMessageActivity.class);
        intent.putExtra(EXTRA_MESSAGE, "https://shaka-player-demo.appspot.com/demo/#asset=//storage.googleapis.com/shaka-demo-assets/angel-one/dash.mpd;lang=en-US");
        startActivity(intent);
    }

    public void sendMessageMinions(View view) {
        Intent intent = new Intent(this, DisplayMessageActivity.class);
        intent.putExtra(EXTRA_MESSAGE, "https://smile.amazon.com/Minions-Sandra-Bullock/dp/B011802KGM?sa-no-redirect=1");
        startActivity(intent);
    }

    public void sendMessageBigBuck(View view) {
        Intent intent = new Intent(this, DisplayMessageActivity.class);
        intent.putExtra(EXTRA_MESSAGE, "https://playitmyway.org/test_movie_for_practicing_edits.html");
        startActivity(intent);
    }

}