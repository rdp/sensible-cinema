package com.example.rdp.myfirstapplication;

import android.content.Intent;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.webkit.PermissionRequest;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.TextView;

import static android.webkit.PermissionRequest.RESOURCE_PROTECTED_MEDIA_ID;

public class DisplayMessageActivity extends AppCompatActivity {

    private static final String TAG = "MyActivity";


    WebView myWebView;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_display_message);

        // TODO try: Oreo, does it work on real devices? bigger web?

        // Get the Intent that started this activity and extract the string
        Intent intent = getIntent();
        String message = intent.getStringExtra(MainActivity.EXTRA_MESSAGE);

        // Capture the layout's TextView and set the string as its text
        TextView textView = (TextView) findViewById(R.id.textView);
        textView.setText("entrd:" + message); // does not work?

         myWebView = (WebView) findViewById(R.id.webView1);
        WebSettings webSettings = myWebView.getSettings();
        webSettings.setJavaScriptCanOpenWindowsAutomatically(true);
        webSettings.setJavaScriptEnabled(true);
        myWebView.getSettings().setDomStorageEnabled(true);
        myWebView.getSettings().setAllowContentAccess(true);
        myWebView.getSettings().setMediaPlaybackRequiresUserGesture(false);

        //myWebView.loadUrl("chrome://components"); // nope
        // Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.135 Safari/537.36 is chrome with "desktop" checked
        myWebView.getSettings().setUserAgentString("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.135 Safari/537.36 PlayItMyWay/0.1");
        // tries to launch app:
        // myWebView.getSettings().setUserAgentString("Mozilla/5.0 (Linux; Android 6.0.1; SGP771 Build/32.2.A.0.253; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/52.0.2743.98 Safari/537.36 PlayItMyWayUndroid/0.0");

        myWebView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onPermissionRequest(PermissionRequest request) {
                request.grant(new String[]{RESOURCE_PROTECTED_MEDIA_ID});
            }
            // alerts should work now anyway :|

        });

        myWebView.setWebViewClient(new WebViewClient() {

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                // loadUrl "might" be broken on real devices wait what?
                Log.v(TAG, "url=" + url);
                StringBuilder sb = new StringBuilder(); // TODO I load this thrice???
                // big buck? sniff https://playitmyway.org/test_movie_for_practicing_edits.html
                if (url.contains("amazon.com") || (url.contains("playitmyway.org") && !url.contains("pimw_edited_youtube"))) {
                    sb.append("var my_awesome_script = document.createElement('script'); my_awesome_script.setAttribute('src','https://playitmyway.org/plugin_javascript/contentscript.js'); document.head.appendChild(my_awesome_script);");
                }

                sb.append("document.getElementById('replace_me').innerHTML = 'texthere4'; null;");
                view.loadUrl("javascript:" + sb.toString());
            }
        });
        if (message.startsWith("http")) {
            myWebView.loadUrl(message);
        } else {
            myWebView.loadUrl("https://playitmyway.org");
        }

    }

    @Override
    public void onBackPressed() {
        if (myWebView.canGoBack()) {
            myWebView.goBack();
        } else {
            super.onBackPressed();
        }
    }
}
