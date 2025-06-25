import 'package:flutter/material.dart';

class CarouselNews extends StatefulWidget {
  const CarouselNews({super.key});

  @override
  _CarouselNewsState createState() => _CarouselNewsState();
}

class _CarouselNewsState extends State<CarouselNews> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> newsList = [
    {
      "title": "Tips Keselamatan Wanita di Jalan",
      "description": "Perhatikan sekitar dan gunakan aplikasi keamanan.",
      "image": "https://i.pinimg.com/736x/89/b7/fe/89b7fe84a6a47c3dfe1f39a3378db1ae.jpg"
    },
    {
      "title": "Fitur Panggilan Darurat di Aplikasi",
      "description": "Gunakan tombol darurat untuk meminta bantuan cepat.",
      "image": "https://i.pinimg.com/736x/d0/20/5a/d0205a2c705eb07810d7e50805c97367.jpg"
    },
    {
      "title": "Pelecehan Verbal",
      "description": "Pelecehan verbal terhadap wanita marak terjadi",
      "image": "https://i.pinimg.com/736x/c1/66/21/c16621027a2ea13050a50e70b37a96a1.jpg"
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_pageController.hasClients) {
        setState(() {
          _currentPage = (_currentPage + 1) % newsList.length;
        });
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // return SizedBox(
    //   height: 200, // Tinggi container carousel
    //   child: PageView.builder(
    //     controller: _pageController,
    //     itemCount: newsList.length,
    //     itemBuilder: (context, index) {
    //       var news = newsList[index];
    //       return Padding(
    //         padding: const EdgeInsets.symmetric(horizontal: 10),
    //         child: Card(
    //           shape: RoundedRectangleBorder(
    //             borderRadius: BorderRadius.circular(10),
    //           ),
    //           elevation: 5,
    //           child: Column(
    //             crossAxisAlignment: CrossAxisAlignment.start,
    //             children: <Widget>[
    //               ClipRRect(
    //                 borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
    //                 child: Image.network(
    //                   news["image"]!,
    //                   height: 120,
    //                   width: double.infinity,
    //                   fit: BoxFit.cover,
    //                 ),
    //               ),
    //               Padding(
    //                 padding: const EdgeInsets.all(8.0),
    //                 child: Column(
    //                   crossAxisAlignment: CrossAxisAlignment.start,
    //                   children: [
    //                     Text(
    //                       news["title"]!,
    //                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    //                     ),
    //                     const SizedBox(height: 4),
    //                     Text(
    //                       news["description"]!,
    //                       style: const TextStyle(fontSize: 12, color: Colors.grey),
    //                     ),
    //                   ],
    //                 ),
    //               ),
    //             ],
    //           ),
    //         ),
    //       );
    //     },
    //   ),
    // );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            "Selamat Datang Sheera's!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200, // Tinggi container carousel
          child: PageView.builder(
            controller: _pageController,
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              var news = newsList[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[

                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: Image.network(
                          news["image"]!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              news["title"]!,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              news["description"]!,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  } 
}

