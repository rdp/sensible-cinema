// for non chrome browser: copy and paste all of this text (including this line) into the "developer tools javascript console" ">" prompt, and hit enter:
// if you have the chrome plugin, it automatically should do all this for you, no copy paste needed... :|

if (typeof clean_stream_timer !== 'undefined') {
  alert("clean stream already loaded...not loading it again...");
  throw "dont know how to load it twice"; // in case they click a plugin button twice, or load it twice (too hard to reload, doesn't work that way anymore)
}

// generated at 2016-10-29 19:30:32 -0400.

function isGoogleIframe() {
  return /play.google.com/.test(window.location.hostname); // assume we're in an iframe, should be safe assumption...should disallow starting if not
}

function getStandardizedCurrentUrl() {
  var current_url = window.location.href;
  if (isGoogleIframe()) {
    current_url = document.referrer; // iframe parent url
  }
  if (current_url.includes("amazon.com")) {
    if (document.querySelector('link[rel="canonical"]') != null) {
      current_url = document.querySelector('link[rel="canonical"]').href; // seems to always convert from "/gp/" to "/dp/" and sometimes even change the ID :|
    }
  }
  // standardize
  current_url = current_url.replace("smile.amazon.com", "www.amazon.com");
  if (current_url.includes("amazon.com") || current_url.includes("netflix.com")) { // known to want to strip off cruft
    current_url = current_url.split("?")[0];
  }
  return current_url;
}

function liveAmazonEpisodeName() {
  if (document.getElementsByClassName("subtitle").length > 0) {
    // amazon
    split = document.getElementsByClassName("subtitle")[0].innerHTML.split(/Ep. \d+/); // like "Season 3, Ep. 3 The Painted Lady"
    if(split.length == 2)
      return split[1].trim();
    else
      return split[0].trim();
  }
  else
    if (isGoogleIframe()) {
      var numberNameDiv = window.parent.document.querySelectorAll('.epname-number')[0]; // apparently I have backward but not forward visibility. phew.
      if (numberNameDiv) {
        var numberName = numberNameDiv.innerHTML; // like " 3. Return to Omashu "
        var numberName = numberName.trim();
        var regex =  /(\d+)\. /; 
        if (regex.test(numberName)) {
          return numberName.split(regex)[2];
        }
        // ??
        return numberName;
     }
    }
    return "";
  end
}

function liveAmazonEpisodeNumber() {
  if (isGoogleIframe()) {
    var numberNameDiv = window.parent.document.querySelectorAll('.epname-number')[0]; // apparently I have backward but not forward visibility. phew.
    if (numberNameDiv) {
      var numberName = numberNameDiv.innerHTML; // like " 3. Return to Omashu "
      var numberName = numberName.trim();
      var regex =  /(\d+)\. /;
      if (regex.test(numberName)) {
        return /(\d+)\. /.exec(numberName)[1];
      }
      else {
        return "0";
      }
    }
  }
  // amazon :)
  var subtitle = document.getElementsByClassName("subtitle")[0];
  if (subtitle && subtitle.innerHTML.match(/Ep. (\d+)/))
    return /Ep. (\d+)/.exec(subtitle.innerHTML)[1];
  else
    return "0"; // anything else
}


function findFirstVideoTag() {
    var all = document.getElementsByTagName("video");
    if (all.length > 0)
      return all[0];
    else {
     // leave this in here in case people try to load it manually, non plugin, and we happen to have access to iframes, which will be about never
     // it won't hurt anything...
     var i, frames;
     frames = document.getElementsByTagName("iframe");
     for (i = 0; i < frames.length; ++i) {
       try { var childDocument = frame.contentDocument } catch (e) { continue }; // skip ones we can't access :|
        all = frames[i].contentDocument.document.getElementsByTagName("video");
        if (all.length > 1)
          return all[0];
     }
     return null;
   }
}

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

extra_message = "";

function checkStatus() {
  var cur_time = video_element.currentTime;
  var [last_start, last_end] = areWeWithin(mutes, cur_time);
  if (last_start) {
    if (!video_element.muted) {
      video_element.muted = true;
      timestamp_log("muting", cur_time, last_start, last_end);
      extra_message = "muted";
    }
  }
  else {
    if (video_element.muted) {
      video_element.muted = false;
      console.log("unmuted at=" + cur_time);
      extra_message = "";
    }
  }
  if (window.location.href.includes("netflix.com")) {
    handleNetflixSeekOrStop(cur_time);
  } 
  else {
     // youtube, amazon et al, sane seeks with no watching it :)    
    [last_start, last_end] = areWeWithin(skips, cur_time);
    if (last_start) {
      timestamp_log("seeking to " + last_end, cur_time, last_start, last_end);
      seekToTime(last_end);
    }
  }  
  [last_start, last_end] = areWeWithin(yes_audio_no_videos, cur_time);
  if (last_start) {
    if (video_element.style.visibility != "hidden") {
      console.log("hiding video leaving audio ", cur_time, last_start, last_end);
      extra_message = "no video yes audio";
      video_element.style.visibility="hidden";
    }
  }
  else {
    if (video_element.style.visibility != "") {
      video_element.style.visibility=""; // non hidden :)
      console.log("unhiding video with left audio" + cur_time);
      extra_message = "";
    }
  }
  
  topLineEditDiv.innerHTML = " " + timeStampToHuman(cur_time) + " " + extra_message + " Add new edit:";
  document.getElementById("add_edit_span_id_for_extra_message").innerHTML = extra_message;
  document.getElementById("playback_rate").innerHTML = video_element.playbackRate.toFixed(2) + "x";
  checkIfEpisodeChanged();
}

function liveEpisodeString() {
  if (liveAmazonEpisodeNumber() != "0")
    return " episode:" + liveAmazonEpisodeNumber() + " " + liveAmazonEpisodeName();
  else
    return "";
  end
}

function liveTitleNoEpisode() {
  var title = document.getElementsByTagName("title")[0].innerHTML;
  if (isGoogleIframe()) {
    title = window.parent.document.getElementsByTagName("title")[0].innerHTML; // always there :) "Avatar Extras - Movies &amp; TV on Google Play"
    var season_episode = window.parent.document.querySelectorAll('.title-season-episode-num')[0];
    if (season_episode) {
      title += season_episode.innerHTML.split(",")[0]; // like " Season 2, Episode 2 "
    }
    // don't add episode name
  }
  return title;
}

function liveFullNameEpisode() {
  return liveTitleNoEpisode() + liveEpisodeString(); 
}

function timestamp_log(message, cur_time, last_start, last_end) {
  local_message = message + " at " + cur_time + " start:" + last_start + " will_end:" + last_end + " in " + (last_end - cur_time)+ "s";;
  console.log(local_message);
}

function handleNetflixSeekOrStop(cur_time) {
    fast_forward_to_skip_speed = 1.01; // even 4 was barfing ?? with 1.25 barfs very rarely
    [last_start, last_end] = areWeWithin(skips, cur_time);
    if (last_start) {
        if (video_element.playbackRate == fast_forward_to_skip_speed) {
          console.log("still fast forwarding to " + last_end + " remaining=" + Math.round(last_end - cur_time));
          // already and still fast forwarding
        } else {
          // fast forward
          timestamp_log("begin fast forward while muted", cur_time, last_start, last_end);
          extra_message = "blanking and muting to skip";
          video_element.playbackRate = fast_forward_to_skip_speed; // seems to be its max or freezes [?]
          video_element.volume = 0;
          video_element.style.visibility="hidden";
        }
    } else {
       // not in a skip, did we just finish one?
       if (video_element.playbackRate == fast_forward_to_skip_speed) {
          console.log("cancel/done fast forwarding " + cur_time);
          extra_message = "";
          video_element.style.visibility="";// non hidden
          video_element.volume = 1;
          video_element.playbackRate = 1;
       }
    }
}

function addEditUi() {
  exposeEditScreenDiv = document.createElement('div');
  exposeEditScreenDiv.style.position = 'absolute';
  exposeEditScreenDiv.style.height = '30px';
  exposeEditScreenDiv.style.background = '#000000';
  exposeEditScreenDiv.style.zIndex = "99999999"; // on top :)
  exposeEditScreenDiv.style.backgroundColor = "rgba(0,0,0,0)"; // still see the video, but also see the text :)
  exposeEditScreenDiv.style.fontSize = "13px";
  exposeEditScreenDiv.style.color = "Grey";
  exposeEditScreenDiv.innerHTML = `<a href=# onclick="addForNewEditToScreen()" id="add_edit_link_id">Add edit</a> <span id=add_edit_span_id_for_extra_message></span>`;
  // and stay visible
  document.body.appendChild(exposeEditScreenDiv);

  topLineEditDiv = document.createElement('div');
  topLineEditDiv.style.position = 'absolute';
  topLineEditDiv.style.height = '30px';
  topLineEditDiv.style.background = '#000000';
  topLineEditDiv.style.zIndex = "99999999"; // on top :)
  topLineEditDiv.style.backgroundColor = "rgba(0,0,0,0)"; // still see the video, but also see the text :)
  topLineEditDiv.style.textShadow="2px 1px 0px white";
  topLineEditDiv.style.fontSize = "13px";
  topLineEditDiv.style.display = 'none';
  document.body.appendChild(topLineEditDiv);
  
  edlLayer = document.createElement('div');
  edlLayer.style.position = 'absolute';
  edlLayer.style.width = '500px';
  edlLayer.style.height = '30px';
  edlLayer.style.background = '#000000';
  edlLayer.style.zIndex = "99999999"; // on top :)
  edlLayer.style.backgroundColor = "rgba(0,0,0,0)"; // still see the video, but also see the text :)
  edlLayer.style.textShadow="2px 1px 0px white";
  edlLayer.style.fontSize = "13px";
  edlLayer.style.display = 'none';
  document.body.appendChild(edlLayer);
  
  // inject the HTML UI 
  edlLayer.innerHTML = `
  from:<textarea name='start' rows='1' cols='20' style='width: 150px; font-size: 12pt; font-family: Arial;' id='start'>0.00s</textarea>
  <input id='clickMe' type='button' value='set to now' onclick="document.getElementById('start').value = getCurrentVideoTimestampHuman();" />
  <br/>
  to:<textarea name='endy' rows='1' cols='20' style='width: 150px; font-size: 12pt; font-family: Arial;' id='endy'>0.00s</textarea>
  <input id='clickMe' type='button' value='set to now' onclick="document.getElementById('endy').value = getCurrentVideoTimestampHuman();" />
  <br/>
  action:
  <select name='default_action' id='new_action'>
    <option value='mute'>mute</option>
    <option value='skip'>skip</option>
    <option value='yes_audio_no_video'>yes_audio_no_video</option>
    <option value='do_nothing'>do_nothing</option>
  </select>
  <input type='submit' value='Test edit once' onclick="testCurrentFromUi();">
  <input type='submit' value='Save edit' onclick="saveEditButton();">
  <br/>
  <a href='#' onclick="seekToTime(video_element.currentTime -5);">-5</a>
  <a href="#" onclick="video_element.playbackRate -= 0.1;">&lt;&lt;</a>
  <span id='playback_rate'>1.00x</span>
  <a href="#" onclick="video_element.playbackRate += 0.1;">&gt;&gt;</a>
  <a href="#" onclick="stepFrame();">step</a>
  <a href="#" onclick="video_element.play()">&#9654;</a>
  <a href="#" onclick="video_element.pause()">&#9612;&#9612;</a>
  `;
  
  // this only works for the few mentioned in externally_connectable in manifest.json :|
  chrome.runtime.sendMessage(editorExtensionId, {text: "YES", color: "#008000"}); // green

  addEvent(window, "resize", function(event) {
    setEditedControlsToTopLeft();
  });
  addEvent(window, "scroll", function(event) {
    setEditedControlsToTopLeft();
  });
  setEditedControlsToTopLeft(); // and call immediately :)
}

var editorExtensionId = "ogneemgeahimaaefffhfkeeakkjajenb";

// method to bind easily to resize event
var addEvent = function(object, type, callback) {
    if (object == null || typeof(object) == 'undefined') return;
    if (object.addEventListener) {
        object.addEventListener(type, callback, false);
    } else if (object.attachEvent) {
        object.attachEvent("on" + type, callback);
    } else {
        object["on"+type] = callback;
    }
};

function toggleDiv(div) {
    div.style.display = div.style.display == "none" ? "block" : "none";
}

function seekToTime(ts) {
  // try and avoid pauses when seeking
  video_element.pause();
  video_element.currentTime = ts;
  video_element.play();
}

function addForNewEditToScreen() {
  if (url_id == 0) {
    alert('cannot add edits to non existing movie in our database yet, please create it, then reload this page after a few minutes');
    return; // abort
  }
  // hope these never get mixed LOL
  if (exposeEditScreenDiv.innerHTML.includes("Add ")) {
    toggleDiv(topLineEditDiv);
    toggleDiv(edlLayer);
    document.getElementById("add_edit_link_id").innerHTML = "Close editor";
  }
  else {
    toggleDiv(topLineEditDiv);
    toggleDiv(edlLayer);
    document.getElementById("add_edit_link_id").innerHTML = "Add edit";
  }
}

function setEditedControlsToTopLeft() {
  // discover where the "currently viewed" top left actually is (not always 0,0 apparently, it seems)
  var doc = document.documentElement;
  var left = (window.pageXOffset || doc.scrollLeft) - (doc.clientLeft || 0);
  var top = (window.pageYOffset || doc.scrollTop)  - (doc.clientTop || 0);
  offset = 150; // allow kill amazon x-ray :|
  left += offset;
  exposeEditScreenDiv.style.left = (left - offset) + "px"; // real zero for this one :|
  exposeEditScreenDiv.style.top = top + "px";
  topLineEditDiv.style.left = left + "px"; 
  topLineEditDiv.style.top = top + "px";
  edlLayer.style.left = left + "px";
  edlLayer.style.top = (top + 30) + "px";
}

function addToCurrentEditArray() {
  start = humanToTimeStamp(document.getElementById('start').value);
  endy = humanToTimeStamp(document.getElementById('endy').value);
  if (endy <= start) {
    alert("seems your end is before your start, please fix!");
    return; // abort
  } 
  currentEditArray().push([start, endy]);
  return [start, endy];
}

function currentTestAction() {
  return document.getElementById('new_action').value;
}

function testCurrentFromUi() {
  if (currentTestAction() == 'do_nothing') {
    alert('testing a do nothing is hard, please set it to yes_audio_no_video, test it, then set it back to do_nothing, then hit save button');
    return; // abort
  }
  var [start, endy] = addToCurrentEditArray();
  seekToTime(start - 2);
  length = endy - start;
  if (currentTestAction() == 'skip') 
    length = 0; // it skips it, so the amount of time before reverting is less it :)
  wait_time_millis = (length + 2 + 1)*1000; 
  setTimeout(function() {
    currentEditArray().pop();
  }, wait_time_millis)
}

function currentEditArray() {
  switch (currentTestAction()) {
    case 'mute':
      return mutes;
    case 'skip':
      return skips;
    case 'yes_audio_no_video':
      return yes_audio_no_videos;
    case 'do_nothing':
      return do_nothings;
    default:
      alert('internal error 1...'); // hopefully never see this
  }
}

function getCurrentVideoTimestampHuman() {
  return timeStampToHuman(video_element.currentTime);
}

function timeStampToHuman(timestamp) {
  var hours = Math.floor(timestamp / 3600);
  timestamp -= hours * 3600;
  var minutes  = Math.floor(timestamp / 60);
  timestamp -= minutes * 60;
  var seconds = timestamp.toFixed(2); //  -> "12.30";
  // padding is "hard" apparently in javascript LOL
  if (hours > 0)
    return hours + "h " + minutes + "m " + seconds + "s";
  else
    return minutes + "m " + seconds + "s";
}

function removeFromArray(arr) {
    var what, a = arguments, L = a.length, ax;
    while (L > 1 && arr.length) {
        what = a[--L];
        while ((ax= arr.indexOf(what)) !== -1) {
            arr.splice(ax, 1);
        }
    }
    return arr;
}

function humanToTimeStamp(timestamp) {
  // 0h 17m 34.54s
  sum = 0.0
  split = timestamp.split(/[hms ]/)
  removeFromArray(split, "");
  split.reverse();
  for (var i = 0; i < split.length; i++) {
    sum += parseFloat(split[i]) * Math.pow(60, i);
  }
  return sum;
}

function saveEditButton() {
  var url = "https://" + request_host + "/add_edl/" + url_id + '?start=' + document.getElementById('start').value + 
  "&endy=" + document.getElementById('endy').value + "&default_action=" + currentTestAction();
  console.log(url);
  var win = window.open(url, '_blank');
  addToCurrentEditArray(); // and leave it there
}

function stepFrame() {
  video_element.play();
  setTimeout(function() { 
    video_element.pause(); 
  }, 1/30*1000); // theoretically about a frame worth :)
}

function loadForCurrentUrl() {
  var filename = encodeURIComponent(getStandardizedCurrentUrl() +  ".ep" + liveAmazonEpisodeNumber() + ".html5_edited.just_settings.json.rendered.js");
  var url = '//rawgit.com/rdp/sensible-cinema-edit-descriptors/master/' + encodeURIComponent (filename);
  var direct_lookup = 'for_current_just_settings_json?url=' + encodeURIComponent(getStandardizedCurrentUrl()) + '&amazon_episode_number=' + liveAmazonEpisodeNumber();
  url = '//cleanstream.inet2.org/' + direct_lookup; // SSL FTW
  
  getRequest(url, parseSuccessfulJson, loadFailed); // only works because we set CORS header :|
}

function parseSuccessfulJson(json) {
  out = JSON.parse(json);
  // assume right format LOL
  url = out.url;
  name=url.name;
  editing_status = url.editing_status;
  amazon_episode_name=url.amazon_episode_name;
  // don't parse them, be lazy for now
  mutes=out.mutes;
  skips=out.skips;
  yes_audio_no_videos=out.yes_audio_no_videos;
  do_nothings=out.do_nothings;
  expected_current_url=out.expected_url_unescaped;
  amazon_second_url=out.url;
  expected_amazon_episode_number=url.amazon_episode_number;
  url_id=url.id;
  request_host=out.request_host; // XXXX should this live at the top only?
  loadSuccessful();
}

// http://stackoverflow.com/questions/1442425/detect-xhr-error-is-really-due-to-browser-stop-or-click-to-new-page
function getRequest (url, success, error) {  
  console.log("starting attempt to download " + url);
  var xhr = XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP"); 
  xhr.open("GET", url); 
  xhr.onreadystatechange = function(){ 
    if ( xhr.readyState == 4 ) { 
      if ( xhr.status == 200 ) { 
        console.log("success download");
        success(xhr.responseText); 
      } else { 
        console.log("fail download 1");
        error && error(xhr.status); 
        error = null;
      } 
    } 
  }; 
  xhr.onerror = function () { 
    console.log("fail download 2");
    error && error(xhr.status); 
    error = null;
  }; 
  xhr.send(); 
}

function checkIfEpisodeChanged() {
  if (getStandardizedCurrentUrl() != old_current_url || liveAmazonEpisodeNumber() != old_amazon_episode) {
    console.log("detected move to another video, to " + liveFullNameEpisode() + "\nfrom\n" +
    old_current_url + " ep. " + old_amazon_episode + "\nwill try to load its edited settings now for the new movie...");
    old_current_url = getStandardizedCurrentUrl(); // set them now so it doesn't re-get them next loop
    old_amazon_episode = liveAmazonEpisodeNumber(); 
    loadForCurrentUrl(); 
  }
}

function loadFailed(status) {
  mutes = skips = yes_audio_no_videos = []; // reset so it doesn't re-use last episode's edits for the current episode!
  editing_status = "unknown to system";
  name = liveFullNameEpisode();
  amazon_episode_name = liveEpisodeString();
  expected_amazon_episode_number = liveAmazonEpisodeNumber();
  url_id = 0; // reset
  // request_host leave ?
  old_current_url = getStandardizedCurrentUrl();
  old_amazon_episode = liveAmazonEpisodeNumber(); 
  chrome.runtime.sendMessage(editorExtensionId, {color: "#A00000", text: "NO"}); // red
  if (status > 0 && confirm("We don't appear to have edits for\n" + liveFullNameEpisode() + "\n yet, would you like to create it in our system now?\n (cancel to watch unedited, OK to add to our edit database.")) {
    window.open("https://cleanstream.inet2.org/new_url?url=" + encodeURIComponent(getStandardizedCurrentUrl()) + "&amazon_episode_number=" + liveAmazonEpisodeNumber() + "&amazon_episode_name=" + encodeURIComponent(liveAmazonEpisodeName()) + "&title=" + encodeURIComponent(liveTitleNoEpisode()), "_blank");
    setTimeout(function() {
      loadForCurrentUrl();
    }, 2000); // it should auto save so we should be live within 2s I hope...if not they'll get the same prompt [?] :|
  }
  else {
    // server down or want to watch unedited...
    if (status == 0) {
      alert("appears the cleanstream server is currently down, please alert us!");
    }
    startWatcherOnce(); // so it can check if episode changes to one we like :)
  }
}

function loadSuccessful() {
  if (getStandardizedCurrentUrl() != expected_current_url && getStandardizedCurrentUrl() != amazon_second_url) {
    alert("danger: this may have been the wrong url? this_page=" + window.location.href + "(" + getStandardizedCurrentUrl() + ") edits expected from=" + expected_current_url + " or " + amazon_second_url);
  }
  old_current_url = getStandardizedCurrentUrl();
  if (liveAmazonEpisodeNumber() != expected_amazon_episode_number) {
    alert("danger: may have gotten wrong amazon episode expected=" + expected_amazon_episode_number + " got=" + liveAmazonEpisodeNumber());
  }
  old_amazon_episode = liveAmazonEpisodeNumber();
  startWatcherOnce();
  var post_message = "This movie is currently marked as \"" + editing_status + "\" in our system, which means it is incomplete.  Please help us groom edits to our system and mark status as done when it's complete, thanks so much!";
  if (editing_status == "done")
    post_message = "\nYou may sit back and relax while you enjoy it now!";

  var message = "Editing playback successfully enabled for\n" + name + " " + amazon_episode_name + "\n" + liveFullNameEpisode() + "\nskips=" + skips.length + " mutes=" + mutes.length +"\nyes_audio_no_videos=" + yes_audio_no_videos.length + "\ndo_nothings=" + do_nothings.length + "\n" + post_message;
  
    alert(message);
  
}

var clean_stream_timer;

function startWatcherOnce() {
  clean_stream_timer = clean_stream_timer || setInterval(function () {
      checkStatus();
  }, 1000 / 100 ); // 100 fps since that's the granularity of our time entries :|
  // guess we just never turn it off
}

function start() {
  video_element = findFirstVideoTag();

  if (video_element == null) { 
    alert("failure: unable to find a video playing, not loading edited playback...");
    // this one's pretty serious, just let it die...plugin should not have let us get this far
  }

  if (isGoogleIframe()) {
    if (!window.parent.location.pathname.startsWith("/store/movies/details") && !window.parent.location.pathname.startsWith("/store/tv/show")) {
      // iframe started from a non "details" page
      // TODO we have access to the ID's, use it instead of hard fail, allow the index, man!
      alert('failure: for google play movies, you need to right click on them and choosen "open in new tab" for it to work edited.');
    }
  }

  // ready to try and load the editor LOL
  addEditUi();
  loadForCurrentUrl();
}

// no jquery since this page might already have it loaded, so avoid any conflict.  [plus speedup load times LOL]
start();
