
function injectJs(link) {
  var scr = document.createElement('script');
  scr.type="text/javascript";
  scr.src=link;
  document.getElementsByTagName('head')[0].appendChild(scr)
}

injectJs(chrome.extension.getURL('bootloader_dev.js'));
