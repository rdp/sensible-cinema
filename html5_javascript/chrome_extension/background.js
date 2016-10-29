update_icon = function(request, sender, sendResponse) {
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
      var active_tab_id = tabs[0].id;
      chrome.browserAction.setBadgeText({ text: request.text, tabId: active_tab_id });
      chrome.browserAction.setBadgeBackgroundColor({ color: request.color }); // red
    });
};

chrome.runtime.onMessage.addListener(update_icon); // from contentscripts.js -- unused these days :|

chrome.runtime.onMessageExternal.addListener(update_icon); // from real page [those allowed to anyway :| ]

// startup:
chrome.browserAction.setBadgeText({ text: ".." });
chrome.browserAction.setBadgeBackgroundColor({ color:"#808080" }); // grey
