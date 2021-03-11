import core.Amaryllis;
import rm.objects.Game_Player;
import rm.scenes.Scene_Map;
import rm.core.Input;
import rm.core.TouchInput;
import utils.Comment;
import core.Types.JsFn;
import rm.scenes.Scene_Title;
import rm.windows.Window_Base;
import utils.Fn;
import rm.core.Rectangle;
import rm.Globals;

using core.NumberExtensions;

typedef PSParams = {
 var titleText: String;
 var fontSize: Int;
 var enableFade: Bool;
 var fadeSpeed: Int;
 var windowWidth: Int;
 var windowHeight: Int;
 var xPosition: Int;
 var yPosition: Int;
 #if !compileMV
 var fontFace: String;
 #end
};

class LunaPressStart {
 public static var PressStartParams: PSParams = null;
 #if mapMode
 public static var pressedStart: Bool = false;
 #end
 public static var pressStartFont: String = "PressStartFont";

 public static function main() {
  var params = Globals.Plugins.filter((plugin) -> {
   return ~/<LunaPressStart>/ig.match(plugin.description);
  })[0].parameters;

  PressStartParams = {
   titleText: params["Start Text"],
   fontSize: Fn.parseIntJs(params['Font Size']),
   enableFade: ~/T/ig.match(params["Fade Enable"]),
   fadeSpeed: Fn.parseIntJs(params["Fade Speed"]),
   windowWidth: Fn.parseIntJs(params["Window Width"]),
   windowHeight: Fn.parseIntJs(params["Window Height"]),
   xPosition: Fn.parseIntJs(params["Window X Position"]),
   yPosition: Fn.parseIntJs(params["Window Y Position"]),
   #if !compileMV
   fontFace: (params['Font Face'])
   #end
  };

  #if !compileMV
  trace(PressStartParams.fontFace);
  Comment.title("FontManager");
  untyped FontManager.load(pressStartFont, PressStartParams.fontFace);
  untyped trace(FontManager);
  #end

  #if !mapMode
  Comment.title("Scene_Title");
  var _SceneTitleCreate: JsFn = Fn.getPrProp(Scene_Title, "create");
  Fn.setPrProp(Scene_Title, "create", () -> {
   var STitle: Dynamic = Fn.self;
   _SceneTitleCreate.call(STitle);
   STitle.createStartWindow();
  });

  Fn.setPrProp(Scene_Title, "createStartWindow", () -> {
   var STitle: Dynamic = Fn.self;
   var PSParams = LunaPressStart.PressStartParams;
   STitle._windowStart = new LTWindowStart(PSParams.xPosition,
    PSParams.yPosition, PSParams.windowWidth, PSParams.windowHeight);
   STitle.addWindow(STitle._windowStart);
  });

  var _SceneTitleIsBusy: JsFn = Fn.getPrProp(Scene_Title, "isBusy");
  Fn.setPrProp(Scene_Title, "isBusy", () -> {
   var STitle: Dynamic = Fn.self;
   return STitle._windowStart.isOpen() || _SceneTitleIsBusy.call(STitle);
  });

  var _SceneTitleUpdate: JsFn = Fn.getPrProp(Scene_Title, "update");
  Fn.setPrProp(Scene_Title, "update", () -> {
   var STitle: Dynamic = Fn.self;
   _SceneTitleUpdate.call(STitle);
   STitle.processStart();
  });

  Fn.setPrProp(Scene_Title, "processStart", () -> {
   var STitle: Dynamic = Fn.self;
   if (STitle._windowStart.isOpen()
    && (TouchInput.isPressed() || Input.isTriggered("ok"))) {
    STitle._windowStart.close();
    STitle._windowStart.deactivate();
   }
  });
  #else
  Comment.title("Scene_Map");
  var _SceneMapCreateAllWindows: JsFn = cast Fn.getPrProp(Scene_Map,
   "createAllWindows");
  Fn.proto(Scene_Map).createAllWindowsD = () -> {
   _SceneMapCreateAllWindows.call(Fn.self);
   untyped Fn.self.createStartWindow();
  }

  Fn.setPrProp(Scene_Map, "createStartWindow", () -> {
   var SMap: Dynamic = Fn.self;
   var PSParams = LunaPressStart.PressStartParams;
   SMap._windowStart = new LTWindowStart(PSParams.xPosition,
    PSParams.yPosition, PSParams.windowWidth, PSParams.windowHeight);
   if (pressedStart == true) {
    untyped SMap._windowStart.close();
   } else {
    SMap.addWindow(SMap._windowStart);
   }
  });

  var _SceneMapIsBusy: JsFn = Fn.getPrProp(Scene_Map, "isBusy");
  Fn.setPrProp(Scene_Map, "isBusy", () -> {
   var SMap: Dynamic = Fn.self;
   return (SMap._windowStart.isOpen() && pressedStart == false)
    || _SceneMapIsBusy.call(SMap);
  });

  var _SceneMapUpdate: JsFn = cast Fn.getPrProp(Scene_Map, "update");
  Fn.setPrProp(Scene_Map, "update", () -> {
   var SMap: Dynamic = Fn.self;
   _SceneMapUpdate.call(SMap);
   SMap.processStart();
  });

  Fn.setPrProp(Scene_Map, "processStart", () -> {
   var SMap: Dynamic = Fn.self;
   if (SMap._windowStart.isOpen()
    && (TouchInput.isPressed() || Input.isTriggered("ok"))) {
    SMap._windowStart.close();
    SMap._windowStart.deactivate();
    pressedStart = true;
   }
  });

  var _PlayerCanMove: JsFn = Fn.getPrProp(Game_Player, "canMove");
  Fn.proto(Game_Player).canMoveD = () -> {
   if (untyped Amaryllis.currentScene()._windowStart != null
    && untyped Amaryllis.currentScene()._windowStart.isOpen()
     && pressedStart == false) {
    return false;
   } else {
    return _PlayerCanMove.call(Fn.self);
   }
  };
  #end
 }
}

@:keep
class LTWindowStart extends Window_Base {
 private var _visible: Bool;

 public function new(x: Int, y: Int, width: Int, height: Int) {
  #if compileMV
  super(x, y, width, height);
  #else
  var rect = new Rectangle(x, y, width, height);
  super(rect);
  #end
 }

 #if compileMV
 public override function initialize(?x: Int, ?y: Int, ?width: Int,
   ?height: Int) {
  super.initialize(x, y, width, height);
 #else
 public override function initialize(rect: Rectangle) {
  super.initialize(rect);
 #end

  this.setBackgroundType(2);
 }
 public override function update() {
  super.update();
  if (LunaPressStart.PressStartParams.enableFade) {
   this.processFade();
   this.refresh();
  }
 }

 public function drawStartText() {
  var PSParams = LunaPressStart.PressStartParams;
  #if !compileMV
  this.contents.fontFace = LunaPressStart.pressStartFont;
  #end
  this.contents.fontSize = PSParams.fontSize;
  var xpos = (this.contentsWidth() / 2)
   - (this.textWidth(PSParams.titleText) / 2);
  this.drawText(PSParams.titleText, 0, 0, this.contentsWidth(), 'center');
  this.resetFontSettings();
 }

 public function processFade() {
  switch (this._visible) {
   case true:
    this.fadeOut();
   case false:
    this.fadeIn();
  }
 }

 public function refresh() {
  if (this.contents != null) {
   this.contents.clear();
   this.drawStartText();
  }
 }

 public function fadeOut() {
  this.contentsOpacity -= LunaPressStart.PressStartParams.fadeSpeed;
  this.contentsOpacity = this.contentsOpacity.clampf(0, 255);
  if (this.contentsOpacity == 0) {
   this._visible = false;
  }
 }

 public function fadeIn() {
  this.contentsOpacity += LunaPressStart.PressStartParams.fadeSpeed;
  this.contentsOpacity = this.contentsOpacity.clampf(0, 255);
  if (this.contentsOpacity == 255) {
   this._visible = true;
  }
 }
}
