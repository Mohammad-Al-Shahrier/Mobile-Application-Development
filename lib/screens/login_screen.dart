import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isPasswordHidden = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),

            child: Column(
              children: [
                const SizedBox(height: 90),

                // Logo
                Image.asset(
                  "assets/images/logo.png",
                  width: 140,
                  height: 140,
                ),

                const SizedBox(height: 15),

                // Title
                const Text(
                  "Login to Your Account",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 40),

                // Email Field
                Container(
                  height: 55,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: TextFormField(
                    decoration: InputDecoration(
                      border: InputBorder.none,

                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                      ),

                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          "assets/icons/email.png",
                          width: 22,
                          height: 22,
                        ),
                      ),

                      hintText: "Enter your email",

                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Password Field
                Container(
                  height: 55,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: TextFormField(
                    obscureText: isPasswordHidden,

                    decoration: InputDecoration(
                      border: InputBorder.none,

                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                      ),

                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          "assets/icons/lock.png",
                          width: 22,
                          height: 22,
                        ),
                      ),

                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            isPasswordHidden = !isPasswordHidden;
                          });
                        },

                        icon: Icon(
                          isPasswordHidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: 22,
                        ),
                      ),

                      hintText: "Enter your password",

                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,

                  child: TextButton(
                    onPressed: () {},

                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(
                        color: Color(0xFFD9D9D9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 55),

                // Login Button
                SizedBox(
                  width: 190,
                  height: 50,

                  child: ElevatedButton(
                    onPressed: () {},

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF109DFF),

                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don’t Have an Account ? ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),

                    InkWell(
                      borderRadius: BorderRadius.circular(5),

                      splashColor: Colors.white24,
                      highlightColor: Colors.transparent,

                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          "/registration",
                        );
                      },

                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),

                        child: Text(
                          "Sign up",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}