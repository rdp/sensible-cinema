// some pieces from this youtube API control demo: https://github.com/rdp/sensible-cinema/wiki/YouTube-Edited-List
if (typeof timer !== 'undefined') {
  clearInterval(timer); // in case we need to reset from previous run
}

function findFirstVideoTag(node) {
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

video_element = findFirstVideoTag(document.body);

timer = setInterval(function () {
    checkStatus();
}, 1000 / 60 /* 30 * 2 fps, try to be frame accurate */);

    
 var mutes=[[2.0,7.0]];   
 var skips=[[10.0, 100.0]]; // skip from here to here
 
      function areWeWithin(thisArray, cur_time) {
          for (key in thisArray) {
            var item = thisArray[key];
            var start_time = item[0];
            var end_time = item[1];
            if(cur_time > start_time && cur_time < end_time) {
              return end_time;
            }
          }
          return false;
      }
function checkStatus() {
       var cur_time = video_element.currentTime;
        if(areWeWithin(mutes, cur_time)) {
            if (!video_element.muted) {
              video_element.muted = true;
              console.log("muted");
            }
          }
          else {
            if (video_element.muted) {
              video_element.muted = false;
              console.log("unmuted");
            }
          }
          if(last_end = areWeWithin(skips, cur_time)) {
            console.log("seeking from " + cur_time + " to " + last_end);
            video_element.pause(); // have to do this before seek so it resumes? huh?
            video_element.currentTime = last_end; // seek past this split
            video_element.play(); // sometimes needed??
          }
}
console.log("ready to go edited skips=" + skips + " mutes=" + mutes); // prompt for the console

