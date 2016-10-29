// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

document.addEventListener('DOMContentLoaded', function() {
  // only enters here after they click on the icon
  // no access *at all* to the current tab DOM apparently :|

   var h = document.getElementById("edited_requested");
   h.addEventListener("click", loadEditedPlayback);
   var y = document.getElementById("index_link");
   y.addEventListener("click", openIndex);
});

function loadEditedPlayback() {
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
        chrome.tabs.sendMessage(tabs[0].id, {action: 'please_start'}, function(response) {
            console.log("send start message from popup");
        });
    });
}

function openIndex() {
  // this is how you have to do links from popup [yikeserz]
  chrome.tabs.create({active: true, url: "http://cleanstream.inet2.org"});
}

update_status = function(request, sender, sendResponse) {
  document.getElementById("status_text_popup").innerHTML = request.text; // also request.color hrm
}

chrome.runtime.onMessageExternal.addListener(update_status); // message from real page [those allowed to anyway :| ]
