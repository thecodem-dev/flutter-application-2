import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_footer.dart';

class PricingPage extends StatelessWidget{
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      
      //appbar
      appBar: CustomAppBar(),

      //body content 
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text("CHOOSE A PLAN THAT'S RIGHT FOR YOU",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center),

                  SizedBox(height:30),

                  Text("Pricing is based on the maximum number of students in your institution.\nAll plans come with x y z",
                  style: TextStyle(fontSize: 20, color: Colors.black54),
                  textAlign: TextAlign.center,),
                ],),),

                //SizedBox(height: 5),

                // ignore: sized_box_for_whitespace
                Container(
                  height: 500, 
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Opacity(
                        opacity: 0.5,
                          child: SvgPicture.asset(
                            'assets/images/image1.svg',
                            height: 400,
                            width: 900,
                            fit: BoxFit.fill,
                          ),
                        ),  
                       ),

                      Align(
                        alignment: Alignment.center,
                        child: Opacity(
                        opacity: 0.4,
                          child: SvgPicture.asset(
                            'assets/images/image1.svg',
                            height: 500,
                            width: 1200,
                            fit: BoxFit.fill,
                          ),
                        ),  
                       ),

                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          //row 1
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Card 1 - lower
                              Transform.translate(
                                offset: Offset(0, 330), // pushes card down
                                child: _planCards(
                                  title: "BASIC",
                                  students: "50 Students",
                                  price: "R1/mo",
                                  description: "Ideal for small classrooms",
                                ),
                              ),

                              // Card 2 - higher
                              Transform.translate(
                                offset: Offset(0, 220), // pulls card up
                                child: _planCards(
                                  title: "STANDARD",
                                  students: "200 Students",
                                  price: "R3/mo",
                                  description: "Best value for mid-sized schools",
                                ),
                              ),

                              // Card 3 - higher
                              Transform.translate(
                                offset: Offset(0, 220), // pulls card up
                                child: _planCards(
                                  title: "PREMIUM",
                                  students: "500 Students",
                                  price: "R5/mo",
                                  description: "All features + support",
                                ),
                              ),

                              // Card 4 - lower
                              Transform.translate(
                                offset: Offset(0, 330), // pushes card down
                                child: _planCards(
                                  title: "ENTERPRISE",
                                  students: "1000+ Students",
                                  price: "Custom",
                                  description: "Tailored for large institutions",
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 8),
                        ],
                        ),
                        )
                    ],
                  ),
                ),

          SizedBox(height: 130),

          //content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(children: [
              Text("Experience the Full Potential — Free for 14 Days",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              SizedBox(height: 20),
              Text("Start your 14-day free trial today and explore all premium features at no cost.\nNo commitment required. Evaluate how our solution fits your needs with full access and dedicated support throughout the trial period.",
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
              ),
              SizedBox(height:20),
              ElevatedButton(
                onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 70),
                backgroundColor: Colors.grey[400],
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12),
                ),
              ),
              child: Text("START FREE TRIAL"),),
            ],),),

            //footer 
            CustomFooter(),   


          ],
          ),
          ),
    );
  }

Widget _planCards({
  required String title, 
  required String students, 
  required String price,
  required String description,
})
{
  return SizedBox(
    width: 180, 
    height: 250,
    child: Card(
      elevation: 4, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            //title 
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white, // background color of the box
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black, // shadow color with opacity
                      blurRadius: 6,
                      offset: Offset(0, 3), // shadow offset (x, y)
                    ),
                  ],
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              SizedBox(height:8),

              Text(students, style: TextStyle(fontSize:14, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 121, 150, 173), )),
              SizedBox(height:4),

              Text(price,style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(height: 8), 
              
              Text(description, textAlign: TextAlign.center),
              SizedBox(height: 20),
              
              ElevatedButton(onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24),
                backgroundColor: const Color.fromARGB(255, 121, 150, 173),
                foregroundColor: Colors.black,
              ),
              child: Text("SELECT"),),
              
          ],))
    ),
  );
}
}