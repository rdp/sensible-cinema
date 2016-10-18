
function injectJs(link) {
  var scr = document.createElement('script');
  scr.type="text/javascript";
  scr.src=link;
  // scr.text = 'alert("we are here 2");'
  document.getElementsByTagName('head')[0].appendChild(scr)
  //document.body.appendChild(scr);
}

injectJs(chrome.extension.getURL('bootloader_dev.js'));
