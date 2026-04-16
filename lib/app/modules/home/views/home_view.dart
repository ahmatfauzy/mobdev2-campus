import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade800, Colors.purple.shade600],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Foto Profil
                Hero(
                  tag: 'profile',
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        controller.biodata.value.fotoPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                
                // Nama
                Text(
                  controller.biodata.value.nama,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                
                // TTL
                Text(
                  controller.biodata.value.ttl,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 50),
                
                // Tombol Navigasi
                _buildMenuButton(
                  icon: Icons.person_outline,
                  label: 'Lihat Biodata Lengkap',
                  onTap: controller.goToBiodata,
                ),
                SizedBox(height: 16),
                _buildMenuButton(
                  icon: Icons.work_outline,
                  label: 'Pengalaman & Pendidikan',
                  onTap: controller.goToPengalaman,
                  isSecondary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    return Material(
      color: isSecondary ? Colors.white24 : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSecondary ? Colors.white : Colors.blue.shade800,
                size: 28,
              ),
              SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSecondary ? Colors.white : Colors.blue.shade800,
                ),
              ),
              Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                color: isSecondary ? Colors.white70 : Colors.blue.shade800,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}