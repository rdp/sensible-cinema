// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


update_icon = function(request, sender, sendResponse) {
    console.log('received message to background');
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
      var active_tab_id = tabs[0].id;
      if (request.action == "loaded") {
        // not "really" loaded yet :|
        chrome.browserAction.setBadgeText({ text: "???", tabId: active_tab_id });
        chrome.browserAction.setBadgeBackgroundColor({ color: "yellow" }); // blue meaning ambiguous :)
        // TODO show on the background UI the current status as well
      }
      else if (request.action == "really_started") {
        chrome.browserAction.setBadgeText({ text: "YES", tabId: active_tab_id });
        chrome.browserAction.setBadgeBackgroundColor({ color: "#008000" }); // green
      }
    });
};

chrome.runtime.onMessage.addListener(update_icon); // from contentscripts.js

chrome.runtime.onMessageExternal.addListener(update_icon); // from real page [those allowed to anyway :| ]

// start:
chrome.browserAction.setBadgeText({ text: "off" });
chrome.browserAction.setBadgeBackgroundColor({ color:"#808080" });
