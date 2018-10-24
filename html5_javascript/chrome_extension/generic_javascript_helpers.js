// also some in _tag_shared_js.ecr

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

function getRequest(success, error) {
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
  var minutes  = Math.floor(timestamp / 60);
  timestamp -= minutes * 60;
  var seconds = Math.floor(timestamp);
  timestamp -= seconds;
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
