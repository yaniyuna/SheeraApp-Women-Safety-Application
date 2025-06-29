import 'package:flutter/material.dart';

class Learnmore extends StatefulWidget {
  const Learnmore({super.key});

  @override
  _LearnmoreState createState() => _LearnmoreState();
}

class _LearnmoreState extends State<Learnmore> {
  final PageController _pageController = PageController();

  final List<Map<String, String>> newsList = [
    {
      "title": "Keselamatan ketika di tempat asing",
      "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTQ8UVXNwEmoeXGTxPbDHFX-n0gSi6VkonWxg&s"
    },
    {
      "title": "10 Tips Keselamatan Taksi untuk Wanita",
      "image": "https://i0.wp.com/thespicytravelgirl.com/wp-content/uploads/2020/06/lighted-taxi-signage-1448598-scaled.jpg?resize=840%2C525&ssl=1"
    },
    {
      "title": "Tingkatkan waspada saat bepergian sendirian",
      "image": "https://www.abroadwithash.com/wp-content/uploads/2022/03/Hotel-Safety-Tips-for-Solo-Female-Travelers.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            "Pelajari lebih lanjut",
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.normal),
          ),
        ),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: newsList.length,
            physics: const BouncingScrollPhysics(), 
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
                          height: 100,
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
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
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
