import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; 
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_footer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Stack(
        children: [
        Positioned(
          top: kToolbarHeight + 20,
              left: -150,
              width: 750,
              height: 500,
              child: Opacity(
                  opacity: 0.4, 
                    child: Transform(
                      alignment: Alignment.center,
                        transform: Matrix4.rotationZ(1.5708), // 90 degrees in radians
                        child: SvgPicture.asset(
                          'assets/images/image1.svg',
                          fit: BoxFit.contain,
                  ),
                  ),
                ),  
        ), 

    // Second SVG positioned similarly but offset slightly differently
        Positioned(
          top: kToolbarHeight + 20,
              left: -150,
              width: 730,
              height: 500,
              child: Opacity(
                  opacity: 0.4, 
                    child: Transform(
                      alignment: Alignment.center,
                        transform: Matrix4.rotationZ(1.5708), // 90 degrees in radians
                        child: SvgPicture.asset(
                          'assets/images/image1.svg',
                          fit: BoxFit.contain,
                  ),
                  ),
                ),  
        ),                   

          // Your original content scroll view
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 30),

                //slogan 
                Container(
                  color: Colors.grey[200],
                  padding: EdgeInsets.all(16),
                  width: double.infinity,
                  height: 270,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: screenWidth > 600 ? 300 : screenWidth * 0.4,
                        child: Image.asset(
                          'assets/images/teacher.jpg',
                          height: 270,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 20),

                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            'This is our brand slogan.\nThis is what we stand for.',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                //about product card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth > 700 ? 60 : 20),
                  child: Container(
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(103, 184, 217, 234),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    width: double.infinity,
                    height: 600,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'About Our\nProduct',
                              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        Container(
                          height: 600,
                          width: 3,
                          color: Colors.black,
                          margin: EdgeInsets.symmetric(horizontal: 10),
                        ),

                        Expanded(
                          flex: 10,
                          child: Padding(
                            padding: const EdgeInsets.all(30),
                            child: SingleChildScrollView(
                              child: Text(
                                "ClassBuddy is your all-in-one digital assistant designed to make teaching easier, faster, and more organized. "
                                "Whether you're managing attendance, tracking student progress, or planning lessons, ClassBuddy streamlines daily classroom tasks "
                                "so teachers can focus on what matters most: teaching. Built for educators in K–12 and beyond, it's intuitive, secure, and customizable "
                                "to fit your unique classroom needs.\n\n"
                                "Key Features:\n\n"
                                "* Smart Attendance Tracking: Mark attendance with one tap and generate reports instantly.\n"
                                "* Gradebook & Progress Reports: Log assignments and automatically calculate grades.\n"
                                "* Lesson Planner: Organize weekly plans, upload resources, and sync with your calendar.\n"
                                "* Parent & Student Communication: Send updates, reminders, and feedback directly through the app.\n"
                                "* Reminders & Alerts: Stay on top of due dates, tests, and meetings.\n"
                                "* Secure Cloud Storage: All your data is encrypted and backed up automatically.\n\n"
                                "Platforms: Android, iOS, and Web.",
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 30),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth > 900 ? 60 : 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //card 1
                        SizedBox(
                          width: screenWidth > 900 ? (screenWidth - 320) / 3 : 300,
                          child: Card(
                            color: const Color.fromARGB(160, 142, 181, 194),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Speak to a member',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Contact a member of Fundisa to get more details into this product.',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  SizedBox(height: 40),

                                  Padding(
                                    padding: EdgeInsets.only(left: 0, right: 16),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 35,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pushReplacementNamed(context, '/contact');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                          backgroundColor: const Color.fromARGB(250, 61, 95, 106),
                                          alignment: Alignment.centerLeft,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(30),
                                              bottomRight: Radius.circular(30),
                                            ),
                                          ),
                                        ),
                                        child: Text('CONTACT A MEMBER', style: TextStyle(color: Colors.black)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 20),

                        //card 2
                        SizedBox(
                          width: screenWidth > 900 ? (screenWidth - 320) / 3 : 300,
                          child: Card(
                            color: const Color.fromARGB(160, 142, 181, 194),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Watch a Demo',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Watch a demonstration of how this product works.',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  SizedBox(height: 40),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 35,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                        backgroundColor: const Color.fromARGB(250, 61, 95, 106),
                                        alignment: Alignment.centerLeft,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(30),
                                            bottomRight: Radius.circular(30),
                                          ),
                                        ),
                                      ),
                                      child: Text('WATCH A DEMO', style: TextStyle(color: Colors.black)),
                                    ),
                                  ),
                                  SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 20),

                        //card 3
                        SizedBox(
                          width: screenWidth > 900 ? (screenWidth - 320) / 3 : 300,
                          child: Card(
                            color: const Color.fromARGB(160, 142, 181, 194),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Get Started',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Choose a pricing plan and start using Fundisa',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  SizedBox(height: 40),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 35,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushReplacementNamed(context, '/pricingpage');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                        backgroundColor: const Color.fromARGB(250, 61, 95, 106),
                                        alignment: Alignment.centerLeft,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(30),
                                            bottomRight: Radius.circular(30),
                                          ),
                                        ),
                                      ),
                                      child: Text('CHECK PRICING', style: TextStyle(color: Colors.black)),
                                    ),
                                  ),
                                  SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 30),

                //footer 
                CustomFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
