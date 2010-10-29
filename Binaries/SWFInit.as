var isPlaying:Boolean;

function gotoFrame(target:Number) {
	if (isPlaying) {
		stop();
		isPlaying = false;
	}
	
	if (target < 1) target = 1;
    if (target > _root._totalframes) target = _root._totalframes;
	
	_root.gotoAndStop(target);
};

function diff(a:Number, b:Number) :Number {
    return a>b? a-b : b-a;
}

function frameAtCoords(x:Number, y:Number) :Number {
	var minindex:Number = -1, mindist:Number = 0;
	
	for (var i:Number = 0; i < _root._totalframes; i++) {
		var dist:Number = diff(x, _root.ControllerOriginX+_root.ControllerWidth/(_root._totalframes-1)*i);
		if (minindex == -1 || dist < mindist) {
            minindex = i;
            mindist = dist;
		}
	}
	
	return minindex+1;
};

// scroll

var timerRef:Number;
var mouseDownMode:Number, ModeLeft:Number = 1, ModeMark:Number = 2, ModeRight:Number = 3;

function handleModalMouse() {
	if (mouseDownMode == ModeLeft || mouseDownMode == ModeRight) {
        if (mouseDownMode == ModeRight)
            gotoFrame(_root._currentframe+1);
        if (mouseDownMode == ModeLeft)
            gotoFrame(_root._currentframe-1);
    }
};

function mouseDown(mode:Number) {
	mouseDownMode = mode;
	
	if (mouseDownMode == ModeLeft || mouseDownMode == ModeRight) {
		handleModalMouse();
		timerRef = setInterval(handleModalMouse, 0200);
	}
};

function leftBarMouseDown() {
	mouseDown(ModeLeft);
};

function markMouseDown() {
	mouseDown(ModeMark);
};

function rightBarMouseDown() {
	mouseDown(ModeRight);
};

function globalMouseUp() {
	if (timerRef)
		clearInterval(timerRef);
	if (mouseDownMode)
		mouseDownMode = 0;
};

function globalMouseDrag() {
	if (mouseDownMode == ModeMark)
		gotoFrame(frameAtCoords(_root._xmouse, _root._ymouse));
};

function globalMouseMove() {
	if (mouseDownMode)
		globalMouseDrag();
};

_root.onLoad = function() {
	gotoAndStop(1);
	isPlaying = false;
	mouseDownMode = 0;
	timerRef = 0;
	
	var eventListener:Object = new Object();
	
	eventListener.onMouseWheel = function(delta:Number) {
		var target = _root._currentframe;
		
		if (delta < 0) target++;
		if (delta > 0) target--;
		
		if (target != _root._currentframe)
			gotoFrame(target);
	};
	
	eventListener.onMouseUp = function() {
		globalMouseUp();
	};
	
	eventListener.onMouseMove = function() {
		globalMouseMove();
	};
	
	Mouse.addListener(eventListener);
	
	eventListener.onKeyDown = function() {
		var target = _root._currentframe;
		var code = Key.getCode();
		
		if (code == Key.RIGHT || code == Key.DOWN)
			target++;
		if (code == Key.LEFT || code == Key.UP)
			target--;
		
		if (target != _root._currentframe)
			gotoFrame(target);
	};

	Key.addListener(eventListener);

	_root.focusEnabled = true;
	Selection.setFocus(_root);

	// debug
	
	_root.createTextField('debugTF', 1, 10,10, 500,500);
	debugTF.text = '';
	debugTF.textColor = 0x888888;
	debugTF.selectable = false;
};

/* JavaScript connection

function jsKeyDown(code) {
	gotoFrame(_root._currentframe+1);
};

var connection = ExternalInterface.addCallback("jsKeyDown", this, jsKeyDown);*/
