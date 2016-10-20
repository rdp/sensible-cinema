// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

chrome.runtime.onMessage.addListener(
  // message presumably from contentscript.js [?]
  function(request, sender, sendResponse) {
    console.log('received message to background');
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
      var active_tab_id = tabs[0].id;
      if (request.action == "loaded") {
        chrome.browserAction.setBadgeText({ text: "YES", tabId: active_tab_id })
      }
    });
});

chrome.runtime.onMessageExternal.addListener(
    function(request, sender, sendResponse) {
      // message from real page, but can't use wildcards for this :|
});

chrome.browserAction.setBadgeText({ text: "no" }); // default :)

