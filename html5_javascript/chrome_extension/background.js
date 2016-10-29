update_icon = function(request, sender, sendResponse) {
  var active_tab_id = sender.tab.id; // sender
  console.log("changing " + request.text + " color:" + request.color);
  chrome.browserAction.setBadgeText({ text: request.text, tabId: active_tab_id });
  chrome.browserAction.setBadgeBackgroundColor({ color: request.color, tabId: active_tab_id });
};

chrome.runtime.onMessage.addListener(update_icon); // from contentscripts.js 

chrome.runtime.onMessageExternal.addListener(update_icon); // from real page [those allowed to anyway permission wise :| ]

// startup, I think only run once for the "backup html page" singleton
// not sure what this means since it only affects one tab once what?
// update_icon( { color: "#808080", text: ".." } );
