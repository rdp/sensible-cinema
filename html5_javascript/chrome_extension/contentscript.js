// content script runs on every page...and once again on each embedded iframe

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
            if (findFirstVideoTag() != null) {
              console.log('got request to start from popup message...starting');
              injectEditedPlayerOnce();
            }
            else {
              if (!inIframe()) {
                alert("you requested to start edited playback, but we do not detect a video playing yet, possibly need to hit the play button first, then try again?");
              }
            }
         }
});

function findFirstVideoTag() {
    var all = document.getElementsByTagName("video");    
    if (all.length > 0)
      return all[0];
    else {
       // don't *want* to work with iframes from the plugin side since they'll get their own edited playback copy
       // hopefully this is enough to prevent double loading (once windows.document, one iframe if they happen to be allowed :|
    }
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
  var location = window.location.href;
  if (location.includes("netflix.com") || location.includes("play.google.com") || location.includes("amazon.com")) {
    if (inIframe()) { // checking for google not reliable here since some of its iframes are like play5.google.com
      // google iframes popup after it says YES and reset it back to wait in error :|
      console.log("not setting to wait from iframe");
    }
    else {
      chrome.runtime.sendMessage({text: "wait", color: "#0000FF", details: "edited playback is enabled and waiting for a video to appear present, then will try to see if can playback edited"}); 
    }
    // iframe wants to load it though, for google play
    var interval = setInterval(function(){
      if (findFirstVideoTag() != null && !findFirstVideoTag().src.endsWith(".mp4")) { // amazon.com main page used mp4's, avoid prompt edited :|
        injectEditedPlayerOnce();
        clearInterval(interval);
      }
    }, 50);  // initial delay 50ms but not too bad :)
  }
  else {
    console.log("not auto starting non big 3 " + location);
    // light blue #ADD8E6 super light blue too light
    // lightish blue 3333FF
    // 808080 grey
    if (!inIframe()) {
      chrome.runtime.sendMessage({text: "non", color: "#808080", details: "edited playback does not auto start on this website because it is not netflix/google play/amazon"});
    } // don't send it for iframes since they might override the "real" iframe as it were, which told it "none"
    var interval = setInterval(function() {
      if (findFirstVideoTag() != null) {
        console.log("detected video element on this page, checking if we have edits...");
        loadIfCurrentHasOne(); 
        clearInterval(interval);
      }
    }, 1000); // hopefully doesn't burden stuff too much :)
  }
}

function currentUrlNotIframe() {
  return (window.location != window.parent.location)
            ? document.referrer
            : document.location.href;
}

function loadIfCurrentHasOne() {
  var url = currentUrlNotIframe();
  var direct_lookup = 'for_current_just_settings_json?url=' + encodeURIComponent(url) + '&amazon_episode_number=0'; // simplified, assume just URL wurx, with GET params
  url = '//cleanstream.inet2.org/' + direct_lookup;  // assume prod :)
  getRequest(url, currentHasEdits, currentHasNone); // TODO retry with GET params off now?
}

function currentHasEdits() {
  console.log("got extant non big 3 " + currentUrlNotIframe());
  injectEditedPlayerOnce();
}

function currentHasNone() {
  console.log("unable to find one for " + currentUrlNotIframe() + " so not auto loading it, doing nothing");
  chrome.runtime.sendMessage({text: "none", color: "#808080", details: "We do not have this video in our system yet, please add it!"}); 
}

function getRequest (url, success, error) {
  console.log("starting attempt to download " + url);
  var xhr = XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
  xhr.open("GET", url);
  xhr.onreadystatechange = function(){
    if ( xhr.readyState == 4 ) {
      if ( xhr.status == 200 ) {
        console.log("success download");
        success(xhr.responseText);
      } else {
        console.log("fail download 1");
        error && error(xhr.status);
        error = null;
      }
    }
  };
  xhr.onerror = function () {
    console.log("fail download 2");
    error && error(xhr.status);
    error = null;
  };
  xhr.send();
}

onReady(autoStartOnBigThree);
