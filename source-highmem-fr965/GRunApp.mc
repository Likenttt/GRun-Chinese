using Toybox.Application;
using Toybox.Graphics;

class GRunApp extends Application.AppBase {
  protected var gRunView;

  function initialize() {
    //System.println("Fr965 (High Memory)");
    AppBase.initialize();
    gRunView = new GRunViewHighMem();
  }

  public static function getTextDimensions(dc, value, font) {
    var textDimensions = dc.getTextDimensions(value, font);

    if (font < 7) {
      textDimensions[0] += 2;
    }
    textDimensions[1] = textDimensions[1] - 1.5 * dc.getFontDescent(font);

    return textDimensions;
  }

  public static function getYOffset(font) {
    var yOffset = -2;
    if (font >= 8) {
      yOffset = 2;
    } else if (font >= 7) {
      yOffset = 1;
    } else if (font >= 6) {
      yOffset = -1;
    } else if (font >= 5) {
      yOffset = 0;
    } else if (font >= 4) {
      yOffset = -3;
    } else if (font == 2) {
      yOffset = -3;
    } else if (font == 1) {
      yOffset = -1;
    }

    return yOffset;
  }

  function onSettingsChanged() {
    AppBase.onSettingsChanged();
    gRunView.initializeUserData();
  }

  function getInitialView() {
    return [gRunView];
  }
}
