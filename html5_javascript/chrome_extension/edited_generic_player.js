//auto-generated file
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
var mutes, skips, yes_audio_no_videos, do_nothings, mute_audio_no_videos;
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
      <a href=# onclick="addForNewVideo(); return false;">Play it My Way: Click here to add to the system...</a>
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
      Feedback? <a href=# onclick="reportProblem(); return false;">Let us know!</a>
      <div style="display: inline-block"> <!-- prevent line feed before this div -->
        <div id="editor_top_line_div_id" style="display: none;"> <!-- we enable if flagged as editor -->
           Or <a href=# onclick="toggleAddNewTagStuff(); return false;">[editor add tag]</a>
        </div>
      </div>
  	</div>
    <div id="tag_details_div_id"  style='display: none;'>
    	<span id=add_edit_span_id_for_extra_message><!-- currently: muting [or a <br/>] --></span>
    	<div id='tag_layer_top_line'>
    		<span id="top_line_current_time" />
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
      <input type='button' onclick="seekToTime(video_element.currentTime + 30); return false;" value='+30s'/> 
      <input type='button' onclick="seekToBeforeSkip(-5); return false;" value='-5s'/>
      <input type='button' onclick="seekToTime(video_element.currentTime + 5); return false;" value='+5s'/> 
      <input type='button' onclick="stepFrameBack(); return false;" value='frame-'/>
      <input type='button' onclick="stepFrame(); return false;" value='frame+'/>

      <br/>
      <input type='button' onclick="playButtonClicked(); video_element.playbackRate = 0.5; return false;" value='0.5x'>
      <input type='button' onclick="video_element.playbackRate -= 0.1; return false;" value='&lt;&lt;'/>
      <span ><a id='playback_rate' href=# onclick="video_element.playbackRate = 1; return false">1.00x</a></span> <!--XX remove link -->
      <input type='button' onclick="video_element.playbackRate += 0.1; return false;" value='&gt;&gt;'/>
      <input type='button' onclick="pauseVideo(); return false;" value='&#9612;&#9612;'/>
      <input type='button' onclick="playButtonClicked(); return false;" value='&#9654;'>
      
      
       <br/>
        action:
        <select name="default_action" id='action_sel' onchange="">
          <option value="mute">mute</option>
          <option value="skip">skip</option>
          <option value="yes_audio_no_video">yes_audio_no_video</option>
          <option value="mute_audio_no_video">mute_audio_no_video</option>
          <option value="do_nothing">do_nothing (just tag)</option>
        </select>
        <input type='submit' value='Test edit locally' onclick="testCurrentFromUi(); return false">
        <br/>
        <br/>        
        
<div id="category_div_id">
<select name="category" id='category_select' onchange="showSubCatWithRightOptionsAvailable(); document.getElementById('subcategory_select_id').value = ''; // reset subcat in case cat changed "
style="background-color: rgba(255, 255, 255, 0.85);" >
  <option value="" disabled selected>unknown -- please select category</option>
  <option value="profanity">profanity (verbal attacks, anything spoken)</option>
  <option value="violence">violence/blood/crude action etc.</option>
  <option value="physical">sex/nudity/lewd etc.</option>
  <option value="suspense">suspense (frightening, scary fighting, surprise)</option>
  <option value="substance-abuse">substance use</option>
  <option value="movie-content">movie content (credits, etc.)</option>
</select>
</div>

<div id="subcategory_div_id">
sub cat:
<select name="subcategory" id='subcategory_select_id' style="background-color: rgba(255, 255, 255, 0.85);" onchange="resizeToCurrentSize(this);">
    <option value="">unknown -- please select subcategory</option>
    
      <option value="initial theme song">movie-content -- initial theme song/credits</option>    
    
      <option value="closing credits">movie-content -- closing credits/songs</option>    
    
      <option value="subscription plea">movie-content -- closing subscription plea</option>    
    
      <option value="joke edit">movie-content -- joke edit -- edits that make video funny when applied</option>    
    
      <option value="movie content morally questionable choice">movie-content -- morally questionable choice</option>    
    
      <option value="raucous music">movie-content -- raucous music</option>    
    
      <option value="movie content other">movie-content -- other</option>    
    
      <option value="loud noise">profanity -- loud noise/screaming</option>    
    
      <option value="personal insult mild">profanity -- insult &#40;&quot;moron&quot;, &quot;idiot&quot; etc.&#41;</option>    
    
      <option value="personal attack mild">profanity -- attack command &#40;&quot;shut up&quot; etc.&#41;</option>    
    
      <option value="being mean">profanity -- being mean/cruel to another</option>    
    
      <option value="derogatory slur">profanity -- categorizing derogatory slur</option>    
    
      <option value="crude humor">profanity -- crude humor, like poop, bathroom, gross, etc.</option>    
    
      <option value="bodily part reference mild">profanity -- bodily part reference mild &#40;butt, bumm, suck...&#41;</option>    
    
      <option value="bodily part reference harsh">profanity -- bodily part reference harsh &#40;balls, etc.&#41;</option>    
    
      <option value="sexual reference">profanity -- sexual innuendo/reference</option>    
    
      <option value="violence reference">profanity -- violence reference</option>    
    
      <option value="euphemized profanities">profanity -- euphemized profanities &#40;ex: crap, dang, gosh dang&#41;</option>    
    
      <option value="lesser expletive">profanity -- other lesser expletive ex &quot;bloomin&#39;&quot; etc.</option>    
    
      <option value="deity religious context">profanity -- deity use in religious context like &quot;the l... is good&quot;</option>    
    
      <option value="deity reference">profanity -- deity use appropriate but non religious context like &quot;in this game you are G...&quot;</option>    
    
      <option value="deity exclamation mild">profanity -- deity exclamation mild like Good L...,</option>    
    
      <option value="deity greek">profanity -- deity greek &#40;Zeus, etc.&#41;</option>    
    
      <option value="deity foreign language">profanity -- deity different language, like Allah or French equivalents, etc</option>    
    
      <option value="deity exclamation harsh">profanity -- deity exclamation harsh, name of the Lord &#40;omg, etc.&#41;</option>    
    
      <option value="deity expletive">profanity -- deity expletive &#40;es: goll durn, the real words&#41;</option>    
    
      <option value="personal insult harsh">profanity -- insult harsh &#40;son of a ..... etc.&#41;</option>    
    
      <option value="a word">profanity -- a.. &#40;and/or followed by anything&#41;</option>    
    
      <option value="d word">profanity -- d word</option>    
    
      <option value="h word">profanity -- h word</option>    
    
      <option value="s word">profanity -- s word</option>    
    
      <option value="f word">profanity -- f-bomb expletive</option>    
    
      <option value="f word sex connotation">profanity -- f-bomb sexual connotation</option>    
    
      <option value="profanity foreign language">profanity -- any other profanity different language, French, etc</option>    
    
      <option value="profanity &#40;other&#41;">profanity -- other</option>    
    
      <option value="light fight">violence -- short fighting &#40;single punch/kick/hit/push&#41;</option>    
    
      <option value="threatening actions">violence -- threatening actions</option>    
    
      <option value="stabbing/shooting no blood">violence -- stabbing/shooting no blood</option>    
    
      <option value="stabbing/shooting with blood">violence -- stabbing/shooting yes blood</option>    
    
      <option value="visible blood">violence -- visible blood &#40;ex: blood from wound&#41;</option>    
    
      <option value="visible wound">violence -- visible wound &#40;no gore, light gore&#41;</option>    
    
      <option value="open wounds">violence -- visible gore &#40;ex: open wound&#41;</option>    
    
      <option value="crudeness">violence -- crude actions, grossness, etc.</option>    
    
      <option value="collision">violence -- collision/crash &#40;no implied death&#41;</option>    
    
      <option value="collision death">violence -- collision/crash &#40;implied death&#41;</option>    
    
      <option value="explosion">violence -- explosion &#40;no implied death&#41;</option>    
    
      <option value="explosion death">violence -- explosion &#40;implied death&#41;</option>    
    
      <option value="sustained fight">violence -- sustained punching/fighting</option>    
    
      <option value="comedic fight">violence -- comedic/slapstick fighting</option>    
    
      <option value="shooting miss">violence -- shooting miss or ambiguous</option>    
    
      <option value="shooting hit non death">violence -- shooting hits person or thing but non fatal</option>    
    
      <option value="killing">violence -- killing on screen &#40;ex: shooting death fatal&#41;</option>    
    
      <option value="non human killing">violence -- non human killing/death on screen &#40;ex: animal, or robot&#41;</option>    
    
      <option value="killing offscreen">violence -- killing off screen &#40;ex: shooting death off screen&#41;</option>    
    
      <option value="circumstantial death">violence -- death non-killing, ex: accidental falling</option>    
    
      <option value="hand gesture">violence -- hand gesture</option>    
    
      <option value="sports violence">violence -- sports violence part of game</option>    
    
      <option value="rape">violence -- rape</option>    
    
      <option value="dead body">violence -- dead body visible lifeless</option>    
    
      <option value="violence &#40;other&#41;">violence -- other</option>    
    
      <option value="art nudity">physical -- art based nudity</option>    
    
      <option value="revealing clothing">physical -- revealing clothing &#40;scantily clad&#41;</option>    
    
      <option value="revealing cleavage">physical -- revealing cleavage</option>    
    
      <option value="partial nudity">physical -- partial nudity &#40;ex: excessive cleavage&#41;</option>    
    
      <option value="nudity posterior male">physical -- nudity &#40;posterior&#41; male</option>    
    
      <option value="nudity posterior female">physical -- nudity &#40;posterior&#41; female</option>    
    
      <option value="nudity anterior male">physical -- nudity &#40;anterior&#41; male</option>    
    
      <option value="nudity anterior female">physical -- nudity &#40;anterior&#41; female</option>    
    
      <option value="nudity breast">physical -- nudity &#40;breast&#41;</option>    
    
      <option value="shirtless male">physical -- shirtless male &#40;non sexual&#41;</option>    
    
      <option value="kissing peck">physical -- kiss &#40;peck&#41;</option>    
    
      <option value="kissing passionate">physical -- kiss &#40;passionate&#41;</option>    
    
      <option value="sexually charged scene">physical -- sexually charged scene</option>    
    
      <option value="sex foreplay">physical -- sex foreplay</option>    
    
      <option value="implied sex">physical -- implied sex</option>    
    
      <option value="explicit sex">physical -- explicit sex</option>    
    
      <option value="homosexual behavior">physical -- homosexual behavior &#40;kissing, holding hands, light stuff&#41;</option>    
    
      <option value="physical &#40;other&#41;">physical -- other</option>    
    
      <option value="alcohol">substance-abuse -- alcohol drinking</option>    
    
      <option value="smoking">substance-abuse -- smoking legal stuff &#40;cigar, cigarette&#41;</option>    
    
      <option value="smoking illegal">substance-abuse -- smoking illegal drugs</option>    
    
      <option value="drugs">substance-abuse -- illegal drug use</option>    
    
      <option value="drug injection">substance-abuse -- drug use injection</option>    
    
      <option value="substance-abuse other">substance-abuse -- other</option>    
    
      <option value="frightening/startling scene/event">suspense -- frightening/startling scene/event</option>    
    
      <option value="suspenseful fight &quot;will they win?&quot;">suspense -- suspenseful fight &quot;will they win?&quot;</option>    
    
      <option value="suspense other">suspense -- other</option>    
    
</select>
</div>

<select id="hidden_select_id" style="display : none;"> <!-- needed/re-used for resizing subcats :| -->
 <option id="hidden_select_option_id"></option>
</select>

age specifier (optional):
<select name="age_maybe_ok" id="age_maybe_ok_id">
  <option value="0">not applicable/needed</option>
  
    <option value="3">not OK age 3 and under</option>
  
    <option value="6">not OK age 6 and under</option>
  
    <option value="9">not OK age 9 and under</option>
  
    <option value="12">not OK age 12 and under</option>
  
    <option value="15">not OK age 15 and under</option>
  
  <option value="-1">no age OK</option>
</select>
<br/>

Impact to Story if edited:
  <select name="impact_to_movie" id="impact_to_movie_id">
    <option value="0">please select impact</option>
    
      <option value="1">1/10</option>
    
      <option value="2">2/10</option>
    
      <option value="3">3/10</option>
    
      <option value="4">4/10</option>
    
      <option value="5">5/10</option>
    
      <option value="6">6/10</option>
    
      <option value="7">7/10</option>
    
      <option value="8">8/10</option>
    
      <option value="9">9/10</option>
    
      <option value="10">10/10</option>
    
  </select>

<br/>
tag details
<input type="text" name="details" id="details_input_id" size="30" value="" style="background-color: rgba(255, 255, 255, 0.85);"/>

<br/>
popup text
<input type="text" name="popup_text_after" id="popup_text_after_id" size="30" value="" style="background-color: rgba(255, 255, 255, 0.85);" placeholder="use with caution" />


<!-- can't put javascript since don't know how to inject it quite right in plugin, though I could use a separate render... -->
 <!-- render here cuz needs/uses macro -->
        <br/>
        <input type='submit' value='Save This Tag' onclick="saveEditButton(); return false;">
        <input type='submit' value='Re-Edit Prev Tag' id='open_prev_tag_id' onclick="openPreviousTagButton(); return false;">
        <input type='submit' value='Re-Edit Next Tag' id='open_next_tag_id' onclick="openNextTagButton(); return false;">
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
}

function playButtonClicked() {
  if (video_element.paused) {
    video_element.play();
  } else if (video_element.playbackRate != 1) {
    video_element.playbackRate = 1; // back to normal :)
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
	pauseVideo();
}

function reportProblem() {
  window.open("http://freeldssheetmusic.org/questions/ask?pre_fill=" + encodeURIComponent("url=" + getStandardizedCurrentUrl()));
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
var last_timestamp = 0;

function checkIfShouldDoActionAndUpdateUI() {
	var cur_time = video_element.currentTime;
  var tag;
  if (cur_time < last_timestamp) {
    console.log("Something just seeked backwards to=" + cur_time);
  	tag = areWeWithin(skips, cur_time); 
    if (tag) {
      // was the seek to within an edit? Since this was a "rewind" let's actually go to *before* the bad spot, so the -10 button can work from UI
      console.log("they just seeked backward to within a skip, rewinding more...");
      seekToBeforeSkip(0);
      return;
    }
  }
  last_timestamp = cur_time;
  
	tag = areWeWithin(mutes, cur_time);
  tag = tag || areWeWithin(mute_audio_no_videos, cur_time);
  extra_message = "";
	if (tag) {
	  if (!video_element.muted) {
	    video_element.muted = true;
      i_muted_it = true;
	    timestamp_log("muting", cur_time, tag);
	  }
   extra_message += "muting";
   notify_if_new(tag);
	}
	else {
	  if (video_element.muted) {
      if (i_muted_it) {
  	    video_element.muted = false;
  	    console.log("unmuted at=" + cur_time);
        i_muted_it = false;      
      }
	  }
	}
	
	tag = areWeWithin(skips, cur_time);
	if (tag) {
	  timestamp_log("seeking", cur_time, tag);
    optionally_show_notification(tag); // show it now so it can notify while it seeks :)
	  seekToTime(tag.endy);
	}
	
	tag = areWeWithin(yes_audio_no_videos, cur_time);
  tag = tag || areWeWithin(mute_audio_no_videos, cur_time);
	if (tag) {
		// use style.visibility here so it retains the space on screen it would have otherwise used...
	  if (video_element.style.visibility != "hidden") {
	    timestamp_log("hiding video leaving audio ", cur_time, tag);
	    video_element.style.visibility="hidden";
	  }
    extra_message += "doing a no video yes audio";
    notify_if_new(tag);
	}
	else {
	  if (video_element.style.visibility != "") {
	    video_element.style.visibility=""; // non hidden :)
	    console.log("unhiding video with left audio " + cur_time);
	  }
	}

	var new_top_line = timeStampToHuman(cur_time);
  var next_future_tag = getNextTagAfterOrWithin(video_element.currentTime);
  if (next_future_tag) {
    tag_layer_top_line += " next: " + timeStampToHuman(next_future_tag.start) + " (" + next_future_tag.default_action + " for " + (next_future_tag.endy - next_future_tag.start).toFixed(2) + "s)";
    document.getElementById("open_next_tag_id").style.visibility = "visible";
  }
  else {
    document.getElementById("open_next_tag_id").style.visibility = "hidden";
  }
  updateHTML(document.getElementById('top_line_current_time'), new_top_line);
  var message = "";
  if (extra_message != "") {
    message = "Currently:" + extra_message; // prefix
  } else {
    message = "<br>"; // can't use <br/> since it gets sanitized out so can't detect changes right FWIW :|
  }
  updateHTML(document.getElementById("add_edit_span_id_for_extra_message"), message);
  updateHTML(document.getElementById("playback_rate"), video_element.playbackRate.toFixed(2) + "x");
  purgeOldNotifyTags(cur_time); // if we "just got past them"
}

function purgeOldNotifyTags(cur_time) {
  for (var tag of currently_in_process_tags.keys()) {
    if (!areWeWithin([tag], cur_time)) {
      console.log("removing done notify " + JSON.stringify(tag));
      currently_in_process_tags.delete(tag);
    }
  }
}

function notify_if_new(tag) {
  if (currently_in_process_tags.get(tag)) {
    // already in there, do nothing
  } else {
    currently_in_process_tags.set(tag, true);
    console.log("optional notify");
    optionally_show_notification(tag);
  }
}

function optionally_show_notification(seek_tag) {
  var popup = seek_tag.popup_text_after;
  if (popup.length > 0) {
    console.log("notifying " + popup);
    // TODO do this for more than skip...
    var maxTitleSize = 45; // max 45 for title OS X 49 for body
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
    sendMessageToPlugin({notification_desired: {title: title, body: body}});
  }
}

function updateHTML(div, new_value) {
  if (div.innerHTML != new_value) {
    div.innerHTML = new_value;
  }
}

function isWatchingAdd() {
  if (url != null) {
		if (current_json.url.total_time > 0 && !withinDelta(current_json.url.total_time, video_element.duration, 2)) {
			console.log("watching add?");
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

function checkStatus() {
	// avoid unmuting videos playing that we don't even control [like youtube main page] with this if...
  if (url != null) {
		if (isWatchingAdd()) {
			console.log("watching add?");
			// and do no mutes etc...
		}
		else {
      checkIfShouldDoActionAndUpdateUI();
		}
	}
  checkIfEpisodeChanged();
  video_element = findFirstVideoTagOrNull() || video_element; // refresh it in case changed, but don't switch to null between clips :|
	setEditedControlsToMovieRight(); // in case something changed [i.e. amazon moved their video element into "on screen" :| ]
}

function timestamp_log(message, cur_time, tag) {
  local_message = message + " at " + cur_time + " start:" + tag.start + " will_end:" + tag.endy + " in " + (tag.endy - cur_time)+ "s";;
  console.log(local_message);
}

function seekToBeforeSkip(delta) {
  var desired_time = video_element.currentTime + delta;
	var tag = areWeWithin(skips, desired_time);  
  if (tag) {
    console.log("would have sought to middle of " + JSON.stringify(tag) + " going back further instead");
    seekToBeforeSkip(tag.start - (video_element.currentTime) - 2); // method, in case we run into another'un right there ... :|
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
  // or current_json.tags; // sorted :|
  var all = mutes.concat(skips);
  all = all.concat(yes_audio_no_videos);
  all = all.concat(mutes);
  // this way doesn't include do_nothings on purpose...
  all.sort(compareTagStarts);
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

function addForNewVideo() {
	if (getStandardizedCurrentUrl().includes("youtube.com/user/")) {
		alert("this is a youtube user page, we don't support those yet, click through to a particular video first");
		// XXXX more generic here somehow possible???
		// TODO don't even offer to edit it for them on that page [?] and other pages where it's impossible today [facebook]?
	}
	else {
    window.open("https://" + request_host + "/new_url_from_plugin?url=" + encodeURIComponent(getStandardizedCurrentUrl()) + "&episode_number=" + liveEpisodeNumber() + "&episode_name="  +
		      encodeURIComponent(liveEpisodeName()) + "&title=" + encodeURIComponent(liveTitleNoEpisode()) + "&duration=" + video_element.duration, "_blank");
		setTimeout(loadForNewUrl, 4000); // it should auto save so we should be live within 2s I hope...if not they'll get the same prompt [?] :|					
    // once took longer than 2000 :|
		pauseVideo();
	}  
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
  if (currentTestAction() == 'do_nothing') {
    alert('testing a do nothing is hard, please set it to yes_audio_no_video, test it, then set it back to do_nothing, before hitting save button');
    return; // abort
  }
	if (inMiddleOfTestingTimer) {
    doTimeoutEarly(inMiddleOfTestingTimer); // nulls it out for us
	}
  if (humanToTimeStamp(document.getElementById('endy').value) == 0) {
    document.getElementById('endy').value = getCurrentVideoTimestampHuman(); // assume they wanted to test till "right now"
  }
	var faux_tag = {
		start: humanToTimeStamp(document.getElementById('start').value),
		endy: humanToTimeStamp(document.getElementById('endy').value),
    default_action: currentTestAction(),
    is_test_tag: true,
    popup_text_after: document.getElementById('popup_text_after_id').value
	}
  if (faux_tag.endy <= faux_tag.start) {
    alert("appears your end is before or equal to your start, please adjust timestamps, then try again!");
    return; // abort!
  } 
  var temp_array = currentEditArray();
  temp_array.push(faux_tag);
  
  var rewindSeconds = 2;
  var start = faux_tag.start - rewindSeconds;
  if (start < 0) {
    start = 0; // allow test edits to start at or near 0 without messing up the "done" timing...
  }
  seekToTime(start, function() {
	  length = faux_tag.endy - start;
	  if (currentTestAction() == 'skip') {
	    length = 0; // it skips it, so the amount of time before being done is less :)
		}
	  wait_time_millis = (length + rewindSeconds + 0.5) * 1000;
    video_element.play(); // seems like we want this, plus otherwise mess up the test timing [?]
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
    case 'do_nothing':
      return do_nothings;
    case 'mute_audio_no_video':
      return mute_audio_no_videos;
    default:
      alert('internal error 1...' + currentTestAction()); // hopefully never get here...
  }
}

function getCurrentVideoTimestampHuman() {
  return timeStampToHuman(video_element.currentTime);
}

function openPreviousTagButton() {
  var timeSearch = video_element.currentTime;
  while (timeSearch > 0) {
    var next_tag = getNextTagAfterOrWithin(timeSearch);
    if (next_tag && (next_tag.endy < video_element.currentTime)) {
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
  var next_tag = getNextTagAfterOrWithin(video_element.currentTime);
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
  
  if (endy > video_element.duration) {
    alert("tag goes past end of movie? aborting...");
    return;
  }

  document.getElementById('create_new_tag_form_id').action = "https://" + request_host + "/save_tag/" + url.id;
  document.getElementById('create_new_tag_form_id').submit();

  // reset so people don't think they can tweak and resave...
	document.getElementById('start').value = timeStampToHuman(0);
  document.getElementById('endy').value = timeStampToHuman(0);
  document.getElementById('tag_details_div_id').value = "";
  document.getElementById('details_input_id').value = "";
  // don't reset category since I'm not sure if the javascript handles its going back to ""
  document.getElementById('subcategory_select_id').selectedIndex = 0; // use a present value so size doesn't go to *0*
  showSubCatWithRightOptionsAvailable(); // resize it back
  document.getElementById('age_maybe_ok_id').value = "0";
  document.getElementById('impact_to_movie_id').value = "0";
  setImpactIfMute(); // or set it to 1
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
  seekToTime(video_element.currentTime - 1/10, function () { // go back 2 frames, 1 seems hard...
    video_element.pause();
  });
}

function stepFrame() {
  video_element.play();
  setTimeout(function() {
    video_element.pause(); 
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
      setTimeout(function() {link.innerHTML = "Reload tags";}, 3000);
    }, loadFailed);
  }
	else {
		alert("not reloading, possibly none loaded or in middle of a test edit [hit browser reload button if the latter]");
	}
}

function loadSucceeded(json_string) {
  parseSuccessfulJson(json_string);
	getEditsFromCurrentTagList();
  startWatcherTimerOnce(); // don't know what to display before this...so leave everything hidden
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
  
  startWatcherTimerOnce(); // so it can check if episode changes to one we like magically LOL [amazon...]
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
    if (tags[i].default_action != "do_nothing") {
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
	for (var i = 0; i < tags.length; i++) {
		var tag = tags[i];
		var push_to_array;
		if (tag.default_action == 'mute') {
      push_to_array = mutes;
		} else if (tag.default_action == 'skip') {
      push_to_array = skips;
		} else if (tag.default_action == 'yes_audio_no_video') {
      push_to_array = yes_audio_no_videos;
		} else if (tag.default_action == 'mute_audio_no_video') {
      push_to_array = mute_audio_no_videos;
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

function startWatcherTimerOnce() {
  clean_stream_timer = clean_stream_timer || setInterval(checkStatus, 1000 / 100 ); // 100 fps since that's the granularity of our time entries :|
  // guess we just never turn it off on purpose :)
}

function start() {
  video_element = findFirstVideoTagOrNull();

  if (video_element == null) {
    // this one's pretty serious, yet could mean they're on youtube.com, there *was* a video playing but now it's just gone...hrm...
    // maybe could get here if they raw load the javascript?
    console.log("play it my way:\nfailure: unable to find a video playing, not loading edited playback...possibly need to reload then hit a play button before loading edited playback?");
    setTimeout(start, 1000); // just retry forever :|
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
    console.log("not showing UI since in add...");
    hideAllPimwStuff();
  }
}

function hideAllPimwStuff() {
  hideDiv(all_pimw_stuff); 
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
    if (all[i].currentTime > 0) {
      return all[i];
    }
  }
  return null;
}

function seekToTime(ts, callback) {
  if (seek_timer) {
    console.log("still seeking from previous, not trying that again...");
    return;
  }
  
  if (ts < 0) {
    console.log("not seeking to before 0, seeking to 0 instead, seeking to negative doesn't work well " + ts);
    ts = 0;
  }  
  var current_state = video_element.paused;
  // try and avoid freezes after seeking...if it was playing first...
	console.log("seeking to " + timeStampToHuman(ts));
  var start_time = video_element.currentTime;
  video_element.pause();
  video_element.currentTime = ts; // if this is far enough away from current, it also implies a "play" call...oddly. I mean seriously that is bizarre.
	// however if it close enough, then we need to call play
	// some shenanigans to pretend to work around...
	seek_timer = setInterval(function() {
		if (video_element.paused && video_element.readyState == 4 || !video_element.paused) {
      var amount_buffered = 0;
      if (video_element.buffered.length == 1) {
        amount_buffered = (video_element.buffered.end(0) - video_element.buffered.start(0));
      }
      if (amount_buffered > 2) { // usually 4 or 6...
  			console.log("appears it just finished seeking successfully to " + timeStampToHuman(ts) + " length=" + (ts - start_time) + " buffered=" + amount_buffered);
        if (!current_state) {
    			video_element.play();
        } else {
          // stay paused
        }
  			clearInterval(seek_timer);
  			if (callback) {
          callback();
        }
        seek_timer = null;
      } else {
        console.log("waiting for it to finish buffering..." + amount_buffered);
      }
		}		
	}, 50);
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

function pauseVideo() {
	video_element.pause();
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
  var seconds = timestamp.toFixed(2); //  -> "12.31" or "2.3"
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


function showSubCatWithRightOptionsAvailable() {
  // theoretically they can never select unknown...
  var type = document.getElementById("category_select").value; // category like "profanity"
  var subcategory_select = document.getElementById("subcategory_select_id");
  var width_needed = 0;
  for (var i=0; i < subcategory_select.length; i++){
    var option = subcategory_select.options[i];
    var cat_from_subcat = option.text.split(" ")[0]; // profanity
		if (cat_from_subcat != type && option.text.includes(" -- ")) {
		  option.style.display = "none";
		}
		else {
		  option.style.display = "block";
      width_needed = Math.max(width_needed, option.offsetWidth);
		}
	}
  resizeToCurrentSize(subcategory_select); // it probably reset to the top option of a new category [so new size]  
}

function resizeToCurrentSize(to_resize) { // requires hidden select also in doc for now :|
       var hidden_opt = document.getElementById("hidden_select_option_id");
       hidden_opt.innerHTML = to_resize.options[to_resize.selectedIndex].textContent;
       var hidden_sel = document.getElementById("hidden_select_id");
       hidden_sel.style.display = ""; // show it
       to_resize.style.width = hidden_sel.clientWidth + "px";
       hidden_sel.style.display = "none";
}

function setImpactIfMute() {
       var action_sel = document.getElementById("action_sel");
       var selected = action_sel.options[action_sel.selectedIndex].textContent;
       if (selected == "mute") {
         document.getElementById("impact_to_movie_id").options.selectedIndex = 1; // == "1/10"
       }
}

function doubleCheckValues() {
  var category = document.getElementById('category_select').value;
  if (category == "") {
    alert("please select category first");
    return false;
  }
  var age = document.getElementById('age_maybe_ok_id').value;
  
  if (document.getElementById('subcategory_select_id').value == "") {
    alert("please select subcategory first");
    return false;
  }
  var impact = document.getElementById('impact_to_movie_id').value;
  if (impact == "0") {
    alert("please select impact to story");
    return false;
  }
  var details = document.getElementById('details_input_id').value;
  if (details == "") {
    alert("please enter tag details");
    return false;
  }
  if ((category == "violence" || category == "suspense") && age == "0") {
    alert("for violence or suspense tags, please also select a value in the age specifier dropdown");
    return false;
  }
  var start = humanToTimeStamp(document.getElementById('start').value);
  var endy = humanToTimeStamp(document.getElementById('endy').value);
  if (start == 0) {
    alert("Can't start at zero, please select 0.01s if you want one that starts near the beginning");
    return false;
  }
  if (start >= endy) {
    alert("end is not after the start, double check timestamps...");
    return false;
  }
  if (endy - start > 60*15) {
    alert("tag is more than 15 minutes long? This should not typically be expected? check timestamps, if you do need it this long, let us know...");
    return false;
  }
  return true;
}

function tagsCreated() {
  // they call this when we're ready to setup shtuff, somehow necessary :|
  
  document.getElementById('action_sel').addEventListener(
     'change',
     setImpactIfMute,
     false
  );
  setImpactIfMute(); // the default is mute so set it up as we'd anticipate :|
  var subcat_select = document.getElementById("subcategory_select_id");
  resizeToCurrentSize(subcat_select);
  subcat_select.addEventListener(
       'change',
       function() {
         if (subcat_select.options[subcat_select.selectedIndex].value == "joke edit") {
           alert("for joking edits please save do_nothing as the action, then create your own personalized edit list where you modify it to get a mute or skip, that way for default playback it isn't edited out");
           document.getElementById('action_sel').value = 'do_nothing';
         }
        },
       false
  ); 
} <!-- render inline cuz uses macro -->

// no jquery setup here since this page might already have its own jQuery loaded, so don't load/use it to avoid any conflict.  [plus speedup load time]

// on ready just in case here LOL
onReady(start);
