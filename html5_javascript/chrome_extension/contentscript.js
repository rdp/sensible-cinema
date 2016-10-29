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
            console.log('got message to start from popup');
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

function autoStartOnBigThree() {
  var location = window.location.href;
  if (location.includes("netflix.com") || location.includes("play.google.com") || location.includes("amazon.com")) {
    chrome.runtime.sendMessage({text: "wait", color: "#0000FF"}); 
    var interval = setInterval(function(){
      if (findFirstVideoTag() != null && !findFirstVideoTag().src.endsWith(".mp4")) { // amazon.com main page used mp4's, avoid prompt edited :|
        injectEditedPlayerOnce();
        clearInterval(interval);
      }
    }, 50);  // initial delay 50ms but not too bad :)
  }
  else {
    console.log("not auto starting non big 3 " + location);
    // light blue #ADD8E6
    chrome.runtime.sendMessage({text: "non", color: "#3333FF"}); 
  }
}

onReady(autoStartOnBigThree);

