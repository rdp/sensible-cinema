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
        // got probably a message from them clicking the icon

        if (request.action == "please_start") {
             if (already_loaded) {
               alert('edited player already loaded for this page, it should pick up when you start a movie on this page');
             }
             else {
                 injectJs(chrome.extension.getURL('bootloader_dev.js'));
                 already_loaded = true;
                 chrome.runtime.sendMessage({action: "loaded"}, function(response) {
                   console.log("sent loaded message from contentscripts");
                 });
             }
         }
});
