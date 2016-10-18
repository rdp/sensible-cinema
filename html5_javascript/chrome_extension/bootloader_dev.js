// this is run "on load" so hope video elements already exist :|

function findFirstVideoTag(node) {
    // there's probably a jquery way to do this easier :)
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

function getSanitizedCurrentUrl() {
  current_url = window.location.href;
  // and sanitize
  if (current_url.includes("amazon.com"))
    current_url = current_url.split("?")[0];
  current_url = current_url.replace("smile.amazon", "www.amazon");
  if (current_url.includes("/dp/") ) {
    id = current_url.split("/dp/")[1].split("/")[0]
    current_url = "https://www.amazon.com/gp/product/" + id
  }
  return current_url;
}

function getCurrentAmazonEpisode() {
  var subtitle = document.getElementsByClassName("subtitle")[0];
  if (subtitle &&  subtitle.innerHTML.match(/Ep. (\d+)/))
    return /Ep. (\d+)/.exec(subtitle.innerHTML)[1];
  else
    return "0"; // anything else
}

clean_stream_extension_ever_loaded = false;
clean_stream_extension_old_url = "";
clean_stream_extension_old_amazon_episode = "";

function checkAndLoadEditor() {

  if (clean_stream_extension_ever_loaded)
     return; // should be self-updating
  var video_element = findFirstVideoTag(document.body);
  if (video_element && (getSanitizedCurrentUrl() != clean_stream_extension_old_url || getCurrentAmazonEpisode() != clean_stream_extension_old_amazon_episode)) {
    var loaded=false;
    javascript:(function(e,s){e.src=s;e.onload=function(){loaded=true; clean_stream_extension_ever_loaded=true};document.head.appendChild(e);})(document.createElement('script'),'https://rawgit.com/rdp/sensible-cinema-edit-descriptors/master/' + encodeURIComponent (encodeURIComponent(getSanitizedCurrentUrl() + ".ep" + getCurrentAmazonEpisode() + ".html5_edited.rendered.js")));
    <!-- // double encode needed apparently :| jquery hopefully already loaded on every site?? hrm... -->
    setTimeout(function(){ 
      if (loaded == false) 
        alert("unable to load for your current movie " + getSanitizedCurrentUrl() + ".ep" + getCurrentAmazonEpisode()); 
        clean_stream_extension_old_url = getSanitizedCurrentUrl();
        clean_stream_extension_old_amazon_episode = getCurrentAmazonEpisode();
     }, 3000); // 3000 < 5000 :|
  }
  // else no video, do nothing :|
}

checkAndLoadEditor();
setInterval(checkAndLoadEditor, 5000);

// TODO only "try" once per video :|
