// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

function renderStatus(statusText) {
  document.getElementById('status').textContent = statusText;
}


function findFirstVideoTag(node) {
    // there's probably a jquery way to do this easier :)
    if (node.nodeType == 1) {
        if (node.tagName.toUpperCase() == 'VIDEO') { // assume html 5 <VIDEO  ...
            return node;
        }
        node = node.firstChild;

        while (node) {
            if ((out = findFirstVideoTag(node)) != null) {
                return out;
            }
            node = node.nextSibling;
        }
    }
}

document.addEventListener('DOMContentLoaded', function() {
  // only enters here after they click on the icon
  video_element = findFirstVideoTag(document.body);
  var h=document.getElementById("edited_requested");
  h.addEventListener("click", loadEditedPlayback());
  alert('did something' + h + " " + video_element);
(function(d, script) {
    script = d.createElement('script');
    script.type = 'text/javascript';
    script.async = true;
    script.onload = function(){
        // remote script has loaded
    };
    script.src = 'https://rawgit.com/rdp/sensible-cinema/master/html5_javascript/kemal_server/views/bootloader_dev.js';
    d.getElementsByTagName('head')[0].appendChild(script);
}(document));
});


function loadEditedPlayback() {
javascript:(function(e,s){e.src=s;e.onload=function(){;;;;;};document.head.appendChild(e);})(document.createElement('script'),'//rawgit.com/rdp/sensible-cinema/master/html5_javascript/kemal_server/views/bootloader_dev.js');
}

