package com.example.rdp.myfirstapplication;

import android.content.Intent;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;
import android.widget.EditText;

import static com.example.rdp.myfirstapplication.MainActivity.EXTRA_MESSAGE;

public class AdminActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_admin);
    }

    // XXX add shaka ? :) or are we "past that" already :)

    public void sendMessageLogin(View view) {
        Intent intent = new Intent(this, EditedWebViewActivity.class);
        EditText editText = (EditText) findViewById(R.id.password);
        String message = editText.getText().toString();
        intent.putExtra(EXTRA_MESSAGE, "https://playitmyway.org/go_admin?secret=" + message);
        startActivity(intent);
    }

    public void sendMessageMinions(View view) {
        Intent intent = new Intent(this, EditedWebViewActivity.class);
        intent.putExtra(EXTRA_MESSAGE, "https://smile.amazon.com/Minions-Sandra-Bullock/dp/B011802KGM?sa-no-redirect=1");
        startActivity(intent);
    }

    public void sendMessageRawUrl(View view) {
        Intent intent = new Intent(this, EditedWebViewActivity.class);
        EditText editText = (EditText) findViewById(R.id.rawUrl);
        String message = editText.getText().toString();
        intent.putExtra(EXTRA_MESSAGE, message);
        startActivity(intent);
    }
}
