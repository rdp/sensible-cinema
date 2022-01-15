// (c) 2016 Roger Pack released under LGPL
// content script runs on every page...and once again on each embedded iframe...
// we mostly use this to bootstrap the real player...

console.log("pimw content script entered... " + window.location); // try and see how fast it "can" load...

function loadScript(url, callback)
{
    // Adding the script tag to the head as suggested before
    var head = document.getElementsByTagName('head')[0];
    var script = document.createElement('script');
    script.type = 'text/javascript';
    script.src = url;

    // Then bind the event to the callback function.
    // There are several events for cross browser compatibility.
    script.onreadystatechange = callback;
    script.onload = callback;

    // Fire the loading
    head.appendChild(script);
    // how to detect failure? not sure...
}

already_loaded = false;

chrome.runtime.onMessage.addListener(
    function(request, sender, sendResponse) {
        if (request.action == "please_start") { // message from popup
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
         };
});

// capture messages from the page and optionally re-broadcast them to background.js: http://stackoverflow.com/a/41836393/32453
window.addEventListener("message", function(event) {
  if (event.source != window)
    return;

  if (event.data.type && (event.data.type == "FROM_PAGE_TO_CONTENT_SCRIPT")) {
    // only way to update the tab icon I think anyway...is from the background.js
    // also want that for permissions weirdness in amazon
    chrome.runtime.sendMessage(event.data.payload); // rebroadcast to rest of extension
  }
}, false);

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
    console.log("pimw injecting editor code...");
    chrome.runtime.sendMessage({text: "load", color: "#808080", details: "Trying to load edited playback..."}); // last thing they see for non big 2 :|
    if (already_loaded) {
        alert('Double load from content script?'); // should never happen from one content script XXX remove
    }
    else {
        already_loaded = true;
        loadScript(chrome.extension.getURL('edited_generic_player.js'));
   }
}

function inIframe () {
    try {
        return window.self !== window.top;
    } catch (e) {
        return true;
    }
}

function autoStartIfShould() {
  var url = currentUrlNotIframe();
  if (url.includes("www.facebook.com")) {
    chrome.runtime.sendMessage({text: "dis", color: "#808080", details: "facebook we don't handle yet"}); // don't auto load for now, too chatty on the server, not compat... [?]
    return;
  }
  var wantItPlayItMyWay = url.includes("playitmyway.org");  // for the demo .mp4 movie editing..
  if (wantItPlayItMyWay && url.includes("edited_youtube")) {
    wantItPlayItMyWay = false; // already hard-coded into the web page itself...
  }
  if (wantItPlayItMyWay && window.navigator.userAgent.includes("PlayItMyWay")) {
    wantItPlayItMyWay = false; // let android inject it, don't want to cheat
  }
  
  if (url.includes("play.google.com") || url.includes("amazon.com") || wantItPlayItMyWay) {
    if (inIframe()) {  // wait I thought url couldn't be from iFrame?
      // avoid google iframes popup after it says <smiley> and reset it back even though it is playing OK
      console.log("not setting plugin text to look from an iframe");
    }
    else {
      chrome.runtime.sendMessage({text: "wait", color: "#808080", 
            details: "edited playback and waiting for a video to appear present, then will try to see if edits exist for it so can playback edited"}); 
    }
    // iframe wants to load the extension though, for google play to work...
    console.log("pimw: big 2/pimw begin polling for video tag..."); // I guess we just look for video tag :|
    var interval = setInterval(function(){
      var video_element = findFirstVideoTagOrNull();
      if (video_element != null) {
        console.log("pimw: found video tag [or pimw non youtube page], injecting, even if it doesn't have edits...");
        injectEditedPlayerOnce();
        clearInterval(interval);
      }
    }, 50);  // initial delay 50ms but me thinks not too bad, still responsive enough :)
  }
  else if (url.includes("netflix.com/") || url.includes("hulu.com/")) {
    console.log("pimw doing nothing netflix hulu :|");
    chrome.runtime.sendMessage({text: "dis", color: "#808080", details: "netflix/hulu the edited plugin player is disabled."});
  }
  else {
    console.log("pimw doing nothing non big 2 :| [" + url + "]"); // youtube is *out* now...
    chrome.runtime.sendMessage({text: "dis", color: "#808080", details: "non google play/amazon therefore disabled :("});
  }
}

function currentUrlNotIframe() { // duplicated with other .js
  return (window.location != window.parent.location) ? document.referrer : document.location.href;
}

function getStandardizedCurrentUrl() { // duplicated with other .js
  var current_url = currentUrlNotIframe();
  if (document.querySelector('link[rel="canonical"]') != null && !current_url.includes("youtube.com")) {
    // -> canonical, the crystal code does this for everything so guess we should do here as well...ex youtube it strips off any &t=2 or something...
    current_url = document.querySelector('link[rel="canonical"]').href; // seems to always convert from "/gp/" to "/dp/" and sometimes even change the ID :|
  }
  // attempt to leave the rest in crystal
  return current_url;
}


// onReady(autoStartIfShould); // takes like 5s for onReady whoa! too slow...
autoStartIfShould(); 