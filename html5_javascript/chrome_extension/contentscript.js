// content script runs on every page

function injectJs(link) {
  var scr = document.createElement('script');
  scr.type="text/javascript";
  scr.src=link;
  document.getElementsByTagName('head')[0].appendChild(scr)
}

chrome.runtime.onMessage.addListener(
    function(request, sender, sendResponse) {
        alert('here1');
        console.log(sender.tab ?
                "from a content script:" + sender.tab.url :
                "from the extension");

        if (request.greeting == "hello")
            sendResponse({farewell: "goodbye"});

       if (request.action == "start") 
         injectJs(chrome.extension.getURL('bootloader_dev.js'));
      alert('here3');

});
