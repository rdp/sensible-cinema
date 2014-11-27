boxee.autoChooseRepeat = true;
var newApi = (boxee.getVersion() > 3.9);

if (!newApi) boxee.renderBrowser = true;
else boxee.preloader = "http://dir.boxee.tv/apps/netflix/loading.html";

boxee.rewriteSrc = function(url) {
	originalUrl = url;
	if (newApi) return url;
	return "http://dir.boxee.tv/apps/netflix/loading.html";
}

if (boxee.getVersion() > 1.8) {
	boxee.setCanPause(true);
	boxee.setCanSkip(true);
	boxee.setCanSetVolume(true);
}

boxee.browserWidth = 800;
boxee.browserHeight = 450;

boxee.preloaderWidth = 800;
boxee.preloaderHeight = 450;

function poll() {
	
	movieObjectLoaded = (browser.execute("typeof netflix.Silverlight.MoviePlayer") == "object");
	playerInit = (browser.execute("boxeePlayerInit") == "true");
	if (!playerInit && movieObjectLoaded) {
		initializePlayer();
	}

	var ready = browser.execute("playerReady");

	if (ready == "1") {
		if (!newApi) boxee.renderBrowser = true;

		var now = browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().play_position');
		var total = browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().play_duration');
		var bEnded = browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().play_state') == "104";

		if (bEnded) {
			boxee.notifyPlaybackEnded();
		} else if (total > 0 && now > 0) {
			var pct = now / total * 100.0;
			boxee.setDuration(total / 1000);
			boxee.notifyCurrentProgress(pct);
		}

		if (!bEnded && now > 0) boxee.notifyCurrentTime(now / 1000);

		if (browser.execute("dimensionChange") == "1") {
			width = browser.execute("movieWidth");
			height = browser.execute("movieHeight");
			browser.execute('dimensionChange = "0";');
		}
	}
	setTimeout(poll, 1000);
}

setTimeout(poll, 1000);

setTimeout(function() {
	hasSilverlight = browser.execute("netflix.Silverlight.isInstalled('1.0');");
	if (hasSilverlight == "false") {
		boxee.showNotification("Please install/reinstall the latest version of Microsoft Silverlight.", "", 4);
		setTimeout(function() {
			boxee.notifyPlaybackEnded();
		}, 4000);
	}
}, 5000);

function inTrickPlayMode() {
	result = (browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().play_state') == "103");
	return result;
}

function enterTrickPlay() {
	browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().trick_play_enter()');
	boxee.notifyPlaybackPaused();
}

function leaveTrickPlay() {
	browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().trick_play_leave(true)');
	boxee.notifyPlaybackResumed();
}

boxee.onNotifyUrl = function(url) {
	if (url.indexOf("http://www.netflix.com/WiPlayer") >= 0) {
		boxee.renderBrowser = false;
	}
}

boxee.onDocumentLoaded = function() {
	browser.execute("document.location='" + originalUrl + "';");
}

function initializePlayer() {
	var res = browser.execute('netflix.Silverlight.MoviePlayer.cookieprompt_response(true, true); ');
	var res = browser.execute('boxeePlayerState="1"; boxeePlayerInit = "true"; dimensionChange = "0"; ' + 'netflix.Silverlight.MoviePlayer.register_onload_handler(' + 'function() {boxeePlayerState="3"; ' + 'netflix.Silverlight.MoviePlayer.get_hosted_player_control().' + 'movie_dimensions_known = function(sender, eArgs) { dimensionChange = "1"; movieWidth = eArgs.width; movieHeight = eArgs.height; }; ' + 'netflix.Silverlight.MoviePlayer.get_hosted_player_control().open({show_navigation_panel: false, show_player_panel: false, show_back_to_browsing: false}); ' + 'playerReady="1"; ' + 'netflix.Silverlight.MoviePlayer.get_hosted_player_control().trick_play_interval=300000; ' + '});');
}

boxee.onPlay = function() {
	if (inTrickPlayMode()) {
		leaveTrickPlay();
	} else {
		browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().play()');
		boxee.notifyPlaybackResumed();
	}
}

boxee.onPause = function() {
	browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().pause()');
	boxee.notifyPlaybackPaused();
}

boxee.onBigSkip = function() {
	if (inTrickPlayMode()) {
		browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().trick_play_next()');
	} else {
		browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().play_position+=600000');
	}
}

boxee.onSkip = function() {
	if (inTrickPlayMode()) {
		browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().trick_play_next()');
	} else {
		enterTrickPlay();
	}
}

boxee.onBigBack = function() {
	if (inTrickPlayMode()) {
		browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().trick_play_previous()');
	} else {
		browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().play_position-=600000');
	}
}

boxee.onBack = function() {
	if (inTrickPlayMode()) {
		browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().trick_play_previous()');
	} else {
		enterTrickPlay();
	}
}

boxee.onSetVolume = function(volume) {
	var volMin = browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().volume_min');
	var volMax = browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().volume_max');
	var volPct = ((volMax - volMin) / 100.0) * volume;
	browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().volume=' + Math.round((volMin + volPct)));
}

boxee.onClose = function() {
	browser.execute('netflix.Silverlight.MoviePlayer.get_hosted_player_control().close()');
}