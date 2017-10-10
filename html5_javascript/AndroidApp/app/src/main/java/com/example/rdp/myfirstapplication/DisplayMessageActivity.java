package com.example.rdp.myfirstapplication;

import android.content.Intent;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.TextView;

public class DisplayMessageActivity extends AppCompatActivity {

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
        myWebView.getSettings().setDomStorageEnabled(true);
        myWebView.loadUrl("https://playitmyway.org");

        myWebView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);

                StringBuilder sb = new StringBuilder();
                sb.append("alert('hello inject');");
                view.loadUrl("javascript:" + sb.toString());
                view.loadUrl("javascript:" +
                        "function() {document.getElementById('replace_me').innerHTML = 'texthere';}()");
                view.evaluateJavascript("alert('hello inject')", null);
                view.evaluateJavascript("document.getElementById('replace_me').innerHTML = 'texthere';", null);
                view.evaluateJavascript("var x = (document.getElementById('replace_me').innerHTML = 'texthere')", null);
                // works!
                view.evaluateJavascript("(function() { alert('x'); " +
                        "return { var1: document.title, var2: \"variable2\", var3: (var y = document.getElementById('replace_me').innerHTML }; })();", new ValueCallback<String>() {
                    @Override
                    public void onReceiveValue(String s) {
                        System.out.println("LogName" + s); // Prints: {"var1":"variable1","var2":"variable2"}
                    }
                });
                view.evaluateJavascript(
                        "(function() { return ('<html>'+document.getElementsByTagName('html')[0].innerHTML+'</html>'); })();",
                        new ValueCallback<String>() {
                            @Override
                            public void onReceiveValue(String html) {
                                System.out.println("HTML"+html);
                                // code here
                            }
                        });



                // actually worked!
                //  view.loadUrl("javascript:document.write('hello')");
                // worked!
                // view.evaluateJavascript("document.write('hello2')", null);
            }

        });

    }

}
