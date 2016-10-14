current_url_sanitized = window.location.href.split("?")[0];
current_url_sanitized = current_url_sanitized.replace("smile.amazon", "www.amazon");
if ( current_url_sanitized.includes("/dp/") ) {
  id = current_url_sanitized.split("/dp/")[1].split("/")[0]
  current_url_sanitized = "https://www.amazon.com/gp/product/" + id
}

function getCurrentAmazonEpisode() {
  var subtitle = document.getElementsByClassName("subtitle")[0];
  if (subtitle &&  subtitle.innerHTML.match(/Ep. (\d+)/))
    return /Ep. (\d+)/.exec(subtitle.innerHTML)[1];
  else
    return "0"; // anything else
}

loaded=false;

javascript:(function(e,s){e.src=s;e.onload=function(){loaded=true;};document.head.appendChild(e);})(document.createElement('script'),'//rawgit.com/rdp/sensible-cinema-edit-descriptors/master/' + encodeURIComponent (encodeURIComponent(current_url_sanitized + getCurrentAmazonEpisode() + ".rendered.js")));
<!-- // double encode needed apparently :| jquery hopefully already loaded on every site?? hrm... -->

setTimeout(function(){ if (loaded == false) alert("unable to load for your current movie"); }, 3000);

