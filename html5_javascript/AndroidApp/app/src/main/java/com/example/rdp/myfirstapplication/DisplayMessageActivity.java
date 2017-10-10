package com.example.rdp.myfirstapplication;

import android.content.Intent;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.TextView;

public class DisplayMessageActivity extends AppCompatActivity {

    private static final String TAG = "MyActivity";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_display_message);

        // Get the Intent that started this activity and extract the string
        Intent intent = getIntent();
        String message = intent.getStringExtra(MainActivity.EXTRA_MESSAGE);

        // Capture the layout's TextView and set the string as its text
        TextView textView = (TextView) findViewById(R.id.textView);
        textView.setText("entrd:" + message); // does not work?

        WebView myWebView = (WebView) findViewById(R.id.webView1);
        WebSettings webSettings = myWebView.getSettings();
        webSettings.setJavaScriptCanOpenWindowsAutomatically(true);
        webSettings.setJavaScriptEnabled(true);
       // myWebView.getSettings().setDomStorageEnabled(true);
        myWebView.loadUrl("https://playitmyway.org");
        myWebView.getSettings().setUserAgentString("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.19 (KHTML, like Gecko) PlayItMyWayUndroid Chrome/18.0.1025.45 Safari/535.19");

        myWebView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                // loadUrl "might" be broken on real devices wait what?
                Log.v(TAG, "index=" + url);
                if (url.contains("amazon.com")) {

                }

                StringBuilder sb = new StringBuilder();
                sb.append("alert('hello inject');document.getElementById('replace_me').innerHTML = 'texthere4'; null;");
                view.loadUrl("javascript:" + sb.toString());

            }

        });

    }

}
