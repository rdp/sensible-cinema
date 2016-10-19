// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

chrome.runtime.onMessage.addListener(
    function(request, sender, sendResponse) {
        console.log("background received:" + request);

    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
        var active_tab_id = tabs[0].id;
        if (request.action == "started") {
          chrome.browserAction.setBadgeText({ text: "5", tabId: active_tab_id })
        }
    });
});
