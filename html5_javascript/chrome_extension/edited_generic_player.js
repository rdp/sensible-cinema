// for non chrome browser: copy and paste all of this text (including this line) into the "developer tools javascript console" ">" prompt, and hit enter:
// if you have the chrome plugin, it automatically should do all this for you, you should not need to do anything here...just install the plugin.

if (typeof clean_stream_timer !== 'undefined') {
  alert("already loaded...not loading it again...please use the on screen links for it"); // hope we never get here :|
  throw "dont know how to load it twice"; // in case they click a plugin button twice, or load it twice (too hard to reload, doesn't work that way anymore)
}

var request_host="localhost:3000";
// var request_host="playitmyway.inet2.org";

var editorExtensionIds = ["ogneemgeahimaaefffhfkeeakkjajenb", "ionkpaepibbmmhcijkhmamakpeclkdml"]; // one for local one for published gah

function inIframe() {
    try {
        return window.self !== window.top;
    } catch (e) {
        return true;
    }
}

function isGoogleIframe() {
  return inIframe() && /google.com/.test(window.location.hostname); 
}

function currentUrlNotIframe() { // hopefully better alternate to window.location.href, though somehow this doesn't always work still [ex: netflix.com iframes?]
  return (window.location != window.parent.location) ? document.referrer : document.location.href;
} 

function isAmazon() {
  return currentUrlNotIframe().includes("amazon.com");
}

function getStandardizedCurrentUrl() {
  var current_url = currentUrlNotIframe();
  if (isAmazon()) {
    if (document.querySelector('link[rel="canonical"]') != null) {
      current_url = document.querySelector('link[rel="canonical"]').href; // seems to always convert from "/gp/" to "/dp/" and sometimes even change the ID :|
    }
  }
  // standardize
  current_url = current_url.replace("smile.amazon.com", "www.amazon.com");
  if (current_url.includes("amazon.com")) { // known to want to strip off cruft
    current_url = current_url.split("?")[0];
  }
  return current_url;
}

function liveEpisodeName() {
  if (isAmazon() && document.getElementsByClassName("subtitle").length > 0) {
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

function liveEpisodeNumber() {
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
  if (isAmazon()) {
    var subtitle = document.getElementsByClassName("subtitle")[0];
    if (subtitle && subtitle.innerHTML.match(/Ep. (\d+)/)) {
      return /Ep. (\d+)/.exec(subtitle.innerHTML)[1];
    }
  }
  else {
    return "0"; // anything else...
  }
}

function findFirstVideoTagOrNull() {
  var all = document.getElementsByTagName("video");
  // search iframes in case people try to load it manually, non plugin, and we happen to have access to iframes, which will be about never
  // it hopefully won't hurt anything...
  var i, frames;
  frames = document.getElementsByTagName("iframe");
  for (i = 0; i < frames.length; ++i) {
    try { var childDocument = frame.contentDocument } catch (e) { continue }; // skip ones we can't access :|
    all.concat(frames[i].contentDocument.document.getElementsByTagName("video"));
  }
  for(var i = 0, len = all.length; i < len; i++) {
    if (all[i].currentTime > 0) {
      return all[i];
    }
  }
  return null;
}

function decodeHTMLEntities(text) {
    var entities = [
        ['amp', '&'], ['apos', '\''], ['#x27', '\''], ['#x2F', '/'], ['#39', '\''], ['#47', '/'], ['lt', '<'], ['gt', '>'], ['nbsp', ' '], ['quot', '"']
    ];
    for (var i = 0, max = entities.length; i < max; ++i) {
        text = text.replace(new RegExp('&'+entities[i][0]+';', 'g'), entities[i][1]);
    }
    return text;
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
  [last_start, last_end] = areWeWithin(skips, cur_time);
  if (last_start) {
    timestamp_log("seeking to " + last_end, cur_time, last_start, last_end);
    seekToTime(last_end);
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
  
  topLineEditDiv.innerHTML = "Add new tag: " + timeStampToHuman(cur_time) + " " + extra_message;
  document.getElementById("add_edit_span_id_for_extra_message").innerHTML = extra_message;
  document.getElementById("playback_rate").innerHTML = video_element.playbackRate.toFixed(2) + "x";
  checkIfEpisodeChanged();
  video_element = findFirstVideoTagOrNull() || video_element; // refresh it in case changed, but don't switch to null :|
}

function liveEpisodeString() {
  if (liveEpisodeNumber() != "0")
    return " episode:" + liveEpisodeNumber() + " " + liveEpisodeName();
  else
    return "";
  end
}

function youtubeChannelName() {
    var all = document.getElementsByTagName("img");
    var arrayLength = all.length;
    for (var i = 0; i < arrayLength; i++) {
        if (all[i].alt != "") {
          return all[i].alt + " "; // "Studio C" channel name, but hacky...
        }
    }
    return "";
}
function liveTitleNoEpisode() {
  var title = "unknown title";
  if (document.getElementsByTagName("title")[0]) {
    title = document.getElementsByTagName("title")[0].innerHTML;
  } // some might not have it [iframes?]
  if (isGoogleIframe()) {
    title = window.parent.document.getElementsByTagName("title")[0].innerHTML; // always there :) "Avatar Extras - Movies &amp; TV on Google Play"
    var season_episode = window.parent.document.querySelectorAll('.title-season-episode-num')[0];
    if (season_episode) {
      title += season_episode.innerHTML.split(",")[0]; // like " Season 2, Episode 2 "
    }
    // don't add episode name
  }
  if (currentUrlNotIframe().includes("youtube.com")) {
    title = youtubeChannelName() + title; 
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

function addEditUi() {
  exposeEditScreenDiv = document.createElement('div');
  exposeEditScreenDiv.style.position = 'absolute';
  exposeEditScreenDiv.style.height = '30px';
  exposeEditScreenDiv.style.background = '#000000';
  exposeEditScreenDiv.style.zIndex = "99999999"; // on top :)
  exposeEditScreenDiv.style.backgroundColor = "rgba(0,0,0,0)"; // still see the video, but also see the text :)
  exposeEditScreenDiv.style.fontSize = "13px";
  exposeEditScreenDiv.style.color = "Grey";
  exposeEditScreenDiv.innerHTML = `<a href=# onclick="return addForNewEditToScreen();" id="add_edit_link_id">Add tag</a> 
	<select id='tag_edit_list_dropdown' onChange='tagEditListDropdownChanged();'></select><span id=add_edit_span_id_for_extra_message></span>`;
  // and stay visible
  document.body.appendChild(exposeEditScreenDiv);

  topLineEditDiv = document.createElement('div');
  topLineEditDiv.style.position = 'absolute';
  topLineEditDiv.style.height = '30px';
  topLineEditDiv.style.background = '#000000';
  topLineEditDiv.style.zIndex = "99999999"; // on top :)
  topLineEditDiv.style.backgroundColor = "rgba(0,0,0,0)"; // still see the video, but also see the text :)
  topLineEditDiv.style.color = "white";
  topLineEditDiv.style.textShadow="2px 1px 0px black";
  topLineEditDiv.style.fontSize = "13px";
  topLineEditDiv.style.display = 'none';
  document.body.appendChild(topLineEditDiv);
  
  tagLayer = document.createElement('div');
  tagLayer.style.position = 'absolute';
  tagLayer.style.width = '500px';
  tagLayer.style.height = '30px';
  tagLayer.style.background = '#000000';
  tagLayer.style.zIndex = "99999999"; // on top :)
  tagLayer.style.backgroundColor = "rgba(0,0,0,0)"; // still see the video, but also see the text :)
  tagLayer.style.color = "white";
  tagLayer.style.textShadow="2px 1px 0px black";
  tagLayer.style.fontSize = "13px";
  tagLayer.style.display = 'none';
  document.body.appendChild(tagLayer);
  
  // inject the "add tag" UI
  tagLayer.innerHTML = `
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
  <a href='#' onclick="seekToTime(video_element.currentTime -5); return false;">-5s</a>
  <a href="#" onclick="video_element.playbackRate -= 0.1; return false;">&lt;&lt;</a>
  <span id='playback_rate'>1.00x</span>
  <a href="#" onclick="video_element.playbackRate += 0.1; return false;">&gt;&gt;</a>
  <a href="#" onclick="stepFrame(); return false;">step</a>
  <a href="#" onclick="video_element.play(); return false;">&#9654;</and>
  <a href="#" onclick="video_element.pause(); return false;">&#9612;&#9612;</a>
  <a href="#" onclick="openEditMostRecentPassed(); return false;">open most recent</a>
  <a href="#" onclick="return addForNewEditToScreen();">Hide editor</a>
  `;
  
  // this only works for the few mentioned in externally_connectable in manifest.json TODO
  chrome.runtime.sendMessage(editorExtensionIds[0], {text: "YES", color: "#008000", details: "Edited playback is enabled and fully operational"});   
	chrome.runtime.sendMessage(editorExtensionIds[1], {text: "YES", color: "#008000", details: "Edited playback is enabled and fully operational"}); // green

  addEvent(window, "resize", function(event) {
    setEditedControlsToTopLeft();
  });
  addEvent(window, "scroll", function(event) {
    setEditedControlsToTopLeft();
  });
  setEditedControlsToTopLeft(); // and call immediately :)
  addMouseMoveListener(showEditLinkOnMouseMove);
}

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
    promptIfWantToCreate();
    return false; // abort link
  }
  // hope these never get mixed LOL
  if (exposeEditScreenDiv.innerHTML.includes("Add ")) {
    toggleDiv(topLineEditDiv);
    toggleDiv(tagLayer);
    document.getElementById("add_edit_link_id").innerHTML = "Hide editor";
  }
  else {
    toggleDiv(topLineEditDiv);
    toggleDiv(tagLayer);
    document.getElementById("add_edit_link_id").innerHTML = "Add tag";
  }
  return false; // always abort link
}

function setEditedControlsToTopLeft() {
  // discover where the "currently viewed" top left actually is (not always 0,0 apparently, it seems)
  var doc = document.documentElement;
  var left = (window.pageXOffset || doc.scrollLeft) - (doc.clientLeft || 0);
  var top = (window.pageYOffset || doc.scrollTop)  - (doc.clientTop || 0);
  top += 75; // couldn't see it when at the top youtube XXXX why? but just in case others are the same LOL
  offset = 150; // allow kill amazon x-ray :|
  left += offset;
  exposeEditScreenDiv.style.left = (left - offset) + "px"; // real zero for this one :|
  exposeEditScreenDiv.style.top = top + "px";
  topLineEditDiv.style.left = left + "px"; 
  topLineEditDiv.style.top = top + "px";
  tagLayer.style.left = left + "px";
  tagLayer.style.top = (top + 30) + "px";
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

var inTest = false;

function testCurrentFromUi() {
  if (currentTestAction() == 'do_nothing') {
    alert('testing a do nothing is hard, please set it to yes_audio_no_video, test it, then set it back to do_nothing, before hitting save button');
    return; // abort
  }
  inTest = true;
  var [start, endy] = addToCurrentEditArray();
  seekToTime(start - 2);
  length = endy - start;
  if (currentTestAction() == 'skip') 
    length = 0; // it skips it, so the amount of time before reverting is less it :)
  wait_time_millis = (length + 2 + 1)*1000; 
  setTimeout(function() {
    currentEditArray().pop();
    inTest = false;
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
  var url = "https://" + request_host + "/add_tag_from_plugin/" + url_id + '?start=' + document.getElementById('start').value + 
            "&endy=" + document.getElementById('endy').value + "&default_action=" + currentTestAction();
  console.log(url);
  window.open(url, '_blank');
  setTimeout(reloadForCurrentUrl, 2000);
  setTimeout(reloadForCurrentUrl, 20000); // and get details :)
}

function openEditMostRecentPassed() {
  var lastest = 0;
  var last_id = 0;
  var cur_time = video_element.currentTime;
  var tags = current_json.tags;
  for (var i = 0; i < tags.length; i++) {
    if (edits[i].endy < cur_time && tags[i].endy > lastest) {
      last_id = tags[i].id;
      lastest = tags[i].endy;
    }
  } 

  if (last_id > 0) {
    window.open("https://" + request_host + "/edit_tag/" + last_id);
  }
  else {
    alert("could not find one earlier than your currently playing back location");
  }
}

function stepFrame() {
  video_element.play();
  setTimeout(function() { 
    video_element.pause(); 
  }, 1/30*1000); // theoretically about an NTSC frame worth :)
}

function lookupUrl() {
  return '//' + request_host + '/for_current_just_settings_json?url=' + encodeURIComponent(getStandardizedCurrentUrl()) + '&episode_number=' + liveEpisodeNumber();
}

function loadForNewUrl() {
  getRequest(lookupUrl(), parseSuccessfulJsonWithAlert, loadFailed); // only works because we set CORS header :|
}

function reloadForCurrentUrl() {
  if (url_id != 0 && !inTest) {
    getRequest(lookupUrl(), parseSuccessfulJson, function() { console.log("huh wuh edits disappeared but used to be here?");  }); 
  }
}

function parseSuccessfulJsonWithAlert(json) {
  parseSuccessfulJson(json);
  // and alert
  if (getStandardizedCurrentUrl() != expected_current_url && getStandardizedCurrentUrl() != amazon_second_url) {
    alert("danger: this may have been the wrong url? this_page=" + currentUrlNotIframe() + "(" + getStandardizedCurrentUrl() + ") edits expected from=" + expected_current_url + " or " + amazon_second_url);
  }
  old_current_url = getStandardizedCurrentUrl();
  if (liveEpisodeNumber() != expected_episode_number) {
    alert("danger: may have gotten wrong episode expected=" + expected_episode_number + " got=" + liveEpisodeNumber());
  }
  old_episode = liveEpisodeNumber();
  startWatcherTimerOnce();
  var post_message = "This movie is currently marked as \"" + editing_status + "\" in our system, which means it is incomplete.  Please help us groom edits to our system and mark status as done when it's complete, thanks so much!";
  if (editing_status == "done")
    post_message = "\nYou may sit back and relax while you enjoy it now!";

  alert(decodeHTMLEntities("Editing playback successfully enabled for\n" + name + " " + episode_name + "\n" + liveFullNameEpisode() + "\nskips=" + skips.length + " mutes=" + mutes.length +"\nyes_audio_no_videos=" + yes_audio_no_videos.length + "\ndo_nothings=" + do_nothings.length + "\n" + post_message));
}

var current_json;

function removeOptions(selectbox)
{
    var i;
    for(i = selectbox.options.length - 1 ; i >= 0 ; i--)
    {
        selectbox.remove(i);
    }
}

function parseSuccessfulJson(json) {
  current_json = JSON.parse(json);
  url = current_json.url;
  name = url.name;
  editing_status = url.editing_status;
  episode_name = url.episode_name;
  expected_current_url = current_json.expected_url_unescaped;
  amazon_second_url = current_json.url;
  expected_episode_number = url.episode_number;
  url_id = url.id;
	mutes = []
	skips = []
	yes_audio_no_videos = []
	do_nothings = [] // :|
	for (var i = 0; i < current_json.tags.length; i++) {
		var tag = current_json.tags[i];
		var push_to_array;
		if (tag.default_action == 'mute') {
      push_to_array = mutes;
		} else if (tag.default_action == 'skip') {
      push_to_array = skips;
		} else if (tag.default_action == 'yes_audio_no_video') {
      push_to_array = yes_audio_no_videos;
		} else {
      push_to_array = do_nothings;
		}
		push_to_array.push([tag.start, tag.endy]);
	}
	
	var dropdown = document.getElementById("tag_edit_list_dropdown");
	removeOptions(dropdown); // out with the old...	
	for (var i = 0; i < current_json.tag_edit_lists.length; i++) {
		var option = document.createElement("option");
		option.text = current_json.tag_edit_lists[i][0].description;
		dropdown.add(option, dropdown[0]); // put it at the top?
	}
	var option = document.createElement("option");
	option.text = "all"; // the default LOL
  option.setAttribute('selected', true);
	dropdown.add(option, dropdown[0]);
}

function tagEditListDropdownChanged() {
	console.log("TODO");
}

// http://stackoverflow.com/questions/1442425/detect-xhr-error-is-really-due-to-browser-stop-or-click-to-new-page
function getRequest (url, success, error) {  
  console.log("starting attempt download " + url);
  var xhr = XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP"); 
  xhr.open("GET", url); 
  xhr.onreadystatechange = function(){ 
    if ( xhr.readyState == 4 ) { 
      if ( xhr.status == 200 ) { 
        success(xhr.responseText); 
      } else { 
        error && error(xhr.status); 
        error = null;
      } 
    } 
  }; 
  xhr.onerror = function () { 
    error && error(xhr.status); 
    error = null;
  }; 
  xhr.send(); 
}

function checkIfEpisodeChanged() {
  if (getStandardizedCurrentUrl() != old_current_url || liveEpisodeNumber() != old_episode) {
    console.log("detected move to another video, to " + liveFullNameEpisode() + "\nfrom\n" +
                 old_current_url + " ep. " + old_episode + "\nwill try to load its edited settings now for the new movie...");
    old_current_url = getStandardizedCurrentUrl(); // set them now so it doesn't re-get them next loop
    old_episode = liveEpisodeNumber(); 
    setTimeout(loadForNewUrl, 1000); // youtube gets the "old name" still for the new prompt :|
  }
}

function promptIfWantToCreate() {
  if (confirm(decodeHTMLEntities("We don't appear to have edits for\n" + liveFullNameEpisode() + "\n yet, would you like to create it in our system now?\n (cancel to watch unedited, OK to add to our edit database)."))) {
    window.open("https://" + request_host + "/new_url?url=" + encodeURIComponent(getStandardizedCurrentUrl()) + "&episode_number=" + liveEpisodeNumber() + "&episode_name=" + encodeURIComponent(liveEpisodeName()) + "&title=" + encodeURIComponent(liveTitleNoEpisode()) + "&duration=" + video_element.duration, "_blank"); // add_new
    setTimeout(loadForNewUrl, 2000); // it should auto save so we should be live within 2s I hope...if not they'll get the same prompt [?] :|
  }
}

function loadFailed(status) {
  mutes = skips = yes_audio_no_videos = []; // reset so it doesn't re-use last episode's edits for the current episode!
  // plus if they paste it in it gets here, so...basically load the no-op :|
  if (current_json != null) {
    current_json.tags = [];
  }
  editing_status = "unknown to system"; // just in case :)
  name = liveFullNameEpisode();
  episode_name = liveEpisodeString();
  expected_episode_number = liveEpisodeNumber();
  url_id = 0; // reset
  document.getElementById("add_edit_link_id").innerHTML = "Unedited..."; // she's dead jim XX confirm prompt on it to create?
  old_current_url = getStandardizedCurrentUrl();
  old_episode = liveEpisodeNumber(); 
  chrome.runtime.sendMessage(editorExtensionIds[0], {color: "#A00000", text: "none", details: "No edited settings found for movie, not playing edited"}); // red
  chrome.runtime.sendMessage(editorExtensionId[1], {color: "#A00000", text: "none", details: "No edited settings found for movie, not playing edited"}); // red
  if (status > 0) {
     promptIfWantToCreate(); 
  }
  else {
    alert("appears the cleanstream server is currently down, please alert us! Edits disabled for now...");
  }
  startWatcherTimerOnce(); // so it can check if episode changes to one we like magically LOL [mostly amazon]
}

var clean_stream_timer;

function startWatcherTimerOnce() {
  clean_stream_timer = clean_stream_timer || setInterval(checkStatus, 1000 / 100 ); // 100 fps since that's the granularity of our time entries :|
  // guess we just never turn it off on purpose :)
}

function start() {
  video_element = findFirstVideoTagOrNull();

  if (video_element == null) {
    // this one's pretty serious, just let it die...
    // maybe could get here if they raw load the javascript?
    alert("failure: unable to find a video playing, not loading edited playback...possibly need to reload then hit a play button before loading edited playback?");
    return;
  }

  if (isGoogleIframe()) {
    if (!window.parent.location.pathname.startsWith("/store/movies/details") && !window.parent.location.pathname.startsWith("/store/tv/show")) {
      // iframe started from a non "details" page with full url
      alert('failure: for google play movies, you need to right click on them and choosen "open in new tab" for it to work edited.');
      return; // avoid future prompts which don't matter anyway for now :|
    }
  }

  // ready to try and load the editor LOL
  addEditUi(); // only do once...
  loadForNewUrl();
}

var mouse_move_timeout;
function showEditLinkOnMouseMove() {
  document.getElementById("add_edit_link_id").style.visibility=""; // non hidden
  clearTimeout(mouse_move_timeout); // clear old
  mouse_move_timeout = setTimeout(function() { document.getElementById("add_edit_link_id").style.visibility="hidden"; }, 3000);
}

// helper method
function addMouseMoveListener(func) {
  // some "old IE" compat :|
  var addListener, removeListener;
  if (document.addEventListener) {
      addListener = function (el, evt, f) { return el.addEventListener(evt, f, false); };
      removeListener = function (el, evt, f) { return el.removeEventListener(evt, f, false); };
  } else {
      addListener = function (el, evt, f) { return el.attachEvent('on' + evt, f); };
      removeListener = function (el, evt, f) { return el.detachEvent('on' + evt, f); };
  }

  addListener(document, 'mousemove', func);
}

// helper method
function onReady(yourMethod) {
  if (document.readyState === 'complete') {
    setTimeout(yourMethod, 1); // schedule to run immediately
  }
  else {
    readyStateCheckInterval = setInterval(function() {
      if (document.readyState === 'complete') {
        clearInterval(readyStateCheckInterval);
        yourMethod();
     }
     }, 10);
  }
}

// no jquery since this page might already have it loaded, so avoid any conflict.  [plus speedup load times LOL]
// on ready just in case LOL
onReady(start);
