class OtpArgs {
  const OtpArgs({required this.restaurantId, required this.phone, this.otp});
  final String restaurantId;
  final String phone;
  final String? otp;
}

class RegisterArgs {
  const RegisterArgs({required this.phone});
  final String phone;
}
