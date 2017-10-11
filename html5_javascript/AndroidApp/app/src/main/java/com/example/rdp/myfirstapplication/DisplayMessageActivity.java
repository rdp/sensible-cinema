package com.example.rdp.myfirstapplication;

import android.content.Intent;
import android.os.Message;
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

        // Get the Intent that started this activity and extract the string
        Intent intent = getIntent();
        String message = intent.getStringExtra(MainActivity.EXTRA_MESSAGE);

        myWebView = (WebView) findViewById(R.id.webView1);
        WebSettings webSettings = myWebView.getSettings();
        webSettings.setJavaScriptCanOpenWindowsAutomatically(true);
        webSettings.setJavaScriptEnabled(true);
        myWebView.getSettings().setDomStorageEnabled(true);
        myWebView.getSettings().setAllowContentAccess(true);
        myWebView.getSettings().setMediaPlaybackRequiresUserGesture(false);
        myWebView.getSettings().setBuiltInZoomControls(true);
        myWebView.getSettings().setSupportMultipleWindows(true);

        myWebView.getSettings().setLoadWithOverviewMode(true);
        myWebView.getSettings().setUseWideViewPort(true);
        // Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.135 Safari/537.36 is chrome with "desktop" checked
        myWebView.getSettings().setUserAgentString("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.135 Safari/537.36 PlayItMyWay/0.2");

        myWebView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onPermissionRequest(PermissionRequest request) {
                request.grant(new String[]{RESOURCE_PROTECTED_MEDIA_ID});
            }


            @Override
            public void onCloseWindow(WebView window) {
                Log.d("onCloseWindow", "called");
            }

            @Override
            public boolean onCreateWindow(final WebView view, boolean isDialog,
                                          boolean isUserGesture, Message resultMsg) {

                // support amazon oauth :\ XXX minify? use intent instead?  Latter probably doesn't work :\
                final WebView newWebView = new WebView(DisplayMessageActivity.this);
                newWebView.getSettings().setJavaScriptEnabled(true);
                newWebView.getSettings().setSupportZoom(true);
                newWebView.getSettings().setBuiltInZoomControls(true);
                newWebView.getSettings().setPluginState(WebSettings.PluginState.ON);
                newWebView.getSettings().setSupportMultipleWindows(true);
                newWebView.getSettings().setJavaScriptEnabled(true);
                newWebView.getSettings().setDomStorageEnabled(true);
                newWebView.getSettings().setAppCacheEnabled(true);
                newWebView.getSettings().setJavaScriptCanOpenWindowsAutomatically(true);
                view.addView(newWebView);
                WebView.WebViewTransport transport = (WebView.WebViewTransport) resultMsg.obj;
                transport.setWebView(newWebView);
                resultMsg.sendToTarget();

                newWebView.setWebViewClient(new WebViewClient() {
                    @Override
                    public boolean shouldOverrideUrlLoading(WebView view, String url) {
                        view.loadUrl(url);
                        return true;
                    }
                });
                newWebView.setWebChromeClient(new WebChromeClient() {
                    @Override
                    public void onCloseWindow(WebView window) {
                        Log.d("onCloseWindow", "called");
                        view.removeView(newWebView);
                    }
                });

                return true;
            }


        });

        myWebView.setWebViewClient(new WebViewClient() {

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                // loadUrl "might" be broken on real devices wait what?
                Log.v(TAG, "url=" + url);
                StringBuilder sb = new StringBuilder(); // XXXX I load this thrice??? huh wuh?
                // XXXX more smarts here, also adjust UA or something? More instructions? Add link to your library?
                // reload button [?] real fullscreen [?]
                if (url.contains("amazon.com") || (url.contains("playitmyway.org") && !url.contains("youtube_pimw_edited"))) {
                    sb.append("var my_awesome_script = document.createElement('script'); my_awesome_script.setAttribute('src','https://playitmyway.org/plugin_javascript/edited_generic_player.js'); document.head.appendChild(my_awesome_script);");
                }

                sb.append("document.getElementById('replace_me').innerHTML = 'Play it my way browser enabled!'; null;");
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
