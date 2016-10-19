// content script runs on every page

function injectJs(link) {
  var scr = document.createElement('script');
  scr.type="text/javascript";
  scr.src=link;
  document.getElementsByTagName('head')[0].appendChild(scr)
}

already_loaded = false;

chrome.runtime.onMessage.addListener(
    function(request, sender, sendResponse) {
        console.log(request);

        if (request.greeting == "hello")
            sendResponse({farewell: "goodbye"});

        if (request.action == "start") {
             if (already_loaded) {
               alert('edited player already loaded for this page');
             }
             else {
                 injectJs(chrome.extension.getURL('bootloader_dev.js'));
                 already_loaded = true;
             }
         }
});
