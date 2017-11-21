/*
        Unobtrusive Slider Control by frequency decoder v1.4 (http://www.frequency-decoder.com/)

        Released under a creative commons Attribution-ShareAlike 2.5 license (http://creativecommons.org/licenses/by-sa/2.5/)

        You are free:

        * to copy, distribute, display, and perform the work
        * to make derivative works
        * to make commercial use of the work

        Under the following conditions:

                by Attribution.
                --------------
                You must attribute the work in the manner specified by the author or licensor.

                sa
                --
                Share Alike. If you alter, transform, or build upon this work, you may distribute the resulting work only under a license identical to this one.

        * For any reuse or distribution, you must make clear to others the license terms of this work.
        * Any of these conditions can be waived if you get permission from the copyright holder.
*/

var fdSliderController;

(function() {

        function fdSlider(inp,range,callback,classname,hide,tween,vertical) {
                this._inp       = inp;
                this._hideInput = hide;
                this._min       = range[0]||0;
                this._max       = range[1]||0;
                this._range     = this._max - this._min;
                this._tween     = tween;
                this._mouseX    = 0;
                this._timer     = null;
                this._classname = classname;
                this._drag      = false;
                this._kbEnabled = true;
                this._callback  = callback;
                this._vertical  = vertical;
                this._steps     = inp.tagName.toLowerCase() == "input" ? 10 : inp.options.length - 1;
                this._resizeVal = 0;
                
                // ARIA namespaces
                this.NS_XHTML = "http://www.w3.org/1999/xhtml";
                this.NS_STATE = "http://www.w3.org/2005/07/aaa";
                
                this.events = {
                        stopevent: function(e) {
                                if(e == null) e = document.parentWindow.event;
                                if(e.stopPropagation) {
                                        e.stopPropagation();
                                        e.preventDefault();
                                }
                                /*@cc_on@*/
                                /*@if(@_win32)
                                e.cancelBubble = true;
                                e.returnValue = false;
                                /*@end@*/
                                return false;
                        },
                        redrawEvent:function(e) {
                                // Get around IE's window.resize bug by testing if the actual size of the wrapper has changed...
                                if((self._vertical && self.outerWrapper.offsetHeight != self._resizeVal) || (!self._vertical && self.outerWrapper.offsetWidth != self._resizeVal)) {
                                        self.events.redraw();
                                };
                        },
                        redraw: function() {
                                self.locate();

                                // Internet Explorer requires the try catch
                                try {
                                        var sW = self.outerWrapper.offsetWidth;
                                        var sH = self.outerWrapper.offsetHeight;
                                        var hW = self.handle.offsetWidth;
                                        var hH = self.handle.offsetHeight;
                                        var bH = self.bar.offsetHeight;
                                        var bW = self.bar.offsetWidth;
                                        var sI = self._steps;

                                        if(self._vertical) {
                                                self.bar.style.height = Math.round(sH - hH) + "px";
                                                self.bar.style.left   = Math.floor((sW - bW) / 2) + "px";
                                                self.bar.style.top    = Math.round(hH / 2) + "px";
                                                self._incPx    = (sH - hH) / sI < 1 ? 1 : (sH - hH) / sI;
                                        } else {
                                                self.bar.style.width  = Math.round(sW - hW) + "px";
                                                self.bar.style.left   = Math.round(hW / 2) + "px";
                                                self.bar.style.top    = Math.floor((sH - bH) / 2) + "px";
                                                self._incPx    = (sW - hW) / sI < 1 ? 1 : (sW - hW) / sI;
                                        };
                                        self.resetHandlePosition();
                                        self._resizeVal = (self._vertical) ? sH : sW;
                                } catch(err) { };
                        },
                        onfocus: function(e) {
                                self.outerWrapper.className = self.outerWrapper.className.replace('focused','') + ' focused';

                                fdSliderController.addEvent(window, 'DOMMouseScroll', self.events.trackmousewheel);
                                fdSliderController.addEvent(document, 'mousewheel', self.events.trackmousewheel);
                                if(!window.opera) fdSliderController.addEvent(window,   'mousewheel', self.events.trackmousewheel);

                                self.doCallback();
                        },
                        onblur: function(e) {
                                self.outerWrapper.className = self.outerWrapper.className.replace(/focused|fd-fc-slider-hover|fd-slider-hover/g,'');

                                fdSliderController.removeEvent(document, 'mousewheel', self.events.trackmousewheel);
                                fdSliderController.removeEvent(window, 'DOMMouseScroll', self.events.trackmousewheel);
                                if(!window.opera) fdSliderController.removeEvent(window,   'mousewheel', self.events.trackmousewheel);
                        },
                        trackmousewheel: function(e) {
                                if(!self._kbEnabled) return;
                                var delta = 0;
                                var e = e || window.event;
                                if (e.wheelDelta) {
                                        delta = e.wheelDelta/120;
                                        if (window.opera && window.opera.version() < 9.2) delta = -delta;
                                } else if(e.detail) {
                                        delta = -e.detail/3;
                                };
                                if(delta) {
                                        var xtmp = self._vertical ? self.handle.offsetTop : self.handle.offsetLeft;
                                        var wtmp = self._vertical ? self.outerWrapper.offsetHeight - self.handle.offsetHeight : self.outerWrapper.offsetWidth - self.handle.offsetWidth;
                                        var inc  = self._inp.tagName.toLowerCase() == "input" ? Math.round(self._incPx / 2) < 1 ? 1 : Math.round(self._incPx / 2) : self._incPx;
                                        if(self._vertical) inc = -inc;
                                        if(delta < 0) {
                                                xtmp += inc;
                                                xtmp = Math.ceil(xtmp);
                                        } else {
                                                xtmp -= inc;
                                                xtmp = Math.floor(xtmp);
                                        };
                                        if(xtmp < 0) xtmp = 0;
                                        else if(xtmp > wtmp) xtmp = wtmp;

                                        if(self._vertical) self.handle.style.top = xtmp + "px";
                                        else self.handle.style.left = xtmp + "px";
                                        self.updateInput(xtmp);
                                };
                                return self.events.stopevent(e);
                        },
                        onkeypress: function(e) {
                                if (e == null) e = document.parentWindow.event;
                                if ((e.keyCode >= 35 && e.keyCode <= 40) || !self._kbEnabled) {
                                        return self.events.stopevent(e);
                                };
                        },
                        onkeydown: function(e) {
                                if(!self._kbEnabled) return true;

                                if(e == null) e = document.parentWindow.event;
                                var kc = e.keyCode != null ? e.keyCode : e.charCode;

                                if ( kc < 35 || kc > 40 ) return true;

                                var xtmp = self._vertical ? self.handle.offsetTop : self.handle.offsetLeft;
                                var wtmp = self._vertical ? self.outerWrapper.offsetHeight - self.handle.offsetHeight : self.outerWrapper.offsetWidth - self.handle.offsetWidth;
                                var inc  = self._inp.tagName.toLowerCase() == "input" ? Math.round(self._incPx / 2) < 1 ? 1 : Math.round(self._incPx / 2) : self._incPx;

                                if(self._vertical) inc = -inc;

                                if( kc == 37 || kc == 40 ) {
                                        // left, up
                                        xtmp -= inc;
                                        xtmp = Math.floor(xtmp);
                                } else if( kc == 39 || kc == 38) {
                                        // right, down
                                        xtmp += inc;
                                        xtmp = Math.ceil(xtmp);
                                } else if( kc == 35 ) {
                                        // max
                                        xtmp = wtmp;
                                } else if( kc == 36 ) {
                                        // min
                                        xtmp = 0;
                                }

                                if(xtmp < 0) xtmp = 0;
                                else if(xtmp > wtmp) xtmp = wtmp;

                                self.handle.style[self._vertical ? "top" : "left"] = xtmp + "px";
                                self.updateInput(xtmp);
                                
                                // Opera doesn't let us cancel key events so the up/down arrows and home/end buttons will scroll the screen - which sucks
                                return self.events.stopevent(e);
                        },
                        onchange: function( e ) {
                                self.resetHandlePosition();
                                self.doCallback();
                                return true;
                        },
                        onmouseover: function( e ) {
                                /*@cc_on@*/
                                /*@if(@_jscript_version <= 5.6)
                                if(this.className.search(/focused/) != -1) {
                                        this.className = this.className.replace("fd-fc-slider-hover", "") +' fd-fc-slider-hover';
                                        return;
                                }
                                /*@end@*/
                                this.className = this.className.replace(/fd\-slider\-hover/g,"") +' fd-slider-hover';
                        },
                        onmouseout: function( e ) {
                                /*@cc_on@*/
                                /*@if(@_jscript_version <= 5.6)
                                if(this.className.search(/focused/) != -1) {
                                        this.className = this.className.replace("fd-fc-slider-hover", "");
                                        return;
                                }
                                /*@end@*/
                                this.className = this.className.replace(/fd\-slider\-hover/g,"");
                        },
                        onHmouseup:function(e) {
                                e = e || window.event;
                                fdSliderController.removeEvent(document, 'mousemove', self.events.trackmouse);
                                fdSliderController.removeEvent(document, 'mouseup', self.events.onHmouseup);
                                self._drag = false;
                                self._kbEnabled = true;

                                // Opera fires the blur event when the mouseup event occurs on a button, so we attept to force a focus
                                if(window.opera) try { setTimeout(function() { self.events.onfocus(); }, 0); } catch(err) {};
                                
                                return self.events.stopevent(e);
                        },
                        onHmousedown: function(e) {
                                e = e || window.event;
                                self._mouseX    = self._vertical ? e.clientY : e.clientX;
                                self.handleX    = parseInt(self._vertical ? self.handle.offsetTop : self.handle.offsetLeft)||0;
                                self._drag      = true;
                                self._kbEnabled = false;

                                fdSliderController.addEvent(document, 'mousemove', self.events.trackmouse);
                                fdSliderController.addEvent(document, 'mouseup', self.events.onHmouseup);
                                
                                // Safari will not "focus" on the button on mouse events, so we attempt to force a focus
                                if(window.devicePixelRatio || (document.all && !window.opera)) try { setTimeout(function() { self.handle.focus(); }, 0); } catch(err) {};
                        },
                        onmouseup: function( e ) {
                                e = e || window.event;
                                fdSliderController.removeEvent(document, 'mouseup', self.events.onmouseup);
                                if(!self._tween) {
                                        clearTimeout(self._timer);
                                        self._timer = null;
                                        self._kbEnabled = true;
                                }
                                self.doCallback();
                                return self.events.stopevent(e);
                        },
                        trackmouse: function( e ) {
                                if (!e) var e = window.event;
                                var x = self._vertical ? self.handleX + (e.clientY-self._mouseX) : self.handleX + (e.clientX-self._mouseX);
                                if(x < 0) x = 0;
                                var max = self._vertical ? self.outerWrapper.offsetHeight - self.handle.offsetHeight : self.outerWrapper.offsetWidth - self.handle.offsetWidth;
                                if(x > max) x = max;
                                if(self._vertical) self.handle.style.top = x + "px";
                                else self.handle.style.left = x + "px";
                                self.updateInput(x);
                        },
                        onmousedown: function( e ) {
                                var targ;
                                if (!e) var e = window.event;
                                if (e.target) targ = e.target;
                                else if (e.srcElement) targ = e.srcElement;
                                if (targ.nodeType == 3) targ = targ.parentNode;

                                if(targ.className.search("fd-slider-handle") != -1) {
                                        return true;
                                };
                                
                                try { setTimeout(function() { self.handle.focus(); }, 0); } catch(err) {};

                                clearTimeout(self._timer);
                                self._timer = null;
                                self._kbEnabled = false;
                                self.locate();
                                self._drag      = false;
                                var posx        = 0;
                                var sLft        = 0;
                                var sTop        = 0;

                                // Internet Explorer doctype woes
                                if (document.documentElement && document.documentElement.scrollTop) {
                                        sTop = document.documentElement.scrollTop;
                                        sLft = document.documentElement.scrollLeft;
                                } else if (document.body) {
                                        sTop = document.body.scrollTop;
                                        sLft = document.body.scrollLeft;
                                };

                                if (e.pageX)            posx = self._vertical ? e.pageY : e.pageX;
                                else if (e.clientX)     posx = self._vertical ? e.clientY + sTop : e.clientX + sLft;

                                var diff = Math.round((self._vertical) ? self.handle.offsetHeight / 2 : self.handle.offsetWidth / 2);
                                posx -= self._vertical ? self._y + diff : self._x + diff;
                                        
                                if(posx < 0) posx = 0;
                                else if(!self._vertical && posx > self.outerWrapper.offsetWidth - self.handle.offsetWidth)  posx = self.outerWrapper.offsetWidth - self.handle.offsetWidth;
                                else if(self._vertical && posx > self.outerWrapper.offsetHeight - self.handle.offsetHeight) posx = self.outerWrapper.offsetHeight - self.handle.offsetHeight;

                                if(self._tween) {
                                        self.tweenTo(posx);
                                } else {
                                        fdSliderController.addEvent(document, 'mouseup', self.events.onmouseup);
                                        self._posx = posx;
                                        self.onTimer();
                                };
                        }
                };

                this.onTimer = function() {
                        var xtmp = self._vertical ? self.handle.offsetTop : self.handle.offsetLeft;
                        if(self._posx < xtmp) {
                                xtmp -= self._incPx;
                                xtmp = Math.floor(xtmp);
                                if(xtmp < self._posx) xtmp = self._posx;
                        } else {
                                xtmp += self._incPx;
                                xtmp = Math.ceil(xtmp);
                                if(xtmp > self._posx) xtmp = self._posx;
                        };
                        xtmp = Math.round(xtmp);
                        self.handle.style[self._vertical ? "top" : "left"] = xtmp + "px";
                        self.updateInput(xtmp);
                        if(xtmp != self._posx) self._timer = setTimeout(self.onTimer, 200);
                        else self._kbEnabled = true;
                };

                this.locate = function(){
                        var curleft = 0;
                        var curtop  = 0;
                        var obj = self.outerWrapper;
                        // Try catch for IE's benefit
                        try {
                                while (obj.offsetParent) {
                                        curleft += obj.offsetLeft;
                                        curtop  += obj.offsetTop;
                                        obj      = obj.offsetParent;
                                };
                        } catch(err) {}
                        self._x = curleft;
                        self._y = curtop;
                };

                this.tweenTo = function(x){
                        self._kbEnabled = false;
                        self._tweenX = parseInt(x);
                        self._tweenB = parseInt(self._vertical ? self.handle.style.top : self.handle.style.left);
                        self._tweenC = self._tweenX - self._tweenB;
                        self._tweenD = 20;
                        self._frame  = 0;
                        if(!self._timer) self._timer = setTimeout(self.tween,50);
                };

                this.tween = function(){
                        self._frame++;
                        var c = self._tweenC;
                        var d = 20;
                        var t = self._frame;
                        var b = self._tweenB;
                        var x = Math.ceil((t==d) ? b+c : c * (-Math.pow(2, -10 * t/d) + 1) + b);

                        self.handle.style[self._vertical ? "top" : "left"] = x + "px";
                        self.updateInput(x);
                        if(t!=d && !self._md) self._timer = setTimeout(self.tween,20);
                        else {
                                self.handle.style[self._vertical ? "top" : "left"] = self._tweenX + "px";
                                clearTimeout(self._timer);
                                self._timer = null;
                                self._kbEnabled = true;
                        };
                };

                this.updateInput = function(x) {
                        var max = self._vertical ? self.outerWrapper.offsetHeight - self.handle.offsetHeight : self.outerWrapper.offsetWidth - self.handle.offsetWidth;
                        var inc = max / self._range;

                        var val = Number(self._min) + Math.abs(Math.floor(x / inc));
                        if(self._vertical) val = -val;
                        
                        if(val < self._min) val = self._min;
                        else if(val > self._max) val = self._max;

                        val = (val <= self._min + (self._max / 2)) ? Math.round(val) : Math.ceil(val);

                        self.setInputValue(val);
                        self.doCallback();
                };
                
                this.setInputValue = function(val) {
                        if(self._inp.tagName.toLowerCase() == "select") {
                                try {
                                        self._inp.options[val].selected = true;
                                        self.setAttrNS(self.handle, self.NS_STATE, "valuenow", self._inp.options[val].value);
                                        self.setAttrNS(self.handle, self.NS_STATE, "valuetext", self._inp.options[val].text);
                                } catch (err) {};
                        } else {
                                self._inp.value = val;
                                self.setAttrNS(self.handle, self.NS_STATE, "valuenow", val);
                                self.setAttrNS(self.handle, self.NS_STATE, "valuetext", val);
                        };
                };
                
                this.doCallback = function() {
                        if(self._callback) {
                                var func;
                                if(self._callback.indexOf(".") != -1) {
                                        var split = self._callback.split(".");
                                        func = window;
                                        for(var i = 0, f; f = split[i]; i++) {
                                                if(f in func) {
                                                        func = func[f];
                                                } else {
                                                        func = "";
                                                        break;
                                                };
                                        };
                                } else if(self._callback in window) {
                                        func = window[self._callback];
                                };
                                if(typeof func == "function") { func(); };
                                func = null;
                        };
                };
                
                this.resetHandlePosition = function() {
                        var value = self._inp.tagName.toLowerCase() == "input" ? parseInt(self._inp.value, 10) : self._inp.selectedIndex;
                        if(isNaN(value) || value < self._min) value = self._min;
                        else if(value > self._max) value = self._max;
                        self.setInputValue(value);
                        var max = self._vertical ? self.outerWrapper.offsetHeight - self.handle.offsetHeight : self.outerWrapper.offsetWidth - self.handle.offsetWidth;
                        var inc = max / self._range;
                        var tot = value - self._min;
                        var pos = (tot * inc < (self._min + (self._range / 2))) ? Math.floor(tot * inc) : Math.ceil(tot * inc);
                        if(self._vertical) {
                                self.handle.style.top = Math.abs(max - pos) + "px";
                        } else {
                                self.handle.style.left = pos + "px";
                        };
                };
                
                this.setAttrNS = function(elmTarget, uriNamespace, sAttrName, sAttrValue) {
                        if (typeof document.documentElement.setAttributeNS != 'undefined') {
                                elmTarget.setAttributeNS(uriNamespace, sAttrName, sAttrValue);
                        } else {
                                var nsMapping = {
                                        "http://www.w3.org/1999/xhtml":"x:",
                                        "http://www.w3.org/2005/07/aaa":"aaa:"
                                };
                                elmTarget.setAttribute(nsMapping[uriNamespace] + sAttrName, sAttrValue);
                        };
                };
                
                this.findLabel = function() {
                        var label;
                        if(self._inp.parentNode && self._inp.parentNode.tagName.toLowerCase() == "label") label = self._inp.parentNode;
                        else {
                                var labelList = document.getElementsByTagName('label');
                                // loop through label array attempting to match each 'for' attribute to the id of the current element
                                for(var lbl = 0; lbl < labelList.length; lbl++) {
                                        // Internet Explorer requires the htmlFor test
                                        if((labelList[lbl]['htmlFor'] && labelList[lbl]['htmlFor'] == self._inp.id) || (labelList[lbl].getAttribute('for') == self._inp.id)) {
                                                label = labelList[lbl];
                                                break;
                                        };
                                };
                        };
                        if(label && !label.id) { label.id = inp.id + "_label_" + fdSliderController.uniqueid++; };
                        return label;
                };
                
                this.build = function() {
                        if(self._hideInput) self._inp.style.display = "none";
                        else fdSliderController.addEvent(self._inp, 'change', self.events.onchange);

                        self.outerWrapper              = document.createElement('div');
                        self.outerWrapper.className    = "fd-slider" + (self._vertical ? "-vertical " : " ") + self._classname;
                        self.outerWrapper.id           = "fd-slider-" + inp.id;

                        self.wrapper                   = document.createElement('span');
                        self.wrapper.className         = "fd-slider-inner";

                        self.bar                       = document.createElement('span');
                        self.bar.className             = "fd-slider-bar";

                        self.handle                    = document.createElement('button');
                        self.handle.className          = "fd-slider-handle";
                        
                        self.handle.appendChild(document.createTextNode(" "));
                        
                        self.handle.setAttribute("type", "button");
                        self.handle.setAttribute("tabindex", "0");
                        
                        self.outerWrapper.appendChild(self.wrapper);
                        self.outerWrapper.appendChild(self.bar);
                        self.outerWrapper.appendChild(self.handle);
                        
                        self._inp.parentNode.insertBefore(self.outerWrapper, self._inp);

                        // ARIA tabindex
                        self.handle.setAttribute("tabindex", "0");

                        /*@cc_on@*/
                        /*@if(@_win32)
                        self.handle.unselectable       = "on";
                        self.bar.unselectable          = "on";
                        self.wrapper.unselectable      = "on";
                        self.outerWrapper.unselectable = "on";
                        /*@end@*/

                        fdSliderController.addEvent(self.outerWrapper, "mouseover", self.events.onmouseover);
                        fdSliderController.addEvent(self.outerWrapper, "mouseout",  self.events.onmouseout);
                        fdSliderController.addEvent(self.outerWrapper, "mousedown", self.events.onmousedown);
                        fdSliderController.addEvent(self.handle,       "keydown",   self.events.onkeydown);
                        fdSliderController.addEvent(self.handle,       "keypress",  self.events.onkeypress);
                        fdSliderController.addEvent(self.handle,       "focus",     self.events.onfocus);
                        fdSliderController.addEvent(self.handle,       "blur",      self.events.onblur);
                        fdSliderController.addEvent(self.handle,       "mousedown", self.events.onHmousedown);
                        fdSliderController.addEvent(self.handle,       "mouseup",   self.events.onHmouseup);
                        fdSliderController.addEvent(window,            "resize",    self.events.redrawEvent);

                        // Add ARIA accessibility info programmatically
                        self.setAttrNS(self.handle, self.NS_XHTML, "role", "wairole:slider");         // role:slider
                        self.setAttrNS(self.handle, self.NS_STATE, "valuemin", self._min);            // aaa:valuemin
                        self.setAttrNS(self.handle, self.NS_STATE, "valuemax", self._max);            // aaa:valuemax
                        //self.setAttrNS(self.handle, self.NS_STATE, "valuenow", self._inp.value);      // aaa:valuenow
                        
                        var lbl = self.findLabel();
                        if(lbl) {
                                self.setAttrNS(self.handle, self.NS_STATE, 'labelledby', lbl.id);     // aaa:labelledby
                                self.handle.id = "fd-slider-handle-" + inp.id;
                                /*@cc_on
                                /*@if(@_win32)
                                lbl.setAttribute("htmlFor", self.handle.id);
                                @else @*/
                                lbl.setAttribute("for", self.handle.id);
                                /*@end
                                @*/
                        };
                        
                        // Are there page instructions - the creation of the instructions has been left up to you fine reader...
                        if(document.getElementById("fd_slider_describedby")) {
                                self.setAttrNS(self.handle, self.NS_STATE, 'describedby', "fd_slider_describedby");     // aaa:describedby
                        };

                        self.events.redraw();
                };

                this.destroy = function() {
                        try {
                                self._callback = null;
                                fdSliderController.removeEvent(self.outerWrapper, "mouseover", self.events.onmouseover);
                                fdSliderController.removeEvent(self.outerWrapper, "mouseout",  self.events.onmouseout);
                                fdSliderController.removeEvent(self.outerWrapper, "mousedown", self.events.onmousedown);
                                fdSliderController.removeEvent(self.handle,       "keydown",   self.events.onkeydown);
                                fdSliderController.removeEvent(self.handle,       "keypress",  self.events.onkeypress);
                                fdSliderController.removeEvent(self.handle,       "focus",     self.events.onfocus);
                                fdSliderController.removeEvent(self.handle,       "blur",      self.events.onblur);
                                fdSliderController.removeEvent(self.handle,       "mousedown", self.events.onHmousedown);
                                fdSliderController.removeEvent(self.handle,       "mouseup",   self.events.onHmouseup);
                                fdSliderController.removeEvent(window,            "resize",    self.events.redraw);
                                if (window.addEventListener && !window.devicePixelRatio) window.removeEventListener('DOMMouseScroll', self.events.trackmousewheel, false);
                                else {
                                        fdSliderController.removeEvent(document, "mousewheel", self.events.trackmousewheel);
                                        fdSliderController.removeEvent(window,   "mousewheel", self.events.trackmousewheel);
                                };
                        } catch(err) {}

                        self.wrapper = self.bar = self.handle = self.outerWrapper = self._timer = null;
                };
                
                var self = this;
                self.build();
        };

        fdSliderController = {
                sliders: {},
                uniqueid: 0,
                forms: {},
                
                addEvent: function(obj, type, fn) {
                        if( obj.attachEvent ) {
                                obj["e"+type+fn] = fn;
                                obj[type+fn] = function(){obj["e"+type+fn]( window.event );}
                                obj.attachEvent( "on"+type, obj[type+fn] );
                        } else { obj.addEventListener( type, fn, true ); }
                },
                removeEvent: function(obj, type, fn) {
                        if( obj.detachEvent ) {
                                try {
                                        obj.detachEvent( "on"+type, obj[type+fn] );
                                        obj[type+fn] = null;
                                } catch(err) { };
                        } else { obj.removeEventListener( type, fn, true ); }
                },
                onload: function(e) {
                        for(slider in fdSliderController.sliders) { fdSliderController.sliders[slider].resetHandlePosition(); }
                },
                joinNodeLists: function() {
                        if(!arguments.length) { return []; }
                        var nodeList = [];
                        for (var i = 0; i < arguments.length; i++) {
                                for (var j = 0, item; item = arguments[i][j]; j++) { nodeList[nodeList.length] = item; };
                        };
                        return nodeList;
                },
                construct: function( e ) {
                        var regExp_1 = /fd_range_([-]{0,1}[0-9]+){1}_([-]{0,1}[0-9]+){1}/;
                        var regExp_2 = /fd_callback_([\S-]+)/;
                        var regExp_3 = /fd_classname_([a-zA-Z0-9_\-]+)/;
                        var inputs   = fdSliderController.joinNodeLists(document.getElementsByTagName('input'), document.getElementsByTagName('select'));
                        var range, callback, classname, hide, tween, vertical;

                        for(var i = 0, inp; inp = inputs[i]; i++) {
                                if((inp.tagName.toLowerCase() == "input" && inp.type == "text" && inp.className && inp.className.search(regExp_1) != -1) || (inp.tagName.toLowerCase() == "select" && inp.className.search(/fd_slider/) != -1)) {
                                        // Create an id if necessary
                                        if(!inp.id) inp.id == "sldr" + fdSliderController.uniqueid++;
                                        // Has the slider already been created?
                                        if(document.getElementById("fd-slider-"+inp.id)) continue;
                                        if(inp.tagName.toLowerCase() == "select") {
                                                range = [0, inp.options.length - 1];
                                                // Always hide the selectlist
                                                hide = true;
                                        } else {
                                                // range
                                                range = inp.className.match(regExp_1);
                                                range = [range[1], range[2]]
                                                // hide associated input
                                                hide  = inp.className.search(/fd_hide_input/ig) != -1;
                                        };
                                        // callback function
                                        callback =  inp.className.search(regExp_2) != -1 ? inp.className.match(regExp_2)[1].replace("-", ".") : "";
                                        // extra classname to assign to the wrapper div
                                        classname = inp.className.search(regExp_3) != -1 ? inp.className.match(regExp_3)[1] : "";
                                        // use the tween animation
                                        tween = inp.className.search(/fd_tween/ig) != -1;
                                        // vertical
                                        vertical = inp.className.search(/fd_vertical/ig) != -1;
                                        fdSliderController.sliders[inp.id] = new fdSlider(inp, range, callback, classname, hide, tween, vertical);
                                };
                        };
                },

                deconstruct: function( e ) {
                        for(slider in fdSliderController.sliders) { fdSliderController.sliders[slider].destroy(); };
                        fdSliderController.sliders = null;
                        fdSliderController.removeEvent(window, "load",   fdSliderController.construct);
                        fdSliderController.removeEvent(window, "unload", fdSliderController.deconstruct);
                        /*@cc_on@*/
                        /*@if(@_win32)
                        fdSliderController.removeEvent(window, "load",   function() { setTimeout(fdSliderController.onload, 200) });
                        /*@end@*/
                }
        }
})();

fdSliderController.addEvent(window, "unload", fdSliderController.deconstruct);
fdSliderController.addEvent(window, "load",   fdSliderController.construct);
/*@cc_on@*/
/*@if(@_win32)
fdSliderController.addEvent(window, "load",   function() { setTimeout(fdSliderController.onload, 200) });
/*@end@*/
