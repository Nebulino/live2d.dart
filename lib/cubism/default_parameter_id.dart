/// Standard Cubism model parameter and hit area IDs.
///
/// Based on the standard Live2D Cubism manual:
/// https://docs.live2d.com/cubism-editor-manual/standard-parametor-list/
abstract class DefaultParameterID {
  // Hit Areas
  static const String hitAreaPrefix = 'HitArea';
  static const String hitAreaHead = 'Head';
  static const String hitAreaBody = 'Body';

  // Parts
  static const String partsIdCore = 'Parts01Core';
  static const String partsArmPrefix = 'Parts01Arm_';
  static const String partsArmLPrefix = 'Parts01ArmL_';
  static const String partsArmRPrefix = 'Parts01ArmR_';

  // Angles
  static const String paramAngleX = 'ParamAngleX';
  static const String paramAngleY = 'ParamAngleY';
  static const String paramAngleZ = 'ParamAngleZ';

  // Eyes
  static const String paramEyeLOpen = 'ParamEyeLOpen';
  static const String paramEyeLSmile = 'ParamEyeLSmile';
  static const String paramEyeROpen = 'ParamEyeROpen';
  static const String paramEyeRSmile = 'ParamEyeRSmile';
  static const String paramEyeBallX = 'ParamEyeBallX';
  static const String paramEyeBallY = 'ParamEyeBallY';
  static const String paramEyeBallForm = 'ParamEyeBallForm';

  // Eyebrows
  static const String paramBrowLY = 'ParamBrowLY';
  static const String paramBrowRY = 'ParamBrowRY';
  static const String paramBrowLX = 'ParamBrowLX';
  static const String paramBrowRX = 'ParamBrowRX';
  static const String paramBrowLAngle = 'ParamBrowLAngle';
  static const String paramBrowRAngle = 'ParamBrowRAngle';
  static const String paramBrowLForm = 'ParamBrowLForm';
  static const String paramBrowRForm = 'ParamBrowRForm';

  // Mouth
  static const String paramMouthForm = 'ParamMouthForm';
  static const String paramMouthOpenY = 'ParamMouthOpenY';
  static const String paramCheek = 'ParamCheek';

  // Body
  static const String paramBodyAngleX = 'ParamBodyAngleX';
  static const String paramBodyAngleY = 'ParamBodyAngleY';
  static const String paramBodyAngleZ = 'ParamBodyAngleZ';
  static const String paramBreath = 'ParamBreath';

  // Arms and Hands
  static const String paramArmLA = 'ParamArmLA';
  static const String paramArmRA = 'ParamArmRA';
  static const String paramArmLB = 'ParamArmLB';
  static const String paramArmRB = 'ParamArmRB';
  static const String paramHandL = 'ParamHandL';
  static const String paramHandR = 'ParamHandR';

  // Hair
  static const String paramHairFront = 'ParamHairFront';
  static const String paramHairSide = 'ParamHairSide';
  static const String paramHairBack = 'ParamHairBack';
  static const String paramHairFluffy = 'ParamHairFluffy';

  // Bust / Base
  static const String paramShoulderY = 'ParamShoulderY';
  static const String paramBustX = 'ParamBustX';
  static const String paramBustY = 'ParamBustY';
  static const String paramBaseX = 'ParamBaseX';
  static const String paramBaseY = 'ParamBaseY';
  static const String paramNone = 'NONE:';
}
