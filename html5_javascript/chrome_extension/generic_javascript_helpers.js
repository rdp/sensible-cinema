function showRightDropdownsForCategory() {
  var category = document.getElementById("category_select_id").value;
  var age_select = document.getElementById('age_maybe_ok_id');
  var lewdness_select = document.getElementById('lewdness_level_id');
  var lip_readable = document.getElementById('lip_readable_id');
  // this is basically called when they change category so only reset values "when should" I guess...
  if (category == "physical") {
    age_select.style.visibility = "hidden";
    age_select.value = "0";
    lewdness_select.style.visibility = "visible";
    lip_readable.style.visibility = "hidden";
    lip_readable.value = "";
  } else if (category == "violence" || category == "suspense" || category == "substance-abuse") {
    // sustance abuse optional for like hard core drugs...?
    age_select.style.visibility = "visible";
    lewdness_select.style.visibility = "hidden";
    lewdness_select.value = "0";
    lip_readable.style.visibility = "hidden";
    lip_readable.value = "";
  } else if (category == "profanity") {
    lewdness_select.style.visibility = "hidden";
    lewdness_select.value = "0";
    age_select.style.visibility = "hidden";
    age_select.value = "0";
    lip_readable.style.visibility = "visible";
  } else { // creditz -> show hardly anything
    lewdness_select.style.visibility = "hidden";
    lewdness_select.value = "0";
    age_select.style.visibility = "hidden";
    age_select.value = "0";
    lip_readable.style.visibility = "hidden";
    lip_readable.value = "";
  }
}

function showSubCatWithRightOptionsAvailable() {
  // theoretically they can never select unknown...
  var category_select = document.getElementById("category_select_id");
  var category = category_select.value;
  var subcategory_select = document.getElementById("subcategory_select_id");
  var width_needed = 0;
  var subcats_with_optgroups = Array.apply(null, subcategory_select.options); // convert to Array
  subcats_with_optgroups = subcats_with_optgroups.concat(Array.apply(null, subcategory_select.getElementsByTagName('optgroup')));
  for (var i=0; i < subcats_with_optgroups.length; i++){
    var option = subcats_with_optgroups[i];
    var text = option.text || option.label; // for optgroup
    var cat_from_subcat = text.split(" ")[0]; // profanity of profanity -- XXX
    if (cat_from_subcat != category && text.includes(" -- ")) {
      option.style.display = "none";
    }
    else {
      option.style.display = "block";
      width_needed = Math.max(width_needed, option.offsetWidth);
    }
  }
    
  reWidthSelectToSizeOfSelected(subcategory_select); // it probably reset to the top option of a new category [so new size]  
}

function reWidthSelectToSizeOfSelected(to_resize) { 
       // requires hidden select also in doc for now, to calculate size in [can't remember why...]
       var hidden_opt = document.getElementById("hidden_select_option_id");
       hidden_opt.innerHTML = to_resize.options[to_resize.selectedIndex].textContent;
       var hidden_sel = document.getElementById("hidden_select_id");
       hidden_sel.style.display = ""; // show it
       to_resize.style.width = hidden_sel.clientWidth + "px";
       hidden_sel.style.display = "none";
}

function setImpactIfActionMute() {
       var action_sel = document.getElementById("action_sel");
       var selected = action_sel.options[action_sel.selectedIndex].textContent;
       if (selected == "mute") {
         document.getElementById("impact_to_movie_id").options.selectedIndex = 1; // == low
       }
}

function isYoutubePimw() {
  return (typeof youtube_pimw_player !== 'undefined');
}

function getEndSpeedOrAlert(value) {
  var re = /(\d\.\d+)x$/;
  var match = re.exec(value);
  if (match) {
    if (!isYoutubePimw() || youtube_pimw_player.getAvailablePlaybackRates().includes(parseFloat(match[1]))) {    
      return parseFloat(match[1]);
    }
  }
  // failure of some kind er other...
  if (isYoutubePimw()) {
      var out = "you need to enter the speed you want in the details like 'my_details 2.0x' or 'my_details 0.5x' (options:";
      var rates = youtube_pimw_player.getAvailablePlaybackRates();
      for (var i = 0; i < rates.length; i++) {
        out += rates[i].toFixed(2) + "x,";
      }
      alert(out + ") [0.25 has no audio]");
  } else {
      alert("you need to enter the speed you want in the details like 'my_details 2.0x' or 'my_details 0.5x' (goes up to 4.0x, down to 0.5x with audio)");
  }
  return null;
}

function getAudioPercentOrAlert(value) {
  var re = /(\d+)%$/;
  var match = re.exec(value);
  if (match) {
    return parseFloat(match[1]);
  }
  alert("you need to enter the audio percent you want, like 'my_details 5%' [at least 5% if youtube]");
  return null;
}

function weakDoubleCheckTimestampsAndAlert(action, details, start, endy) {

  if ((action == "make_video_smaller" || action == "change_speed") && !isYoutubePimw()) {
    alert("we only do that for youtube today, ping us if you want it added elsewhere");
    return;
  }
  
  if (action == "change_speed" && !getEndSpeedOrAlert(details)) {
    return false;
  }
  if (action == "set_audio_volume" && !getAudioPercentOrAlert(details)) {
    return false;
  }
 
  if (isYoutubePimw() && (action == "mute_audio_no_video")) {
    alert("we seemingly aren't allowed to do mute_audio_no_video non-video for youtube, you could make it smaller and mute, two separate overlapping edits, instead");
    return false;
  }
  if (isYoutubePimw() && action == "yes_audio_no_video") {
    alert("we seemingly aren't allowed to do yes_audio_no_video (black screen) for youtube, just skip instead...");
    return false;
  }
  if (start == 0) {
    alert("Can't start at zero, please select 0.01s if you want one that starts near the beginning");
    return false;
  }
  if (start >= endy) {
    alert("appears your end is before or equal to your start, please adjust timestamps, then try again!");
    return false;
  }
  if (endy - start > 60*15) {
    alert("tag is more than 15 minutes long? This should not typically be expected? check timestamps, if you do need it this long, let us know...");
    return false;
  }

  return true;
}

function humanToTimeStamp(timestamp) {
  // 0h 17m 34.54s
  sum = 0.0
  split = timestamp.split(/[hms ]/)
  removeElementFromArray(split, "");
  split.reverse();
  for (var i = 0; i < split.length; i++) {
    sum += parseFloat(split[i]) * Math.pow(60, i);
  }
  return sum;
}

function removeElementFromArray(arr) {
    var what, a = arguments, L = a.length, ax;
    while (L > 1 && arr.length) {
        what = a[--L];
        while ((ax= arr.indexOf(what)) !== -1) {
            arr.splice(ax, 1);
        }
    }
    return arr;
}

function doubleCheckValues() {

  var action = document.getElementById('action_sel').value;
  var details = document.getElementById('details_input_id');
  var start = humanToTimeStamp(document.getElementById('start').value);
  var endy = humanToTimeStamp(document.getElementById('endy').value);
  if (!weakDoubleCheckTimestampsAndAlert(action, details.value, start, endy)) {
    addRedBorderTemporarily(document.getElementById('endy'));
    addRedBorderTemporarily(document.getElementById('start'));
    return false;
  }

  var category_div = document.getElementById('category_select_id');
  var category = category_div.value;
  if (category == "") {
    alert("please select category first");
    addRedBorderTemporarily(category_div);
    return false;
  }  
 
  var subcat_select = document.getElementById('subcategory_select_id');
  if (subcat_select.value == "") {
    alert("please select subcategory first");
    addRedBorderTemporarily(subcat_select);
    return false;
  }
  var impact = document.getElementById('impact_to_movie_id');
  if (impact.value == "0") {
    alert("please select impact to story");
    addRedBorderTemporarily(impact);
    return false;
  }
  if (details.value == "") {
    alert("please enter tag details");
    addRedBorderTemporarily(details);
    return false;
  }
  
  var age = document.getElementById('age_maybe_ok_id');
  if ((category == "violence" || category == "suspense") && age.value == "0") {
    alert("for violence or suspense tags, please also select a value in the age specifier dropdown");
    addRedBorderTemporarily(age);
    return false;
  }
  var lewdness_level = document.getElementById('lewdness_level_id');
  if ((category == "physical") && lewdness_level.value == "0") {
    alert("for sex/nudity/lewdness, please also select a value in the lewdness_level dropdown");
    addRedBorderTemporarily(lewdness_level);
    return false;
  }
  var lip_readable = document.getElementById('lip_readable_id');
  if ((category == "profanity") && lip_readable.value == "") {
    alert("for profanity please also select 'lip_readable?' dropdown");
    addRedBorderTemporarily(lip_readable);
    return false;
  }
  if (subcat_select.options[subcat_select.selectedIndex].value == "joke edit" && document.getElementById('default_enabled_id').value == 'true') {
    alert("for joking edits please remember to save them with default_enabled as N!");
  }
  return true;
}

function addRedBorderTemporarily(to_this_div) {
  to_this_div.classList.add("error");  // not ie 9 compat oh well!
  setTimeout(function(){ 
       to_this_div.classList.remove("error");
     }, 
    3000);
}

function editDropdownsCreated() {
  // called when we're ready to setup variables in the dropdowns, since otherwise the right divs aren't in place yet in plugin

  document.getElementById('category_select_id').addEventListener('change', function(event) {
    categoryChanged(true);
   });
  document.getElementById("subcategory_select_id").addEventListener('change', function(event) {
    subcategoryChanged(true);
   });

  document.getElementById('action_sel').addEventListener('change', setImpactIfActionMute);
}

function categoryChanged(full_change) {
    var subcat_select = document.getElementById("subcategory_select_id");
    subcat_select.selectedIndex = 0;  // reset subcat to top, since cat just changed...
    reWidthSelectToSizeOfSelected(document.getElementById('category_select_id'));
    showSubCatWithRightOptionsAvailable();
    showRightDropdownsForCategory();
    if (full_change) {
      clearDetails(); // rarely want to reuse these for a newly selected category...    
    } // else: can't yet it calls this after loading an existing tag into the UI for re-editing :|
}

function subcategoryChanged(full_change) {
    var subcat_select = document.getElementById("subcategory_select_id");
    reWidthSelectToSizeOfSelected(subcat_select);
    if (full_change) {
      clearDetails();
    } // else don't if we're loading a tag into UI
}

function clearDetails() {
  document.getElementById('details_input_id').value = "";
}

function htmlDecode(input) { // unescape I guess typically we inject "inline" which works fine <sigh> but not for value = nor alert ... I did DB wrong
  var doc = new DOMParser().parseFromString(input, "text/html");
  return doc.documentElement.textContent;
}

function updateHTML(div, new_value) {
  if (div.innerHTML != new_value) {
    div.innerHTML = new_value;
  }
}

function addListenerMulti(element, eventNames, listener) {
  var events = eventNames.split(' ');
  for (var i=0, iLen=events.length; i<iLen; i++) {
    element.addEventListener(events[i], listener, false);
  }
}

function videoNotBuffering() {
  if (isYoutubePimw()) {
    // -1 – unstarted 0 – ended 1 – playing 2 – paused 3 – buffering 5 – video cued assume paused means not buffering? huh wuh? XXXX experiment...
    return youtube_pimw_player.getPlayerState() == YT.PlayerState.PAUSED || youtube_pimw_player.getPlayerState() == YT.PlayerState.PLAYING;
  } else {
    var HAVE_ENOUGH_DATA_HTML5 = 4;
    return video_element.readyState == HAVE_ENOUGH_DATA_HTML5;// it's HAVE_NOTHING, HAVE_METADATA, HAVE_CURRENT_DATA [i.e. 1 frame], HAVE_FUTURE_DATA [i.e. 2 frames], HAVE_ENOUGH_DATA_HTML5 == 4 [i.e. lots of data buffered]
  }
}

function sendNotification(notification_desired) {
  if (isYoutubePimw()) {
      // can't rely on background.js at all :|
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
  var notification = new Notification(notification_desired.title, {body: notification_desired.body, tag: notification_desired.tag.id}); // auto shows it
  notification.onclose = function() { console.log("notification onclose");};
  // doesn't work "well" OS X (only when they really choose close, not auto disappear :| ) requireInteraction doesn't help either?? TODO report to chrome, when fixed update my SO answer :)
  notification.onclick = function(event) {
    event.preventDefault(); // prevent the browser from focusing the Notification's tab
    window.open('https://playitmyway.org/view_tag/' + notification_desired.tag.id, '_blank'); // also opens and sets active
  }
  setTimeout(function() {
    notification.close();
  },
  10000);
}

// early callable timeout's ... :) not used anymore...
var timeouts = {};  // hold the data
function makeEarlyOutTimeout (func, interval) {
    var run = function(){
        timeouts[id] = undefined;
        func();
    }

    var id = window.setTimeout(run, interval);
    timeouts[id] = func

    return id;
}

function removeEarlyOutTimeout (id) {
    window.clearTimeout(id);
    timeouts[id]=undefined; // is this enough tho??
}

function doTimeoutEarly (id) {
  func = timeouts[id];
  removeTimeout(id);
  func();
}


function inIframe() {
  try {
      return window.self !== window.top;
  } catch (e) {
      return true;
  }
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

function onReady(yourMethod) { // polling one, from SO :)
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

function pointWithinElement(cursorX, cursorY, element) {
  var coords = getLocationOfElement(element);
  return (cursorX < coords.left + coords.width && cursorX > coords.left && cursorY < coords.top + coords.height && cursorY > coords.top);
}

function submitFormXhr(oFormElement, success, failure)
{
  var xhr = new XMLHttpRequest();
  xhr.onload = function() {success(xhr); }
  xhr.onerror = function() { failure(xhr) };
  xhr.withCredentials = true; // or we don't know who is sending the data in to save it
  xhr.open (oFormElement.method, oFormElement.action, true);
  xhr.send (new FormData (oFormElement));
  return false;
}

function loadRequest(success, error) {
  var url = lookupUrl();
  console.log("starting attempt GET download " + url);
  var xhr = XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP");
  xhr.open("GET", url);
  xhr.withCredentials = true; // the only request we do is the json one which should work secured...
  xhr.onreadystatechange = function(){  // or onload for newer browsers LOL onload == success
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

function removeOptionByName(selectobject, nameToRemove) {
  for (var i=0; i<selectobject.length; i++){
  if (selectobject.options[i].value == nameToRemove ) // seems required sadly
     selectobject.remove(i);
  }
}

function removeAllOptions(selectbox) {
  for(var i = selectbox.options.length - 1 ; i >= 0 ; i--) {
    selectbox.remove(i);
  }
}

function selectHasOption(select_element, desired_value) {
  for (var i = 0; i < select_element.length; i++){
    var option = select_element.options[i];
    if (option.value == desired_value) {
      return true;
    }
  }
  return false;
}

function timeStampToHuman(timestamp) {
  var hours = Math.floor(timestamp / 3600);
  timestamp -= hours * 3600;
  timestamp = Number.parseFloat(timestamp.toFixed(2)); // 9936.71 - 2*3600 = 2736.709999999999 whaaat?
  var minutes  = Math.floor(timestamp / 60);
  timestamp -= minutes * 60;
  timestamp = Number.parseFloat(timestamp.toFixed(2));
  var seconds = Math.floor(timestamp);
  timestamp -= seconds;
  timestamp = Number.parseFloat(timestamp.toFixed(2));
  var hundredths = paddTo2(Math.floor(timestamp * 100)); // round to hundredth, pad the other way...
  var secondsString = paddTo2(seconds) + "." + hundredths + "s";
  if (hours > 0)
    return hours + "h " + paddTo2(minutes) + "m " + secondsString;
  else
    return minutes + "m " + secondsString;
}

function timeStampToHumanRoundSecond(ts) {
  var x = timeStampToHuman(ts);
  return x.replace(/\.\d+s$/, "s");
}

function timeStampToEuropean(timestamp) { // for the subsyncer :|
  // want 00:00:12,074
  var hours = Math.floor(timestamp / 3600);
  timestamp -= hours * 3600;
  var minutes  = Math.floor(timestamp / 60);
  timestamp -= minutes * 60;
  var seconds = Math.floor(timestamp);
  timestamp -= seconds;
  var fractions = timestamp;
  // hope hundredths is enough
  return paddTo2(hours) + ":" + paddTo2(minutes) + ":" + paddTo2(seconds) + "," + paddTo2(Math.floor(fractions * 100));
}

function paddTo2(n) { // 1 becomes 01
  // "hard" apparently...
  var pad = new Array(1 + 2).join('0');
  return (pad + n).slice(-pad.length);
}

function twoDecimals(thisNumber) {
  return thisNumber.toFixed(2); // rounds it
}

function truncTwoDecimals(thisNumber) {
  return Math.floor(thisNumber * 100) / 100; // https://stackoverflow.com/a/41259341/32453
}

// method to bind easily to resize event (with compat. with old browsers)
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

function findFirstVideoTagOrNull() {
   // or document.querySelector("video") LOL (though not enough)
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
