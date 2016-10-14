
function getSanitizedCurrentUrl() {
  current_url = window.location.href;
  # and sanitize
  if (!current_url.contain("play.google.com"))
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

loaded=false;

javascript:(function(e,s){e.src=s;e.onload=function(){loaded=true;};document.head.appendChild(e);})(document.createElement('script'),'//rawgit.com/rdp/sensible-cinema-edit-descriptors/master/' + encodeURIComponent (encodeURIComponent(getSanitizedCurrentUrl() + getCurrentAmazonEpisode() + ".rendered.js")));
<!-- // double encode needed apparently :| jquery hopefully already loaded on every site?? hrm... -->

setTimeout(function(){ if (loaded == false) alert("unable to load for your current movie"); }, 3000);

