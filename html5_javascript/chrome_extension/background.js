update_icon = function(request, sender, sendResponse) {
	console.log("got request in background " + JSON.stringify(request));
  var active_tab_id = sender.tab.id; // sender
  if (request.text) {
    console.log("changing " + request.text + " color:" + request.color + " details:" + request.details);
    chrome.browserAction.setBadgeText({ text: request.text, tabId: active_tab_id });
    chrome.browserAction.setBadgeBackgroundColor({ color: request.color, tabId: active_tab_id });
    chrome.browserAction.setTitle({title: request.details, tabId: active_tab_id});
  } else if (request.version_request) {
    var manifest = chrome.runtime.getManifest();
    console.log("sent version response" + manifest.version);
    sendResponse({version: manifest.version});
   } else if (request.do_url) {
     // can only create tabs from b/g not contentscript apparently :|
     chrome.tabs.create({url: "https://playitmyway.org" + request.do_url}); // opens and sets active
   } else if (request.notification_desired) {
     console.log("got it in background.js");
     var notification_desired = request.notification_desired;
     // empty string for body works well too, and possibly should be preferred hmmmm...
     createNotification(notification_desired);
   }
};

function createNotification(notification_desired) { // shared with edited_generic_player.ecr.js
  var notification = new Notification(notification_desired.title, {body: notification_desired.body, tag: notification_desired.tag.id}); // auto shows it
  notification.onclose = function() { console.log("notification onclose");};
  // doesn't work "well" OS X (only when they really choose close, not auto disappear :| ) requireInteraction doesn't help either?? TODO report to chrome, when fixed update my SO answer :)
  notification.onclick = function(event) {
    event.preventDefault(); // prevent the browser from focusing the Notification's tab
    window.open('https://playitmyway.org/view_tag/' + notification_desired.tag.id, '_blank'); // also opens and sets active
  }
  setTimeout(function() {
    notification.close();
  }, 
  10000);
}

chrome.runtime.onMessage.addListener(update_icon); // from contentscripts.js 

chrome.runtime.onMessageExternal.addListener(update_icon); // from real page [those allowed to anyway permission wise :| ]

// startup, I think only run once for the "backup html page" singleton
// not sure what this means since it only affects one tab once what?
// update_icon( { color: "#808080", text: ".." } );

chrome.runtime.onUpdateAvailable.addListener(function(status, details) {
  console.log(status);
  console.log(details);
  chrome.runtime.reload(); // if you want it to be installed sooner you can explicitly call chrome.runtime.reload(). else it waits for background page refresh...when does that happen?
});


chrome.runtime.onInstalled.addListener(function(details){
  if (details.reason === 'install'){ // or 'update'
    chrome.tabs.create({active: true, url: "https://playitmyway.org"}); // they just intalled it, avoid confusion by sending them back to main
    // TODO just activate the one they already have open that sent them here?
  }
});