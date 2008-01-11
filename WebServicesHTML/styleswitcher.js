var WebKitDetect = { 
	isWebKit : function() 
	{ 
		return new RegExp(" AppleWebKit/").test(navigator.userAgent); 
	}, 
	
	isMobile : function()
	{ 
		return WebKitDetect.isWebKit() && new RegExp("Mobile/").test(navigator.userAgent);
	}, 
	
	mobileDevice : function()
	{
		if (!WebKitDetect.isMobile()) {
			return null; 
		} 
		var fields = new RegExp("(Mozilla/5.0 \\()([^;]+)").exec(navigator.userAgent); 
		if (!fields || fields.length < 3) { 
			return null; 
		} 
		return fields[2];
	} 
}; 


function setActiveStyleSheet(title) {
  var i, a, main;
  for(i=0; (a = document.getElementsByTagName("link")[i]); i++) {
    if(a.getAttribute("rel").indexOf("style") != -1 && a.getAttribute("title")) {
      a.disabled = true;
      if(a.getAttribute("title") == title) a.disabled = false;
    }
  }
}

function getActiveStyleSheet() {
  var i, a;
  for(i=0; (a = document.getElementsByTagName("link")[i]); i++) {
    if(a.getAttribute("rel").indexOf("style") != -1 && a.getAttribute("title") && !a.disabled) return a.getAttribute("title");
  }
  return null;
}

function getPreferredStyleSheet() {
	if(WebKitDetect.mobileDevice()) return "iPhone";
  var i, a;
  for(i=0; (a = document.getElementsByTagName("link")[i]); i++) {
    if(a.getAttribute("rel").indexOf("style") != -1
       && a.getAttribute("rel").indexOf("alt") == -1
       && a.getAttribute("title")
       ) return a.getAttribute("title");
  }
  return null;
}

function createCookie(name,value,days) {
  if (days) {
    var date = new Date();
    date.setTime(date.getTime()+(days*24*60*60*1000));
    var expires = "; expires="+date.toGMTString();
  }
  else expires = "";
  document.cookie = name+"="+value+expires+"; path=/";
}

function readCookie(name) {
  var nameEQ = name + "=";
  var ca = document.cookie.split(';');
  for(var i=0;i < ca.length;i++) {
    var c = ca[i];
    while (c.charAt(0)==' ') c = c.substring(1,c.length);
    if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
  }
  return null;
}

window.onload = function(e) {
  var cookie = readCookie("style");
  //var title = cookie ? cookie : getPreferredStyleSheet();
	var title = getPreferredStyleSheet();
  setActiveStyleSheet(title);
  
}

window.onunload = function(e) {
  var title = getActiveStyleSheet();
 // createCookie("style", title, 365);
}

//var cookie = readCookie("style");
//var title = cookie ? cookie : getPreferredStyleSheet();
var title = getPreferredStyleSheet();
setActiveStyleSheet(title);

setTimeout(function(){window.scrollTo(0, 1);}, 100);
