function injectJs(link) {
var scr = document.createElement('script');
scr.type="text/javascript";
scr.src=link;
document.getElementsByTagName('head')[0].appendChild(scr)
//document.body.appendChild(scr);
}

injectJs(chrome.extension.getURL('injected.js'));
