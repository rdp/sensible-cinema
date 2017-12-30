
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
