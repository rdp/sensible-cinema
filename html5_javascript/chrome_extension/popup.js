// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

document.addEventListener('DOMContentLoaded', function() {
  // only enters here after they click on the icon
  var h=document.getElementById("edited_requested");
  //h.addEventListener("click", loadEditedPlayback());
(function(d, script) {
    script = d.createElement('script');
    script.type = 'text/javascript';
    script.async = true;
    script.onload = function(){
        // remote script has loaded
    };
    script.text = 'alert("we are here");'
    d.getElementsByTagName('head')[0].appendChild(script);
}(document));
});

