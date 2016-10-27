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

function findFirstVideoTag(node) {
    // there's probably a jquery way to do this easier :)
    if (node.nodeType == 1) {
        if (node.tagName.toUpperCase() == 'VIDEO') { // assume html 5 <VIDEO  ...
            return node;
        }
        node = node.firstChild;

        while (node) {
            if ((out = findFirstVideoTag(node)) != null) {
                return out;
            }
            node = node.nextSibling;
        }
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
    injectEditedPlayerOnce();
  }
  // for the rest, they have to click plugin link :|
}

var interval = setInterval(function(){
  if (findFirstVideoTag(document.body) != null && !findFirstVideoTag(document.body).src.endsWith(".mp4")) { // amazon.com main used mp4's, avoid prompt there :|
    autoStartOnBigThree();
    clearInterval(interval);
  }
}, 50); 

