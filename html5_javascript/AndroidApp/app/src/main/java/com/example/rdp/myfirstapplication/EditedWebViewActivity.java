package com.example.rdp.myfirstapplication;

import android.content.Intent;
import android.os.Build;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.CookieManager;
import android.webkit.PermissionRequest;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ProgressBar;
import android.widget.TextView;

import static android.webkit.PermissionRequest.RESOURCE_PROTECTED_MEDIA_ID;

public class EditedWebViewActivity extends AppCompatActivity {

    private static final String LOG_TAG = "EditedWebViewActivity";
    WebView myWebView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_display_message);

        // Get the Intent that started this activity and extract the string
        Intent intent = getIntent();
        final String message = intent.getStringExtra(MainActivity.EXTRA_MESSAGE);
        final ProgressBar loadingBar = (ProgressBar) findViewById(R.id.pB1);

        myWebView = (WebView) findViewById(R.id.webView1);
        WebSettings webSettings = myWebView.getSettings();

        // might not need all of these
        webSettings.setJavaScriptCanOpenWindowsAutomatically(true);
        webSettings.setJavaScriptEnabled(true);
        myWebView.getSettings().setDomStorageEnabled(true);
        myWebView.getSettings().setAllowContentAccess(true);
        myWebView.getSettings().setMediaPlaybackRequiresUserGesture(false); // otherwise amazon wouldn't start
        myWebView.getSettings().setBuiltInZoomControls(true); // allow pinch
        myWebView.getSettings().setDisplayZoomControls(true); // seem useful

        myWebView.getSettings().setLoadWithOverviewMode(true);
        myWebView.getSettings().setUseWideViewPort(true);
        
        String chromeAndroidDesktopChecked = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.135 Safari/537.36";
        myWebView.getSettings().setUserAgentString(chromeAndroidDesktopChecked + "PlayItMyWay/0.2");

        // required seemingly for my cookies to connect with logged in user
       CookieManager cookieManager = CookieManager.getInstance();
       cookieManager.setAcceptThirdPartyCookies(myWebView, true);

        myWebView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onPermissionRequest(PermissionRequest request) {
                request.grant(new String[]{RESOURCE_PROTECTED_MEDIA_ID}); // allow playing videos
            }

            public void onProgressChanged(WebView view, int progress) {
                if(progress < 100 && loadingBar.getVisibility() == ProgressBar.GONE){
                    loadingBar.setVisibility(ProgressBar.VISIBLE);
                }

                loadingBar.setProgress(progress);
                if(progress == 100) {
                    loadingBar.setVisibility(ProgressBar.GONE);
                }
            }
        });

        myWebView.setWebViewClient(new WebViewClient() {

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                return false; // false == default  [means "you handle it, WebView!"] we never get here anyway?? what???
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                Log.v(LOG_TAG, "onPageFinished url=" + url);
                StringBuilder sb = new StringBuilder();
                // NB: keep synchronized with the contentscript injector [could combine?]
                if (url.contains("amazon.com") || (url.contains("playitmyway.org") && !url.contains("youtube_pimw_edited"))) {
                    sb.append("var my_awesome_script = document.createElement('script'); my_awesome_script.setAttribute('src','https://playitmyway.org/plugin_javascript/edited_generic_player.js'); document.head.appendChild(my_awesome_script);");
                }

                if (url.equals("https://playitmyway.org/")) {
                    sb.append("document.getElementById('replace_me').innerHTML = 'Play it my way Android browser enabled!'; null;"); // more confirmation :)
                }
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
    public void onBackPressed() { // allow android left button to navigate within webview
        if (myWebView.canGoBack()) {
            myWebView.goBack();
        } else {
            super.onBackPressed();
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        myWebView.onPause();
    }

    @Override
    public void onResume() {
        super.onResume();
        myWebView.onResume();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        // once ran into
        // 10-18 20:50:13.103 2580-2580/? E/ActivityThread: Activity com.example.rdp.myfirstapplication.EditedWebViewActivity has leaked IntentReceiver android.widget.ZoomButtonsController$1@910dfc3 that was originally registered here. Are you missing a call to unregisterReceiver()?
        ViewGroup view = (ViewGroup) getWindow().getDecorView();
        view.removeAllViews();

        myWebView.destroy(); // seems necessary else it just...keeps...running...
    }
}
