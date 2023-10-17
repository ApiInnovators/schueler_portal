class UserData {
  static final Set<String> _registeredCourses = {
    "2M_7",
    "2SK_7",
    "2KU_5",
    "2P_PH1",
    "2D_7",
    "2INF_1",
    "2ETH_1",
    "2W_M1",
    "2SP_BAD2",
    "2PH_1",
    "2E_7",
    "2G_7",
    "2GEO_2"
  };

  static bool userIsRegisteredForCourse(String course) {
    return _registeredCourses.contains(course.toUpperCase());
  }
}
