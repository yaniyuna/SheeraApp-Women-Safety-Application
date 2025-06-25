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
      "title": "Edukasi 1",
      "image": "https://i.pinimg.com/736x/d5/81/e0/d581e0b1d350a08b17ac7b057514dc7d.jpg"
    },
    {
      "title": "Edukasi 2",
      "image": "https://i.pinimg.com/736x/b5/e9/19/b5e919b71c036b6a1775c7dd94964a42.jpg"
    },
    {
      "title": "Edukasi 3",
      "image": "https://i.pinimg.com/736x/8e/2c/52/8e2c5284371de3717e5decbd8d10a530.jpg"
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
