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
}, 1000 / 30 / 5 /* 30 fps * 5, try to be frame accurate even during skips */);

    
var mutes=[[2.0,7.0]];   
var skips=[[10.0, 30.0]]; // skip from here to here

function areWeWithin(thisArray, cur_time) {
    for (key in thisArray) {
      var item = thisArray[key];
      var start_time = item[0];
      var end_time = item[1];
      if(cur_time > start_time && cur_time < end_time) {
        return item;
      }
    }
    return [false];
}

function checkStatus() {
  var cur_time = video_element.currentTime;
    [last_start, last_end] = areWeWithin(mutes, cur_time);
  if(last_start) {
      if (!video_element.muted) {
        video_element.muted = true;
        console.log("muted " + cur_time + " start=" + last_start + " end " + last_end);
      }
    }
  else {
      if (video_element.muted) {
        video_element.muted = false;
        console.log("unmuted " + cur_time);
      }
  }
  if (window.location.href.includes("netflix.com")) {
        [last_start, last_end] = areWeWithin(skips, cur_time);
      if(last_start) {
          if (video_element.playbackRate == 5) {
            console.log("still fast forwarding to " + last_end);
            // already and still fast forwarding
          } else {
            // begin fast forward
            console.log("begin fast forwarding "+ cur_time + " start=" + last_start + " end " + last_end);
            video_element.style.width="1%"
            video_element.playbackRate = 5; // seems to be its max or freezes [?]
          }
      } else {
         // not in a skip, did we just finish one?
         if (video_element.playbackRate == 5) {
            console.log("cancel/done fast forwarding " + cur_time);
           // end current fast forward
           video_element.style.width="100%"
           video_element.playbackRate = 1;
         }
      }
  } else {
       // youtube, amazon et al, easy seeks :)
        [last_start, last_end] = areWeWithin(skips, cur_time);
        
      if(last_start) {
       console.log("seeking from " + cur_time + " to " + last_end);
       video_element.pause(); // have to do this before seek so it resumes? huh?
       video_element.currentTime = last_end; // seek past this split
       video_element.play(); // sometimes needed??
      }
  }
}


// netflix stuff [most from netflix party] ( not used yet ) :|

// load jquery
javascript:(function(e,s){e.src=s;e.onload=function(){jQuery.noConflict();console.log('jQuery injected')};document.head.appendChild(e);})(document.createElement('script'),'//code.jquery.com/jquery-latest.min.js')


var uiEventsHappening = 0;

    // video duration in milliseconds
    var lastDuration = 60 * 60 * 1000;
    var getDuration = function() {
      var video = jQuery('.player-video-wrapper video');
      if (video.length > 0) {
        lastDuration = Math.floor(video[0].duration * 1000);
      }
      return lastDuration;
    };


var showControls = function() {
  uiEventsHappening += 1;
  var scrubber = $('#scrubber-component');
  var eventOptions = {
    'bubbles': true,
    'button': 0,
    'currentTarget': scrubber[0]
  };
  scrubber[0].dispatchEvent(new MouseEvent('mousemove', eventOptions));
  return to(10)().then(function() {
    uiEventsHappening -= 1;
  });
};

console.log("ready to go edited skips=" + skips + " mutes=" + mutes); // prompt for the console

// load this exact file (github):
// javascript:(function(e,s){e.src=s;e.onload=function(){console.log('editor injected from github')};document.head.appendChild(e);})(document.createElement('script'),'//rawgit.com/rdp/sensible-cinema/master/html5_javascript/html5_edited.js')
