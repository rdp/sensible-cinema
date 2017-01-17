// content script runs on every page...and once again on each embedded iframe...
// we only use it to bootstrap the real player...

// var request_host="localhost:3000";
var request_host="playitmyway.inet2.org";

function injectJs(link) {
  var scr = document.createElement('script');
  scr.type = "text/javascript";
  scr.src = link;
  document.getElementsByTagName('head')[0].appendChild(scr)
}

already_loaded = false;

chrome.runtime.onMessage.addListener(
    function(request, sender, sendResponse) {
        if (request.action == "please_start") {
            var url = currentUrlNotIframe();
            if (url.includes("netflix.com/") || url.includes("hulu.com/")) {
              alert("terms of use on this website disallow us injecting code, please ask on the mailing list for support for watching these edited if it has been created yet");
              return; 
            }
            if (findFirstVideoTagOrNull() != null) {
              console.log('got request to start from popup message...');
              injectEditedPlayerOnce();
            }
            else {
              if (!inIframe()) {
                alert("you requested to start edited playback, but we do not detect a video playing yet, possibly need to hit the play button first, then try again?");
              }
            }
         }
});

function findFirstVideoTagOrNull() {
   var all = document.getElementsByTagName("video");
    // look for first "real" playing vid as it were [byu.tv needs this, it has two, first is an add player, i.e. wrong one]
   for(var i = 0, len = all.length; i < len; i++) {
     if (all[i].currentTime > 0) {
       return all[i];
     } 
   }
   // don't *want* to work with iframes from the plugin side since they'll get their own edited playback copy
   // hopefully this is enough to prevent double loading (once windows.document, one iframe if they happen to be allowed :|
   return null;
}

function onReady(yourMethod) {
     if (document.readyState === 'complete') {
       setTimeout(yourMethod, 1); // schedule to run immediately
     }
     else {
       readyStateCheckInterval = setInterval(function() {
         if (document.readyState === 'complete') {
           clearInterval(readyStateCheckInterval);
           yourMethod();
        }
        }, 10);
     }
}

function injectEditedPlayerOnce() {
    console.log("injecting editor code...");
    chrome.runtime.sendMessage({text: "try", color: "#008000", details: "Trying to load edited playback..."}); // last thing they see for non big 3 :|
    if (already_loaded) {
        alert('edited player already loaded for this page...please use its UI. If edits created recently use your browser refresh button to try again if it exists now.');
    }
    else {
        already_loaded = true;
        injectJs(chrome.extension.getURL('edited_generic_player.js'));
        // appears background.js is the only thing that can adjust the icon, so could send it a message, but why these days...the script sends it an immediate message either way anyway
   }
}

function inIframe () {
    try {
        return window.self !== window.top;
    } catch (e) {
        return true;
    }
}

function autoStartOnBigThree() {
  var url = currentUrlNotIframe();
  if (url.includes("play.google.com") || url.includes("amazon.com")) {
    if (inIframe()) { // checking for google not reliable here since some of its iframes are like play5.google.com
      // google iframes popup after it says YES and reset it back to wait in error :|
      console.log("not setting to wait from iframe");
    }
    else {
      chrome.runtime.sendMessage({text: "wait", color: "#808080", details: "edited playback is enabled and waiting for a video to appear present, then will try to see if edits exist for it so can playback edited"}); 
    }
    // iframe wants to load it though, for google play
    console.log("big 3 polling for video tag...");
    var interval = setInterval(function(){
      if (findFirstVideoTagOrNull() != null && !findFirstVideoTagOrNull().src.endsWith(".mp4")) { // amazon.com main page used mp4's, avoid prompt edited :|
        injectEditedPlayerOnce();
        clearInterval(interval);
      }
    }, 50);  // initial delay 50ms but not too bad :)
  }
  else if (url.includes("netflix.com/") || url.includes("hulu.com/")) {
    console.log("doing nothing netflix et al :|");
    chrome.runtime.sendMessage({text: "dis", color: "#808080", details: "netflix/hulu the edited plugin player is disabled."});
  }
  else {
    // non big 2, just poll
    if (!inIframe()) {
      chrome.runtime.sendMessage({text: ".", color: "#808080", details: "edited playback does not auto start on this website because it is not google play/amazon, but will auto start if it finds a video for which we have edits"});
    } // don't send for iframes since they might override the "real" iframe as it were, which told it "none"
    var interval = setInterval(function() {
      var local_video_tag;
      if ((local_video_tag = findFirstVideoTagOrNull()) != null) {
        console.log("detected video element on this page, checking if we have edits..." + local_video_tag.src);
        loadIfCurrentHasOne(); 
        clearInterval(interval);
      }
    }, 1000); // hopefully doesn't burden unrelated web pages too much :)
  }
}

function currentUrlNotIframe() {
  return (window.location != window.parent.location) ? document.referrer : document.location.href;
}

function loadIfCurrentHasOne() {
  var url = currentUrlNotIframe();
  var direct_lookup = 'for_current_just_settings_json?url=' + encodeURIComponent(url) + '&episode_number=0'; // simplified, assume just URL wurx, with GET params, no episode at play LOL
  url = '//' + request_host + '/' + direct_lookup;
  getRequest(url, currentHasEdits, currentHasNone);
}

function currentHasEdits() {
  console.log("got extant non big 3 " + currentUrlNotIframe());
  injectEditedPlayerOnce();
}

function currentHasNone() {
  console.log("unable to find one for " + currentUrlNotIframe() + " so not auto loading it, doing nothing");
  chrome.runtime.sendMessage({text: "none", color: "#808080", details: "We found a video playing, do not have edits for this video in our system yet, please click above to add it!"}); 
}

function getRequest (url, success, error) {
  console.log("starting attempt to download " + url);
  var xhr = XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
  xhr.open("GET", url);
  xhr.onreadystatechange = function(){
    if ( xhr.readyState == 4 ) {
      if ( xhr.status == 200 ) {
        success(xhr.responseText);
      } else {
        error && error(xhr.status);
        error = null;
      }
    }
  };
  xhr.onerror = function () {
    error && error(xhr.status);
    error = null;
  };
  xhr.send();
}

onReady(autoStartOnBigThree);
