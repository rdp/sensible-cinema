// (c) 2016, 2017, 2018 Roger Pack released under LGPL

// var request_host="localhost:3000"; // dev
var request_host="playitmyway.org";  // prod

if (typeof clean_stream_timer !== 'undefined') {
  alert("play it my way: already loaded...not loading it again...extension installed twice?");
  throw "dont know how to load it twice"; // in case they click a plugin button twice, or load it twice (too hard to reload, doesn't work that way anymore)
}

var video_element;
var current_json;
var mouse_move_timer;
var seek_timer;
var all_pimw_stuff;
var currently_in_process_tags = new Map();
var old_current_url, old_episode;
var current_tags_to_use;
var i_muted_it = false; // attempt to let them still control their mute button :|
var i_changed_its_speed = false; // attempt to let them still control speed manually if desired
var i_changed_audio_percent = false;
var i_hid_it = false; // make us "unhide" it only if we hid it, so that hiding because seeked into skip middle does its own hiding...don't mess with that one...
var last_speed_value = null;
var last_audio_percent = null;
var i_unfullscreened_it_element = null;
var i_paused_it = null;

function addEditUiOnce() {
  all_pimw_stuff = document.createElement('div');
  all_pimw_stuff.id = "all_pimw_stuff_id";
  all_pimw_stuff.style.color = "white";
  all_pimw_stuff.style.background = '#000000';
  all_pimw_stuff.style.backgroundColor = "rgba(0,0,0,0)"; // still see the video, but also see the text :)
  all_pimw_stuff.style.fontSize = "15px";
  all_pimw_stuff.style.textShadow="2px 1px 1px black";
  all_pimw_stuff.style.zIndex = "99999999";
  all_pimw_stuff.style.width = "440px";
  all_pimw_stuff.style.position = 'absolute';

  all_pimw_stuff.innerHTML = `
   <!-- our own styles, # means id -->
  <style>
    #all_pimw_stuff_id a:link { color: rgb(255,228,181); text-shadow: 0px 0px 5px black; }
    #all_pimw_stuff_id a:visited { color: rgb(255,228,181); text-shadow: 0px 0px 5px black; }
    #all_pimw_stuff_id { text-align: right; }
    #all_pimw_stuff_id input_disabled { margin-left: .0; }
    #all_pimw_stuff_id .error {  border:2px solid red; }
  </style>

  <!-- no pre-load message here since...we don't start the watcher thread until after the first fail or success to give us the right coords, and possibly annoying... -->

  <div id=load_failed_div_id style='display: none; a:link {font-size: 10px;}'>
  <style>
    #load_failed_div_id a:link { font-size: 10px; }
  </style>
    <a href=# onclick="displayDiv(document.getElementById('click_to_add_to_system_div_id')); return false;">
      PIMW unedited...
    </a>
    <div id=click_to_add_to_system_div_id style='display: none;'>
      <a href=# onclick="addForNewVideo(); return false;">Play it My Way: Click here to add to the system...</a> <!-- TODO disallow -->
    </div>
  </div>

  <div id=server_down_div_id style='display: none;' style='font-size: 14px;'> <!-- big -->
    Play it my way Server down, please alert us and try again later...
  </div>

  <div id="load_succeeded_div_id" style='display: none;'>
    <div id="currently_playing_it_your_way_id" style="color: rgb(148, 148, 148);">
     <div id="top_human_stuff_id" style='display: block;'>
      <svg id="big_edited_text_svg_id" style="font: 50px 'Arial'; height: 50px;" viewBox="0 0 350 50"> <!-- svg shenanigans seem only way to get outlined text -->
        <text style="fill: none; stroke: rgb(188, 188, 188); stroke-width: 0.5px; stroke-linejoin: round;" y="40" x="55" id="big_edited_text_id">Edited</text>
      </svg>
      <br/>
      Editing out: <select id='tag_edit_list_dropdown_id' onChange='personalizedDropdownChanged();'></select> <!-- javascript will set up this select -->
      <br/>
      <a href=# onclick="openPersonalizedEditList(); return false">Or personalize which parts you edit out</a>
      <br/>
      Pimw is in Beta, we miss anything? <a href=# onclick="reportProblem(); return false;">Let us know!</a>
      <br/>
     </div>
      Picture-free dragger: use this to seek in the movie, to avoid any bad preview pictures! <input type="range" min="0" max="100" value="0" step="1" id="safe_seek_id" style="width: 180px;" /> <span id='safe_seek_ts_id'>2h 32m 10s</span> <!-- be careful modifying the text to test it on one past an hour to make sure it still fits -->
      <div style=""> 
        <span id="currently_xxx_span_id"> <!-- "currently: muting" --></span>
        <div id="editor_top_line_div_id" style="display: none;"> <!-- we enable this later if flagged as editor -->
           <a href=# onclick="toggleAddNewTagStuff(); return false;">[add/edit tag]</a>
        </div>
      </div>
    </div>
    <div id="tag_details_div_id"  style='display: none;'>
      <div id='tag_layer_top_section'>
        <span id="current_timestamp_span_id"> <!-- 0m32s --> </span> <span id="next_will_be_at_x_span_id" > <!-- next will be at x for y --> </span>
        <br/>
        <span id="next_will_be_at_x_second_line_span_id" > <!-- skip for 6.86x --> </span>
        <br/>
      </div>
      <form target="_blank" action="filled_in_later_if_you_see_this_it_may_mean_an_onclick_method_threw" method="POST" id="create_new_tag_form_id">
        <br/>
        from:<input type="text" name='start' style='width: 150px; height: 20px; font-size: 12pt;' id='start' value='0m 0.00s'/>
        <input id='set_start_to_current_id' type='button' value='<--set to current time' onclick="document.getElementById('start').value = getCurrentVideoTimestampHuman();" />
        <input type='button' value='<-- Test' onclick="testCurrentFromUiStart(); return false">
        <br/>
        &nbsp;&nbsp;&nbsp;&nbsp;to:<input type='text' name='endy' style='width: 150px; font-size: 12pt; height: 20px;' id='endy' value='0m 0.00s'/>
        <input id='set_end_to_current_id' type='button' value='<--set to current time' onclick="document.getElementById('endy').value = getCurrentVideoTimestampHuman();" />
        <input type='button' id='test_current_from_ui_end_id' value='<-- Test' onclick="testCurrentFromUiEnd(); return false">
        <br/>


      <!-- no special method for seek forward since it'll at worst seek to a skip then skip -->
      <input type='button' onclick="seekToBeforeSkip(-30); return false;" value='-30s'/>
      <input type='button' onclick="seekToTime(getCurrentTime() + 5); return false;" value='+5s'/>
      <input type='button' onclick="seekToBeforeSkip(-5); return false;" value='-5s'/>
      <input type='button' onclick="seekToTime(getCurrentTime() + 1); return false;" value='1s+'/>
      <input type='button' onclick="seekToTime(getCurrentTime() - 1); return false;" value='1s-'/>
      <input type='button' onclick="stepFrameBack(); return false;" value='.1s -'/>
      <input type='button' onclick="stepFrame(); return false;" value='.1s +'/>

      <br/>
      Speed:
      <input type='button' onclick="playButtonClicked(); setPlaybackRate(0.5); return false;" value='0.5x'>
      <input type='button' onclick="decreasePlaybackRate();; return false;" value='&lt;&lt;'/>
      <span ><a id='playback_rate' href=# onclick="setPlaybackRate(1.0); return false">1.00x</a></span> <!--XX remove link -->
      <input type='button' onclick="increasePlaybackRate(); return false;" value='&gt;&gt;'/>
      <input type='button' onclick="doPause(); return false;" value='&#9612;&#9612;'/>
      <input type='button' onclick="playButtonClicked(); return false;" value='&#9654;'>
       <br/>
       action:

        <input type="hidden" id="tag_hidden_id" name="id" value="0"> <!-- 0 means new...I think... -->
        <select name="default_action" id='action_sel' onchange="">
          <option value="mute">mute</option>
          <option value="skip">skip</option>
          <option value="yes_audio_no_video">yes_audio_no_video</option>
          <option value="mute_audio_no_video">mute_audio_no_video</option>
          <option value="make_video_smaller">make_video_smaller</option>
          <option value="change_speed">change_speed</option>
          <option value="set_audio_volume">set_audio_volume</option>
          <option value="do_nothing">do_nothing</option>
        </select>
        <br/>
      <button type="" value="" onclick="clearButton(); return false;">discard changes/new tag</button>
        <input type='button' id='save_tag_button_id' value='Save Edit' onclick="saveTagButton(); return false;" style="color: blue;">
        <br/>
        <br/>
		Describe the content:

<div id="category_div_id">
category:<select name="category" id='category_select_id' onchange=""
style="background-color: rgba(255, 255, 255, 0.85);" >
  <option value="" disabled selected>category -- please select one</option>
  <option value="profanity">profanity/verbal attack</option>
  <option value="violence">violence/blood/crude action etc.</option>
  <option value="physical">sex/nudity/lewd etc.</option>
  <option value="suspense">suspense (frightening, scary fighting, surprise)</option>
  <option value="substance-abuse">substance use</option>
  <option value="movie-content">movie content (credits, etc.)</option>
</select>
</div>

<div id="subcategory_div_id">
<select name="subcategory" id='subcategory_select_id' style="background-color: rgba(255, 255, 255, 0.85);" onchange="">
    <option value="">please select subcategory</option> <!-- this one sticks around no matter which category you select -->
    <% subcategory_map().each{|subcat_name, entries| %>
      <% old_sub_sub = "" %>
      <% entries.group_by{|entry| entry[:sub_sub_cat] }.each{|sub_sub_cat, entries| %>
        <% if sub_sub_cat != "" %>
          <optgroup label="<%= subcat_name.to_s + " -- " + sub_sub_cat %>"> <!-- so it'll hide them when profanity not selected -->
        <% end %>
        <% entries.each{|entry| %>
          <option value="<%= HTML.escape(entry[:db_name]) %>"><%= HTML.escape(subcat_name.to_s + " -- " + entry[:human_name]) %></option>    
        <% } %>
        <% if sub_sub_cat != "" %>
          </optgroup>
        <% end %>
      <% } %>
    <% } %>
</select>
</div>

<select id="hidden_select_id" style="display : none;"> <!-- needed/re-used for resizing subcats :| -->
 <option id="hidden_select_option_id"></option>
</select>

age specifier (if violence):
<select name="age_maybe_ok" id="age_maybe_ok_id">
  <option value="0">please select</option>
  <% [3,6,9,12,15].each{|n| %>
    <option value="<%= n %>">not OK age <%= n %> and under</option>
  <% } %>
  <option value="-1">no age OK</option>
</select>
<br/>

Lewdness level:
<select name="lewdness_level" id="lewdness_level_id">
  <!-- TODO fix ordering in DB :|  two 2's? -->
  <option value="0">please select</option>
  <option value="2">Cartoon (non sensual)</option> 
  <option value="2">Art-based (non sensual)</option>
  <option value="10">Non sensual, hard to even see</option>
  <option value="3">Non sensual or barely revealing</option>
  <option value="11">Non sensual or medium revealing</option>
  <option value="4">Mild sensual or medium revealing</option>
  <option value="5">Art-based and moderate sensual</option>
  <option value="6">Moderate sensual</option>
  <option value="7">Art-based and severe/extreme sensual</option>
  <option value="8">Severe sensual  </option>
  <option value="9">Extreme sensual "rated X"</option>
</select>
		<br/>
lip readable? <!-- XXX make totally disappear replaced by lewdness box, etc. -->
<select name="lip_readable" id="lip_readable_id"> <!-- check boxes have some gotchas avoid for now -->
  <option value="">lip readable?</option>
  <option value="true">Yes lip-readable</option>
  <option value="false">Not lip-readable</option>
</select>
<br/>

Impact to Story if edit used:
  <select name="impact_to_movie" id="impact_to_movie_id">
    <option value="0">please select impact</option>
    <option value="1">negligible</option>
    <option value="2">low'ish</option>
    <option value="4">medium or bit confusing</option>
    <option value="5">high/confusing</option>
    <option value="7">extreme or serious plot holes</option>
  </select>

<br/>
details
<input type="text" name="details" id="details_input_id" size="30" value="" style="background-color: rgba(255, 255, 255, 0.85);"/>
<input type='button' value='Copy prev\'' onclick="reUseLastTagDetails(); return false;">
<br/>
popup overlay
<input type="text" name="popup_text_after" id="popup_text_after_id" size="30" value="" style="background-color: rgba(255, 255, 255, 0.85);" placeholder="(use only on occasion optional)" />
<br/>

By default edit should be turned on?
<select name="default_enabled" id="default_enabled_id"> <!-- check boxes have caveats avoid for now -->
  <option value="true">Y</option>
  <option value="false">N</option>
</select>
<br/>
        <input type='button' value='&lt;&lt;' id='open_tag_before_current_id' onclick="openTagBeforeOneInUi(); return false;">
        <input type='button' value='Re-Edit Just Passed Tag' id='open_prev_tag_id' onclick="openTagPreviousToNowButton(); return false;">
        <input type='button' value='Re-Edit Next Tag' id='open_next_tag_id' onclick="openNextTagButton(); return false;">
        <input type='button' value='&gt;&gt;' id='open_tag_after_current_id' onclick="openTagAfterOneInUi(); return false;">
        <br/>
        <input type='button' id='destroy_button_id' onclick="destroyCurrentTagButton(); return false;" value='Destroy tag &#10006;'/>
        <button type="" id='reload_tag_button_id' value="" onclick="reloadTagButton(); return false;">Reload This Tag</button>

      </form>

      <a id=reloading_id href=# onclick="reloadForCurrentUrl(''); return false;" </a></a> <!-- filled in later while things are going -->
      &nbsp;&nbsp;&nbsp;
      <a href=# onclick="getSubtitleLink(); return false;" </a>Get subtitles</a>
      &nbsp;&nbsp;
      <a href=# onclick="doneMoviePage(); return false;">PIMW Movie page</a>
      <input type="button" onclick="toggleAddNewTagStuff(); return false;" value='✕ Hide this editor'/>
    </div>
  </div>`;

  document.body.appendChild(all_pimw_stuff);

  addMouseAnythingListener(mouseJustMoved);
  mouseJustMoved({pageX: 0, pageY: 0}); // start its timer, prime it :|
  editDropdownsCreated(); // from shared javascript, means "the HTML elements are in there"
  if (isYoutubePimw()) {
    // assume it can never change on the fly to a different host of the movie...I doubt it :| can use jquery since on my site...
    $("#action_sel option[value='yes_audio_no_video']").remove();
    //$("#action_sel option[value='mute']").remove();
    //$("#action_sel option[value='mute_audio_no_video']").remove();
  }

  if (isAmazon()) {
    // guess these don't qualify as "making imperceptible" we already have black screen, these are kinder work arounds for youtube anyway...
    var select =  document.getElementById("action_sel");
    removeOptionByName(select, "change_speed");
//    removeOptionByName(select, "make_video_smaller"); // this one might be legit if they made it "impercetibly small" LOL leave disabled
//    removeOptionByName(select, "set_audio_volume"); // this one miiight be legit if it makes it super soft...hmm...
  }

  setupSafeSeekOnce();

  setInterval(doPeriodicChecks, 100); // XX figure out if we even need this v. often or not...
  setInterval(doRarePeriodicChecks, 1000); // too cpu hungry :|
  // we don't start the "real" interval until after first safe load...apparently...odd...

} // end addEditUiOnce

var seek_dragger_being_dragged = false;

function updateSafeSeekTime() {
  if (!seek_dragger_being_dragged) {
    var seek_dragger =  document.getElementById('safe_seek_id');
    seek_dragger.value = getCurrentTime() / videoDuration() * 100;
    updateHTML(document.getElementById('safe_seek_ts_id'), timeStampToHumanRoundSecond(getCurrentTime()));
  } // else let the mouse movement change it only...it's about to seek soon'ish...
}

function seekToPercentage(valMaxOneHundred) {
  var desired_time_seconds = videoDuration() / 100.0 * valMaxOneHundred;
  console.log("safe seek slider seeking to " + timeStampToHuman(desired_time_seconds));
  seekToTime(desired_time_seconds);
  checkStatus(); // may as well, save 0.01, plus we are "safe seek" after all
}

function setupSafeSeekOnce() {

  // basically copied from edited_youtube but scary...
  var seek_dragger = document.getElementById('safe_seek_id');

  addListenerMulti(seek_dragger, "mousedown touchstart", function() {
    seek_dragger_being_dragged = true;
  });

  addListenerMulti(seek_dragger, "mouseup touchend", function() {
    seek_dragger_being_dragged = false;
    seekToPercentage(this.value);
  });

  addListenerMulti(seek_dragger, "mousemove touchmove", function() {
     if (seek_dragger_being_dragged) {
       var desired_time_seconds = videoDuration() / 100.0 * this.value;
       document.getElementById('safe_seek_ts_id').innerHTML = timeStampToHumanRoundSecond(desired_time_seconds);
        // but don't seek yet :)
      }
  });

  setInterval(updateSafeSeekTime, 250); // only 4/sec because ... uh...
}

function playButtonClicked() {
  if (isPaused()) {
    doPlay();
  } else if (getPlaybackRate() != 1) {
    setPlaybackRate(1.0); // back to normal if they hit the play button while going slow :)
  }
}

function getStandardizedCurrentUrl() { // duplicated with contentscript .js
  var current_url = currentUrlNotIframe();
  if (document.querySelector('link[rel="canonical"]') != null && !isYoutube()) {
    // -> canonical, the crystal code does this for everything so guess we should do here as well...ex youtube it strips off any &t=2 or something...
    current_url = document.querySelector('link[rel="canonical"]').href; // seems to always convert from "/gp/" to "/dp/" and sometimes even change the ID :|
  }
  // attempt to leave the rest in crystal
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
        // ?? punt!
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

function areWeWithin(desiredAction, cur_time) {
  var all = getAllTagsIncludingReplacedFromUISorted(current_tags_to_use);
  for (var i = 0; i < all.length; i++) {
    var tag = all[i];
    if (tag.default_action != desiredAction) {
      continue;
    }
    if (!tag.default_enabled) { // also means "personalized enabled" as it were...
      continue;
    }
    if(areWeWithinTag(tag, cur_time)) {
      return tag;
    }
    // no early out/break yet because 1) test unsaved edits uses push/pop and 2) even if we did, at the end of movies it would still be slow so...fix it different?
  }
  return false;
}


function checkIfShouldDoActionAndUpdateUI() {
  var cur_time = getCurrentTime();
  var tag;

  tag = areWeWithin('mute', cur_time);
  tag = tag || areWeWithin('mute_audio_no_video', cur_time);
  var extra_message = "";
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

  tag = areWeWithin('yes_audio_no_video', cur_time);
  tag = tag || areWeWithin('mute_audio_no_video', cur_time);
  if (tag) {
    // use style.visibility here so it retains the space on screen it would have otherwise used...(for non amazon LOL) and to not confuse the seektoheart logic :|
    if (video_element.style.visibility != "hidden") {
      timestamp_log("hiding video leaving audio ", cur_time, tag);
      video_element.style.visibility = "hidden";
      i_hid_it = true;
    }
    extra_message += "doing a no video yes audio black screen";
    notify_if_new(tag);
  }
  else {
    if (video_element.style.visibility != "" && i_hid_it && videoNotBuffering()) { // need videoNotBuffering() in case seeking out of yes_audio_no_video don't want to show still frame while seek completes :|
      console.log("unhiding video with cur_time=" + cur_time + " " + timeStampToHuman(cur_time));
      video_element.style.visibility=""; // non hidden :)
      i_hid_it = false;
      //  case it heart blanked it to start (or seek into) this one and needs to un now...(or if it needs to start a blank before the next one...)
      doneWithPossibleHeartBlankUnlessImpending(true);
    }
  }

  tag = areWeWithin('skip', cur_time); // do after unhiding so it can use 'right now' to know if should heart blank :|
  if (tag) {
    timestamp_log("seeking forward", cur_time, tag);
    notify_if_new(tag); // show it now so it can notify while it seeks :) [NB for longer seeks it shows it over and over [bug] but notification tag has our back'ish for now :\ ]
    blankScreenIfWithinHeartOfSkip(tag, cur_time);
    heartBlankScreenIfImpending(tag.endy);  // warn it to start a blank now, for the gap, otherwise when it gets there it's already too late
    extra_message += "Skipping forward...";
    seekToTime(tag.endy, doneWithPossibleHeartBlankUnlessImpending);
  }

  if (isYoutubePimw()) {
    tag = areWeWithin('make_video_smaller', cur_time);
    if (tag) {
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
      var iframe = youtube_pimw_player.getIframe();
      if (iframe.height == "200") {
        console.log("back to normal size cur_time=" + cur_time);
        // if you modify this also modify edited_youtube.ecr to match
        iframe.height = "100%"; // XXXX save away instead?? :|
        iframe.width = "100%";
        // can't refullscreen it "programmatically" at least in chrome, so punt!
      }
    }

    tag = areWeWithin('change_speed', cur_time);
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

    tag = areWeWithin('set_audio_percent', cur_time);
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
  }

  var top_line_text = "";
  if (extra_message != "") {
    top_line_text = "Currently:" + extra_message; // prefix
  } else {
    top_line_text = "<br>"; // NB can't use <br/> since trailing slash gets sanitized out so can't detect changes right FWIW :| <br> is OK :)
  }
  updateHTML(document.getElementById("currently_xxx_span_id"), top_line_text);

  if (isAddtagStuffVisible()) { // uses a bit o' cpu, is editor only...so don't calc typically...
    updateHTML(document.getElementById("current_timestamp_span_id"), "now: " + timeStampToHuman(cur_time));
    var nextLine = "";
    var nextsecondline = "";
    var next_future_tag = getFirstTagEndingAfter(cur_time, getAllTagsIncludingReplacedFromUISorted(current_json.tags)); // so we can see stuff if "unedited" dropdown selected, "endingAfter" so we can show the "currently playing" edit
    if (next_future_tag) {
      nextLine += "next: ";
      var time_until = next_future_tag.start - cur_time;
      if (time_until < 0) {
        time_until =  next_future_tag.endy - cur_time; // we're in the heart of one, don't show a negative :|
      }
      time_until = Math.round(time_until);
      nextLine +=  " in " + timeStampToHuman(time_until).replace(new RegExp('.00s$'), 's'); // humanish friendly numbers

      if (faux_tag_being_tested && uiTagDiffersFromOriginalAndThereIsOriginal()) { // faux_tag_being_tested means they hit "test"
        nextsecondline += "(using your new values)";
      }
      nextsecondline += "(" + next_future_tag.default_action + " for " + twoDecimals((next_future_tag.endy - next_future_tag.start)) + "s)";
      if (!next_future_tag.default_enabled) {
        nextsecondline += " (disabled)";
      }
      document.getElementById("open_next_tag_id").style.visibility = "visible";
    }
    else {
      nextLine += "(no upcoming tags)";
      document.getElementById("open_next_tag_id").style.visibility = "hidden";
    }

    var next_earlier_tag = getFirstTagEndingBefore(cur_time);
    if (next_earlier_tag) {
      document.getElementById("open_prev_tag_id").style.visibility = "visible";
    } else {
      document.getElementById("open_prev_tag_id").style.visibility = "hidden";
    }

    var save_button = document.getElementById("save_tag_button_id");
    var destroy_button = document.getElementById("destroy_button_id");
    var reload_tag_button = document.getElementById("reload_tag_button_id");
    var test_end_button = document.getElementById('test_current_from_ui_end_id');
    if (currentTestAction() == 'skip') {
      test_end_button.style.visibility = "hidden";
    } else {
      test_end_button.style.visibility = "visible";
    }
    if (uiTagIsNotInDb()) {
      save_button.value = "Save New Tag";
      destroy_button.style.visibility = "hidden"; // couldn't figure out how to grey it
      reload_tag_button.style.visibility = "hidden";
      if (createFauxTagForCurrentUI().start > 0) {
        nextsecondline = "CREATING NEW TAG..." + nextsecondline;
      } // else already obvious because all 0's
    } else {
      save_button.value = "Update This Tag";
      destroy_button.style.visibility = "visible";
      reload_tag_button.style.visibility = "visible";
      nextsecondline = "RE-EDITING existing tag..." + nextsecondline;
    }
    var endy = humanToTimeStamp(document.getElementById('endy').value);
    var start = humanToTimeStamp(document.getElementById('start').value);  
    if (doubleCheckFullFormAddRedAndAlert(false)) {
      save_button.style.color = "blue";
    } else {
      save_button.value += " ?"; // "kind of saveable" LOL
    }
    updateHTML(document.getElementById('next_will_be_at_x_span_id'), nextLine);
    updateHTML(document.getElementById('next_will_be_at_x_second_line_span_id'), nextsecondline);

    updateHTML(document.getElementById("playback_rate"), twoDecimals(getPlaybackRate()) + "x");
  }
  // XXXX cleanup the below needed still? huh?
  removeIfNotifyEditsHaveEnded(cur_time); // gotta clean this up sometime, and also support "rewind and renotify" so just notify once on first tag...
}

function uiTagIsNotInDb() {
  return document.getElementById('tag_hidden_id').value == '0';
}

var i_heart_blanked_it = false;

function blankScreenIfWithinHeartOfSkip(skipish_tag, cur_time) {
  // if it's trying to seek out of something baaad then don't show a still frame of the bad stuff in the meanwhile while seek is going...
  // but don't show black blips on normal seek from playing continuous...only black screen if we're in the "heart" of the bad stuff...
  // if they overlap from black screen to skip we don't need to do a heart blank, it'll stay dark
  // if it seeks into a black screen, we have heartBlankScreenIfImpending for that [does matter]
  var within_heart_of_skipish = !withinDelta(skipish_tag.start, cur_time, 0.05);
  if (within_heart_of_skipish) {
    console.log("within_heart_of_skipish doing startHeartBlank");
    startHeartBlank(skipish_tag, cur_time);
  } else {
    //console.log("not blanking it because it's normal playing continuous beginning of skip..." + skipish_tag.start);
  }
}

function heartBlankScreenIfImpending(skip_time) { // basically for pre-emptively detecting if there'll be bad stuff when skips end...
  var just_before_bad_stuff = areWeWithinNoShowVideoTag(skip_time + 0.02); // if about to re-non-video, don't show blip of bad stuff if two such edits back to back
  if (just_before_bad_stuff) {
    console.log("starting heartblank b/c just_before_bad_stuff or just into it");
    startHeartBlank(just_before_bad_stuff, skip_time);
  } else {
    // console.log("not heartblanking it, not in middle of anything");
  }
}

function areWeWithinNoShowVideoTag(cur_time) {
  return areWeWithin('skip', cur_time) || areWeWithin('yes_audio_no_video', cur_time) || areWeWithin('mute_audio_no_video', cur_time);
}

function startHeartBlank(skipish_tag, cur_time) {
  if (video_element.style.display != "none") {
    console.log("heartblanking it start=" + skipish_tag.start + " cur_time=" + cur_time);
    video_element.style.display = "none"; // have to use style.display or it hoses us and still shows it or something.
    // NB we are using style.display here when a "black screen" uses style.visibility, so no ambiguity!
    // style.display is more violent/painful/jarring so we try and use as least as possible...
    i_heart_blanked_it = true;
  } else {
    console.log("should never get here anymore already video_element.style.display=" + video_element.style.display + " so not changing that even though we're in the heart of a skip");
  }
}

function doneWithPossibleHeartBlankUnlessImpending(start_heart_blank_if_close) { // do as its "whole own thing" (versus aumenting yes_audio_no_video) since it *has* to use style.display...I guess that means needs its own :|...
  var cur_time = getCurrentTime();
  // 0.02 cuz if it's "the next 0.01" then count it, plus some rounding error :)
  var just_before_bad_stuff = areWeWithinNoShowVideoTag(cur_time + 0.02); // if about to re-non-video, don't show blip of bad stuff if two such edits back to back
  if (!just_before_bad_stuff) {
    if (i_heart_blanked_it) {
      console.log("unheart blanking it");
      video_element.style.display="block"; // non none :) 
      i_heart_blanked_it = false;
    } else {
      // console.log("doneWithPossibleHeartBlankUnlessImpending nothing to do (i.e. didn't run into a heart-of-bad-stuff when performed last seekish"); // too chatty
    }
  }
  else {
    if (start_heart_blank_if_close) {
      console.log("start_heart_blank_if_close'ing");
      startHeartBlank(just_before_bad_stuff, cur_time);
    } else {
      console.log("not unheart blanking it, we're already heart_blanked and about to enter another bad stuff section...start=" + 
        timeStampToHuman(just_before_bad_stuff.start) + " cur_time=" + timeStampToHuman(cur_time)); // XX is this accurate?
    }
  }
}

function areWeWithinTag(tag, cur_time) {
  // don't count it if we're right at the very end
  // to avoid "seeking at 4123.819999 will_end:4123.82 in 9.99999429041054e-7s" infinite loop
  if (cur_time >= tag.start && cur_time < tag.endy && !withinDelta(cur_time, tag.endy, 0.0001)) {
    return tag;
  } else {
    return false;
  }
}

function removeIfNotifyEditsHaveEnded(cur_time) { // wait how does this interface with the 10s timeout?
  for (var tag of currently_in_process_tags.keys()) {
    if (!areWeWithinTag(tag, cur_time)) {
      currently_in_process_tags.delete(tag);
    }
  }
}

function notify_if_new(tag) { // we have to do our own timeout'ish instead of just relying on Notification tags so that if it's a 20s yes_audio_no_video we'll just show it the first 10s...or maybe tags should have worked?
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
        // XXXX if body too large still, split to second notification?
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

var last_log = "";
function logAddOnce(to_log) {
  if (last_log != to_log) {
    console.log(to_log);
    last_log = to_log;
  } // else don't log :|
}

function isWatchingAdd() {
  if (current_json != null) {
    // guess this > 0 check is for amazon when it has "lost" its video?
    // withinDelta 10 is amazon at the end weird stuff LOL
    if (current_json.url.total_time > 0 && !withinDelta(current_json.url.total_time, videoDuration(), 10.5)) { // amazon can be 10.01 or something if you go to the end
      logAddOnce("watching add? Or possibly hit X after starting movie amazon expected=" + current_json.url.total_time + " got_duration=" + videoDuration()); // we get NaN for video_element.duration after hit video x in amazon :| [?]
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
var video_ever_initialized = false; // can't do seeks "off the bat" in amazon [while still obscured] -> spinner then crash!
var last_timestamp = -1;
var last_timestamp_trunc = -1;

function checkStatus() { // called "at a lot of" fps (didn't seem to increase too much cpu to poll like this?)

  // while playing, current timestamp is basically different each time...
  // we're guaranteed a video element, that's about it, at this point...
  var cur_time = getCurrentTime();
  // sometimes an editor hits "clear tag" button, it won't do anything if we avoid recalc...hmm...
  // seems to have some other optimization anyway that helps...low cpu...
  //if (truncTwoDecimals(cur_time) == last_timestamp_trunc) {
    // we've "already handled" this millisecond...hopefully...
    // basically restrict to 100 fps but try and run only at the "start" of the hundredth...
    // when slammed it gets in by like 0.04 still...every so often 9, seems to always get it though...so possibly better than 100/s like before there...
    // sometimes 3, sometimes 2/sec [macbook] with logging so...some timer limit?
    // also avoids calling more than once/ms the saving! :)
    //return;
  //}

  // avoid unmuting videos playing that we don't even control [like youtube main page] with this...basically if the movie changes to something else unedited,
  if (current_json != null) {
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
        setExtensionSmiley();
        i_set_it_to_add = false;
      }

      // seems necessary to let it "come alive" first in amazon before we can begin to hide it, even if within heart of seek <sigh> I guess... :|
      // an initial blip [video] is OK [this should be super rare, and is "hard" to avoid], just try not to crash working around it for now...
      if (!video_ever_initialized) {
        if (!videoNotBuffering() || video_element.offsetWidth == 0) {
          console.log("appears video never initialized yet...doing nothing! readyState=" + video_element.readyState + " width=" + video_element.offsetWidth + " cur_time=" + getCurrentTime());
          return;
        } else {
          console.log("video is firstly initialized readyState=" + video_element.readyState + " width=" + video_element.offsetWidth);
          video_ever_initialized = true;
        }
      }
      if (cur_time < last_timestamp) { // needs some TLC
        console.log("Something (possibly pimw) just sought backwards to=" + cur_time + " from=" + last_timestamp + " to=" + timeStampToHuman(cur_time) + " from=" + timeStampToHuman(last_timestamp) + " readyState=" + video_element.readyState);
        var tag = areWeWithinNoShowVideoTag(cur_time);
        if (tag) {
          blankScreenIfWithinHeartOfSkip(tag, cur_time);
        }
        tag = areWeWithin('skip', cur_time);
        // just skips for this one (also happens to avoid infinite loop...["seek to before skip oh it's the current location..., repeat"])
        // was the seek to within an edit? Since this was a "rewind" let's actually go to *before* the bad spot, so the traditional +-10 buttons can work from UI
        if (tag) {
          console.log("they just seeked backward to within a skip, rewinding more..."); // tag already gets logged in seekToBeforeSkip
          blankScreenIfWithinHeartOfSkip(tag, cur_time);
          var delta_right_now = 0;
          seekToBeforeSkip(delta_right_now, doneWithPossibleHeartBlankUnlessImpending);
          return; // don't keep going which would do a skip forward...
        }
      }
      last_timestamp = cur_time;
      last_timestamp_trunc = truncTwoDecimals(cur_time);

      // GO!
      checkIfShouldDoActionAndUpdateUI();
    } // end "am I add?"
  } // end if current_json != null
}

function refreshVideoElement() {
  var old_video_element = video_element;
  video_element = findFirstVideoTagOrNull() || video_element; // refresh it in case changed, but don't switch to null between clips, I don't think our code handles nulls very well...
  // only add event things once :)
  if (video_element != old_video_element) {
    console.log("video element changed...");
    var seek_func = function(event) {
        console.log("got " + event.type + " event cur_time=" + getCurrentTime());
        checkStatus(); // do a normal pass "fast/immediately" in case need to blank [saves 0.007s, woot!]
      };
    // time will already be updated to "seek to time" with seeking event...I think...or at least most of the time LOL so do seeked too
    // sometimes "seeking" comes after a few ms...bizarrely..maybe that's what lets stuff through sometime TODO add events to the +10 and dragger so they tell me earlier
    video_element.addEventListener("seeking", seek_func);
    video_element.addEventListener("seeked", seek_func);
    var listener = function(event) {
      console.log("got " + event.type + " event isPaused()=" + isPaused() + " cur_time=" + getCurrentTime());
      if (event.type == "canplaythrough") {
        if (seek_timer) {
          console.log("canplaythrough doing early seek callback"); // XXX could I use this instead of the timer, so I can avoid the weird spinner/hang issue?
          seek_timer_callback.call();
        }
      }
    };
    video_element.addEventListener("play", listener);
    video_element.addEventListener("canplay", listener);
    video_element.addEventListener("canplaythrough", listener);
    video_element.addEventListener("readystatechange", listener);
    video_element.addEventListener("paused", listener);
    video_element.addEventListener("abort", listener);
    // timeupdate is not granular enough for much
    if (isAmazon()) {
      var progressbar = document.getElementsByClassName("bottomPanel")[0];
      progressbar.addEventListener("mouseup", function (event) {
        console.log("clicked on amazon seek bar " + " cur_time=" + getCurrentTime());  // we don't know the time even for 10ms after...
        // XXXX do a preemptive heartblank?
     });
    }
  }
}

function timestamp_log(message, cur_time, tag) {
  local_message = "edit:" + message + " cur_time=" + timeStampToHuman(cur_time) + " start=" + timeStampToHuman(tag.start) + " will_end=" + twoDecimals(tag.endy) + " will_end=" + timeStampToHuman(tag.endy) + " in " + twoDecimals(tag.endy - cur_time) + "s";
  console.log(local_message);
}

function seekToBeforeSkip(delta, callback) {
  var cur_time = getCurrentTime();
  var desired_time = cur_time + delta;
  var tag = areWeWithin('skip', desired_time);
  if (tag) {
    var new_delta = tag.start - cur_time - 5; // youtube with 2 would fail here seeking backward and loop forever :\
    console.log("would have sought to middle of " + twoDecimals(tag.start) + " -> " + twoDecimals(tag.endy) + " going back further instead old_delta=" + delta + " new_delta=" + new_delta + " cur_time=" + cur_time);
    seekToBeforeSkip(new_delta, callback); // in case we run into another'un right there ... :|
  }
  else {
    seekToTime(desired_time, callback);
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

function getAllTagsNotIncludingReplacedFromUI() {
  return current_json.tags;
}

function getAllTagsIncludingReplacedFromUISorted(tags_wanting_replacement_inserted) {
  if (!faux_tag_being_tested) {
    return tags_wanting_replacement_inserted; // should be sorted, good to go
  }
  if (uiTagIsNotInDb()) {
    // we got a fresh tag being edited
    return [faux_tag_being_tested].concat(tags_wanting_replacement_inserted).sort(compareTagStarts); // add in new tag chronologically
  } else {
    // UI tag is in DB, so in the current list, we need to search out and replace it with what's in the UI
    var allWithReplacement = [];
    var found_it = false;
    for (var i = 0; i < tags_wanting_replacement_inserted.length; i++) {
      if (faux_tag_being_tested.id == tags_wanting_replacement_inserted[i].id) {
        allWithReplacement.push(faux_tag_being_tested);
        found_it = true;
      } else {
        allWithReplacement.push(tags_wanting_replacement_inserted[i]);
      }
    }
    if (!found_it) {
      // case "watch unedited" and "still click test an edit"
      allWithReplacement.push(faux_tag_being_tested);
    }
    return allWithReplacement.sort(compareTagStarts); // and sort it in
  }
}

function getFirstTagEndingAfter(cur_time, all_tags) {
  for (var i = 0; i < all_tags.length; i++) {
    var tag = all_tags[i];
    var end_time = tag.endy;
    if(end_time > cur_time) { // first one ending past our current position
      return tag;
    }
  }
  return null; // none found
}

function getFirstTagStartingAfter(cur_time, all_tags) {
  for (var i = 0; i < all_tags.length; i++) {
    var tag = all_tags[i];
    var start_time = tag.start;
    if(start_time > cur_time) { // first one ending past our current position
      return tag;
    }
  }
  return null; // none found
}

function videoDuration() {
  if (isYoutubePimw()) {
    return youtube_pimw_player.getDuration();
  } else {
    return video_element.duration; // and hope they're not near the end, otherwise should be -10
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
  console.log("doing doPlay() paused=" + video_element.paused + " readyState=" + video_element.readyState + " buffered=" + twoDecimals(getSecondsBufferedAhead()));
  if (isYoutubePimw()) {
    youtube_pimw_player.playVideo();
  } else {
    // could return this "play promise" but seems to get called immediately even if play is actually still working [amazon]
    video_element.play(); // implies video_element.style.visibility = "visible" after...enough time to see the video :(
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
  toggleDiv(document.getElementById("top_human_stuff_id")); // make more space screen real estate is expensive!
  toggleDiv(document.getElementById("tag_details_div_id"));
}

function isAddtagStuffVisible() {
  return document.getElementById("tag_details_div_id").style.display != "none";
}

function setEditedControlsToMovieRight() {
  if (videoCurrentlyBlackedByUs()) {
    return; // we won't get the right coords to sync up with, which if we try makes our edit_tag area go off screen... [NB not enough if video "starts" right in a blank screen, but auto-corrects after once is visible... :| ]
  }
  var width = parseInt(all_pimw_stuff.style.width, 10);
  var video_element_size = getLocationOfElement(video_element);
  var desired_left = video_element_size.right - width;
  var desired_top = video_element_size.top;
  if (isAmazon()) {
    if ((getLocationOfElement(all_pimw_stuff).height + 200) > video_element_size.height) {
      // video is too small to fit all the edit stuff, so no do top padding :|
    } else {
      desired_top += 200; // make top amazon stuff visible, plus ability to see subs dropdown ...      
      // this is OK because it only blocks the icons in "editor" mode anyway...
    }
    desired_left -= 10; // avoid amazon x-ray so go offset from right
  }

  if (current_json == null) {
    // put "unedited" at the very very top :| hopefully less intrusive, doesn't interfere with the normal buttons there too
    desired_top = video_element_size.top;
  }
  desired_left = desired_left + "px"; // has to be this way apparently
  desired_top = desired_top + "px";
  if (parseInt(all_pimw_stuff.style.left) != parseInt(desired_left) || parseInt(all_pimw_stuff.style.top) != parseInt(desired_top)) { // youtube had some weird off by 0.001
    console.log("moving controls to top=" + desired_top + " left=" + desired_left);
    all_pimw_stuff.style.left = desired_left;
    all_pimw_stuff.style.top = desired_top;
  }
}

function currentTestAction() {
  return document.getElementById('action_sel').value;
}

function createFauxTagForCurrentUI() {
  var faux_tag = {
    start: humanToTimeStamp(document.getElementById('start').value),
    endy: humanToTimeStamp(document.getElementById('endy').value),
    default_action: currentTestAction(),
    is_test_tag: true, // just for debugging in the console purposes :)
    popup_text_after: document.getElementById('popup_text_after_id').value,
    default_enabled: document.getElementById('default_enabled_id').value == 'true',
    details: document.getElementById('details_input_id').value,
    id: parseInt(document.getElementById('tag_hidden_id').value), // not that we use it LOL
    category: document.getElementById('category_select_id').value,
    subcategory: document.getElementById('subcategory_select_id').value,
    impact_to_movie: document.getElementById('impact_to_movie_id').value,
    age_maybe_ok: document.getElementById('age_maybe_ok_id').value,
    lewdness_level: document.getElementById('lewdness_level_id').value,
    lip_readable: document.getElementById('lip_readable_id').value == 'true'
  }
  return faux_tag;
}

var faux_tag_being_tested = null;

function loadTagIntoUI(tag) {
  // a bit manual but...
  document.getElementById('start').value = timeStampToHuman(tag.start);
  document.getElementById('endy').value = timeStampToHuman(tag.endy);
  document.getElementById('action_sel').value = tag.default_action;
  document.getElementById('details_input_id').value = htmlDecode(tag.details);
  document.getElementById('popup_text_after_id').value = htmlDecode(tag.popup_text_after);
  document.getElementById('category_select_id').value = tag.category;
  categoryChanged(false);

  var subcat_select = document.getElementById('subcategory_select_id');
  var desired_value = htmlDecode(tag.subcategory);
  if (!selectHasOption(subcat_select, desired_value)) {
    alert("old subcat was " + desired_value + " please select a more updated one"); // don't just show blank which is frustrating and loses info :|
  }
  subcat_select.value = desired_value;
  subcategoryChanged(); // so it'll go to the right size, needed apparently, or send event?... :|
  document.getElementById('age_maybe_ok_id').value = tag.age_maybe_ok;
  document.getElementById('lewdness_level_id').value = tag.lewdness_level;
  document.getElementById('lip_readable_id').value = tag.lip_readable; // will come in as false for non profs...ah well...
  document.getElementById('impact_to_movie_id').value = tag.impact_to_movie; // sets it by number == index not the human readable [should all line up now...]
  document.getElementById('default_enabled_id').value = tag.default_enabled;
  document.getElementById('tag_hidden_id').value = tag.id;
  faux_tag_being_tested = null;
}

function testCurrentFromUiStart() {
  testCurrentFromUi(document.getElementById('start').value);
}

function testCurrentFromUiEnd() {
  if (currentTestAction() == 'skip') {
    // gotta test it from the beginning, not middle, else it rewinds too far, etc.
    testCurrentFromUiStart();
    return;
  }
  testCurrentFromUi(document.getElementById('endy').value);
}

function testCurrentFromUi(timeToTestString) {
  if (humanToTimeStamp(document.getElementById('endy').value) == 0) {
    document.getElementById('endy').value = getCurrentVideoTimestampHuman(); // assume they wanted to test till "right now" I did sometimes :)
  }
  var faux_tag = createFauxTagForCurrentUI();

  if (!doubleCheckActionTimestampSanityAndAlert(currentTestAction(), faux_tag.details, faux_tag.start, faux_tag.endy, true)) {
    return;
  }

  if (!faux_tag.default_enabled) {
    alert("tag is set to disabled, hard to test, please toggle on temporarily!");
    return;
  }

  var rewindSeconds = 1.5;
  var start = humanToTimeStamp(timeToTestString) - rewindSeconds;
  faux_tag_being_tested = faux_tag; // just concretize for now...i.e. if they hit "test" then save/keep saved one...seems to work OK :)
  doPlay(); // seems like I like it this way...
  seekToTime(start);
}

function uiTagDiffersFromOriginalAndThereIsOriginal() {
  if (uiTagIsNotInDb()) {
    return false; // no original
  }
  var original_tag = get_original_tag_of_ui();
  if (withinDelta(original_tag.start, faux_tag_being_tested.start, 0.01) && withinDelta(original_tag.endy, faux_tag_being_tested.endy, 0.01) && original_tag.default_action == faux_tag_being_tested.default_action) {
    return false;
  } else {
    return true;
  }
}

function getCurrentVideoTimestampHuman() {
  return timeStampToHuman(getCurrentTime());
}

function openTagStartingBefore(search_time) {
  var tag = getFirstTagStartingBefore(search_time);
  if (tag){
    loadTagIntoUI(tag);
  } else {
    alert("none found ending before current playback position");
  }
}
 
function reUseLastTagDetails() {
  var details_text_form = document.getElementById('details_input_id');
  var tag = getTagRightBeforeNowOrAlert();
  if (tag) {
    details_text_form.value = tag.details;
  }
}

function openTagPreviousToNowButton() {
  var tag = getTagRightBeforeNowOrAlert();
  if (tag) {
    loadTagIntoUI(tag);
  }
}

function getTagRightBeforeNowOrAlert() {
  var search_time = getCurrentTime();
  var tag = getFirstTagEndingBefore(search_time);
  if (tag){
    return tag;
  } else {
    alert("none found starting before current playback position");
    return null;
  }
}

function getFirstTagEndingBefore(search_time) { // somewhat duplicate but seemed distinct enough :|
  var all = getAllTagsNotIncludingReplacedFromUI();
  for (var i = all.length - 1; i >= 0; i--) {
    var tag = all[i];
    var start_time = tag.start;
    var end_time = tag.endy;
    if(end_time < search_time) {
      return tag;
    }
  }
  return null; // not found
}

function getFirstTagStartingBefore(search_time) { // somewhat duplicate but seemed distinct enough :|
  var all = getAllTagsNotIncludingReplacedFromUI();
  for (var i = all.length - 1; i >= 0; i--) {
    var tag = all[i];
    var start_time = tag.start;
    if(start_time < search_time) {
      return tag;
    }
  }
  return null; // not found
}

function openTagBeforeOneInUi() {
  if (!uiTagIsNotInDb()) {
    var search_time = createFauxTagForCurrentUI().start - 0.02; // get the next down... 0.01 wasn't enough once
    openTagStartingBefore(search_time);
  } else {
    openTagPreviousToNowButton();
  }
}

function openTagAfterOneInUi() {
  if (!uiTagIsNotInDb()) {
    var search_time = createFauxTagForCurrentUI().start + 0.02; // 0.01 wasn't enough once
    openFirstTagStartingAfter(search_time);
  } else {
    openNextTagButton();
  }
}

function openNextTagButton() {
  var search_time = getCurrentTime();
  openFirstTagEndingAfter(search_time); // want ending after so we can get the current...
}

function openFirstTagEndingAfter(search_time) {
  var next_tag = getFirstTagEndingAfter(search_time, getAllTagsNotIncludingReplacedFromUI());
  if (next_tag) {
    loadTagIntoUI(next_tag);
  }
  else {
    alert("none after the spot requested...");
  }
}

function openFirstTagStartingAfter(search_time) {
  var next_tag = getFirstTagStartingAfter(search_time, getAllTagsNotIncludingReplacedFromUI());
  if (next_tag) {
    loadTagIntoUI(next_tag);
  }
  else {
    alert("none after the spot requested...");
  }
}

function saveTagButton() {

  var endy = humanToTimeStamp(document.getElementById('endy').value);
  var start = humanToTimeStamp(document.getElementById('start').value);
  if (!doubleCheckFullFormAddRedAndAlert(true)) { // this used to be more of a "generic value" check...
    return;
  }
  if (endy > videoDuration()) {
    alert("tag goes past end of movie? aborting...");
    return;
  }

  var otherTags = allTagsExceptOneBeingEdited();
  for (var i = 0; i < otherTags.length; i++) {
     var otherTag = otherTags[i];
     if (is_overlapping(start, endy, otherTag.start, otherTag.endy)) {
       alert("warning: tag overlaps with other tag beginning at " + timeStampToHuman(otherTag.start) + 
         "that lasts " + timeStampToHuman(otherTag.endy - otherTag.start) + 
         " (this might be anticipated, if not, double check), saving...");
     }
   }

  var submit_form = document.getElementById('create_new_tag_form_id');
  submit_form.action = "https://" + request_host + "/save_tag/" + current_json.url.id; // allow request_host to change :| NB this goes to the *movie* id on purpose
  var reload_tags_link = document.getElementById('reloading_id');
  reload_tags_link.innerHTML = "saving..."; // :|
  submitFormXhr(submit_form, function(xhr) {
    clearForm();
    reloadForCurrentUrl("SAVED tag! "); // it's done saving so we can do this ja
  }, function(xhr) {
    alert("save didn't take? website down?");
    // and don't clear uh guess...
  });
}

function is_overlapping(x1,x2,y1,y2) {
  return Math.max(x1,y1) < Math.min(x2,y2);
}

function allTagsExceptOneBeingEdited() {
  var tags = current_json.tags; // we've already avoided getting the "temp tag" being parsed...
  var id_desired = document.getElementById('tag_hidden_id').value;
  if (id_desired == '0') {
    return tags;
  }
  tags = tags.slice(0); // clone since slice modifies the array :|
  for (var i = 0; i < tags.length; i++) {
    if (tags[i].id == parseInt(id_desired)) {
      tags.splice(i, 1); // remove it
      return tags;
    } 
  }
  alert("should never get here allTagsExceptOneBeingEdited");
}

function reloadTagButton() {
  var original_tag = get_original_tag_of_ui();
  loadTagIntoUI(original_tag);
}

function get_original_tag_of_ui() {
  var id_desired = document.getElementById('tag_hidden_id').value;
  if (id_desired == '0') {
    alert("can't reset if don't have tag loaded");
    return;
  }
  var tags = current_json.tags; // so it works if they have "Unedited" selected :|
  for (var i = 0; i < tags.length; i++) {
    if (tags[i].id == parseInt(id_desired)) {
      return tags[i];
    }
  }
  alert("should never see this please report 3 " + id_desired);
}

function clearButton() {
  clearForm();
  reloadForCurrentUrl('cleared!');
}

function clearForm() {
  document.getElementById('start').value = timeStampToHuman(0);
  document.getElementById('endy').value = timeStampToHuman(0);
  document.getElementById('popup_text_after_id').value = "";
  document.getElementById('details_input_id').value = "";
  //document.getElementById('age_maybe_ok_id').value = "0"; // tends to stay same
  document.getElementById('lewdness_level_id').value = "0";
  document.getElementById('lip_readable_id').value = "";
  document.getElementById('impact_to_movie_id').value = "0"; // force them to choose one
  document.getElementById('tag_hidden_id').value = '0'; // reset
  document.getElementById('default_enabled_id').value = 'true';

  document.getElementById('action_sel').dispatchEvent(new Event('change')); // so it'll set impact if mute...wait again?
  faux_tag_being_tested = null; // give up testing anything if anything happened to be doing so...
}

function destroyCurrentTagButton() {
  var id = document.getElementById('tag_hidden_id').value;
  if (id == '0') {
    alert("cannot destroy non previously saved tag"); // should be impossible I don't even think we show the button these days...
    return;
  }
  if (confirm("sure you want to nuke/remove from entire system this currently loaded tag?")) {
    window.open("https://" + request_host + "/delete_tag/" + id); // assume it works, and ja :| used so rarely haven't made it inline
    clearForm(true);
    setTimeout(function() { reloadForCurrentUrl('destroyed tag')}, 1000); // reload to get it "back" from the server after saved...longest I've seen like like 60ms
  }
}

function doneMoviePage() {
  window.open("https://" + request_host + "/edit_url/" + current_json.url.id + "?status=done");
}

//performance.setResourceTimingBufferSize(1000); // catch subtitles more consistently, seems to help, still needs a browser restart tho, or we could capture oveflow... :|

var old_subs = [];

performance.addEventListener('resourcetimingbufferfull', function (event) {
   //console.log("got timing event " + event);
   old_subs = old_subs.concat(getSubsFromCurrentPerformance());
   performance.clearResourceTimings(); // let it fill again, hope nobody else uses these!?? :|
   // NB we miss one here oh well! :| ?? :|
   // console.log("cleared performance list");
});

function getAllSubs() {
  return old_subs.concat(getSubsFromCurrentPerformance());
}

function getSubsFromCurrentPerformance() {
  var arr = window.performance.getEntries();
  var out = [];
  for (var i = arr.length - 1; i >= 0; --i) {
    // console.log(arr[i].name); http://m.amazon.com/yo.png or something.mp4
    var name = arr[i].name;
    if (name.endsWith(".dfxp") || name.endsWith(".ttml2")) { // ex: https://dmqdd6hw24ucf.cloudfront.net/341f/e367/03b5/4dce-9c0e-511e3b71d331/15e8386e-0cb0-477f-b2e4-b21dfa06f1f7.dfxp apparently https://dmqdd6hw24ucf.cloudfront.net/dbe4/26aa/fe6a/42c7-91c6-bb48d076306d/6d5a1b8b-52de-4da6-b351-8b35146d8165.ttml2
      out.push(arr[i]);
    }
  }
  return out;
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
  var subs = getAllSubs();
  if (subs.length > 0) {
    var response = prompt("this appears to be a subtitles url, copy this:", subs[0].name); // has a cancel prompt, but we don't care which button they use, we just want to give them something they can copy more easily! :)
  } else {
    alert("didn't find a subtitles file, try turning subtitles on, then try again");
  }
}

function stepFrameBack() {
  // doPause(); // TODO seems there's a bug where this is required if playing :|
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
  loadRequest(loadSucceeded, loadFailed);
}

function reloadForCurrentUrl(additional_string) {
  if (current_json != null) {
    console.log("submitting reload request...");
    var reload_tags_link = document.getElementById('reloading_id');
    reload_tags_link.innerHTML = additional_string + "-ing...";
    loadRequest(
      function(json_string) { reloadSucceeded(json_string, additional_string); },
      loadFailed // straight load failed since shouldn't ever happen, riiiight?
    );
  }
  else {
    alert("not reloading, possibly no edits loaded?"); // amazon already went to next episode?? server went down?
  }
}

function reloadSucceeded(json_string, additional_string) {
  loadSucceeded(json_string);
  var reload_tags_link = document.getElementById('reloading_id');
  reload_tags_link.innerHTML = additional_string;
  setTimeout(function() {reload_tags_link.innerHTML = "";}, 5000); // back to normal by clearing all text
}

function loadSucceeded(json_string) {
  parseSuccessfulJson(json_string);
  setEditsToUseFromSelectedPersonalizeDropdown();
  startWatcherTimerSingleton(); // don't know what to display before this...so leave everything none until now
  old_current_url = getStandardizedCurrentUrl();
  old_episode = liveEpisodeNumber();
  var expected_episode_number = current_json.url.episode_number;
  if (liveEpisodeNumber() != expected_episode_number) {
    alert("play it my way\ndanger: may have gotten wrong episode expected=" + expected_episode_number + " got=" + liveEpisodeNumber());
  }
  displayDiv(document.getElementById("load_succeeded_div_id"));
  if (current_json.editor) {
    displayDiv(document.getElementById("editor_top_line_div_id"));
  }
  hideDiv(document.getElementById("load_failed_div_id"));
  hideDiv(document.getElementById("server_down_div_id")); // in case it's a recovery now, server just came back up...
  setExtensionSmiley();
}

function doPeriodicChecks() {
  setEditedControlsToMovieRight();
}

function doRarePeriodicChecks() {
  // these take a bit o' cpu, do them even less often...
  addPluginEnabledTextOnce();
  checkIfEpisodeChanged();
  refreshVideoElement();
}

function addPluginEnabledTextOnce() {
  if (isAmazon() && current_json) {
    var span = document.getElementsByClassName("av-playback-messages")[0]; // just random from their UI
    span = span || document.getElementsByClassName("av-alert-inline")[0];
    if (span && !span.innerHTML.includes("it my way")) {
      var extra = "<br/><small>(Play it my way enabled! Disclaimer: Performance of the motion picture will be altered from the performance intended by the director/copyright holder, because play it my way enabled)";
      if (current_json.url.edit_passes_completed < 2) { // XXXX use the new status...somehow...??
        extra += " (not fully edited yet)";
      }
      extra += "</small";
      span.innerHTML += extra;
      console.log("added plugin enabled to amazon");
    }
  }
}

function setExtensionSmiley() {
  sendMessageToPlugin({text: "☺", color: "#008000", details: "Edited playback is enabled and fully operational for current video being played"}); // green
}

function loadFailed(status) {
  current_json = null;
  hideDiv(document.getElementById("load_succeeded_div_id"));
  displayDiv(document.getElementById("load_failed_div_id"));
  hideDiv(document.getElementById("server_down_div_id"));

  removeAllOptions(document.getElementById("tag_edit_list_dropdown_id")); // clean up...in case it matters...
  old_current_url = getStandardizedCurrentUrl();
  old_episode = liveEpisodeNumber();
  sendMessageToPlugin({color: "#A00000", text: "none", details: "No edited settings found for movie, not playing edited"}); // red
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
    // ?? just let it stay saying unedited :|
  }

  startWatcherTimerSingleton(); // so it can check if episode changes to one we like magically LOL [amazon...]
  console.log("got failure/ABSENT HTML response status=" + status);
}

function parseSuccessfulJson(json_string) {
  current_json = JSON.parse(json_string); // non var on purpose

  refreshPersonalizedDropdownOptions(current_json);

  var big_edited = document.getElementById("big_edited_text_id");
  if (current_json.url.edit_passes_completed == 2) {
    big_edited.innerHTML = "PIMW Edited";
  } else {
    big_edited.innerHTML = "PIMW Partially edited...";
    big_edited.setAttribute("x", "0"); // move it left so they can see all that text..
  }
  console.log("finished parsing response SUCCESS JSON");
}

function refreshPersonalizedDropdownOptions() {
  var dropdown = document.getElementById("tag_edit_list_dropdown_id");
  var old_selected = dropdown.value;
  removeAllOptions(dropdown); // out with any old...
  var option = document.createElement("option");
  option.text = "All tags (default) (" + countDoSomethingTags(current_json.tags) + ")";
  option.value = "-1"; // special case :|
  // I think this will start as selected...
  list_length = current_json.tag_edit_lists.length;
  if (list_length > 1) {
    // wait what? should be 1:1 these days...
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
  option.value = "-2"; // special case "unedited" :|
  dropdown.add(option);
  if (old_selected != "") {
    dropdown.value = old_selected; // preserve this across a save, but not for initially
  }
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
  current_tags_to_use = tags;
}

function personalizedDropdownChanged() {
  setEditsToUseFromSelectedPersonalizeDropdown();
}

function setEditsToUseFromSelectedPersonalizeDropdown() {
  var dropdown = document.getElementById("tag_edit_list_dropdown_id");
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
  alert("unable to select " + dropdown.value + "shouldn't get here ever");
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

var clean_stream_timer = null;

function startWatcherTimerSingleton() {
  if (!clean_stream_timer) {
    // 5 ms should be enough to "hit each 100th at least once"...until can spend more time on it? see TODO
    clean_stream_timer = setInterval(checkStatus, 5);
    // guess we just never turn interval off, on purpose :)
  }
}

function startOnce() {
  // sanity check
  refreshVideoElement();
  if (video_element == null) {
    // maybe could get here if they raw load the javascript?
    console.log("unable to find a video playing, not loading edited playback, should never get here...");
    setTimeout(startOnce, 500); // just retry forever :|
    return;
  }

  if (isGoogleIframe()) {
    if (!window.parent.location.pathname.startsWith("/store/movies/details") && !window.parent.location.pathname.startsWith("/store/tv/show")) {
      // iframe started from a non "details" page with full url
      alert('play it my way: failure: for google play movies, you need to right click on the title, choose "open link in new tab" for it to work edited in google play...');
      return; // avoid future prompts which don't matter anyway for now :|
    }
  }

  // ready to try and load the editor LOL
  console.log("adding edit UI, requesting for current URL...");

  addEditUiOnce(); // and only do once...but before we load anything so it can say "loading" I guess...
  loadForNewUrl(); // will eventually call startWatcherTimerSingleton
}

function videoCurrentlyBlackedByUs() {
  return video_element.style.visibility == "hidden";
}

function mouseJustMoved(event) {
  var cursorX = event.pageX;
  var cursorY = event.pageY;
  var mouse_within_all_pimw_stuff = pointWithinElement(cursorX, cursorY, all_pimw_stuff);
  var mouse_within_video = pointWithinElement(cursorX, cursorY, video_element) || videoCurrentlyBlackedByUs(); // middle of yes_audio_no_video still show our stuff, amazon's does this...
  var enough_focus = isAmazon() || document.hasFocus(); // only enforce this for youtube :|
  if (!mouse_move_timer || (mouse_within_video && enough_focus)) {
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
  if (!isYoutubePimw() && (!window.navigator.userAgent.includes("PlayItMyWay"))) { // don't hide it in android app, too hard to do edits elsewise [wait do I want that?]
    hideDiv(all_pimw_stuff);
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
  console.log("doing doPause paused=" + video_element.paused + " buffered=" + twoDecimals(getSecondsBufferedAhead()));
  if (isYoutubePimw()) {
    youtube_pimw_player.pauseVideo();
  } else {
    video_element.pause();
  }
  pause_since_requested = true;
}

function rawRequestSeekToTime(ts, already_cached, current_time) {
  console.log("about to do rawRequestSeekToTime=" + twoDecimals(ts));
  console.log("rawRequestSeekToTime paused=" + video_element.paused + " readyState=" + video_element.readyState + " buffered_was=" + twoDecimals(getSecondsBufferedAhead()));

  if (isYoutubePimw()) {
    var allowSeekAhead = true; // "allow to seek past buffered" but doesn't quite work well iOS?
    var ios = on_ios();
    if (already_cached || !ios) {
      youtube_pimw_player.seekTo(ts, allowSeekAhead); // no callback option seemingly...can take floats...
    } else {
      console.log("iOS and not cached skipping waaay forward"); // TODO test
      // TODO if it's within 5s just "wait" to see if it'll buffer itself???
      // make tiny then seek? :|
      // attempt avoid infinite loop, and also skipping to bad scenes :|
       // 5.3 seemed max key frame length :|
      // if they seek 2 in future -> 2 + 5.3
      // if they seek 7 in the future -> 7 + 5.3 TODO what if that's also a bad part?! At least we'll skip past it quickly'ish...
      var desired = ts + 5.3;
      if (ts < current_time) {
        desired = ts; // seek backwards, hope for the best!
        // TODO check if the 5s surrounding it is clean?!
      }
      // TODO seek to precise, hide it, wait for it to buffer then... :|
      youtube_pimw_player.seekTo(desired, allowSeekAhead);
    }
  } else {
    if (isAmazon()) {
      video_element.currentTime = ts + 10;
    } else {
      // really raw HTML5 :) XXX iOS ? :|
      video_element.currentTime = ts;
    }
  }
}

function getSecondsBufferedAhead() {
  var cur_time = getCurrentTime();
  var seconds_buffered;
  if (isYoutubePimw()) {
    seconds_buffered = youtube_pimw_player.getDuration() * youtube_pimw_player.getVideoLoadedFraction() - cur_time;
  } else if (video_element.buffered.length > 0) { // amazon is this way...but not always...
    cur_time = video_element.currentTime; // use raw time since amazon is += 10... :| XXX annoying/lame...
    for (var i = 0; i < video_element.buffered.length; i++) {
      if(video_element.buffered.start(i) <= cur_time && video_element.buffered.end(i) >= cur_time) {
        seconds_buffered = (video_element.buffered.end(0) - cur_time); // it reports buffered as "10s ago until 10s from now" or what have you
      }
    }
    if (!seconds_buffered) {
      // happens when it seeks way ahead and the buffering hasn't even caught up at all yet, amazon...
      console.log("html5 says it has buffered but not around current timestamp?");
      seconds_buffered =- 1;
    }
  } else {
    console.log("uninitialized html5 perhaps? nothing buffered?" + video_element.buffered);
    seconds_buffered = -1;
  }
  return seconds_buffered;
}

var save_seek_ts;

function seekToTime(seek_to_ts, callback) {
  if (seek_timer) {
    console.log("still seeking from previous_requested=" + save_seek_ts + ", not trying that again...new_requested_was=" + seek_to_ts);
    return;
  }
  save_seek_ts = seek_to_ts;

  if (seek_to_ts < 0) {
    console.log("not seeking to before 0, seeking to 0 instead, seeking to negative doesn't work well " + seek_to_ts);
    seek_to_ts = 0;
  }
  // try and avoid freezes after seeking...if it was playing first...
  var current_time = getCurrentTime();
  var seeked_from_time = getCurrentTime();
  console.log("seeking to " + timeStampToHuman(seek_to_ts) + " from=" + timeStampToHuman(current_time) + " readyState=" + video_element.readyState + " to_ts=" + twoDecimals(seek_to_ts) + " from_ts=" + twoDecimals(current_time));
  // [amazon] if this is far enough away from current, it also implies a "play" call...oddly. I mean seriously that is bizarre.
  // however if it close enough, then we need to call play
  // some shenanigans to pretend to work around this...
  var did_preseek_pause = false; // youtube loses 0.05 with these shenanigans needed on amazon, so attempt avoid :|
  var already_cached = seek_to_ts > getCurrentTime() && seek_to_ts < (getCurrentTime() + getSecondsBufferedAhead() - 1); // 0.4 seemed to really quite fail in amazon
  if (isAmazon() && !isPaused() && !already_cached) {
    doPause(); // amazon just seems to need this, no idea why...
    console.log("doing preseek pause seek_to_ts=" + seek_to_ts);
    did_preseek_pause = true;
  }
  rawRequestSeekToTime(seek_to_ts, already_cached, current_time);

  if (already_cached && !isYoutubePimw()) { // youtube a "raw request" doesn't actually change the time instantaneously...always use polling with callback so we can have the logic work out more eaisly...
    if (callback) {
      console.log("quick seek assuming possible since cached...");
      callback(); // scawah?? but thought it might be useful in case we "seek into" another seek...etc...seems to work OK...
    }
  } else {
    seek_timer_callback = function() {
        check_if_done_seek(seeked_from_time, seek_to_ts, did_preseek_pause, callback);
    };
    seek_timer = setInterval(seek_timer_callback, 25);
  }
}

// purpose of this mostly is to not hit play before amazon thought we "could"
function check_if_done_seek(seeked_from_time, seek_to_ts, did_preseek_pause, callback) {
  if (isYoutubePimw()) {
    console.log("check_if_done_seek youtube_player_state=" + youtube_pimw_player.getPlayerState());
    var done_buffering = (youtube_pimw_player.getPlayerState() == YT.PlayerState.PAUSED); // This "might" mean done buffering :| [we pause it ourselves first...hmm...maybe don't have to?]
  } else {
    var done_buffering = videoNotBuffering();
  }
  if ((isPaused() && done_buffering) || !isPaused()) { // !isPaused meaning if it went on ahead already and is leaving us in the dust... for HTML5 got this once...maybe !isPaused implies done buffering there? gah...to repro in big buck test an edit at min 2 from just loaded...
    var seconds_buffered = getSecondsBufferedAhead();

    if (seconds_buffered > 2 || !isPaused()) { // usually buffers 4 or 6...it auto plays if within buffered [amazon]
      // success
      console.log("appears it just finished seeking successfully to " + timeStampToHuman(seek_to_ts) + " seek_to_ts=" + seek_to_ts + " length_was=" + twoDecimals(seek_to_ts - seeked_from_time) + " buffered_ahead=" 
          + twoDecimals(seconds_buffered) + " from=" + twoDecimals(seeked_from_time) + " cur_time_actually=" + twoDecimals(getCurrentTime()) + " readyState=" + video_element.readyState);
      if (did_preseek_pause) {
        doPlay();
        make_sure_does_not_get_stuck_after_play(); // doPlay isn't always enough sadly...and then it gets stuck in this weird half paused state :| hopefully rare!
      } else {
        console.log("not doing doPlay or make sure does not get stuck after seek because !did_preseek_pause just kidding actually doing it");
        make_sure_does_not_get_stuck_after_play();
      }
      clearInterval(seek_timer);
      if (callback) {
        callback(); // just too scary to poll to see if play "actually worked" can't wait for it!
      }
      seek_timer = null;
    } else {
      console.log("waiting for it to finish buffering after seek seconds_buffered=" + twoDecimals(seconds_buffered) + " seek_to_ts=" + seek_to_ts + " cur_time_actually=" + twoDecimals(getCurrentTime()));
      if (did_preseek_pause) {
        doPlay(); // das boot 2:05'ish needed this...whaat? I think we were sending play too early...but why? <sigh>
      }
    }
  } else {
    console.log("seek_timer interval [i.e. still seeking...] paused=" + isPaused() + " seek_to_ts=" + seek_to_ts + " readyState=" + video_element.readyState + " cur_time=" + getCurrentTime());
  }
}

function spinner_present() {
  var elements = document.getElementsByClassName('loadingSpinner');
  len = elements.length;
  for (i=0; i<len; ++i) {
    var s = elements[i];
    if (s.style.display != "none") {
      return true;
    }
  }
  return false;
}

function make_sure_does_not_get_stuck_after_play() {
  pause_since_requested = false; // needed for our quick pauses :|
  var start = new Date().getTime();
  var timer = setInterval(function() {
    var millisPassed = (new Date().getTime()) - start;
    console.log("millisPassed waiting for it to play=" + millisPassed + " paused=" + isPaused() + " spinner_present=" + spinner_present());
    // it's either check for spinner or...uh...could we check for this earlier??????? and avoid this? but without introducing any possible latencies???
    if ((!isPaused() || pause_since_requested) && !spinner_present()) {
      console.log("detected it did not get stuck after play (or recovered)");
      clearInterval(timer); // we're done
    }
    if (millisPassed > 1500) {
      console.log("EMERGENCY seemed to still be stuck after play, beep beep");
      doPause(); // needed to get rid of that annoying twisting circle seemingly...
      doPlay();
      start = new Date().getTime(); // start timer over...
    }
  }, 25); // poll it so we can detect "oh it worked once but then was legit paused after"
}

function displayDiv(div) { // who needs jQuery :)
  div.style.display = "block";
}

function toggleDiv(div) {
  if (div.style.display == "block" ) { // only works if specified initially with style: block to avoid some formatting cdonfusion...
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
    title = youtubeChannelName() + title; // more info the better! :)
  }
  return title;
}

function liveFullNameEpisode() {
  return liveTitleNoEpisode() + liveEpisodeString();
}

<%= File.read("generic_javascript_helpers.js") %>

// no jquery setup here since this page might already have its own jQuery loaded, so don't load/use it to avoid any conflict.  [bonus: speed's up our load time]

// on ready just in case here LOL
onReady(startOnce);
