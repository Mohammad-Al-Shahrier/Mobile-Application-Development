import 'package:flutter/material.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() =>
      _RegistrationScreenState();
}

class _RegistrationScreenState
    extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController =
      TextEditingController();

  final TextEditingController addressController =
      TextEditingController();

  final TextEditingController dobController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;

  String selectedRole = "Customer";

  Future<void> pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        dobController.text =
            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  void registerUser() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration Successful"),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(
          context,
          "/login",
        );
      });
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    addressController.dispose();
    dobController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Widget customTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 55,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),

      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,

        decoration: InputDecoration(
          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
          ),

          prefixIcon: Icon(
            icon,
            color: Colors.black,
          ),

          suffixIcon: suffixIcon,

          hintText: hint,

          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF0047B3),
              Color(0xFFB65AD8),
            ],
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 25,
            ),

            child: Form(
              key: _formKey,

              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  Image.asset(
                    "assets/images/logo.png",
                    width: 130,
                    height: 130,
                  ),

                  const SizedBox(height: 10),

                  // Title
                  const Text(
                    "Create Your Account",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Full Name
                  customTextField(
                    hint: "Enter your full name",
                    icon: Icons.person_outline,
                    controller: fullNameController,

                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return "Please enter full name";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // Address
                  customTextField(
                    hint: "Enter your address",
                    icon: Icons.location_on_outlined,
                    controller: addressController,

                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return "Please enter address";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // Date of Birth
                  customTextField(
                    hint: "Select date of birth",
                    icon:
                        Icons.calendar_month_outlined,
                    controller: dobController,
                    readOnly: true,
                    onTap: pickDate,

                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return "Please select date of birth";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // Phone
                  customTextField(
                    hint: "Enter your phone number",
                    icon: Icons.phone_outlined,
                    controller: phoneController,
                    keyboardType: TextInputType.phone,

                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return "Please enter phone number";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // Email
                  customTextField(
                    hint: "Enter your email",
                    icon: Icons.email_outlined,
                    controller: emailController,
                    keyboardType:
                        TextInputType.emailAddress,

                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return "Please enter email";
                      }

                      if (!value.contains("@")) {
                        return "Enter valid email";
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // Password
                  customTextField(
                    hint: "Create a password",
                    icon: Icons.lock_outline,
                    controller: passwordController,
                    obscureText: isPasswordHidden,

                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isPasswordHidden =
                              !isPasswordHidden;
                        });
                      },

                      icon: Icon(
                        isPasswordHidden
                            ? Icons
                                .visibility_off_outlined
                            : Icons
                                .visibility_outlined,
                        color: Colors.grey,
                      ),
                    ),

                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return "Please enter password";
                      }

                      if (value.length < 6) {
                        return "Password must be at least 6 characters";
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // Confirm Password
                  customTextField(
                    hint: "Confirm your password",
                    icon: Icons.lock_outline,
                    controller:
                        confirmPasswordController,
                    obscureText:
                        isConfirmPasswordHidden,

                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isConfirmPasswordHidden =
                              !isConfirmPasswordHidden;
                        });
                      },

                      icon: Icon(
                        isConfirmPasswordHidden
                            ? Icons
                                .visibility_off_outlined
                            : Icons
                                .visibility_outlined,
                        color: Colors.grey,
                      ),
                    ),

                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return "Please confirm password";
                      }

                      if (value !=
                          passwordController.text) {
                        return "Passwords do not match";
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  // Role Title
                  const Text(
                    "Select Your Role",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Role Buttons
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedRole = "Customer";
                            });
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                selectedRole ==
                                        "Customer"
                                    ? const Color(
                                        0xFF109DFF)
                                    : Colors.white24,

                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      10),
                            ),
                          ),

                          child: const Text(
                            "Customer",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedRole =
                                  "Service Provider";
                            });
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                selectedRole ==
                                        "Service Provider"
                                    ? const Color(
                                        0xFF109DFF)
                                    : Colors.white24,

                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      10),
                            ),
                          ),

                          child: const Text(
                            "Service Provider",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Sign Up Button
                  SizedBox(
                    width: 190,
                    height: 50,

                    child: ElevatedButton(
                      onPressed: registerUser,

                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF109DFF),

                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),

                      child: const Text(
                        "Sign up",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Login Button
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already Have an Account ? ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),

                      InkWell(
                        borderRadius:
                            BorderRadius.circular(5),

                        splashColor: Colors.white24,
                        highlightColor:
                            Colors.transparent,

                        onTap: () {
                          Navigator.pushReplacementNamed(
                            context,
                            "/login",
                          );
                        },

                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),

                          child: Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}