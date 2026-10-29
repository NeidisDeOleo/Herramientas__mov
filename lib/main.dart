import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const CouteauApp());

// ====== CONFIGURA ESTO ======
const wpSite = 'https://techcrunch.com'; // API WordPress publicada en el foro
const miNombre = 'Neidis De Oleo';
const miCorreo = 'deoleoneidis00@gmail.com';
const miTelefono = '849-472-5973';
// ============================

Future<dynamic> getJson(String url) async {
  final r = await http.get(Uri.parse(url));
  if (r.statusCode != 200) throw Exception('Error ${r.statusCode}');
  return jsonDecode(utf8.decode(r.bodyBytes));
}

Future<void> abrir(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

class CouteauApp extends StatelessWidget {
  const CouteauApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
    title: 'Couteau',
    theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
    home: const Home(),
  );
}

class Home extends StatelessWidget {
  const Home({super.key});
  @override
  Widget build(BuildContext context) {
    final items = <(String, IconData, Widget)>[
      ('Género', Icons.wc, const GenderPage()),
      ('Persona', Icons.person, const RandomUserPage()),
      ('Universidades', Icons.school, const UniPage()),
      ('Clima RD', Icons.wb_sunny, const WeatherPage()),
      ('Pokémon', Icons.catching_pokemon, const PokemonPage()),
      ('Noticias', Icons.newspaper, const NewsPage()),
      ('Acerca de', Icons.info, const AboutPage()),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Couteau')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset('assets/caja.jpg', height: 200, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                  height: 200, child: Icon(Icons.handyman, size: 120))),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, crossAxisSpacing: 12,
          mainAxisSpacing: 12, physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final (t, i, p) in items)
              Card(
                child: InkWell(
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => p)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(i, size: 48), const SizedBox(height: 8), Text(t)]),
                ),
              ),
          ],
        ),
      ]),
    );
  }
}

// Scaffold genérico para cada vista
Widget page(String title, Widget body, {Color? bg}) => Scaffold(
    backgroundColor: bg,
    appBar: AppBar(title: Text(title)),
    body: Padding(padding: const EdgeInsets.all(16), child: body));

Widget loading() => const Center(child: CircularProgressIndicator());

// 2. GÉNERO
class GenderPage extends StatefulWidget {
  const GenderPage({super.key});
  @override
  State<GenderPage> createState() => _GenderPageState();
}

class _GenderPageState extends State<GenderPage> {
  final ctrl = TextEditingController();
  String? gender, msg;
  double prob = 0;
  bool busy = false;

  Future<void> predecir() async {
    setState(() { busy = true; msg = null; gender = null; });
    try {
      final d = await getJson(
          'https://api.genderize.io/?name=${Uri.encodeComponent(ctrl.text.trim())}');
      gender = d['gender'];
      prob = (d['probability'] ?? 0).toDouble();
      if (gender == null) msg = 'No se pudo predecir';
    } catch (e) { msg = 'Error: $e'; }
    setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final male = gender == 'male';
    final bg = gender == null ? null : (male ? Colors.blue.shade200 : Colors.pink.shade200);
    return page('Predecir género', Column(children: [
      TextField(controller: ctrl, decoration: const InputDecoration(
          labelText: 'Nombre', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      FilledButton(onPressed: busy ? null : predecir, child: const Text('Predecir')),
      const SizedBox(height: 24),
      if (busy) loading(),
      if (msg != null) Text(msg!),
      if (gender != null) ...[
        Icon(male ? Icons.male : Icons.female, size: 120,
            color: male ? Colors.blue.shade900 : Colors.pink.shade900),
        Text(male ? 'Masculino' : 'Femenino',
            style: Theme.of(context).textTheme.headlineMedium),
        Text('Probabilidad: ${(prob * 100).toStringAsFixed(0)}%'),
      ],
    ]), bg: bg);
  }
}

// 3. PERSONA ALEATORIA
class RandomUserPage extends StatefulWidget {
  const RandomUserPage({super.key});
  @override
  State<RandomUserPage> createState() => _RandomUserPageState();
}

class _RandomUserPageState extends State<RandomUserPage> {
  late Future<dynamic> f = getJson('https://randomuser.me/api/?results=1');
  @override
  Widget build(BuildContext context) => page('Persona aleatoria',
      FutureBuilder(future: f, builder: (_, s) {
        if (s.hasError) return Text('Error: ${s.error}');
        if (!s.hasData) return loading();
        final u = s.data['results'][0];
        final fecha = (u['dob']['date'] as String).substring(0, 10);
        return Column(children: [
          CircleAvatar(radius: 70, backgroundImage: NetworkImage(u['picture']['large'])),
          const SizedBox(height: 16),
          Text('Nombre: ${u['name']['first']}', style: const TextStyle(fontSize: 20)),
          Text('Apellido: ${u['name']['last']}', style: const TextStyle(fontSize: 20)),
          Text('Nacimiento: $fecha', style: const TextStyle(fontSize: 20)),
          Text('Edad: ${u['dob']['age']}', style: const TextStyle(fontSize: 20)),
          const Spacer(),
          FilledButton.icon(
              onPressed: () => setState(() =>
              f = getJson('https://randomuser.me/api/?results=1')),
              icon: const Icon(Icons.refresh), label: const Text('Otra persona')),
        ]);
      }));
}

// 4. UNIVERSIDADES
class UniPage extends StatefulWidget {
  const UniPage({super.key});
  @override
  State<UniPage> createState() => _UniPageState();
}

class _UniPageState extends State<UniPage> {
  final ctrl = TextEditingController(text: 'Dominican Republic');
  List unis = [];
  bool busy = false;
  String? err;

  Future<void> buscar() async {
    setState(() { busy = true; err = null; });
    try {
      final c = Uri.encodeQueryComponent(ctrl.text.trim());
      unis = await getJson('https://adamix.net/proxy.php?country=$c');
    } catch (e) { err = '$e'; unis = []; }
    setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => page('Universidades', Column(children: [
    TextField(controller: ctrl, decoration: const InputDecoration(
        labelText: 'País (en inglés)', border: OutlineInputBorder())),
    const SizedBox(height: 8),
    FilledButton(onPressed: buscar, child: const Text('Buscar')),
    if (busy) loading(),
    if (err != null) Text('Error: $err'),
    Expanded(child: ListView.builder(
      itemCount: unis.length,
      itemBuilder: (_, i) {
        final u = unis[i];
        final doms = (u['domains'] as List?)?.join(', ') ?? '';
        final webs = (u['web_pages'] as List?) ?? [];
        return Card(child: ListTile(
          title: Text(u['name'] ?? ''),
          subtitle: Text('Dominio: $doms'),
          trailing: webs.isEmpty ? null : IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => abrir(webs.first)),
          onTap: webs.isEmpty ? null : () => abrir(webs.first),
        ));
      },
    )),
  ]));
}

// 5. CLIMA RD (Open-Meteo, sin API key) - Santo Domingo
class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});
  static String desc(int c) {
    if (c == 0) return 'Despejado';
    if (c <= 3) return 'Parcialmente nublado';
    if (c <= 48) return 'Niebla';
    if (c <= 67) return 'Lluvia';
    if (c <= 82) return 'Aguaceros';
    return 'Tormenta eléctrica';
  }

  @override
  Widget build(BuildContext context) => page('Clima en RD',
      FutureBuilder(
        future: getJson('https://api.open-meteo.com/v1/forecast?latitude=18.4861'
            '&longitude=-69.9312&current_weather=true&timezone=America/Santo_Domingo'
            '&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max,weathercode'
            '&forecast_days=1'),
        builder: (_, s) {
          if (s.hasError) return Text('Error: ${s.error}');
          if (!s.hasData) return loading();
          final d = s.data['daily'];
          final now = s.data['current_weather'];
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(d['time'][0], style: const TextStyle(fontSize: 18)),
            const Text('Santo Domingo, RD'),
            const Icon(Icons.wb_cloudy, size: 100),
            Text('${now['temperature']}°C ahora', style: const TextStyle(fontSize: 32)),
            Text(desc(d['weathercode'][0]), style: const TextStyle(fontSize: 22)),
            Text('Máx ${d['temperature_2m_max'][0]}° / Mín ${d['temperature_2m_min'][0]}°'),
            Text('Prob. de lluvia: ${d['precipitation_probability_max'][0]}%'),
          ]));
        },
      ));
}

// 6. POKÉMON
class PokemonPage extends StatefulWidget {
  const PokemonPage({super.key});
  @override
  State<PokemonPage> createState() => _PokemonPageState();
}

class _PokemonPageState extends State<PokemonPage> {
  final ctrl = TextEditingController(text: 'pikachu');
  final player = AudioPlayer();
  Map? p;
  bool busy = false;
  String? err;

  Future<void> buscar() async {
    setState(() { busy = true; err = null; p = null; });
    try {
      p = await getJson(
          'https://pokeapi.co/api/v2/pokemon/${ctrl.text.trim().toLowerCase()}');
    } catch (e) { err = 'Pokémon no encontrado'; }
    setState(() => busy = false);
  }

  @override
  void dispose() { player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => page('Pokémon', SingleChildScrollView(
    child: Column(children: [
      TextField(controller: ctrl, decoration: const InputDecoration(
          labelText: 'Nombre del Pokémon', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      FilledButton(onPressed: buscar, child: const Text('Buscar')),
      if (busy) loading(),
      if (err != null) Text(err!),
      if (p != null) ...[
        Image.network(p!['sprites']['other']['official-artwork']['front_default']
            ?? p!['sprites']['front_default'], height: 220),
        Text(p!['name'].toString().toUpperCase(),
            style: Theme.of(context).textTheme.headlineMedium),
        Text('Experiencia base: ${p!['base_experience']}'),
        const SizedBox(height: 8),
        const Text('Habilidades:', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(spacing: 6, children: [
          for (final a in p!['abilities']) Chip(label: Text(a['ability']['name']))
        ]),
        FilledButton.icon(
            onPressed: () {
              final url = p!['cries']?['latest'];
              if (url != null) player.play(UrlSource(url));
            },
            icon: const Icon(Icons.volume_up), label: const Text('Escuchar sonido')),
      ],
    ]),
  ));
}

// 7. NOTICIAS WORDPRESS
String limpiar(String h) => h
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&#8217;', "'").replaceAll('&#8216;', "'")
    .replaceAll('&#8220;', '"').replaceAll('&#8221;', '"')
    .replaceAll('&#8211;', '-').replaceAll('&amp;', '&')
    .replaceAll('&hellip;', '...').replaceAll('&nbsp;', ' ')
    .replaceAll(RegExp(r'&#\d+;'), '').trim();

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});
  @override
  Widget build(BuildContext context) => page('Noticias', FutureBuilder(
    future: Future.wait([
      getJson('$wpSite/wp-json'),
      getJson('$wpSite/wp-json/wp/v2/posts?per_page=3'),
    ]),
    builder: (_, s) {
      if (s.hasError) return Text('Error: ${s.error}');
      if (!s.hasData) return loading();
      final site = s.data![0] as Map;
      final posts = s.data![1] as List;
      final logo = site['site_icon_url'] as String?;
      return ListView(children: [
        Center(child: (logo != null && logo.isNotEmpty)
            ? Image.network(logo, height: 80,
            errorBuilder: (_, __, ___) => Text(site['name'] ?? ''))
            : Text(site['name'] ?? '', style: const TextStyle(fontSize: 24))),
        const SizedBox(height: 12),
        for (final n in posts)
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(limpiar(n['title']['rendered']),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(limpiar(n['excerpt']['rendered'])),
            TextButton(onPressed: () => abrir(n['link']), child: const Text('Visitar')),
          ]))),
      ]);
    },
  ));
}

// 8. ACERCA DE
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => page('Acerca de', ListView(children: [
    Center(child: CircleAvatar(radius: 80,
        backgroundImage: const AssetImage('assets/foto.jpg'))),
    const SizedBox(height: 16),
    Center(child: Text(miNombre, style: Theme.of(context).textTheme.headlineMedium)),
    const Center(child: Text('Desarrollador de software')),
    const SizedBox(height: 16),
    ListTile(leading: const Icon(Icons.email), title: const Text(miCorreo),
        onTap: () => abrir('mailto:$miCorreo')),
    ListTile(leading: const Icon(Icons.phone), title: const Text(miTelefono),
        onTap: () => abrir('tel:$miTelefono')),
  ]));
}