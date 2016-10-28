// content script runs on every page...

function injectJs(link) {
  var scr = document.createElement('script');
  scr.type = "text/javascript";
  scr.src = link;
  document.getElementsByTagName('head')[0].appendChild(scr)
}

already_loaded = false;

chrome.runtime.onMessage.addListener(
    function(request, sender, sendResponse) {
        // got probably a message from them clicking the link in the browser popup icon
        if (request.action == "please_start") {
            console.log('got message to start');
            injectEditedPlayerOnce();
         }
});

function findFirstVideoTag() {
    var all = document.getElementsByTagName("video");    
    if (all.length > 0)
      return all[0];
    else {
     var i, frames;
     frames = document.getElementsByTagName("iframe");
     for (i = 0; i < frames.length; ++i) {
       try { var childDocument = frame.contentDocument } catch (e) { continue }; // skip ones we can't access :|
        all = frames[i].contentDocument.document.getElementsByTagName("video");
        if (all.length > 1)
          return all[0];
     }
     return null;
   }
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
                // appears background.js is the only thing that can adjust the icon, so could send it a message, but why these days...
             }
}

function autoStartOnBigThree() {
  var location = window.location.href;
  if (location.includes("netflix.com") || location.includes("play.google.com") || location.includes("amazon.com")) {
    var interval = setInterval(function(){
      if (findFirstVideoTag(document.body) != null && !findFirstVideoTag(document.body).src.endsWith(".mp4")) { // amazon.com main used mp4's, avoid prompt there :|
        injectEditedPlayerOnce();
        clearInterval(interval);
      }
    }, 50);  // initial delay 50ms but not too bad :)
  } // else don't do useless timer :)
}

onReady(autoStartOnBigThree);

