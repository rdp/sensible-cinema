// (c) 2016, 2017 Roger Pack released under LGPL

// var request_host="localhost:3000"; // dev
var request_host="playitmyway.org";  // prod

if (typeof clean_stream_timer !== 'undefined') {
  alert("play it my way: already loaded...not loading it again...please use the on screen links for it"); // hope we never get here :|
  throw "dont know how to load it twice"; // in case they click a plugin button twice, or load it twice (too hard to reload, doesn't work that way anymore)
}

var extra_message = "";
var inMiddleOfTestingTimer;
var current_json, url;
var mouse_move_timer;
var mutes, skips, yes_audio_no_videos, do_nothings, mute_audio_no_videos, make_video_smallers, change_speeds, set_audio_percents, pause_videos;
var seek_timer;
var all_pimw_stuff;
var currently_in_process_tags = new Map();

function addEditUi() {
  
  all_pimw_stuff = document.createElement('div');
  all_pimw_stuff.id = "all_pimw_stuff_id";
  all_pimw_stuff.style.color = "white";
  all_pimw_stuff.style.background = '#000000';
  all_pimw_stuff.style.backgroundColor = "rgba(0,0,0,0)"; // still see the video, but also see the text :)
  all_pimw_stuff.style.fontSize = "15px";
  all_pimw_stuff.style.textShadow="2px 1px 1px black";
  all_pimw_stuff.style.zIndex = "99999999";
  all_pimw_stuff.style.width = "400px";
  all_pimw_stuff.style.position = 'absolute';
  
  all_pimw_stuff.innerHTML = `
   <!-- our own styles, # is id -->
  <style>
    #all_pimw_stuff_id a:link { color: rgb(255,228,181); text-shadow: 0px 0px 5px black;}
    #all_pimw_stuff_id a:visited { color: rgb(255,228,181); text-shadow: 0px 0px 5px black;}
    #all_pimw_stuff_id { text-align: right;}  
  </style>
  
  <!-- no pre-load message here since...we don't start the watcher thread until after the first fail or success to give us the right coords, and possibly annoying... -->
    
  <div id=load_failed_div_id style='display: none; a:link {font-size: 10px;}'>
  <style>
    #load_failed_div_id a:link { font-size: 10px; }
  </style>
    <a href=# onclick="displayDiv(document.getElementById('click_to_add_to_system_div_id')); return false;">
      Unedited...
    </a>
    <div id=click_to_add_to_system_div_id style='display: none;'>
      <a href=# onclick="addForNewVideo(); return false;">Play it My Way: Click here to add to the system...</a> <!-- TODO disallow -->
    </div>
  </div>

  <div id=server_down_div_id style='display: none;' style='font-size: 14px;'>
    Play it my way Server down, please alert us and try again later...
  </div>
  
  <div id="load_succeeded_div_id" style='display: none;'>
    <div id="currently_playing_it_your_way_id" style="color: rgb(188, 188, 188);">
      <svg style="font: 50px 'Arial'; height: 50px;" viewBox="0 0 350 50">
        <text style="fill: none; stroke: white; stroke-width: 0.5px; stroke-linejoin: round;" y="40" x="175" id="big_edited_text_id">Edited</text>
      </svg>
       <br/>
      Currently Editing out: <select id='tag_edit_list_dropdown' onChange='editListChanged();'></select> <!-- javascript will set up this select --> 
      <br/>
      <a href=# onclick="openPersonalizedEditList(); return false">Personalize which parts you edit out</a>
      <br/>
      We're still in Beta, did we miss anything? <a href=# onclick="reportProblem(); return false;">Let us know!</a>
      <div style="display: inline-block"> <!-- prevent line feed before this div -->
        <div id="editor_top_line_div_id" style="display: none;"> <!-- we enable if flagged as editor -->
           <a href=# onclick="toggleAddNewTagStuff(); return false;">[add tag]</a>
        </div>
      </div>
    </div>
    <div id="tag_details_div_id"  style='display: none;'>
      <div id='tag_layer_top_section'>
        <span id="tag_details_top_line"> <!-- currently: muting, 0m32s --></span>
        <span id="tag_details_second_line" /> <!-- next will be at x for y -->
      </div>
      <form target="_blank" action="filled_in_later_if_you_see_this_it_may_mean_an_onclick_method_threw" method="POST" id="create_new_tag_form_id">
        from:<input type="text" name='start' style='width: 150px; height: 20px; font-size: 12pt;' id='start' value='0m 0.00s'/>
        <input id='' type='button' value='<--set to current time' onclick="document.getElementById('start').value = getCurrentVideoTimestampHuman();" />
        <br/>
        &nbsp;&nbsp;&nbsp;&nbsp;to:<input type='text' name='endy' style='width: 150px; font-size: 12pt; height: 20px;' id='endy' value='0m 0.00s'/>
        <input id='' type='button' value='<--set to current time' onclick="document.getElementById('endy').value = getCurrentVideoTimestampHuman();" />
        <br/>
        
        
      <!-- no method for seek forward since it'll at worst seek too far forward --> 
      <input type='button' onclick="seekToBeforeSkip(-30); return false;" value='-30s'/>
      <input type='button' onclick="seekToTime(getCurrentTime() - 2); return false;" value='-2s'/> 
      <input type='button' onclick="seekToBeforeSkip(-5); return false;" value='-5s'/>
      <input type='button' onclick="seekToTime(getCurrentTime() + 5); return false;" value='+5s'/> 
      <input type='button' onclick="stepFrameBack(); return false;" value='frame-'/>
      <input type='button' onclick="stepFrame(); return false;" value='frame+'/>

      <br/>
      <input type='button' onclick="playButtonClicked(); setPlaybackRate(0.5); return false;" value='0.5x'>
      <input type='button' onclick="decreasePlaybackRate();; return false;" value='&lt;&lt;'/>
      <span ><a id='playback_rate' href=# onclick="setPlaybackRate(1.0); return false">1.00x</a></span> <!--XX remove link -->
      <input type='button' onclick="increasePlaybackRate(); return false;" value='&gt;&gt;'/>
      <input type='button' onclick="doPause(); return false;" value='&#9612;&#9612;'/>
      <input type='button' onclick="playButtonClicked(); return false;" value='&#9654;'>
      
      
       <br/>
        <input type='submit' value='Test edit locally' onclick="testCurrentFromUi(); return false">
        <br/>
       action:
        <%= pre_details = "tag details"; pre_popup = "popup text"; io2 = IO::Memory.new; ECR.embed "../kemal_server/views/_tag_shared.ecr", io2; io2.to_s %> <!-- render full filename cuz macro -->
        <input type='submit' value='Save This Tag' onclick="saveEditButton(); return false;">
        <br/>
        <input type='submit' value='Re-Edit Prev Tag' id='open_prev_tag_id' onclick="openPreviousTagButton(); return false;">
        <input type='submit' value='Re-Edit Next Tag (or current)' id='open_next_tag_id' onclick="openNextTagButton(); return false;">
      </form>
      
      <a id=reload_tags_a_id href=# onclick="reloadForCurrentUrl(); return false;" </a>Reload tags</a>
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <a href=# onclick="getSubtitleLink(); return false;" </a>Get movie subtitles</a>
        <input type='submit' value='Done with movie' onclick="doneMoviePage(); return false;">
      <br/>
      <input type='button' onclick="collapseAddTagStuff(); return false;" value='✕ Hide editor'/>
    </div>
  </div>`;
  document.body.appendChild(all_pimw_stuff);
  
  addMouseAnythingListener(mouseJustMoved);
  mouseJustMoved({pageX: 0, pageY: 0}); // start its timer, prime it :|
  tagsCreated(); // from shared javascript, means "the HTML elements are in there"
  if (isYoutubePimw()) {
    // assume it can never change to a different type of movie...I doubt it :|
    $("#action_sel option[value='yes_audio_no_video']").remove();
    $("#action_sel option[value='mute']").remove();
    $("#action_sel option[value='mute_audio_no_video']").remove();
  }
}

function playButtonClicked() {
  if (isPaused()) {
    doPlay();
  } else if (getPlaybackRate() != 1) {
    setPlaybackRate(1.0); // back to normal if they hit the play button while going slow :)
  }
}

function getStandardizedCurrentUrl() { // duplicated with other .js
  var current_url = currentUrlNotIframe();
  if (document.querySelector('link[rel="canonical"]') != null && !isYoutube()) {
    // -> canonical, the crystal code does this for everything so guess we should do here as well...ex youtube it strips off any &t=2 or something...
    current_url = document.querySelector('link[rel="canonical"]').href; // seems to always convert from "/gp/" to "/dp/" and sometimes even change the ID :|
  }
  // attempt to leave the rest in cyrstal
  return current_url;
}

function openPersonalizedEditList() {
  window.open("https://" + request_host + "/personalized_edit_list/" + current_json.url.id);
  doPause();
}

function reportProblem() {
  window.open("http://freeldssheetmusic.org/questions/ask?pre_fill=" + encodeURIComponent("url=" + getStandardizedCurrentUrl() + " time=" + timeStampToHuman(getCurrentTime())));
}

function liveEpisodeName() {
  if (isAmazon() && document.getElementsByClassName("subtitle").length > 0) {
    split = document.getElementsByClassName("subtitle")[0].innerHTML.split(/Ep. \d+/); // like "Season 3, Ep. 3 The Painted Lady"
    var just_name;
    if(split.length == 2) {
      just_name = split[1]; // has Ep. x in it
    } else {
      just_name = split[0];
    }
    return just_name.replace(/<!--([\s\S]*?)-->/mig, '').trim(); // remove weird <-- react --> comments
  }
  else {
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
  }
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
      var out = /Ep. (\d+)/.exec(subtitle.innerHTML)[1];
      return out;
    }
    else {
      return "0";
    }
  }
  else {
    return "0"; // anything else...
  }
}

function areWeWithin(thisTagArray, cur_time) {
  for (var i = 0; i < thisTagArray.length; i++) {
    var tag = thisTagArray[i];
    var start_time = tag.start;
    var end_time = tag.endy;
    if(cur_time > start_time && cur_time < end_time && !withinDelta(cur_time, end_time, 0.0001)) { // avoid seeking at 4123.819999 will_end:4123.82 in 9.99999429041054e-7s
      return tag;
    }
  }
  return false;
}

var i_muted_it = false; // attempt to let them still control their mute button :|
var i_changed_its_speed = false; // attempt to let them still control speed manually if desired
var i_changed_audio_percent = false;
var i_hid_it = false; // allow our own hiding to be persevered while seeking out of a skip :\

var last_speed_value = null;
var last_audio_percent = null;
var last_timestamp = 0;
var i_unfullscreened_it_element = null;
var i_paused_it = null;


function checkIfShouldDoActionAndUpdateUI() {
  var cur_time = getCurrentTime();
  var tag;
  if (cur_time < last_timestamp) {
    console.log("Something (possibly pimw) just sought backwards to=" + cur_time + " from=" + last_timestamp);
    tag = areWeWithin(skips, cur_time); 
    if (tag) {
      // was the seek to within an edit? Since this was a "rewind" let's actually go to *before* the bad spot, so the traditional +-10 buttons can work from UI
      console.log("they just seeked backward to within a skip, rewinding more..."); // tag already gets logged in seekToBeforeSkip
      seekToBeforeSkip(0);
      blankScreenIfWithinHeartOfSkip(tag, cur_time);
      return; // don't keep going which would do a skip forward...
    }
  }
  last_timestamp = cur_time;
  
  tag = areWeWithin(mutes, cur_time);
  tag = tag || areWeWithin(mute_audio_no_videos, cur_time);
  extra_message = "";
  if (tag) {
    if (!isMuted()) {
      setMute(true);
      i_muted_it = true;
      timestamp_log("muting", cur_time, tag);
    }
   extra_message += "muting";
   notify_if_new(tag);
  }
  else {
    if (isMuted()) {
      if (i_muted_it) {
        setMute(false);
        console.log("unmuted at=" + cur_time);
        i_muted_it = false;      
      }
    }
  }
  
  tag = areWeWithin(skips, cur_time);
  if (tag) {
    timestamp_log("seeking forward", cur_time, tag);
    optionally_show_notification(tag); // show it now so it can notify while it seeks :) [NB for longer seeks it shows it over and over but notification tag has our back :\ ]
    seekToTime(tag.endy); // just seek (works fine in amazon, and seems to even work ok these days in youtube...
    blankScreenIfWithinHeartOfSkip(tag, cur_time);
  }
  
  tag = areWeWithin(yes_audio_no_videos, cur_time);
  tag = tag || areWeWithin(mute_audio_no_videos, cur_time);

  if (tag) {
    // use style.visibility here so it retains the space on screen it would have otherwise used...
    if (video_element.style.visibility != "hidden") {
      timestamp_log("hiding video leaving audio ", cur_time, tag);
      video_element.style.visibility = "hidden";
      i_hid_it = true;
    }
    extra_message += "doing a no video yes audio";
    notify_if_new(tag);
  }
  else {
    if (video_element.style.visibility != "" && i_hid_it) {
      video_element.style.visibility=""; // non hidden :)
      console.log("unhiding video with cur_time=" + cur_time);
      i_hid_it = false;
    }
  }
  
  tag = areWeWithin(make_video_smallers, cur_time);
  if (tag) {
    // assume youtube :|
    var iframe = youtube_pimw_player.getIframe();
    if (iframe.width == "100%") {
      timestamp_log("making small", cur_time, tag);
      youtube_pimw_player.setSize(200, 200); // smallest youtube's terms of use permits :)
      var fullscreenElement = document.fullscreenElement || document.mozFullScreenElement || document.webkitFullscreenElement;
      if (fullscreenElement) {
        exitFullScreen(); // :| XXXX
      }
    }
    extra_message += "making small";
  } else {
    if (isYoutubePimw()) {
      var iframe = youtube_pimw_player.getIframe();
      if (iframe.height == "200") {
        console.log("back to normal size cur_time=" + cur_time);
        iframe.height = "70%"; // XXXX save away instead
        iframe.width = "100%";
        // can't refullscreen it "programmatically" at least in chrome, so punt!
      }
    }
  }
  
  tag = areWeWithin(change_speeds, cur_time);
  if (tag) {
    var desired_speed = getEndSpeedOrAlert(tag.details);
    if (desired_speed) {
      if (getPlaybackRate() != desired_speed) {
        timestamp_log("setting speed=" + desired_speed, cur_time, tag);      
        last_speed_value = getPlaybackRate();
        setPlaybackRate(desired_speed);
        i_changed_its_speed = true;
      }
      extra_message += "speed=" + desired_speed + "x";
    }
  } else {
    if (i_changed_its_speed && getPlaybackRate() != last_speed_value) {
      i_changed_its_speed = false;
      console.log("back to speed=" + last_speed_value + " cur_time=" + cur_time);
      setPlaybackRate(last_speed_value);
    }
  }
  
  tag = areWeWithin(set_audio_percents, cur_time);
  if (tag) {
    var desired_percent = getAudioPercentOrAlert(tag.details);
    if (desired_percent) {
      var relative_desired_percent;
      if (i_changed_audio_percent) {
        relative_desired_percent = last_audio_percent * desired_percent / 100;
      } else {
        relative_desired_percent = getAudioVolumePercent() * desired_percent / 100;
      }
      if (!withinDelta(getAudioVolumePercent(), relative_desired_percent, 1)) { // we never changed it, or they did after it was decreased :\
        timestamp_log("setting audio=" + desired_percent, cur_time, tag);
        last_audio_percent = getAudioVolumePercent();
        setAudioVolumePercent(relative_desired_percent);
        i_changed_audio_percent = true;
      }
      extra_message += "audio percent=" + desired_percent + "%";
    }
  } else {
    if (i_changed_audio_percent && getAudioVolumePercent() != last_audio_percent) {
      i_changed_audio_percent = false;
      console.log("back to audio_percent=" + last_audio_percent + " cur_time=" + cur_time);
      setAudioVolumePercent(last_audio_percent);
    }
  }
  
  tag = areWeWithin(pause_videos, cur_time);
  if (tag) {
    var pause_tag = tag; // save it :\
    // "should" be right at beginning hrm...todo seek back to beginning if they seek to within it, first? hrm...
    if (!i_paused_it) {
      i_paused_it = true;
      if (!isPaused()) {
        doPause();
      } // else ??
      setTimeout(function() {
        seekToTime(pause_tag.endy);
      }, (pause_tag.endy - pause_tag.start)*1000);
    }
    extra_message += "pausing";
  } else {
    if (i_paused_it) {
      i_paused_it = false;
      if (isPaused()) {
        doPlay();
      } // else how? but it's already playing anyway... :\
    }
  }
  
  var top_line = "";
  if (extra_message != "") {
    top_line = "Currently:" + extra_message; // prefix
  } else {
    top_line = ""; //NB can't use <br/> since trailing slash gets sanitized out so can't detect changes right FWIW :|
  }
  updateHTML(document.getElementById("tag_details_top_line"), top_line + " " + timeStampToHuman(cur_time) + "<br>");
  
  var second_line = "";
  var next_future_tag = getNextTagAfterOrWithin(getCurrentTime());
  if (next_future_tag) {
    second_line += "next: " + timeStampToHuman(next_future_tag.start) + 
           " (" + next_future_tag.default_action + " for " + twoDecimals((next_future_tag.endy - next_future_tag.start)) + "s)";
    if (!next_future_tag.default_enabled) {
      second_line += "(disabled)";
    }
    document.getElementById("open_next_tag_id").style.visibility = "visible";
  }
  else {
    document.getElementById("open_next_tag_id").style.visibility = "hidden";
    second_line = "<br>";
  }
  updateHTML(document.getElementById('tag_details_second_line'), second_line);
  
  updateHTML(document.getElementById("playback_rate"), twoDecimals(getPlaybackRate()) + "x");
  // XXXX cleanup the below wasn't working enough huh?
  removeIfNotifyEditsHaveEnded(cur_time); // gotta clean this up sometime, and also support "rewind and renotify" so just notify once on init...
}

function blankScreenIfWithinHeartOfSkip(skip_tag, cur_time) {
    // if it's trying to seek out of something baaad then don't show a still frame of the bad stuff right in its middle!
    if (!withinDelta(skip_tag.start, cur_time, 0.05)) { // don't show black blip on normal seek from playing continuous...
      if (video_element.style.visibility != "hidden") {
        console.log("blanking it because within skip");
        video_element.style.visibility = "hidden"; // it'll unhide it for us soon...
      } else {
        console.log("already hidden so not blanking it even though we're in the heart of a skip");
      }
    } else {
      console.log("not blanking it because it's normal playing continuous beginning of skip..." + skip_tag.start);
    }
}

function removeIfNotifyEditsHaveEnded(cur_time) {
  for (var tag of currently_in_process_tags.keys()) {
    if (!areWeWithin([tag], cur_time)) {
      currently_in_process_tags.delete(tag);
    }
  }
}

function notify_if_new(tag) {
  if (currently_in_process_tags.get(tag)) {
    // already in there, do nothing
  } else {
    currently_in_process_tags.set(tag, true);
    optionally_show_notification(tag);
  }
}

function exitFullScreen() { // called in other .js too
  if (document.exitFullscreen) {
      document.exitFullscreen(); // Standard
  } else if (document.webkitExitFullscreen) {
      document.webkitExitFullscreen(); // Blink
  } else if (document.mozCancelFullScreen) {
      document.mozCancelFullScreen(); // Gecko
  } else if (document.msExitFullscreen) {
      document.msExitFullscreen(); // Old IE
  }
}

function optionally_show_notification(seek_tag) {
  var popup = seek_tag.popup_text_after;
  if (popup.length > 0) {
    console.log("notifying " + popup);
    if (window.navigator.userAgent.indexOf("Windows")!= -1) {
      exitFullScreen(); // not sure what else to do here so they can see it TODO test etc :|
    }
    var maxTitleSize = 40; // max 45 for title OS X (49 for body), 40 for being able to add ellipsis
    if (window.navigator.userAgent.indexOf("Windows NT") != -1) {
      maxTitleSize = 25; // seems smaller, chrome windows
    }
    // search backward for first space to split on...
    for (var i = maxTitleSize; i > 0; i--) {
      var char = popup.charAt(i);
      if (char == " " || char == "") { // "" means "past end" for shorter ones...
        var title = popup.substring(0, i);
        var body = popup.substring(i); 
        // XXXX if body too large still split to second notification? have to wait for previous to close?
        break;
      }
    }          
    if (popup.length > maxTitleSize) {
      title += " ...";
      // body = "... " + body;
    }
    sendNotification({title: htmlDecode(title), body: htmlDecode(body), tag: seek_tag});
  }
}

function sendNotification(notification_desired) {
  if (isYoutubePimw()) {
      // can't rely on background.js existing at all :|
      // so just send it here...

      if (!("Notification" in window)) {
        console.log("This browser does not support desktop notification");
        return; // oh well, punt!
      }
      else if (Notification.permission === "granted") { // already been granted before...
        createNotification(notification_desired);
      }
      // Otherwise, we need to ask the user for permission
      else if (Notification.permission !== "denied") {
        Notification.requestPermission(function (permission) {
          // If the user accepts, let's create a notification
          if (permission === "granted") {
            createNotification(notification_desired);
          }
        });
      }
      else {
        // denied previously :| I guess don't alert they denied it right? :) but they're using it? oh well...
      }
  } else {
    sendMessageToPlugin({notification_desired : notification_desired});
  }
}

function createNotification(notification_desired) { // shared with background.js
  var notification = new Notification(notification_desired.title, {body: notification_desired.body}); // auto shows it
  notification.onclose = function() { console.log("closed?!?");}; // doesn't work "well" OS X (only when they really choose close, not auto disappear :| ) requireInteraction doesn't help either?? TODO report to chrome, when fixed update my SO answer :)
  notification.onclick = function(event) {
    event.preventDefault(); // prevent the browser from focusing the Notification's tab
    window.open('https://playitmyway.org/view_tag/' + notification_desired.tag.id, '_blank'); // also opens and sets active
  }
}

function updateHTML(div, new_value) {
  if (div.innerHTML != new_value) {
    div.innerHTML = new_value;
  }
}

var last_log = "";
function logOnce(to_log) {
  if (last_log != to_log) {
    console.log(to_log);
    last_log = to_log;
  } // else don't log :|
}

function isWatchingAdd() {
  if (url != null) {
    // guess this > 0 check is for ancient ones I used to add manually [?] youtubes [?]
    // TODO remove them... :|
    // withinDelta 10 is for amazon at the end, weird stuff LOL
    if (current_json.url.total_time > 0 && !withinDelta(current_json.url.total_time, videoDuration(), 10.5)) { // amazon can be 10.01 or something if you go to the end
      logOnce("watching add? Or possibly hit X after starting movie amazon expected=" + current_json.url.total_time + " got_duration=" + videoDuration()); // we get NaN for video_element.duration after hit video x in amazon :| [?]
      return true;
      // and do nothing
    }
    else {
      return false;
    }
  } else {
    return false; // ??
  }
  
}

var i_set_it_to_add = false;

function checkStatus() { // called 100 fps
  // avoid unmuting videos playing that we don't even control [like youtube main page] with this if...
  if (url != null) {
    if (isWatchingAdd()) {
      if (!i_set_it_to_add) {
        i_set_it_to_add = true;
        var dark_yellow = "#CCCC00";
        sendMessageToPlugin({text: "add?", color: dark_yellow, details: "Watching add? edits disabled"}); 
      }
      // and enforce no mutes etc...since it's an add
      // still fall through in case amazon reloaded :\ 
    }
    else {
      if (i_set_it_to_add) {
        setSmiley();
        i_set_it_to_add = false;
      }
      // GO!
      checkIfShouldDoActionAndUpdateUI();      
      addPluginEnabledText();
    }
  }

  checkIfEpisodeChanged();
  video_element = findFirstVideoTagOrNull() || video_element; // refresh it in case changed, but don't switch to null between clips, I don't think our code handles nulls very well...
  setEditedControlsToMovieRight(); // in case something changed [i.e. amazon moved their video element into "on screen" :| ]
}

function timestamp_log(message, cur_time, tag) {
  local_message = message + " at " + twoDecimals(cur_time) + " start:" + tag.start + " will_end:" + tag.endy + " in " + twoDecimals(tag.endy - cur_time) + "s";;
  console.log(local_message);
}

function seekToBeforeSkip(delta) {
  var cur_time = getCurrentTime();
  var desired_time = cur_time + delta;
  var tag = areWeWithin(skips, desired_time);  
  if (tag) {
    var new_delta = tag.start - cur_time - 5; // youtube with 2 would fail here seeking backward and loop forever :\ 
    console.log("would have sought to middle of " + JSON.stringify(tag) + " going back further instead new_delta=" + new_delta + " cur_time=" + cur_time);
    seekToBeforeSkip(new_delta); // in case we run into another'un right there ... :|
  }
  else {
    seekToTime(desired_time);
  }
}

function compareTagStarts(tag1, tag2) {
  if (tag1.start < tag2.start) {
    return -1;
  }
  if (tag1.start > tag2.start) {
    return 1;
  }
  return 0;
}

function getNextTagAfterOrWithin(cur_time) {
  var all = current_json.tags; // already sorted :|
  for (var i = 0; i < all.length; i++) {
    var tag = all[i];
    var start_time = tag.start;
    var end_time = tag.endy;
    if(end_time > cur_time) {
      return tag;
    }
  }
  return null;
}

function videoDuration() {
  if (isYoutubePimw()) {
    return youtube_pimw_player.getDuration();
  } else {
    return video_element.duration; // and hope they're not near the end :|
  }
}


function isPaused() {
  if (isYoutubePimw()) {
    var paused = 2;
    return youtube_pimw_player.getPlayerState() == paused;
  } else {
    return video_element.paused;
  }
}

function doPlay() {
  console.log("doing doPlay() paused=" + video_element.paused);
  if (isYoutubePimw()) {
    youtube_pimw_player.playVideo();
  } else {
    video_element.play();
  }
}

function getPlaybackRate() {
  if (isYoutubePimw()) {
    return youtube_pimw_player.getPlaybackRate();
  } else {
    return video_element.playbackRate;
  }
}

function getAudioVolumePercent() {
  if (isYoutubePimw()) {
    return youtube_pimw_player.getVolume();
  } else {
    return video_element.volume * 100;
  }
}

function setAudioVolumePercent(toThisMaxOneHundred) {
  console.log("setting audio_volume_percent=" + toThisMaxOneHundred);
  if (isYoutubePimw()) {
    return youtube_pimw_player.setVolume(toThisMaxOneHundred);
  } else {
    return video_element.volume = toThisMaxOneHundred / 100;
  }
}

function relativeRateIndex(diff) { // youtube only
  var options = youtube_pimw_player.getAvailablePlaybackRates();
  return options[options.indexOf(getPlaybackRate()) + diff];
}

function decreasePlaybackRate() {
  if (isYoutubePimw()) {
    setPlaybackRate(relativeRateIndex(-1));
  } else {
    setPlaybackRate(video_element.playbackRate - 0.1);
  }
}

function increasePlaybackRate() {
  if (isYoutubePimw()) {
    setPlaybackRate(relativeRateIndex(+1));
  } else {
    setPlaybackRate(video_element.playbackRate + 0.1);
  }
}

function setPlaybackRate(toExactlyThis) {
  console.log("setting playbackrate=" + toExactlyThis);
  if (isYoutubePimw()) {
    youtube_pimw_player.setPlaybackRate(toExactlyThis);
  } else {
    video_element.playbackRate = toExactlyThis;
  }
}

function isMuted() {
  if (isYoutubePimw()) {
    return youtube_pimw_player.isMuted();
  } else {
    return video_element.muted;
  }
}

function setMute(yesMute) {
  if (isYoutubePimw()) {
    if (yesMute) {
      youtube_pimw_player.mute();
    } else {
      youtube_pimw_player.unMute();
    }
  } else {
    video_element.muted = yesMute;
  }
}

function addForNewVideo() {
  if (getStandardizedCurrentUrl().includes("youtube.com/user/")) {
    alert("this is a youtube user page, we don't support those yet, click through to a particular video first");
    // XXXX more generic here somehow possible???
    // TODO don't even offer to edit it for them on that page [?] and other pages where it's impossible today [facebook]?
    return;
  }
  if (isAmazon()) {
    if (withinDelta(getCurrentTime(), videoDuration(), 30)) { // unfortunately not accurate enough, it gets the "inflated" time if has ever once gone past end :|
      // paranoia, even accurate [?]
      alert("we can't tell the right duration if it's too near the end in amazon, seek to beginning and try again");
      return;
    }
  }
  window.open("https://" + request_host + "/new_url_from_plugin?url=" + encodeURIComponent(getStandardizedCurrentUrl()) + "&episode_number=" + liveEpisodeNumber() + "&episode_name="  +
          encodeURIComponent(liveEpisodeName()) + "&title=" + encodeURIComponent(liveTitleNoEpisode()) + "&duration=" + videoDuration(), "_blank");
  setTimeout(loadForNewUrl, 4000); // it should auto save so we should be live within 2s I hope...if not they'll get the same prompt [?] :|         
  // once took longer than 2000 :|
  doPause();
}

function toggleAddNewTagStuff() {
  toggleDiv(document.getElementById("tag_details_div_id"));
}

function collapseAddTagStuff() {
  hideDiv(document.getElementById("tag_details_div_id"));
}

function isAddtagStuffVisible() {
  return document.getElementById("tag_details_div_id").style.display != "none";
}

function setEditedControlsToMovieRight() {
  var width = parseInt(all_pimw_stuff.style.width, 10);
  var desired_left = getLocationOfElement(video_element).right - width - 10; // avoid amazon x-ray so go to right
  var desired_top = getLocationOfElement(video_element).top;
  if (isAmazon()) {
    desired_top += 225; // top amazon stuff, plus ability to select subs
  }
    
  all_pimw_stuff.style.left = desired_left + "px";
  all_pimw_stuff.style.top = desired_top + "px";
  
  var pimw_bottom = getLocationOfElement(all_pimw_stuff).bottom;
  if (pimw_bottom > getLocationOfElement(video_element).bottom) {
    // video is too small to fit it all, so just punt on the top spacing :|
    desired_top = getLocationOfElement(video_element).top;
    all_pimw_stuff.style.top = desired_top + "px";
  }
}

function currentTestAction() {
  return document.getElementById('action_sel').value;
}

// early callable timeout's ... :)
var timeouts = {};  // hold the data
function makeTimeout (func, interval) {
    var run = function(){
        timeouts[id] = undefined;
        func();
    }

    var id = window.setTimeout(run, interval);
    timeouts[id] = func

    return id;
}
function removeTimeout (id) {
    window.clearTimeout(id);
    timeouts[id]=undefined; // is this enough tho??
}

function doTimeoutEarly (id) {
  func = timeouts[id];
  removeTimeout(id);
  func();
}

function testCurrentFromUi() {
  if (inMiddleOfTestingTimer) {
    doTimeoutEarly(inMiddleOfTestingTimer); // nulls it out for us
  }
  if (humanToTimeStamp(document.getElementById('endy').value) == 0) {
    document.getElementById('endy').value = getCurrentVideoTimestampHuman(); // assume they wanted to test till "right now" I did this a couple of times :)
  }
  var faux_tag = {
    start: humanToTimeStamp(document.getElementById('start').value),
    endy: humanToTimeStamp(document.getElementById('endy').value),
    default_action: currentTestAction(),
    is_test_tag: true,
    popup_text_after: document.getElementById('popup_text_after_id').value,
    default_enabled: true,
    details: document.getElementById('details_input_id').value
  }
  if (faux_tag.start == 0) {
    alert("appears your start time is zero, which is not allowed, if you want one that starts near the beginning enter 0.1s");
    return;
  }
  if (faux_tag.endy <= faux_tag.start) {
    alert("appears your end is before or equal to your start, please adjust timestamps, then try again!");
    return; // abort!
  }
  if ((currentTestAction() == "make_video_smaller") && !isYoutubePimw()) {
    alert("we only do that for youtube today, ping us if you want it added elsewhere");
    return;
  }
  if (currentTestAction() == "change_speed" && !getEndSpeedOrAlert(faux_tag.details)) {
    return;
  }
  var temp_array = currentEditArray();
  temp_array.push(faux_tag);
  
  var rewindSeconds = 2;
  var start = faux_tag.start - rewindSeconds;
  if (start < 0) {
    start = 0; // allow test edits to start at or near 0 without messing up the "done" timing...
  }
  seekToTime(start, function() {
    var length = faux_tag.endy - start;
    if (currentTestAction() == 'skip') {
      length = 0; // it skips it, so the amount of time before being done is less :)
    }
    if (currentTestAction() == "change_speed") {
      length /= getEndSpeedOrAlert(faux_tag.details); // XXXX this is wrong somehow (too long?).
    }
    
    wait_time_millis = (length + rewindSeconds + 0.5) * 1000;
    if (isPaused()) {
      doPlay(); // seems like we want it like this...
    }
    inMiddleOfTestingTimer = makeTimeout(function() { // we call this early to cancel if they hit it a second time...
      console.log("popping " + JSON.stringify(faux_tag));
      temp_array.pop();
      removeTimeout(inMiddleOfTestingTimer);
      inMiddleOfTestingTimer = null;
    }, wait_time_millis);
  });
}

function currentEditArray() {
  switch (currentTestAction()) {
    case 'mute':
      return mutes;
    case 'skip':
      return skips;
    case 'yes_audio_no_video':
      return yes_audio_no_videos;
    case 'mute_audio_no_video':
      return mute_audio_no_videos;
    case 'make_video_smaller':
      return make_video_smallers;
    case 'change_speed':
      return change_speeds;
    case 'set_audio_volume':
      return set_audio_percents;
    case 'pause_video':
      return pause_videos;
    default:
      alert('internal error 1...' + currentTestAction()); // hopefully never get here...
  }
}

function getCurrentVideoTimestampHuman() {
  return timeStampToHuman(getCurrentTime());
}

function openPreviousTagButton() {
  var timeSearch = getCurrentTime();
  while (timeSearch > 0) {
    var next_tag = getNextTagAfterOrWithin(timeSearch);
    if (next_tag && (next_tag.endy < getCurrentTime())) {
      window.open("https://" + request_host + "/edit_tag/" + next_tag.id);
      return;
    }
    else {
      timeSearch -= 1; // OK OK this is lame I know...
    }
  }
  alert("none found before current playback position");
}

function openNextTagButton() {
  var next_tag = getNextTagAfterOrWithin(getCurrentTime());
  if (next_tag) {
    window.open("https://" + request_host + "/edit_tag/" + next_tag.id);
  }
  else {
    alert("didn't find a tag the current times seem to match??"); // this should be impossible...
  }
}

function saveEditButton() {
  if (!doubleCheckValues()) {
    return;
  }
  var endy = humanToTimeStamp(document.getElementById('endy').value);
  
  if (endy > videoDuration()) {
    alert("tag goes past end of movie? aborting...");
    return;
  }

  document.getElementById('create_new_tag_form_id').action = "https://" + request_host + "/save_tag/" + url.id;
  document.getElementById('create_new_tag_form_id').submit();

  // reset so people don't think they can tweak and resave...
  document.getElementById('start').value = timeStampToHuman(0);
  document.getElementById('endy').value = timeStampToHuman(0);
  document.getElementById('details_input_id').value = "";
  document.getElementById('popup_text_after_id').value = "";
  // don't reset category since I'm not sure if the javascript handles its going back to ""
  document.getElementById('subcategory_select_id').selectedIndex = 0; // use a present value so size doesn't go to *0*
  showSubCatWithRightOptionsAvailable(); // resize it back to none, not sure how to auto-trigger this
  document.getElementById('age_maybe_ok_id').value = "0";
  document.getElementById('impact_to_movie_id').value = "0";
  setImpactIfMute(); // reset if mute :|
  document.getElementById('tag_hidden_id').value = '0'; // reset
  document.getElementById('default_enabled_id').value = 'true';
  
  setTimeout(reloadForCurrentUrl, 1000); // reload to get it "back" from the server after saved...
  setTimeout(reloadForCurrentUrl, 5000); // reload to get it "back" from the server after saved...
}

function doneMoviePage() {
  window.open("https://" + request_host + "/edit_url/" + current_json.url.id + "?status=done");
}

function getSubtitleLink() {
  if (isYoutube()) {
    window.open("http://www.yousubtitles.com/load/?url=" + currentUrlNotIframe()); // go git 'em
    return;
  }
  if (!isAmazon()) {
    alert("subtitles not supported except on amazon/youtube today");
    return;
  }
  var arr = window.performance.getEntriesByType("resource");
  for (var i = arr.length - 1; i >= 0; --i) {
    console.log("name=" + arr[i].name);
    if (arr[i].name.endsWith(".dfxp")) { // ex: https://dmqdd6hw24ucf.cloudfront.net/341f/e367/03b5/4dce-9c0e-511e3b71d331/15e8386e-0cb0-477f-b2e4-b21dfa06f1f7.dfxp apparently
      var response = prompt("this appears to be a subtitles url, copy this:", arr[i].name); // has a cancel prompt, but we don't care which button they use
      return;
    }
  }
  alert("didn't find a subtitles file, try turning subtitles on, then reload your browser, then try again");
}

function stepFrameBack() {
  seekToTime(getCurrentTime() - 1/10, function () { // go back 2 frames, 1 seems hard...
    doPause();
  });
}

function stepFrame() {
  doPlay();
  setTimeout(function() {
    doPause(); 
  }, 1/10*1000); // audio needs some pretty high granularity :|
}

function lookupUrl() {
  return '//' + request_host + '/for_current_just_settings_json?url=' + encodeURIComponent(getStandardizedCurrentUrl()) + '&episode_number=' + liveEpisodeNumber();
}

function loadForNewUrl() {
  getRequest(loadSucceeded, loadFailed);
}

function reloadForCurrentUrl() {
  if (url != null && !inMiddleOfTestingTimer) {
    console.log("reloading...");
    var link = document.getElementById('reload_tags_a_id');
    link.innerHTML = "Reloading...";
    getRequest(function(json_string) {
      loadSucceeded(json_string);     
      link.innerHTML = "Reloaded!";
      setTimeout(function() {link.innerHTML = "Reload tags";}, 5000);
    }, loadFailed);
  }
  else {
    alert("not reloading, possibly no edits loaded or in middle of a test edit=" + inMiddleOfTestingTimer + "[hit Reload tags if the latter]");
  }
}

function loadSucceeded(json_string) {
  parseSuccessfulJson(json_string);
  getEditsFromCurrentTagList();
  startWatcherTimerSingleton(); // don't know what to display before this...so leave everything hidden until now
  old_current_url = getStandardizedCurrentUrl();
  old_episode = liveEpisodeNumber();
  if (liveEpisodeNumber() != expected_episode_number) {
    alert("play it my way\ndanger: may have gotten wrong episode expected=" + expected_episode_number + " got=" + liveEpisodeNumber());
  }
  displayDiv(document.getElementById("load_succeeded_div_id"));
  if (current_json.editor) {
    displayDiv(document.getElementById("editor_top_line_div_id"));
  }
  hideDiv(document.getElementById("load_failed_div_id"));
  hideDiv(document.getElementById("server_down_div_id")); // in case it's a recovery
  setSmiley();
}

function addPluginEnabledText() {
  if (isAmazon()) {
    var span = document.getElementsByClassName("dv-provenence-msg")[0];
    if (span && !span.innerHTML.includes("it my way")) {
      var extra = "<br/><small>(Play it my way plugin enabled)";
      if (url.editing_status != "Done with second review, tags viewed as complete") {
        extra += " (not fully edited yet)";
      }
      extra += "</small";
      span.innerHTML += extra;
    }
  }
}

function setSmiley() {
  sendMessageToPlugin({text: "☺", color: "#008000", details: "Edited playback is enabled and fully operational for current video being played"}); // green
}

function loadFailed(status) {
  mutes = skips = yes_audio_no_videos = mute_audio_no_videos = []; // reset so it doesn't re-use last episode's edits for the current episode!
  current_json = null;
  url = null; // reset
  name = liveFullNameEpisode();
  episode_name = liveEpisodeString();
  expected_episode_number = liveEpisodeNumber();
  hideDiv(document.getElementById("load_succeeded_div_id"));
  displayDiv(document.getElementById("load_failed_div_id"));
  hideDiv(document.getElementById("server_down_div_id"));
  
  removeAllOptions(document.getElementById("tag_edit_list_dropdown")); // clean up...in case it matters...
  old_current_url = getStandardizedCurrentUrl();
  old_episode = liveEpisodeNumber(); 
  sendMessageToPlugin({color: "#A00000", text: "none", details: "No edited settings found for movie, not playing edited"}); // red
  console.log("got failure HTML status=" + status);
  if (status == 412) {
    // not in our system yet
    // alert here is annoying
  }
  else if (status == 0) {
    // the server responded with nothing [i.e. down]
    displayDiv(document.getElementById("server_down_div_id"));
    // I guess still start watcher thread so if they shift movies it tries again [?] but kinda weird...though should be setup "as if we don't have it in our system" hrm...
    hideDiv(document.getElementById("load_failed_div_id")); // it's not use to click on unedited... so don't show it
    // repoll :|
    setTimeout(loadForNewUrl, 10000);// refire once...
  }
  else if (status == 500) {
    // system is broken LOL
    displayDiv(document.getElementById("server_down_div_id"));
  }
  else {
    // just let it stay saying unedited :|
  }
  
  startWatcherTimerSingleton(); // so it can check if episode changes to one we like magically LOL [amazon...]
}


function parseSuccessfulJson(json_string) {
  current_json = JSON.parse(json_string);
  url = current_json.url;
  name = url.name;
  episode_name = url.episode_name;
  expected_episode_number = url.episode_number;
  
  var dropdown = document.getElementById("tag_edit_list_dropdown");
  removeAllOptions(dropdown); // out with any old...  
  
  var option = document.createElement("option");
  option.text = "Default (all tags) (" + countDoSomethingTags(current_json.tags) + ")";
  option.value = "-1"; // special case :|
  // I think this will start as selected...
  list_length = current_json.tag_edit_lists.length;
  if (list_length > 1) {
    // wait what? should be 1:1 today...
    console.log("list size greater than 1???" + current_json.tag_edit_lists);
  }
  dropdown.add(option);
  
  for (var i = 0; i < current_json.tag_edit_lists.length; i++) {
    var tag_edit_list_and_its_tags = current_json.tag_edit_lists[i];
    var tag_edit_list = tag_edit_list_and_its_tags[0];
    var tags = tag_edit_list_and_its_tags[1];
    var option = document.createElement("option");

    option.text = tag_edit_list.description + " (" + countDoSomethingTags(tags) + ")";
    option.value = tag_edit_list.id;
    dropdown.add(option);
    option.setAttribute('selected', true); // hope this overrides, we want it to be the default for now uh guess...
  }  
  
  option = document.createElement("option");
  option.text = "Watch Unedited (0 tags)";
  option.value = "-2"; // special case :|
  dropdown.add(option);
  
  var big_edited = document.getElementById("big_edited_text_id");
  if (url.editing_status == 'Done with second review, tags viewed as complete') {
    big_edited.innerHTML = "Edited";
  } else {
    big_edited.innerHTML = "Partially edited...";
    big_edited.setAttribute("x", "0");
  }
  
  console.log("finished parsing response successful JSON");
}

function countDoSomethingTags(tags) {
  var count = 0;
  for (var i = 0; i < tags.length; i++) {
    if (tags[i].default_enabled) {
      count++;
    }
  }
  return count;
}

function setTheseTagsAsTheOnesToUse(tags) {
  mutes = []; // all get re-filled in this method :)
  skips = [];
  yes_audio_no_videos = [];
  do_nothings = [];
  mute_audio_no_videos = [];
  make_video_smallers = [];
  change_speeds = [];
  set_audio_percents = [];
  pause_videos = [];
  for (var i = 0; i < tags.length; i++) {
    var tag = tags[i];
    var push_to_array;
    if (tag.default_enabled) {
      if (tag.default_action == 'mute') {
        push_to_array = mutes;
      } else if (tag.default_action == 'skip') {
        push_to_array = skips;
      } else if (tag.default_action == 'yes_audio_no_video') {
        push_to_array = yes_audio_no_videos;
      } else if (tag.default_action == 'mute_audio_no_video') {
        push_to_array = mute_audio_no_videos;     
      } else if (tag.default_action == 'make_video_smaller') {
        push_to_array = make_video_smallers;
      } else if (tag.default_action == 'change_speed') {
        push_to_array = change_speeds;
      } else if (tag.default_action == 'set_audio_volume') {
        push_to_array = set_audio_percents;
      } else if (tag.default_action == 'pause_video') {
        push_to_array = pause_videos;
      } else { alert("please report failure 1 " + tag.default_action); }
    } else {
      push_to_array = do_nothings;
    }
    push_to_array.push(tag);
  }
}

function editListChanged() {
  getEditsFromCurrentTagList();
}

function getEditsFromCurrentTagList() {
  var dropdown = document.getElementById("tag_edit_list_dropdown");
  var selected_edit_list_id = dropdown.value;
  if (selected_edit_list_id == "-2") {
    setTheseTagsAsTheOnesToUse([]); // i.e. no-tags LOl
    return;
  }
  
  if (selected_edit_list_id == "-1") {
    setTheseTagsAsTheOnesToUse(current_json.tags);
    return;
  }

  for (var i = 0; i < current_json.tag_edit_lists.length; i++) {
    var tag_edit_list_and_its_tags = current_json.tag_edit_lists[i];
    if (tag_edit_list_and_its_tags[0].id == selected_edit_list_id) {
      setTheseTagsAsTheOnesToUse(tag_edit_list_and_its_tags[1]);
      return;
    }   
  }
  alert("unable to select " + dropdown.value); // shouldn't get here ever LOL.
}

function getRequest(success, error) {  
  var url = lookupUrl();
  console.log("starting attempt GET download " + url);
  var xhr = XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP"); 
  xhr.open("GET", url); 
  xhr.withCredentials = true; // the only request we do is the json one which should work secured...
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
  var current_episode_number = liveEpisodeNumber();
  if (getStandardizedCurrentUrl() != old_current_url || current_episode_number != old_episode) {
    if (old_episode != "0" && current_episode_number == "0") {
      console.log("got change from an episode " + old_episode + " to non episode? ignoring..."); // amazon when you hit the x
      return;
    }
    console.log("detected move to another video, to\n" + getStandardizedCurrentUrl() + "\nep. " + liveEpisodeNumber() + "\nfrom\n" +
                 old_current_url + "\n ep. " + old_episode + "\nwill try to load its edited settings now for the new movie...");
    old_current_url = getStandardizedCurrentUrl(); // set them now so it doesn't re-get them next loop
    old_episode = liveEpisodeNumber(); 
    setTimeout(loadForNewUrl, 1000); // youtube has the "old name" still for awhile, so for the new prompt wait
  }
}

var clean_stream_timer;

function startWatcherTimerSingleton() {
  clean_stream_timer = clean_stream_timer || setInterval(checkStatus, 1000/100); // 100 fps since that's the granularity of our time entries :|
  // guess we just never turn it off on purpose :)
}

function startOnce() {
  video_element = findFirstVideoTagOrNull();

  if (video_element == null) {
    // maybe could get here if they raw load the javascript?
    console.log("play it my way:\nfailure: unable to find a video playing, not loading edited playback...need to reload then hit a play button before loading edited playback?");
    setTimeout(startOnce, 500); // just retry forever :| [seems to work OK in pimw_youtube, never retries...]
    return;
  }

  if (isGoogleIframe()) {
    if (!window.parent.location.pathname.startsWith("/store/movies/details") && !window.parent.location.pathname.startsWith("/store/tv/show")) {
      // iframe started from a non "details" page with full url
      alert('play it my way: failure: for google play movies, you need to right click on them and choosen "open link in new tab" for it to work edited in google play...');
      return; // avoid future prompts which don't matter anyway for now :|
    }
  }

  // ready to try and load the editor LOL
  console.log("adding edit UI, looking for URL");

  addEditUi(); // and only do once...
  loadForNewUrl();
}

function pointWithinElement(cursorX, cursorY, element) {
  var coords = getLocationOfElement(element);
  return (cursorX < coords.left + coords.width && cursorX > coords.left && cursorY < coords.top + coords.height && cursorY > coords.top);
}

function mouseJustMoved(event) {
  var cursorX = event.pageX;
  var cursorY = event.pageY;
  var mouse_within_all_pimw_stuff = pointWithinElement(cursorX, cursorY, all_pimw_stuff);
  var mouse_within_video = pointWithinElement(cursorX, cursorY, video_element);
  if (!mouse_move_timer || (mouse_within_video && document.hasFocus())) {
    displayDiv(all_pimw_stuff);
  
    clearTimeout(mouse_move_timer); // in case previously set
    if (mouse_within_all_pimw_stuff) {
      if (!isAddtagStuffVisible()) {
        mouse_move_timer = setTimeout(hideAllPimwStuff, 10000); // sometimes the mouse gets "stuck" "left" in that corner and
        // there really is no mouse notification after that but it's gone, so hide it eventually...
      } // else they might be hovering there to adjust stuff, so don't tick off editors :)
    } else {
      mouse_move_timer = setTimeout(hideAllPimwStuff, 1500); // in add mode we ex: use the dropdown and it doesn't trigger this mousemove thing so when it comes off it it disappears and scares you, so 5000 here...
    }
  }
  else if(!mouse_within_video && !mouse_within_all_pimw_stuff) {
    // mimic youtube which removes immediately if mouse ever leaves video
    hideAllPimwStuff();
    clearTimeout(mouse_move_timer);
  }
  if (isWatchingAdd()) {
    console.log("not showing UI from mouse move since in add...");
    hideAllPimwStuff();
  }
}

function hideAllPimwStuff() {
  if (!isYoutubePimw() && (!window.navigator.userAgent.includes("PlayItMyWay"))) {
    hideDiv(all_pimw_stuff);
  }
}

function addMouseAnythingListener(func) {
  // some "old IE" browser compat stuff :|
  var addListener, removeListener;
  if (document.addEventListener) {
    addListener = function (el, evt, f) { return el.addEventListener(evt, f, false); };
    removeListener = function (el, evt, f) { return el.removeEventListener(evt, f, false); };
  } else {
    addListener = function (el, evt, f) { return el.attachEvent('on' + evt, f); };
    removeListener = function (el, evt, f) { return el.detachEvent('on' + evt, f); };
  }

  addListener(document, 'mousemove', func);
  addListener(document, 'mouseup', func);
  addListener(document, 'mousedown', func);
}

function onReady(yourMethod) { // from SO :)
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

function isYoutube() {
  return currentUrlNotIframe().includes("www.youtube.com");  
}

function withinDelta(first, second, delta) {
  var diff = Math.abs(first - second);
  return diff < delta;
}

function findFirstVideoTagOrNull() {
   // or document.querySelector("video") LOL
  if (isYoutubePimw()) {
    return document.getElementById("show_your_instructions_here_id");
  }
  
  var all = document.getElementsByTagName("video");
  // search iframes in case people try to load it manually, non plugin, and we happen to have access to iframes, which will be about never
  // it hopefully won't hurt anything tho...since with the plugin way and most pages "can't access child iframes" the content script injected into all iframes will take care of business instead.
  var i, frames;
  frames = document.getElementsByTagName("iframe");
  for (i = 0; i < frames.length; ++i) {
    try { var childDocument = frame.contentDocument } catch (e) { continue }; // skip ones we can't access :|
    all.concat(frames[i].contentDocument.document.getElementsByTagName("video"));
  }
  for(var i = 0, len = all.length; i < len; i++) {
    if (all[i].currentTime > 0) { // somewhere once had some background ones that stayed paused :|
      return all[i];
    }
  }
  return null;
}

function getCurrentTime() {
  if (isYoutubePimw()) {
    return youtube_pimw_player.getCurrentTime();
  } else {
    if (isAmazon()) {
      return video_element.currentTime - 10; // not sure why they did this :|
    } else {
      return video_element.currentTime;
    }
  }
}

function doPause() {
  console.log("doing doPause paused=" + video_element.paused + " buffered=" + getSecondsBufferedAhead());
  if (isYoutubePimw()) {
    youtube_pimw_player.pauseVideo();
  } else {
    video_element.pause();
  }
}

function rawSeekToTime(ts) {
  console.log("doing rawSeekToTime=" + ts);
  if (isYoutubePimw()) {
    var allowSeekAhead = true;
    youtube_pimw_player.seekTo(ts, allowSeekAhead); // no callback option
  } else {
    if (isAmazon()) {
      video_element.currentTime = ts + 10;
    } else {
      // really raw LOL
      video_element.currentTime = ts;
    }
  }
}

function getSecondsBufferedAhead() {
  if (isYoutubePimw()) {
    var seconds_buffered = youtube_pimw_player.getDuration() * youtube_pimw_player.getVideoLoadedFraction() - getCurrentTime();
  } else if (video_element.buffered.length == 1) { // the normal case I think...
    var seconds_buffered = (video_element.buffered.end(0) - video_element.buffered.start(0)); // wait is this end guaranteed to be after our current???
  }
  return seconds_buffered;
}

var old_ts;
var video_ever_initialized = false; // can't do seeks "off the bat" in amazon :(
function seekToTime(ts, callback) {
  if (seek_timer) {
    console.log("still seeking from previous to=" + old_ts + ", not trying that again... requested=" + ts);
    return;
  }
  if (!video_ever_initialized) {
    // XXX move this "up" to...I think doing any edits at all...somehow...
    if (video_element.readyState == 1 || video_element.style.visibility == "hidden") { // XXX does this stuff work on youtube at all? huh?
      // allow for hidden so if we're in the middle of a seek, it needs to come alive briefly before *we* seek out of there...or seeks can't work...hrm...
      console.log("appears video never initialized yet...ignoring skip command! readyState=" + video_element.readyStat + " vis=" + video_element.style.visibility);
      return;
    } else {
      console.log("video is initialized readyState=" + video_element.readyState + " vis=" + video_element.style.visibility);
      video_ever_initialized = true;
    }
  }
  
  if (ts < 0) {
    console.log("not seeking to before 0, seeking to 0 instead, seeking to negative doesn't work well " + ts);
    ts = 0;
  }
  var current_pause_state = isPaused();
  // try and avoid freezes after seeking...if it was playing first...
  var start_time = getCurrentTime();
  console.log("seeking to " + timeStampToHuman(ts) + " from=" + timeStampToHuman(start_time) + " state=" + video_element.readyState + " to_ts=" + ts);
  // [amazon] if this is far enough away from current, it also implies a "play" call...oddly. I mean seriously that is bizarre.
  // however if it close enough, then we need to call play
  // some shenanigans to pretend to work around this...
  if (!isYoutubePimw()) {
    doPause();
  } // youtube seems to retain it!
  rawSeekToTime(ts);
  old_ts = ts;
  seek_timer = setInterval(function() {
      if (isYoutubePimw()) {
        // var done_buffering = (youtube_pimw_player.getPlayerState() == YT.PlayerState.CUED);
        // it stays always as state "paused" ???? :|
        var done_buffering = true;
      } else {
        var HAVE_ENOUGH_DATA_HTML5 = 4;
        var done_buffering = (video_element.readyState == HAVE_ENOUGH_DATA_HTML5);
      }
      if ((isPaused() && done_buffering) || !isPaused()) {
        var seconds_buffered = getSecondsBufferedAhead();

        if (seconds_buffered > 2) { // usually 4 or 6...
          console.log("appears it just finished seeking successfully to " + timeStampToHuman(ts) + " ts=" + ts + " length_was=" + twoDecimals(ts - start_time) + " buffered_ahead=" + twoDecimals(seconds_buffered) + " start=" + twoDecimals(start_time) + " cur_time_actually=" + getCurrentTime() + " state=" + video_element.readyState);
          if (!isYoutubePimw()) {
            if (!current_pause_state) { // youtube loses 0.05 with these shenanigans needed on amazon, so attempt avoid :|
              doPlay();
            } else {
              console.log("staying paused [was paused before seek]");
            }
          }
          clearInterval(seek_timer);
          if (callback) {
            callback();
          }
          seek_timer = null;
        } else {
          console.log("waiting for it to finish buffering after seek seconds_buffered=" + seconds_buffered);
        }
      } else {
        console.log("seek_timer interval [i.e. still seeking...] paused=" + isPaused() + " desired_seek_to=" + ts + " state=" + video_element.readyState + " cur_time=" + getCurrentTime());
      }
  }, 25);
}

function twoDecimals(thisNumber) {
  return thisNumber.toFixed(2);
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

function displayDiv(div) {
  div.style.display = "block";
}

function toggleDiv(div) {
  if (div.style.display == "block") {
    hideDiv(div);
  }
  else {
    displayDiv(div);
  }
}

function hideDiv(div) {
  div.style.display = "none";
}

function sendMessageToPlugin(message_obj) {
  window.postMessage({ type: "FROM_PAGE_TO_CONTENT_SCRIPT", payload: message_obj }, "*");
  console.log("sent message from page to content script " + JSON.stringify(message_obj));
}

function getLocationOfElement(el) {
  el = el.getBoundingClientRect();
  return {
    left: el.left + window.scrollX,
    top: el.top + window.scrollY,
    width: el.width,
    height: el.height,
    right: el.left + window.scrollX + el.width,
    bottom: el.top + window.scrollY + el.height
  }
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
  if (isYoutube()) {
    title = youtubeChannelName() + title; 
  }
  return title;
}

function liveFullNameEpisode() {
  return liveTitleNoEpisode() + liveEpisodeString(); 
}

function removeAllOptions(selectbox)
{
  for(var i = selectbox.options.length - 1 ; i >= 0 ; i--) {
    selectbox.remove(i);
  }
}

function timeStampToHuman(timestamp) {
  var hours = Math.floor(timestamp / 3600);
  timestamp -= hours * 3600;
  var minutes  = Math.floor(timestamp / 60);
  timestamp -= minutes * 60;
  var seconds = twoDecimals(timestamp); //  -> "12.31" or "2.3"
  // padding is "hard" apparently in javascript LOL
  if (hours > 0)
    return hours + "h " + minutes + "m " + seconds + "s";
  else
    return minutes + "m " + seconds + "s";
}


function timeStampToEuropean(timestamp) { // for the subsyncer :|
  var hours = Math.floor(timestamp / 3600);
  timestamp -= hours * 3600;
  var minutes  = Math.floor(timestamp / 60);
  timestamp -= minutes * 60;
  var seconds = Math.floor(timestamp);
  timestamp -= seconds;
  var fractions = timestamp;
  // want 00:00:12,074
  return paddTo2(hours) + ":" + paddTo2(minutes) + ":" + paddTo2(seconds) + "," + paddTo2(Math.floor(fractions * 100));
}

function paddTo2(n) {
  var pad = new Array(1 + 2).join('0');
  return (pad + n).slice(-pad.length);
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

<%= io2 = IO::Memory.new; ECR.embed "../kemal_server/views/_tag_shared_js.ecr", io2; io2.to_s %> <!-- render inline cuz uses macro -->

// no jquery setup here since this page might already have its own jQuery loaded, so don't load/use it to avoid any conflict.  [plus speedup our load time]

// on ready just in case here LOL
onReady(startOnce);