class AppAssets {
  // Base paths
  static const String _img = "assets/images";
  static const String _svg = "assets/svgs"; // SVG ke liye alag folder

  // PNGs
  static const String Goal_Improve_Shape = "$_img/Goal_Improve_Shap.png";
  static const String Goal_Lose_Fat = "$_img/Goal_Lose_a_Fat.png";
  static const String Goal_Lean_Tone = "$_img/Goal_Lean_Tone.png";
  static const String Complete_your_profile = "$_img/Complete_your_profile.png";
  static const String Welcome_Stefani = "$_img/Welcome_image.png";
  static const String Google = "$_img/Google.png";
  static const String Facebook = "$_img/facebook.png";
  static const String Onboarding_Eat = "$_img/Onboarding_Eat.png";
  static const String Onboarding_Get = "$_img/Onboarding_Get.png";
  static const String Onboarding_Sleep = "$_img/Onboarding_Sleep.png";
  static const String Onboarding_track = "$_img/Onboarding_track.png";
  static const String Fullbody_Workout = "$_img/Fullbody_Workout.png";
  static const String Lowerbody_Workout = "$_img/Lowerbody_Workout.png";
  static const String Ab_Workout = "$_img/Ab _Workout.png";
  static const String Main_Tab_view_dots = "$_img/Main_Tab_view_dots.png";
  static const String Main_Tab_view_Banner = "$_img/Main_Tab_View_Banner.png";
  static const String Main_Tab_view_HeartRate =
      "$_img/Main_Tab_View_HeartRate.png";
  static const String Main_Tab_view_Sleep = "$_img/Main_Tab_View_Sleep.png";
  static const String Profile_images = "$_img/Profile_images.png";

  // Paths define karein
  static const String lunchIcon = "assets/images/lunch.png";
  static const String workoutIcon = "assets/images/workouts.png";
  static const String mealIcon = "assets/images/foods.png";

  // Function jo string name ko path mein convert karega
  static String getNotificationIcon(String? imageName) {
    switch (imageName) {
      case "lunch.png":
        return lunchIcon;
      case "workouts.png":
        return workoutIcon;
      case "foods.png":
        return mealIcon;
      default:
        return "assets/images/default_notification.png";
    }
  }

  // SVGs (Agar aapne icons folder banaya hai)
  static const String googleLogo = "$_svg/Google.svg";
  static const String facebookLogo = "$_svg/Facebook.svg";
}
