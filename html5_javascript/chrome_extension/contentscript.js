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
            console.log('got message to start from popup, starting...');
            injectEditedPlayerOnce();
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
             if (already_loaded) {
               alert('edited player already loaded for this page, it should pick up when you start a movie on this page, so is loaded...');
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
        console.log("injecting editor code...");
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
    chrome.runtime.sendMessage({text: "non", color: "#808080", details: "edited playback does not auto start on this website because it is not netflix/google play/amazon"}); 
  }
}

onReady(autoStartOnBigThree);

