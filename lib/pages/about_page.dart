import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_footer.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
  child: Column(
    children: [
      SizedBox(height: 30),
      Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildResponsiveSection(
                context,
                title: 'WHO WE ARE',
                text:
                    "At Fundisa we believe in creating technology that empowers people and organizations to work smarter, faster, and more effectively. "
                    "Since our founding, our mission has been clear: to simplify complexity, enhance productivity, and deliver solutions that make a real difference in everyday operations.",
                imagePath: 'assets/images/about1.PNG',
                imageFirst: false,
              ),
              const SizedBox(height: 30),
              _buildResponsiveSection(
                context,
                title: 'OUR TEAM AND PHILOSOPHY',
                text:
                    "We are a team of passionate innovators, developers, designers, and problem-solvers who are deeply committed to building intuitive, reliable, and high-performing tools. "
                    "Whether it's streamlining workflows, enhancing collaboration, or unlocking valuable insights through intelligent automation, our platform is designed with real-world users in mind.",
                imagePath: 'assets/images/about2.PNG',
                imageFirst: true,
              ),
              const SizedBox(height: 30),
              _buildResponsiveSection(
                context,
                title: 'WHAT MAKES US DIFFERENT',
                text:
                    "What sets us apart is our focus on user experience and our dedication to continuous improvement. "
                    "We listen carefully to feedback, stay ahead of emerging trends, and constantly refine our offerings to ensure they meet the evolving needs of businesses in an ever-changing digital landscape.",
                imagePath: 'assets/images/about3.PNG',
                imageFirst: false,
              ),
              const SizedBox(height: 30),
              _buildResponsiveSection(
                context,
                title: 'TRUSTED BY BUSINESSES WORLDWIDE',
                text:
                    "Our platform is trusted by teams of all sizes — from startups to global enterprises — across a wide range of industries. "
                    "We take pride in offering scalable solutions backed by responsive support, robust security standards, and a commitment to transparency and trust.",
                imagePath: 'assets/images/about4.PNG',
                imageFirst: true,
              ),
              const SizedBox(height: 30),
              const Center(
                child: Column(
                  children: [
                    Text(
                      'BUILT AROUND PEOPLE',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "But more than just technology, we're about people. We're here to help our customers solve problems, make better decisions,"
                      " and focus on what matters most. Whether you're just getting started or scaling to new heights, we're with you every step of the way.",
                      style:
                          TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Thank you for being part of our journey. We're excited to be part of yours.",
                      style:
                          TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),

      const SizedBox(height: 30), // space between box and footer
      const CustomFooter(),  // footer expands full width here
    ],
  ),
),


    );
  }

Widget _buildResponsiveSection(
  BuildContext context, {
  required String title,
  required String text,
  required String imagePath,
  required bool imageFirst,
}) {
  final isWideScreen = MediaQuery.of(context).size.width > 600;

  Widget image = Flexible(
    flex: 1,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        width: isWideScreen ? null : double.infinity,
        height: 250,
      ),
    ),
  );

  Widget textColumn = Flexible(
    flex: 2,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // centered horizontally
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center, // center heading text
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center, // center paragraph text
          ),
        ],
      ),
    ),
  );

  if (isWideScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: imageFirst ? [image, textColumn] : [textColumn, image],
    );
  } else {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: imageFirst ? [image, textColumn] : [textColumn, image],
    );
  }
}
}

