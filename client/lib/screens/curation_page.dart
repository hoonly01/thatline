import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CurationPage extends StatefulWidget {
  final int curationId;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final String? description;
  final Map<String, dynamic>? recommender;
  final List<Map<String, dynamic>>? books;

  const CurationPage({
    Key? key,
    required this.curationId,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.description,
    this.recommender,
    this.books,
  }) : super(key: key);

  @override
  State<CurationPage> createState() => _CurationPageState();
}

class _CurationPageState extends State<CurationPage> {
  late Map<String, dynamic> curationData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCurationData();
  }

  Future<void> _fetchCurationData() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/curation/${widget.curationId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          curationData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load curation data');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        
        // Use default data if API call fails
        curationData = {
          'title': widget.title ?? '추천 도서',
          'subtitle': widget.subtitle ?? '당신을 위한 특별한 책들',
          'image': widget.imageUrl ?? 'assets/images/placeholder.jpg',
          'description': widget.description ?? '이 큐레이션에 대한 설명이 없습니다.',
          'recommender': widget.recommender ?? {
            'name': '독립 서점',
            'title': '책방 이름',
            'latitude': 37.5665,
            'longitude': 126.9780,
          },
          'books': widget.books ?? [],
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('오류')),
        body: Center(child: Text(errorMessage!)),
      );
    }

    final books = List<Map<String, dynamic>>.from(curationData['books'] ?? []);
    final recommender = curationData['recommender'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(curationData['title'] ?? '큐레이션'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (curationData['image'] != null)
              Image.network(
                curationData['image'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    curationData['subtitle'] ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    curationData['description'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            ...books.map((book) => ListTile(
                  title: Text(book['name'] ?? '제목 없음'),
                  subtitle: Text(book['writer'] ?? '작자 미상'),
                  onTap: () {
                    // Handle book tap
                  },
                )),
            ListTile(
              title: const Text('이 큐레이터를 작성한 독립서점'),
              subtitle: Text(recommender['title'] ?? ''),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showStoreMapDialog(
                  recommender['name'] ?? '서점',
                  recommender['latitude'] ?? 37.5665,
                  recommender['longitude'] ?? 126.9780,
                  recommender['title'] ?? '추천서점',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStoreMapDialog(String name, double lat, double lng, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title 위치'),
        content: SizedBox(
          height: 250,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(lat, lng),
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: MarkerId(name),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(title: title),
              ),
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
