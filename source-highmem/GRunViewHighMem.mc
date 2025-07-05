using Toybox.WatchUi;
using Toybox.Application.Properties;

class GRunViewHighMem extends GRunView {
  // Used to determine if Activity has been paused
  protected var previousTimer;

  // Current distance
  var currentDistance;
  // Boolean to make sure value is added once per second in distanceArray
  protected var distanceArrayRequired = false;
  // Index for distanceArray
  protected var arrayDistPointer = 0;
  // Precision in seconds for distanceArray
  protected var arrayDistPrecision;
  // Circular Array to calculate custom average speed
  protected var distanceArray;

  // Current altitude
  var currentAltitude;
  // Boolean to make sure value is added once per second in distanceArray
  protected var altitudeArrayRequired = false;
  // Index for altitudeArray
  protected var arrayAltPointer = 0;
  // Precision in seconds for altitudeArray
  protected var arrayAltPrecision;
  // Circular Array to calculate custom average vertical speed
  protected var altitudeArray;

  // Used to determine if current cadence is too slow/fast
  protected var targetCadence;
  protected var cadenceRange;

  // Lap Average Heart Rate
  protected var lapHRSum = 0;
  protected var lapHRCount = 0;

  // protected var hasGetCurrentWorkoutStep =
  //   Activity has :getCurrentWorkoutStep && Activity.WorkoutStepInfo has :step;
  // protected var hasTargetType = Activity.WorkoutStep has :targetType;
  // protected var hasActiveStep = Activity.WorkoutIntervalStep has :activeStep;

  var charArray = [
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
  ];

  //0 -> 'b'
  //25 -> 'A'
  //49 -> 'Z'
  //只使用纯字母
  //number 0~49
  function getCharByNumber(number) {
    //25 + 25 = 50
    if (number > 51 || number < 0) {
      return 0;
    }
    return charArray[number];
  }

  function getValueFromChar(char) {
    // if (char >= '0' && char <= '9') {
    //   //0-9 48~57
    //   return char.toNumber() - 48; //9 -> 57 - 48
    // }
    if (char >= 'b' && char <= 'z') {
      //b-z 98~122
      return char.toNumber() - 98; //b -> 98-98=0
    }
    if (char >= 'A' && char <= 'Y') {
      //A-Y 65~89
      return char.toNumber() - 40; //A -> 65 - 65 + 25 = 26   Y -> 89 -65 + 25 = 49
    }
    return 0;
  }

  function recoverStyle(style) {
    var original = "";
    var number = "";
    var count = 1;
    var styleCharArray = style.toCharArray();

    for (var i = 0; i < style.length(); i++) {
      if (styleCharArray[i] >= '0' && styleCharArray[i] <= '9') {
        number += styleCharArray[i];
      } else {
        if (number.length() > 0) {
          count = number.toNumber();
        }
        while (count > 0) {
          original += styleCharArray[i];
          count -= 1;
        }
        count = 1;
        number = "";
      }
    }
    return original;
  }

  //aH2cFdfceir5befgheHI2ic2bH2bhCqZ
  function compressStyle(style) {
    var compressedStyle = "";
    var styleCharArray = style.toCharArray();
    for (var i = 0; i < style.length(); i++) {
      var count = 1; //eee 3e
      while (
        i < style.length() - 1 &&
        styleCharArray[i] == styleCharArray[i + 1]
      ) {
        count++;
        i++;
      }
      if (count >= 2) {
        compressedStyle += count;
        count = 1;
      }
      compressedStyle += styleCharArray[i];
    }
    return compressedStyle;
  }
  //MJHuu01u24137g0000004563uu00000HB3NLS
  //to ^H2bHcebdhq6aefgd2H5aH2amlo$
  //to aI2cIdfceir6bfghe2I5bI2bnmpZ
  //编码为1+？？+1位字符串
  function encodeStyle() {
    var style = "a";
    style += getCharByNumber(Properties.getValue("HeaderHeight")); //1

    var bits = 0;
    bits += Properties.getValue("SingleBackgroundColor") ? 1 : 0;
    bits += Properties.getValue("HeaderBackgroundColor") ? 2 : 0;
    style += getCharByNumber(bits); //2
    bits = 0;
    var value = Properties.getValue("LapDistance");
    var low = value % 50; // 获取50进制的低位
    var middle = Math.floor((value % 2500) / 50); // 获取50进制的中位
    var high = Math.floor(value / 2500); // 获取50进制的高位

    style += getCharByNumber(high); //3
    style += getCharByNumber(low); //4

    value = Properties.getValue("TargetPace");
    high = value / 50;
    low = value % 50;

    style += getCharByNumber(high); //5
    style += getCharByNumber(low); //6

    style += getCharByNumber(Properties.getValue("PaceRange")); //7

    var rowHeightRatio = getParameter("RowHeightRatio", "4,7,7,3,3");
    var numberArray = splitString(rowHeightRatio, [4, 7, 7, 3, 3]b);
    style += getCharByNumber(numberArray[0]); //8
    style += getCharByNumber(numberArray[1]); //9
    style += getCharByNumber(numberArray[2]); //10
    style += getCharByNumber(numberArray[3]); //11
    style += getCharByNumber(numberArray[4]); //12

    // Column width for second row
    var columnWidthRatio1 = getParameter("ColumnWidthRatio1", "2,1,2");
    // Column width for third row
    numberArray = splitString(columnWidthRatio1, [2, 1, 2]b);
    style += getCharByNumber(numberArray[0]); //13
    style += getCharByNumber(numberArray[1]); //14
    style += getCharByNumber(numberArray[2]); //15

    var columnWidthRatio2 = getParameter("ColumnWidthRatio2", "2,1,2");
    numberArray = splitString(columnWidthRatio2, [2, 1, 2]b);
    style += getCharByNumber(numberArray[0]); //16
    style += getCharByNumber(numberArray[1]); //17
    style += getCharByNumber(numberArray[2]); //18

    style += getCharByNumber(Properties.getValue("DataBackgroundColor")); //19
    style += getCharByNumber(Properties.getValue("DataForegroundColor")); //20

    value = Properties.getValue("Area1");
    high = value / 50;
    low = value % 50;

    style += getCharByNumber(high); //21
    style += getCharByNumber(low); //22

    value = Properties.getValue("Area2");
    high = value / 50;
    low = value % 50;

    style += getCharByNumber(high); //23
    style += getCharByNumber(low); //24

    value = Properties.getValue("Area3");
    high = value / 50;
    low = value % 50;

    style += getCharByNumber(high); //25
    style += getCharByNumber(low); //26
    value = Properties.getValue("Area4");
    high = value / 50;
    low = value % 50;

    style += getCharByNumber(high); //27
    style += getCharByNumber(low); //28
    value = Properties.getValue("Area5");
    high = value / 50;
    low = value % 50;

    style += getCharByNumber(high); //29
    style += getCharByNumber(low); //30
    value = Properties.getValue("Area6");
    high = value / 50;
    low = value % 50;

    style += getCharByNumber(high); //31
    style += getCharByNumber(low); //32
    value = Properties.getValue("Area7");
    high = value / 50;
    low = value % 50;

    style += getCharByNumber(high); //33
    style += getCharByNumber(low); //34
    value = Properties.getValue("Area8");
    high = value / 50;
    low = value % 50;

    style += getCharByNumber(high); //35
    style += getCharByNumber(low); //36
    value = Properties.getValue("Area9");
    high = value / 50;
    low = value % 50;

    style += getCharByNumber(high); //37
    style += getCharByNumber(low); //38
    value = Properties.getValue("Area10");
    high = value / 50;
    low = value % 50;

    style += getCharByNumber(high); //39
    style += getCharByNumber(low); //40
    value = Properties.getValue("AvgSpeedTime");
    high = value / 50;
    low = value % 50;

    style += getCharByNumber(high); //41
    style += getCharByNumber(low); //42
    value = Properties.getValue("AvgVerticalSpeedTime");
    high = value / 50;
    low = value % 50;

    style += getCharByNumber(high); //43
    style += getCharByNumber(low); //44

    value = Properties.getValue("TargetCadence");
    high = value / 50;
    low = value % 50;

    style += getCharByNumber(high); //45
    style += getCharByNumber(low); //46

    value = Properties.getValue("CadenceRange");
    high = value / 50;
    low = value % 50;

    style += getCharByNumber(high); //47
    style += getCharByNumber(low); //48
    style += getCharByNumber(middle); //49

    style += "Z";
    // System.println("Style was encoded:" + style);
    var compressedStyle = compressStyle(style);
    // System.println("compressedStyle is:" + compressedStyle);
    // System.println(
    //   "recovered is true:" + recoverStyle(compressedStyle).equals(style)
    // );
    Properties.setValue("style", compressedStyle);
    Properties.setValue("olderStyle", compressedStyle);
  }

  function decodeStyle(style) {
    if (style == null) {
      return;
    }
    var length = style.length();
    var mjhIdx = style.find("a");
    var nlsIdx = style.find("Z");
    if (
      !(
        length > 0 &&
        mjhIdx != null &&
        mjhIdx == 0 &&
        nlsIdx != null &&
        nlsIdx == length - 1
      )
    ) {
      return;
    }

    var originalStyle = recoverStyle(style);
    // System.println("decoding Style:" + style);
    // System.println("recovered Style:" + originalStyle);
    // System.println("recovered Style size:" + originalStyle.length());
    //aiccbdfoeirFqLjfdfgheFFigbbbFccnmpHnginZ
    var styleCharArray = originalStyle.toCharArray();
    //编码为1+ 32 +1=34位字符串
    // Properties.setValue("theme_code", getValueFromChar(styleCharArray[3]));
    //第一位也空着备用

    Properties.setValue("HeaderHeight", getValueFromChar(styleCharArray[1]));
    var value = getValueFromChar(styleCharArray[2]);
    Properties.setValue("SingleBackgroundColor", (value & 1) == 1);
    Properties.setValue("HeaderBackgroundColor", (value & 2) == 2);

    var high = getValueFromChar(styleCharArray[3]);
    var low = getValueFromChar(styleCharArray[4]);
    var middle = getValueFromChar(styleCharArray[49]);
    Properties.setValue("LapDistance", high * 2500 + middle * 50 + low);

    high = getValueFromChar(styleCharArray[5]);
    low = getValueFromChar(styleCharArray[6]);
    Properties.setValue("TargetPace", high * 50 + low);

    Properties.setValue("PaceRange", getValueFromChar(styleCharArray[7]));

    var combinedString = combineArrayStr([
      getValueFromChar(styleCharArray[8]),
      getValueFromChar(styleCharArray[9]),
      getValueFromChar(styleCharArray[10]),
      getValueFromChar(styleCharArray[11]),
      getValueFromChar(styleCharArray[12]),
    ]);
    Properties.setValue("RowHeightRatio", combinedString);

    combinedString = combineArrayStr([
      getValueFromChar(styleCharArray[13]),
      getValueFromChar(styleCharArray[14]),
      getValueFromChar(styleCharArray[15]),
    ]);
    Properties.setValue("ColumnWidthRatio1", combinedString);

    combinedString = combineArrayStr([
      getValueFromChar(styleCharArray[16]),
      getValueFromChar(styleCharArray[17]),
      getValueFromChar(styleCharArray[18]),
    ]);
    Properties.setValue("ColumnWidthRatio2", combinedString);

    Properties.setValue(
      "DataBackgroundColor",
      getValueFromChar(styleCharArray[19])
    );
    Properties.setValue(
      "DataForegroundColor",
      getValueFromChar(styleCharArray[20])
    );

    high = getValueFromChar(styleCharArray[21]);
    low = getValueFromChar(styleCharArray[22]);
    Properties.setValue("Area1", high * 50 + low);
    high = getValueFromChar(styleCharArray[23]);
    low = getValueFromChar(styleCharArray[24]);
    Properties.setValue("Area2", high * 50 + low);
    high = getValueFromChar(styleCharArray[25]);
    low = getValueFromChar(styleCharArray[26]);
    Properties.setValue("Area3", high * 50 + low);
    high = getValueFromChar(styleCharArray[27]);
    low = getValueFromChar(styleCharArray[28]);
    Properties.setValue("Area4", high * 50 + low);
    high = getValueFromChar(styleCharArray[29]);
    low = getValueFromChar(styleCharArray[30]);
    Properties.setValue("Area5", high * 50 + low);
    high = getValueFromChar(styleCharArray[31]);
    low = getValueFromChar(styleCharArray[32]);
    Properties.setValue("Area6", high * 50 + low);
    high = getValueFromChar(styleCharArray[33]);
    low = getValueFromChar(styleCharArray[34]);
    Properties.setValue("Area7", high * 50 + low);
    high = getValueFromChar(styleCharArray[35]);
    low = getValueFromChar(styleCharArray[36]);
    Properties.setValue("Area8", high * 50 + low);
    high = getValueFromChar(styleCharArray[37]);
    low = getValueFromChar(styleCharArray[38]);
    Properties.setValue("Area9", high * 50 + low);
    high = getValueFromChar(styleCharArray[39]);
    low = getValueFromChar(styleCharArray[40]);
    Properties.setValue("Area10", high * 50 + low);

    high = getValueFromChar(styleCharArray[41]);
    low = getValueFromChar(styleCharArray[42]);
    Properties.setValue("AvgSpeedTime", high * 50 + low);
    high = getValueFromChar(styleCharArray[43]);
    low = getValueFromChar(styleCharArray[44]);
    Properties.setValue("AvgVerticalSpeedTime", high * 50 + low);
    high = getValueFromChar(styleCharArray[45]);
    low = getValueFromChar(styleCharArray[46]);
    Properties.setValue("TargetCadence", high * 50 + low);
    high = getValueFromChar(styleCharArray[47]);
    low = getValueFromChar(styleCharArray[48]);
    Properties.setValue("CadenceRange", high * 50 + low);
  }

  function combineArrayStr(array) {
    var str = "";
    var size = array.size();
    for (var i = 0; i < size; i++) {
      str += array[i] + (i < size - 1 ? "," : "");
    }
    return str;
  }
  enum {
    /*
    OPTION_EMPTY = 0,
    OPTION_CURRENT_TIME = 1,
    OPTION_TIMER_TIME = 2,
    OPTION_ELAPSED_DISTANCE = 5,
    OPTION_CURRENT_HEART_RATE = 6,
    OPTION_CURRENT_PACE = 7,
    OPTION_CURRENT_SPEED = 8,
    OPTION_AVERAGE_HEART_RATE = 9,
    OPTION_AVERAGE_PACE = 10,
    OPTION_AVERAGE_SPEED = 12,
    OPTION_CALORIES = 13,
    OPTION_CURRENT_CADENCE = 14,
    OPTION_ALTITUDE = 15,
    OPTION_TOTAL_ASCENT = 16,
    OPTION_TOTAL_DESCENT = 17,
    OPTION_CURRENT_BATTERY = 18,
    OPTION_CURRENT_LOCATION_ACCURACY = 19,
    OPTION_CURRENT_LOCATION_ACCURACY_AND_BATTERY = 20,
    OPTION_CURRENT_POWER = 21,
    OPTION_AVERAGE_POWER = 22,
    OPTION_PREVIOUS_LAP_DISTANCE = 23,
    OPTION_PREVIOUS_LAP_PACE = 24,
    OPTION_CURRENT_LAP_TIME = 25,
    OPTION_CURRENT_LAP_DISTANCE = 26,
    OPTION_CURRENT_LAP_PACE = 27,
    OPTION_TRAINING_EFFECT = 28,
    OPTION_PREVIOUS_LAP_TIME = 30,
    OPTION_ETA_LAP = 31.
    OPTION_LAP_COUNT = 32,
    OPTION_AVERAGE_CADENCE = 33,
    OPTION_TIME_OFFSET = 34,
    OPTION_ETA_5K = 50,
    OPTION_ETA_10K = 51,
    OPTION_ETA_HALF_MARATHON = 52,
    OPTION_ETA_MARATHON = 53,
    OPTION_ETA_50K = 54,
    OPTION_ETA_100K = 55,
    OPTION_REQUIRED_PACE_5K = 56,
    OPTION_REQUIRED_PACE_10K = 57,
    OPTION_REQUIRED_PACE_HALF_MARATHON = 58,
    OPTION_REQUIRED_PACE_MARATHON = 59,
    OPTION_REQUIRED_PACE_50K = 60
    OPTION_REQUIRED_PACE_100K = 61
*/
    /*
    OPTION_AMBIENT_PRESSURE = 101,
    OPTION_AVERAGE_DISTANCE = 103,
    OPTION_BEARING = 105,
    OPTION_BEARING_FROM_START = 106,
    OPTION_CURRENT_HEADING = 107,
    OPTION_CURRENT_LOCATION = 108,
    OPTION_DISTANCE_TO_DESTINATION = 110,
    OPTION_DISTANCE_TO_NEXT_POINT = 111,
    OPTION_ELAPSED_TIME = 112,
    OPTION_ELEVATION_AT_DESTINATION = 113,
    OPTION_ELEVATION_AT_NEXT_POINT = 114,
    OPTION_ENERGY_EXPENDITURE = 115,
    OPTION_FRONT_DERAILLEUR_INDEX = 116,
    OPTION_FRONT_DERAILLEUR_MAX = 117,
    OPTION_FRONT_DERAILLEUR_SIZE = 118,
    OPTION_MAX_CADENCE = 119,
    OPTION_MAX_HEART_RATE = 120,
*/
    OPTION_MAX_POWER = 121,
    /*
    OPTION_MAX_SPEED = 122,
    OPTION_MEAN_SEA_LEVEL_PRESSURE = 123,
    OPTION_NAME_OF_DESTINATION = 124,
    OPTION_NAME_OF_NEXT_POINT = 125,
    OPTION_OFF_COURSE_DISTANCE = 126,
    OPTION_RAW_AMBIENT_PRESSURE = 127,
    OPTION_REAR_DERAILLEUR_INDEX = 128,
    OPTION_REAR_DERAILLEUR_MAX = 129,
    OPTION_REAR_DERAILLEUR_SIZE = 130,
    OPTION_START_LOCATION = 131,
    OPTION_START_TIME = 132,
    OPTION_SWIM_STROKE_TYPE = 133,
    OPTION_SWIM_SWOLF = 134,
    OPTION_TIMER_STATE = 135,
    OPTION_TRACK = 136,
*/
    OPTION_AVERAGE_PACE_CUSTOM = 137,
    OPTION_AVERAGE_SPEED_CUSTOM = 138,
    OPTION_AVERAGE_VERTICAL_SPEED_MIN = 139,
    OPTION_AVERAGE_VERTICAL_SPEED_HOUR = 140,

    OPTION_REQUIRED_SPEED_5K = 147,
    OPTION_REQUIRED_SPEED_10K = 148,
    OPTION_REQUIRED_SPEED_HALF_MARATHON = 149,
    OPTION_REQUIRED_SPEED_MARATHON = 150,
    OPTION_REQUIRED_SPEED_100K = 151,

    OPTION_REQUIRED_PACE_LAP = 152,
    OPTION_REQUIRED_SPEED_LAP = 153,

    OPTION_LAP_AVERAGE_HEART_RATE = 170,
  }

  function getParameter(paramName, defaultValue) {
    var paramValue = GRunView.getParameter(paramName, defaultValue);
    if (paramName.length() > 4 && paramName.substring(0, 4).equals("Area")) {
      if (
        paramValue == OPTION_AVERAGE_PACE_CUSTOM ||
        paramValue == OPTION_AVERAGE_SPEED_CUSTOM
      ) {
        distanceArrayRequired = true;
      }

      if (
        paramValue == OPTION_AVERAGE_VERTICAL_SPEED_MIN ||
        paramValue == OPTION_AVERAGE_VERTICAL_SPEED_HOUR
      ) {
        altitudeArrayRequired = true;
      }
    }

    return paramValue;
  }

  function initializeUserData() {
    distanceArrayRequired = false;
    altitudeArrayRequired = false;

    var style = Properties.getValue("style");
    if (style != null && !style.equals(Properties.getValue("olderStyle"))) {
      try {
        // Sys.println("going to decode style:" + style);
        decodeStyle(style);
        Properties.setValue("olderStyle", style);
      } catch (e) {
        System.println(e);
      }
    }
    GRunView.initializeUserData();

    var info = Activity.getActivityInfo();

    if (distanceArrayRequired == false) {
      distanceArray = null;
    } else {
      var oldParam = arrayDistPrecision;
      arrayDistPrecision = getParameter("AvgSpeedTime", 15).toNumber();
      if (oldParam != arrayDistPrecision) {
        distanceArray = new [arrayDistPrecision];
        currentDistance =
          info.elapsedDistance == null ? 0 : info.elapsedDistance;

        for (var i = 0; i < arrayDistPrecision; i++) {
          distanceArray[i] = currentDistance;
        }
      }
    }

    if (altitudeArrayRequired == false) {
      altitudeArray = null;
    } else {
      var oldParam = arrayAltPrecision;
      arrayAltPrecision = getParameter("AvgVerticalSpeedTime", 60).toNumber();
      if (oldParam != arrayAltPrecision) {
        altitudeArray = new [arrayAltPrecision];
        currentAltitude = info.altitude == null ? 0 : info.altitude;

        for (var i = 0; i < arrayAltPrecision; i++) {
          altitudeArray[i] = currentAltitude;
        }
      }
    }

    targetCadence = getParameter("TargetCadence", 180);
    cadenceRange = getParameter("CadenceRange", 5);

    try {
      encodeStyle();
    } catch (e) {
      System.println(e);
    }
    // DEBUG
    //System.println("elapsedDistance,OPTION_TIMER_TIME,OPTION_TIMER_TIME,OPTION_ELAPSED_DISTANCE,OPTION_ELAPSED_DISTANCE,OPTION_CURRENT_HEART_RATE,OPTION_CURRENT_HEART_RATE,OPTION_CURRENT_PACE,OPTION_CURRENT_PACE,OPTION_CURRENT_SPEED,OPTION_CURRENT_SPEED,OPTION_AVERAGE_HEART_RATE,OPTION_AVERAGE_HEART_RATE,OPTION_AVERAGE_PACE,OPTION_AVERAGE_PACE,OPTION_AVERAGE_SPEED,OPTION_AVERAGE_SPEED,OPTION_CALORIES,OPTION_CALORIES,OPTION_CURRENT_CADENCE,OPTION_CURRENT_CADENCE,OPTION_ALTITUDE,OPTION_ALTITUDE,OPTION_TOTAL_ASCENT,OPTION_TOTAL_ASCENT,OPTION_TOTAL_DESCENT,OPTION_TOTAL_DESCENT,OPTION_CURRENT_BATTERY,OPTION_CURRENT_BATTERY,OPTION_CURRENT_LOCATION_ACCURACY,OPTION_CURRENT_LOCATION_ACCURACY,OPTION_CURRENT_LOCATION_ACCURACY_AND_BATTERY,OPTION_CURRENT_LOCATION_ACCURACY_AND_BATTERY,OPTION_PREVIOUS_LAP_DISTANCE,OPTION_PREVIOUS_LAP_DISTANCE,OPTION_PREVIOUS_LAP_PACE,OPTION_PREVIOUS_LAP_PACE,OPTION_CURRENT_LAP_TIME,OPTION_CURRENT_LAP_TIME,OPTION_CURRENT_LAP_DISTANCE,OPTION_CURRENT_LAP_DISTANCE,OPTION_CURRENT_LAP_PACE,OPTION_CURRENT_LAP_PACE,OPTION_TRAINING_EFFECT,OPTION_TRAINING_EFFECT,OPTION_PREVIOUS_LAP_TIME,OPTION_PREVIOUS_LAP_TIME,OPTION_ETA_LAP,OPTION_ETA_LAP,OPTION_LAP_COUNT,OPTION_LAP_COUNT,OPTION_AVERAGE_CADENCE,OPTION_AVERAGE_CADENCE,OPTION_TIME_OFFSET,OPTION_TIME_OFFSET,OPTION_ETA_5K,OPTION_ETA_5K,OPTION_ETA_10K,OPTION_ETA_10K,OPTION_ETA_HALF_MARATHON,OPTION_ETA_HALF_MARATHON,OPTION_ETA_MARATHON,OPTION_ETA_MARATHON,OPTION_ETA_50K,,OPTION_ETA_50K,OPTION_ETA_100K,OPTION_ETA_100K,OPTION_REQUIRED_PACE_5K,OPTION_REQUIRED_PACE_5K,OPTION_REQUIRED_PACE_10K,OPTION_REQUIRED_PACE_10K,OPTION_REQUIRED_PACE_HALF_MARATHON,OPTION_REQUIRED_PACE_HALF_MARATHON,OPTION_REQUIRED_PACE_MARATHON,OPTION_REQUIRED_PACE_MARATHON,OPTION_REQUIRED_PACE_50K,OPTION_REQUIRED_PACE_50K,OPTION_REQUIRED_PACE_100K,OPTION_REQUIRED_PACE_100K,OPTION_MAX_POWER,OPTION_MAX_POWER,OPTION_AVERAGE_PACE_CUSTOM,OPTION_AVERAGE_PACE_CUSTOM,OPTION_AVERAGE_SPEED_CUSTOM,OPTION_AVERAGE_SPEED_CUSTOM,OPTION_AVERAGE_VERTICAL_SPEED_MIN,OPTION_AVERAGE_VERTICAL_SPEED_MIN,OPTION_AVERAGE_VERTICAL_SPEED_HOUR,OPTION_AVERAGE_VERTICAL_SPEED_HOUR,OPTION_REQUIRED_SPEED_5K,OPTION_REQUIRED_SPEED_5K,OPTION_REQUIRED_SPEED_10K,OPTION_REQUIRED_SPEED_10K,OPTION_REQUIRED_SPEED_HALF_MARATHON,OPTION_REQUIRED_SPEED_HALF_MARATHON,OPTION_REQUIRED_SPEED_MARATHON,OPTION_REQUIRED_SPEED_MARATHON,OPTION_REQUIRED_SPEED_100K,OPTION_REQUIRED_SPEED_100K,OPTION_REQUIRED_PACE_LAP,OPTION_REQUIRED_PACE_LAP,OPTION_REQUIRED_SPEED_LAP,OPTION_REQUIRED_SPEED_LAP,OPTION_LAP_AVERAGE_HEART_RATE,OPTION_LAP_AVERAGE_HEART_RATE");
  }

  function initialize() {
    GRunView.initialize();
  }

  function onTimerLap() {
    GRunView.onTimerLap();
    lapHRSum = 0;
    lapHRCount = 0;
  }

  function computeValue(info, id, value, valueData) {
    if (value <= 100) {
      return GRunView.computeValue(info, id, value, valueData);
    }

    /*
    // Ambient pressure in Pascals (Pa).
    if ( (value == OPTION_AMBIENT_PRESSURE) && (info.ambientPressure  != null) )
    {
      return info.ambientPressure;
    }
    
    // Average swim stroke distance from the previous interval in meters (m)
    if ( (value == OPTION_AVERAGE_DISTANCE) && (info.averageDistance != null) )
    {
      if (System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE) {
        // Convert in miles (mi)
        return (info.averageDistance / 1000 * CONVERSION_KM_TO_MILE).toNumber(); 
      }
      
      // Convert to kilometers (km)
      return (info.averageDistance / 1000).toNumber();
    }
    
    // Current bearing in radians
    if ( (value == OPTION_BEARING) && (info.bearing != null) ) 
    {
      return info.bearing;
    }
    
    // Bearing from the starting location to the destination in radians
    if ( (value == OPTION_BEARING_FROM_START) && (info.bearingFromStart != null) ) 
    {
      return info.bearingFromStart;
    }
    
    // True north referenced heading in radians
    if ( (value == OPTION_CURRENT_HEADING) && (info.currentHeading != null) )
    {
      return info.currentHeading;
    }
    
    // Current location
    if ( (value == OPTION_CURRENT_LOCATION) && (info.currentLocation != null) ) 
    {
      // return [ latitude, longitude ]
      return info.currentLocation.toDegrees();
    }
    
    // Distance to the destination in meters (m)
    if ( (value == OPTION_DISTANCE_TO_DESTINATION) && (info.distanceToDestination != null) )   
    {
      if (System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE) {
        // Convert in miles (mi)
        return (info.distanceToDestination / 1000 * CONVERSION_KM_TO_MILE).toNumber(); 
      }
      
      // Convert to kilometers (km)
      return (info.distanceToDestination / 1000).toNumber();
    }
    
    // Distance to the next point in meters (m)
    if ( (value == OPTION_DISTANCE_TO_NEXT_POINT) && (info.distanceToNextPoint != null) )
    {
      if (System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE) {
        // Convert in miles (mi)
        return (info.distanceToNextPoint / 1000 * CONVERSION_KM_TO_MILE).toNumber(); 
      }
      
      // Convert to kilometers (km)
      return (info.distanceToNextPoint / 1000).toNumber();
    }
    
    // Elapsed time of the current activity in milliseconds (ms)
    // Time since the recording starts. Elapsed Time Continue to increment when activity is paused. 
    if ( (value == OPTION_ELAPSED_TIME) (info.elapsedTime != null) )
    {
      // Convert to second
      return info.elapsedTime / 1000;
    }
    
    // Elevation at the destination in meters (m)
    if ( (value == OPTION_ELEVATION_AT_DESTINATION) && (info.elevationAtDestination != null) )
    {
      if (System.getDeviceSettings().heightUnits == System.UNIT_STATUTE) {
        // Convert in miles (mi)
        return (info.elevationAtDestination / 1000 * CONVERSION_KM_TO_MILE).toNumber(); 
      }
      
      return (info.elevationAtDestination / 1000).toNumber();
    }
    
    // Elevation at the next point in meters (m)
    if ( (value == OPTION_ELEVATION_AT_NEXT_POINT) && (info.elevationAtNextPoint != null) )
    {
      if (System.getDeviceSettings().heightUnits == System.UNIT_STATUTE) {
        // Convert in miles (mi)
        return (info.elevationAtNextPoint / 1000 * CONVERSION_KM_TO_MILE).toNumber(); 
      }
      
      return (info.elevationAtNextPoint / 1000).toNumber();
    }
    
    // Current energy expenditure in kilocalories per minute (kcals/min)
    if ( (value == OPTION_ENERGY_EXPENDITURE) && (info.energyExpenditure != null) )
    {
      return info.energyExpenditure;
    }
    
    // Current front bicycle derailleur index
    if ( (value == OPTION_FRONT_DERAILLEUR_INDEX) && (info.frontDerailleurIndex != null) )
    {
      return info.frontDerailleurIndex;
    }
    
    // Front bicycle derailleur maximum index
    if ( (value == OPTION_FRONT_DERAILLEUR_MAX) && (info.frontDerailleurMax != null) )
    {
      return info.frontDerailleurMax;
    }
    
    // Front bicycle derailleur gear size in number of teeth
    if ( (value == OPTION_FRONT_DERAILLEUR_SIZE) && (info.frontDerailleurSize != null) )
    {
      return info.frontDerailleurSize;
    }
    
    // Maximum cadence recorded during the current activity in revolutions per minute (rpm)
    if ( (value == OPTION_MAX_CADENCE) && (info.maxCadence != null) )
    {
      return info.maxCadence;
    }

    // Maximum heart rate recorded during the current activity in beats per minute (bpm)
    if ( (value == OPTION_MAX_HEART_RATE) && (info.maxHeartRate != null) ) 
    {
      return info.maxHeartRate;
    }
    */

    // Maximum power recorded during the current activity in Watts (W)
    if (value == OPTION_MAX_POWER && info.maxPower != null) {
      return info.maxPower;
    }

    /*
    // Maximum speed recorded during the current activity in meters per second (mps)
    if ( (value == OPTION_MAX_SPEED) && (info.maxSpeed != null) )
    {
      if (System.getDeviceSettings().paceUnits == System.UNIT_STATUTE) {
        // Convert in miles/h
        return info.maxSpeed * 3.6 * CONVERSION_KM_TO_MILE;
      }
      
      // Convert in km/h
      return info.maxSpeed * 3.6;
    }
    
    // The mean sea level barometric pressure in Pascals (Pa)
    if ( (value == OPTION_MEAN_SEA_LEVEL_PRESSURE) && (info.meanSeaLevelPressure != null) )
    {
      return info.meanSeaLevelPressure;
    }

    // Name of the destination
    if ( (value == OPTION_NAME_OF_DESTINATION) && (info.nameOfDestination != null) )
    {
      return info.nameOfDestination;
    }

    // Name of the next point
    if ( (value == OPTION_NAME_OF_NEXT_POINT) && (info.nameOfNextPoint != null) )
    {
      return info.nameOfNextPoint;
    }

    // Distance to the nearest point on the current course in meters (m)
    if ( (value == OPTION_OFF_COURSE_DISTANCE) && (info.offCourseDistance != null) )
    {
      if (System.getDeviceSettings().paceUnits == System.UNIT_STATUTE) {
        // Convert in miles (mi)
        return (info.offCourseDistance / 1000 * CONVERSION_KM_TO_MILE).toNumber(); 
      }
      
      return (info.offCourseDistance / 1000).toNumber();
    }
    
    // The raw ambient pressure in Pascals (Pa)
    if ( (value == OPTION_RAW_AMBIENT_PRESSURE) && (info.rawAmbientPressure != null) )
    {
      return info.rawAmbientPressure;
    }

    // The current front bicycle derailleur index
    if ( (value == OPTION_REAR_DERAILLEUR_INDEX) && (info.rearDerailleurIndex != null) )
    {
      return info.rearDerailleurIndex;
    }

    // The rear bicycle derailleur maximum index
    if ( (value == OPTION_REAR_DERAILLEUR_MAX) && (info.rearDerailleurMax != null) )
    {
      return info.rearDerailleurMax;
    }

    // The rear bicycle derailleur gear size in number of teeth
    if ( (value == OPTION_REAR_DERAILLEUR_SIZE) && (info.rearDerailleurSize != null) )
    {
      return info.rearDerailleurSize;
    }

    // The starting location of the current activity
    if ( (value == OPTION_START_LOCATION) && (info.startLocation != null) )
    {
      // return [ latitude, longitude ]
      return info.startLocation.toDegrees();
    }

    // The starting time of the current activity
    if ( (value == OPTION_START_TIME) && (info.startTime != null) )
    {
      return info.startTime;
    }

    // The swim stroke type from the previous length
    if ( (value == OPTION_SWIM_STROKE_TYPE) && (info.swimStrokeType != null) )
    {
      return info.swimStrokeType;
    }

    // The SWOLF score from the previous length
    if ( (value == OPTION_SWIM_SWOLF) && (info.swimSwolf != null) )
    {
      return info.swimSwolf;
    }

    // The recording timer state. One off:
    //  - Activity.TIMER_STATE_OFF
    //  - Activity.TIMER_STATE_ON
    //  - Activity.TIMER_STATE_PAUSED
    //  - Activity.TIMER_STATE_STOPPED
    if ( (value == OPTION_TIMER_STATE) && (info.timerState != null) )
    {
      return info.timerState;
    }
    
    // The current track in radians
    if ( (value == OPTION_TRACK) && (info.track != null) )
    {
      return info.track;
    }
    */

    // Current Speed calculated using the last arrayDistPrecision seconds
    if (value == OPTION_AVERAGE_SPEED_CUSTOM && currentDistance != null) {
      var calculatedDistance =
        currentDistance - distanceArray[arrayDistPointer % arrayDistPrecision];
      var indexLastArrayElement =
        arrayDistPointer + 1 < arrayDistPrecision
          ? arrayDistPointer + 1
          : arrayDistPrecision;
      return convertUnitIfRequired(
        (calculatedDistance / indexLastArrayElement) * 3.6,
        0.62137119 /* CONVERSION_KM_TO_MILE */,
        isPaceUnitsImperial
      );
    }

    // Current Pace calculated using the last arrayDistPrecision seconds
    if (value == OPTION_AVERAGE_PACE_CUSTOM && currentDistance != null) {
      var calculatedDistance =
        currentDistance - distanceArray[arrayDistPointer % arrayDistPrecision];
      if (calculatedDistance <= 0) {
        return 0;
      }

      var indexLastArrayElement =
        arrayDistPointer + 1 < arrayDistPrecision
          ? arrayDistPointer + 1
          : arrayDistPrecision;
      return convertUnitIfRequired(
        indexLastArrayElement / (calculatedDistance / 1000.0),
        1.609344 /* CONVERSION_MILE_TO_KM */,
        isPaceUnitsImperial
      );
    }

    // Vertical Speed in meter or feet per min calculated using the last arrayAltPrecision seconds
    if (value == OPTION_AVERAGE_VERTICAL_SPEED_MIN && currentAltitude != null) {
      var calculatedAltitude =
        currentAltitude - altitudeArray[arrayAltPointer % arrayAltPrecision];
      var indexLastArrayElement =
        arrayAltPointer + 1 < arrayAltPrecision
          ? arrayAltPointer + 1
          : arrayAltPrecision;
      return convertUnitIfRequired(
        (calculatedAltitude / indexLastArrayElement) * 60,
        3.28084 /* CONVERSION_METER_TO_FEET */,
        isElevationUnitsImperial
      );
    }

    // Vertical Speed in meter or feet per hour calculated using the last arrayAltPrecision seconds
    if (
      value == OPTION_AVERAGE_VERTICAL_SPEED_HOUR &&
      currentAltitude != null
    ) {
      var calculatedAltitude =
        currentAltitude - altitudeArray[arrayAltPointer % arrayAltPrecision];
      var indexLastArrayElement =
        arrayAltPointer + 1 < arrayAltPrecision
          ? arrayAltPointer + 1
          : arrayAltPrecision;
      return convertUnitIfRequired(
        (calculatedAltitude / indexLastArrayElement) * 3600,
        3.28084 /* CONVERSION_METER_TO_FEET */,
        isElevationUnitsImperial
      );
    }

    if (
      value >= OPTION_REQUIRED_SPEED_5K &&
      value <= OPTION_REQUIRED_SPEED_100K
    ) {
      var requiredPace = GRunView.computeValue(
        info,
        id,
        value - OPTION_REQUIRED_SPEED_5K + 56 /* OPTION_REQUIRED_PACE_5K */,
        valueData
      );

      // Convert to km/h or mph
      return 60 / (requiredPace == 0 ? 0.01 : requiredPace);
    }

    if (
      value == OPTION_REQUIRED_PACE_LAP ||
      value == OPTION_REQUIRED_SPEED_LAP
    ) {
      var distanceMetric = convertUnitIfRequired(
        distance * 1000,
        1.609344 /* CONVERSION_MILE_TO_KM */,
        isDistanceUnitsImperial
      );
      var startDistanceCurrentLapMetric = convertUnitIfRequired(
        startDistanceCurrentLap * 1000,
        1.609344 /* CONVERSION_MILE_TO_KM */,
        isDistanceUnitsImperial
      );

      var distanceCurrentLap = distanceMetric - startDistanceCurrentLapMetric;
      var remainingLapDistance = (lapDistance - distanceCurrentLap) / 1000.0;
      if (remainingLapDistance <= 0) {
        return 0;
      }

      // Elapsed time for the current lap
      var timerCurrentLap = timer - startTimerCurrentLap;
      if (timerCurrentLap <= 0) {
        return valueData;
      }

      var targetPaceMetric = convertUnitIfRequired(
        targetPace,
        0.62137119 /* CONVERSION_KM_TO_MILE */,
        isPaceUnitsImperial
      );
      var targetTime = targetPaceMetric * (lapDistance / 1000.0);
      var remainingTime = targetTime - timerCurrentLap;

      if (value <= OPTION_REQUIRED_PACE_LAP) {
        return convertUnitIfRequired(
          remainingTime / remainingLapDistance,
          1.609344 /* CONVERSION_MILE_TO_KM */,
          isPaceUnitsImperial
        );
      }

      if (remainingTime == 0) {
        return 0;
      }
      return convertUnitIfRequired(
        (remainingLapDistance / remainingTime) * 3600,
        0.62137119 /* CONVERSION_KM_TO_MILE */,
        isPaceUnitsImperial
      );
    }

    if (
      value == OPTION_LAP_AVERAGE_HEART_RATE &&
      info.currentHeartRate != null
    ) {
      if (lapCount <= 0 && info.averageHeartRate != null) {
        return info.averageHeartRate;
      }

      lapHRCount++;
      lapHRSum += info.currentHeartRate;
      return round(lapHRSum / lapHRCount.toFloat());
    }

    return valueData;
  }

  /*
  function debugMetric(name, type, defaultValue, info)
  {
    var value = computeValue(info, 1, type, defaultValue);
    System.print(value + "," + getFormattedValue(1, type, value) + ",");
  }
  
  function printAllMetrics(info)
  {
    System.print(info.elapsedDistance + ",");
    debugMetric("OPTION_TIMER_TIME", 2, "", info);
    debugMetric("OPTION_ELAPSED_DISTANCE", 5, "", info);
    debugMetric("OPTION_CURRENT_HEART_RATE", 6, "", info);
    debugMetric("OPTION_CURRENT_PACE", 7, "", info);
    debugMetric("OPTION_CURRENT_SPEED", 8, 0, info);
    debugMetric("OPTION_AVERAGE_HEART_RATE", 9, "", info);
    debugMetric("OPTION_AVERAGE_PACE", 10, "", info);
    debugMetric("OPTION_AVERAGE_SPEED", 12, 0, info);
    debugMetric("OPTION_CALORIES", 13, "", info);
    debugMetric("OPTION_CURRENT_CADENCE", 14, "", info);
    debugMetric("OPTION_ALTITUDE", 15, "", info);
    debugMetric("OPTION_TOTAL_ASCENT", 16, 0, info);
    debugMetric("OPTION_TOTAL_DESCENT", 17, 0, info);
    debugMetric("OPTION_CURRENT_BATTERY", 18, "", info);
    debugMetric("OPTION_CURRENT_LOCATION_ACCURACY", 19, "", info);
    debugMetric("OPTION_CURRENT_LOCATION_ACCURACY_AND_BATTERY", 20, "", info);
    debugMetric("OPTION_PREVIOUS_LAP_DISTANCE", 23, "", info);
    debugMetric("OPTION_PREVIOUS_LAP_DISTANCE", 24, "", info);
    debugMetric("OPTION_CURRENT_LAP_TIME", 25, "", info);
    debugMetric("OPTION_CURRENT_LAP_DISTANCE", 26, "", info);
    debugMetric("OPTION_CURRENT_LAP_PACE", 27, "", info);
    debugMetric("OPTION_TRAINING_EFFECT", 28, 0, info);
    debugMetric("OPTION_PREVIOUS_LAP_TIME", 30, "", info);
    debugMetric("OPTION_ETA_LAP", 31, "", info);
    debugMetric("OPTION_LAP_COUNT", 32, "", info);
    debugMetric("OPTION_AVERAGE_CADENCE", 33, "", info);
    debugMetric("OPTION_TIME_OFFSET", 34, "", info);
    debugMetric("OPTION_ETA_5K", 50, "", info);
    debugMetric("OPTION_ETA_10K", 51, "", info);
    debugMetric("OPTION_ETA_HALF_MARATHON", 52, "", info);
    debugMetric("OPTION_ETA_MARATHON", 53, "", info);
    debugMetric("OPTION_ETA_50K", 54, "", info);
    debugMetric("OPTION_ETA_100K", 55, "", info);
    debugMetric("OPTION_REQUIRED_PACE_5K", 56, "", info);
    debugMetric("OPTION_REQUIRED_PACE_10K", 57, "", info);
    debugMetric("OPTION_REQUIRED_PACE_HALF_MARATHON", 58, "", info);
    debugMetric("OPTION_REQUIRED_PACE_MARATHON", 59, "", info);
    debugMetric("OPTION_REQUIRED_PACE_50K", 60, "", info);
    debugMetric("OPTION_REQUIRED_PACE_100K", 61, "", info);

    debugMetric("OPTION_MAX_POWER", OPTION_MAX_POWER, "", info);
    debugMetric("OPTION_AVERAGE_PACE_CUSTOM", OPTION_AVERAGE_PACE_CUSTOM, "", info);
    debugMetric("OPTION_AVERAGE_SPEED_CUSTOM", OPTION_AVERAGE_SPEED_CUSTOM, 0, info);
    debugMetric("OPTION_AVERAGE_VERTICAL_SPEED_MIN", OPTION_AVERAGE_VERTICAL_SPEED_MIN, 0, info);
    debugMetric("OPTION_AVERAGE_VERTICAL_SPEED_HOUR", OPTION_AVERAGE_VERTICAL_SPEED_HOUR, 0, info);
    debugMetric("OPTION_REQUIRED_SPEED_5K", OPTION_REQUIRED_SPEED_5K, 0, info);
    debugMetric("OPTION_REQUIRED_SPEED_10K", OPTION_REQUIRED_SPEED_10K, 0, info);
    debugMetric("OPTION_REQUIRED_SPEED_HALF_MARATHON", OPTION_REQUIRED_SPEED_HALF_MARATHON, 0, info);
    debugMetric("OPTION_REQUIRED_SPEED_MARATHON", OPTION_REQUIRED_SPEED_MARATHON, 0, info);
    debugMetric("OPTION_REQUIRED_SPEED_100K", OPTION_REQUIRED_SPEED_100K, 0, info);
    debugMetric("OPTION_REQUIRED_PACE_LAP", OPTION_REQUIRED_PACE_LAP, "", info);
    debugMetric("OPTION_REQUIRED_SPEED_LAP", OPTION_REQUIRED_SPEED_LAP, 0, info);
    debugMetric("OPTION_LAP_AVERAGE_HEART_RATE", OPTION_LAP_AVERAGE_HEART_RATE, 0, info);
    System.print(altitudeArray);
    System.println("");
  }
  */

  function compute(info) {
    previousTimer = timer;
    currentDistance = info.elapsedDistance;
    currentAltitude = info.altitude;
    GRunView.compute(info);

    // DEBUG
    //printAllMetrics(info);

    if (previousTimer == timer) {
      return;
    }

    if (
      distanceArray != null &&
      currentDistance != null &&
      currentDistance > 0
    ) {
      distanceArray[arrayDistPointer % arrayDistPrecision] = currentDistance;
      arrayDistPointer++;
    }

    if (altitudeArray != null && currentAltitude != null) {
      altitudeArray[arrayAltPointer % arrayAltPrecision] = currentAltitude;
      arrayAltPointer++;
    }
  }

  function getHeaderName(type) {
    if (type <= 100) {
      return GRunView.getHeaderName(type);
    }

    //if (type == OPTION_AMBIENT_PRESSURE) { return "PRES"; }
    //if (type == OPTION_AVERAGE_DISTANCE) { return "A DIST"; }
    //if (type == OPTION_BEARING) { return "BEAR"; }
    //if (type == OPTION_BEARING_FROM_START) { return "BEARS"; }
    //if (type == OPTION_CURRENT_HEADING) { return "HEAD"; }
    //if (type == OPTION_CURRENT_LOCATION) { return "LOC"; }
    //if (type == OPTION_DISTANCE_TO_DESTINATION) { return "DISTD"; }
    //if (type == OPTION_DISTANCE_TO_NEXT_POINT) { return "DISTN"; }
    //if (type == OPTION_ELAPSED_TIME) { return "TIME"; }
    //if (type == OPTION_ELEVATION_AT_DESTINATION) { return "ELVD"; }
    //if (type == OPTION_ELEVATION_AT_NEXT_POINT) { return "DELNP"; }
    //if (type == OPTION_ENERGY_EXPENDITURE) { return "NRG"; }
    //if (type == OPTION_FRONT_DERAILLEUR_INDEX) { return "DERI"; }
    //if (type == OPTION_FRONT_DERAILLEUR_MAX) { return "DERM"; }
    //if (type == OPTION_FRONT_DERAILLEUR_SIZE) { return "DERS"; }
    //if (type == OPTION_MAX_CADENCE) { return "MAX CAD"; }
    //if (type == OPTION_MAX_HEART_RATE) { return "MAX HR"; }
    if (type == OPTION_MAX_POWER) {
      return "最大功率";
    }
    //if (type == OPTION_MAX_SPEED) { return "MAX SPD"; }
    //if (type == OPTION_MEAN_SEA_LEVEL_PRESSURE) { return "SEA PRES"; }
    //if (type == OPTION_NAME_OF_DESTINATION) { return "DEST"; }
    //if (type == OPTION_NAME_OF_NEXT_POINT) { return "NEXT P"; }
    //if (type == OPTION_OFF_COURSE_DISTANCE) { return "DIST NP"; }
    //if (type == OPTION_RAW_AMBIENT_PRESSURE) { return "PRESS"; }
    //if (type == OPTION_REAR_DERAILLEUR_INDEX) { return "RDERI"; }
    //if (type == OPTION_REAR_DERAILLEUR_MAX) { return "RDERM"; }
    //if (type == OPTION_REAR_DERAILLEUR_SIZE) { return "RDERS"; }
    //if (type == OPTION_START_LOCATION) { return "S LOC"; }
    //if (type == OPTION_START_TIME) { return "S TIME"; }
    //if (type == OPTION_SWIM_STROKE_TYPE) { return "STK TYPE"; }
    //if (type == OPTION_SWIM_SWOLF) { return "SWOLF"; }
    //if (type == OPTION_TIMER_STATE) { return "TMR ST"; }
    //if (type == OPTION_TRACK) { return "TRACK"; }
    if (type == OPTION_AVERAGE_PACE_CUSTOM) {
      return "配速(" + arrayDistPrecision + ")";
    }
    if (type == OPTION_AVERAGE_SPEED_CUSTOM) {
      return "速度(" + arrayDistPrecision + ")";
    }
    if (
      type == OPTION_AVERAGE_VERTICAL_SPEED_MIN ||
      type == OPTION_AVERAGE_VERTICAL_SPEED_HOUR
    ) {
      return "垂直速度(" + arrayAltPrecision + ")";
    }
    if (type == OPTION_REQUIRED_SPEED_5K) {
      return "5K 所需配速";
    }
    if (type == OPTION_REQUIRED_SPEED_10K) {
      return "10K 所需配速";
    }
    if (type == OPTION_REQUIRED_SPEED_HALF_MARATHON) {
      return "21K 所需配速";
    }
    if (type == OPTION_REQUIRED_SPEED_MARATHON) {
      return "42K 所需配速";
    }
    if (type == OPTION_REQUIRED_SPEED_100K) {
      return "100K 所需配速";
    }
    if (type == OPTION_REQUIRED_PACE_LAP) {
      return "单圈所需配速";
    }
    if (type == OPTION_REQUIRED_SPEED_LAP) {
      return "单圈所需速度";
    }
    if (type == OPTION_LAP_AVERAGE_HEART_RATE) {
      return "单圈平均心率";
    }

    return "";
  }

  function getFormattedValue(id, type, value) {
    if (type <= 100) {
      return GRunView.getFormattedValue(id, type, value);
    }

    //if ( (type == OPTION_CURRENT_LOCATION) && (value instanceof Array) )
    //{
    //  return "[" + value[0].format("%.2f") + "," + value[1].format("%.2f") + "]";
    //}

    if (
      type == OPTION_AVERAGE_SPEED_CUSTOM ||
      type == OPTION_REQUIRED_SPEED_5K ||
      type == OPTION_REQUIRED_SPEED_10K ||
      type == OPTION_REQUIRED_SPEED_HALF_MARATHON ||
      type == OPTION_REQUIRED_SPEED_MARATHON ||
      type == OPTION_REQUIRED_SPEED_100K ||
      type == OPTION_REQUIRED_SPEED_LAP
    ) {
      if (value < 10) {
        return value.format("%.2f");
      }
      return value.format("%.1f");
    }

    if (
      type == OPTION_AVERAGE_PACE_CUSTOM ||
      type == OPTION_REQUIRED_PACE_LAP
    ) {
      return formatDuration(value, false);
    }

    if (
      type == OPTION_AVERAGE_VERTICAL_SPEED_MIN ||
      type == OPTION_AVERAGE_VERTICAL_SPEED_HOUR
    ) {
      return Math.round(value).format("%.0f");
    }

    return GRunView.getFormattedValue(id, type, value);
  }

  function getColor(type, value) {
    if (
      type == 14 /* OPTION_CURRENT_CADENCE */ ||
      type == 33 /* OPTION_AVERAGE_CADENCE */
    ) {
      if (value <= 0) {
        return null;
      }
      if (value < targetCadence - cadenceRange) {
        return Graphics.COLOR_RED;
      } // 0x00AAFF
      if (value > targetCadence + cadenceRange) {
        return Graphics.COLOR_BLUE;
      } // 0xFF0000
      return Graphics.COLOR_DK_GREEN; // 0x00AA00
    }

    if (type <= 100) {
      return GRunView.getColor(type, value);
    }

    if (type == OPTION_AVERAGE_SPEED_CUSTOM) {
      if (value > 0) {
        type = OPTION_AVERAGE_PACE_CUSTOM;
        value = 1000 / (value / 3.6);
      }
    }
    if (type == OPTION_AVERAGE_PACE_CUSTOM) {
      if (value <= 0) {
        return null;
      }
      if (value < targetPace - paceRange) {
        return Graphics.COLOR_BLUE;
      }
      if (value > targetPace + paceRange) {
        return Graphics.COLOR_RED;
      }
      return Graphics.COLOR_DK_GREEN;
    }
    // if (type == OPTION_AVERAGE_PACE_CUSTOM) {
    //   if (value <= 0) {
    //     return null;
    //   }
    //   var paceHighLowArray = getWorkoutStepGoalPace(targetPace, paceRange);

    //   System.println("paceLow = " + paceHighLowArray[0]);
    //   System.println("paceHigh = " + paceHighLowArray[1]);
    //   if (value < paceHighLowArray[0]) {
    //     return Graphics.COLOR_BLUE;
    //   }
    //   if (value > paceHighLowArray[1]) {
    //     return Graphics.COLOR_RED;
    //   }
    //   return Graphics.COLOR_DK_GREEN;
    // }

    if (type == OPTION_LAP_AVERAGE_HEART_RATE) {
      if (value < hrZones[0]) {
        return null;
      } // Black
      if (value < hrZones[1]) {
        return 0xaaaaaa;
      } // Light Gray
      if (value < hrZones[2]) {
        return 0x00aaff;
      } // Blue
      if (value < hrZones[3]) {
        return 0x00aa00;
      } // Dark Green
      if (value < hrZones[4]) {
        return 0xff5500;
      } // Orange
      return 0xff0000; // Red
    }

    return null;
  }

  // function getWorkoutStepGoalPace(targetPace, paceRange) {
  //   if (hasGetCurrentWorkoutStep) {
  //     var workoutStepInfo = Activity.getCurrentWorkoutStep();
  //     var workoutStep = null;
  //     if (
  //       workoutStepInfo != null &&
  //       workoutStepInfo.step instanceof Activity.WorkoutStep
  //     ) {
  //       workoutStep = workoutStepInfo.step;
  //     } else {
  //       var intervalStep = workoutStepInfo.step;
  //       if (hasActiveStep && intervalStep != null) {
  //         workoutStep = intervalStep.activeStep;
  //       }
  //     }
  //     if (hasTargetType && workoutStep != null) {
  //       if (workoutStep.targetType == Activity.WORKOUT_STEP_TARGET_SPEED) {
  //         var low = workoutStep.targetValueLow;
  //         var high = workoutStep.targetValueHigh;
  //         low = ((isDistanceUnitsImperial ? 1609.344 : 1000) / low).toNumber();
  //         high = (
  //           (isDistanceUnitsImperial ? 1609.344 : 1000) / high
  //         ).toNumber();

  //         return [low, high];
  //       }
  //     }
  //   } else {
  //     return [targetPace - paceRange, targetPace + paceRange];
  //   }
  // }
}
