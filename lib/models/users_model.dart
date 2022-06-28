class UserModel {
  String? uid;
  String? fullname;
  String? email;
  String? profilepic;
  String? fcm_token;

  UserModel(
      {this.uid, this.fullname, this.email, this.profilepic, this.fcm_token});

  UserModel.fromMap(Map<String, dynamic> map) {
    uid = map["uid"];
    fullname = map["fullname"];
    email = map["email"];
    profilepic = map["profilepic"];
    fcm_token = map["fcm_token"];
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "fullname": fullname,
      "email": email,
      "profilepic": profilepic,
      "fcm_token": fcm_token,
    };
  }
}
