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
            injectBootLoaderOnce();
         }
});

function injectBootLoaderOnce() {
             if (already_loaded) {
               alert('edited player already loaded for this page, it should pick up when you start a movie on this page');
             }
             else {
                injectJs(chrome.extension.getURL('bootloader_dev.js'));
                already_loaded = true;
                // appears background.js is the only thing that can adjust the icon, so send it a message
                chrome.runtime.sendMessage({action: "loaded"}, function(response) {
                  console.log("sent loaded message from contentscripts");
                });
             }
}

function autoStartOnBigThree() {
  var location = window.location.href;
  if (location.includes("netflix.com") || location.includes("play.google.com") || location.includes("amazon.com")) {
     // can't seem to send message to self here :|
    injectBootLoaderOnce();
  }
}

setTimeout(autoStartOnBigThree, 3000); // amazon takes awhile to load its video, avoid a spurious 'not ready' message :|
