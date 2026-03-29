# Contexte projet Alfawz (pour assistants IA / reprise de travail)

Ce fichier résume **l’architecture**, **l’état fonctionnel** et **les choix récents** du dépôt. À lire en priorité sur une nouvelle machine (ex. Mac) avant de modifier le code.

**Dépôt Git :** [github.com/Lab0a/alfawz](https://github.com/Lab0a/alfawz) — branche `main`.

---

## 1. Objectif produit

Application Flutter **« Alfawz »** : lecture du Coran, navigation par sourate, lecteur audio par verset, signets, favoris, progression de lecture, contenu aligné (texte + timings mots quand disponible), mode hors-ligne partiel pour les sourates mises en cache.

---

## 2. Stack technique

| Élément | Détail |
|--------|--------|
| **SDK** | Dart `>=3.3.0 <4.0.0`, Flutter |
| **UI** | Material 3, `google_fonts`, thème maison (`theme/alfawz_colors.dart`, `alfawz_theme.dart`) |
| **Police arabe** | `UthmanicHafs` — fichier `assets/fonts/UthmanicHafs1Ver18.ttf` |
| **Audio** | `just_audio` (playlist par sourate, seek par index de piste) |
| **Réseau** | `http` — APIs Quran (voir ci‑dessous) |
| **Stockage local** | `shared_preferences` + fichiers via `path_provider` (cache sourate JSON, etc.) |
| **Partage / liens** | `share_plus`, `url_launcher` |

Après clonage : `flutter pub get` puis lancer (ex. `flutter run`).

---

## 3. Structure utile sous `lib/`

| Chemin | Rôle |
|--------|------|
| `main.dart` | Point d’entrée, barre de statut |
| `alfawz_app.dart` | **Shell principal** : onglets (`AlfawzBottomNav`), bootstrap auth/inscription, injection des services, navigation vers `ReaderScreen` |
| `config/api_config.dart` | Backend Alfawz : `ALFAWZ_API_BASE`, `ALFAWZ_API_KEY`, `ALFAWZ_ALLOW_LOCAL_ONLY` (`bool.fromEnvironment` / `String.fromEnvironment`) |
| `screens/` | `home_screen`, `library_screen`, `search_screen`, `settings_screen`, `registration_screen`, **`reader_screen`** (lecteur riche) |
| `services/quran_com_api.dart` | Chargement contenu aligné (ayahs + audio + timings mots) — chemin privilégié |
| `services/quran_api_service.dart` | API alternative / repli (ayahs + URLs audio) |
| `services/offline_surah_cache.dart` | Cache disque d’une sourate (payload aligné) |
| `services/surah_list_cache.dart` | Liste des sourates (cache) |
| `services/bookmarks_store.dart` | Signets **verset** et **plages** (sérialisation JSON dans prefs) |
| `services/reading_progress.dart` | Dernière sourate / verset lus |
| `services/favorite_surahs_store.dart` | Sourates favorites |
| `services/user_prefs_store.dart` | Inscription, token, profil, taille de police arabe, rappel quotidien |
| `services/alfawz_backend_api.dart` | Appels HTTP vers le backend (profil, etc.) |
| `widgets/glass_sliver_app_bar.dart` | App bar « verre » en sliver (écrans liste ; le reader utilise une barre équivalente inline) |
| `test/reader_features_test.dart` | Tests unitaires ciblant la logique reader (selon évolutions) |

---

## 4. Flux de données contenu / audio

1. **Priorité** : `QuranComApiService.fetchSurahAlignedContent` si disponible.
2. **Sinon** : chargement **hors-ligne** via `OfflineSurahCache.load` si la sourate a été téléchargée.
3. **Sinon** : `QuranApiService` (ayahs + URLs) + timings mots optionnels vides ou partiels.

Le **reader** reçoit listes d’ayahs, URLs audio, map `wordTimingsByAyah` (clé = `numberInSurah`).

---

## 5. Écran lecteur (`reader_screen.dart`) — comportement important

### Navigation entre versets

- Un **`PageController`** (`_versePageController`) pilote un **`PageView.builder`** horizontal : une page = un verset.
- **`_viewIndex`** = index courant dans `widget.ayahs` (affichage, signets, progression).
- **`_onVersePageChanged`** : sync `_viewIndex`, progression, signet, **seek audio** (`_player.seek(Duration.zero, index: i)`) si l’audio est prêt.
- **`_goVerse`** / boutons prev-next : met à jour `_viewIndex`, `jumpToPage`, seek playlist.

**Choix UI récent (fiabilité du swipe)** : le `PageView` **ne doit pas** être enfant direct d’un `CustomScrollView` + `SliverFillRemaining` — cela gérait mal les gestes horizontaux. La mise en page actuelle est du type :

- `Column` → barre d’app (effet verre + `AppBar`) + en-tête sourate → **`Expanded`** → **`PageView.builder`** → chaque page : **`SingleChildScrollView`** (contenu du verset).
- Barre audio en bas de la `Column` (`_ReaderPlayerBar`).

### Audio

- **`AudioPlayer`** `just_audio` avec **`setAudioSources`** (une source par ayah).
- **`_audioReady`**, **`_audioPrepareError`**, **`_currentTrackIndex`** suivent l’état.
- Boucles : enum **`ReaderAyahLoop`** — `off`, `oneAyah`, `range` (plage avec dialogue ; logique dans listeners `sequenceStateStream`, `positionStream`, `playerStateStream`). **`_syncPageAfterStateChange`** appelle `jumpToPage` après certains `setState` pour garder le pager aligné.

### Barre lecteur (`_ReaderPlayerBar`)

- Style **sobre** : fond `AlfawzColors.surface`, bordure haute légère, `SafeArea`.
- `PopupMenuButton` pour mode de répétition + `IconButton` précédent / **`IconButton.filled`** play-pause (cercle ~54×54) + suivant.
- **`beforePlay`** peut appeler `_syncPlayToViewIndex` pour aligner la piste sur le verset affiché avant lecture.

### Autres

- Partage verset : **`share_plus`** (texte construit dans `_shareVerseAt`).
- Lien soutien : constante **`_alfawzSupportUrl`** en tête de fichier (à adapter).
- Surlignage **mot à mot** : widgets `_AyahArabicWithTracking` / `_AyahArabicWordTracked` si timings compatibles avec le texte arabe.

---

## 6. Inscription & backend

- **`ApiConfig`** : si `baseUrl` vide, le backend « Alfawz » n’est pas configuré.
- **`allowLocalRegistration`** (défaut `true`) : permet une session **locale** (token préfixe `local_…`) sans serveur.
- **`AlfawzApp`** : au boot, charge préférences ; si token réel, tente `fetchProfile` ; 401/403 → reset registration.
- Fichiers modèles : `user_registration.dart`, `remote_user_profile.dart`.

---

## 7. Plateformes & fichiers générés

Projet **multi-plateforme** : `android/`, `ios/`, `macos/`, `web/`, `windows/`, `linux/`.

Ne pas versionner : voir **`.gitignore`** (`.dart_tool/`, `build/`, `.idea/`, etc.). Les **clés API réelles** ne doivent pas être commitées ; utiliser `--dart-define` au build/run.

Exemple :

```bash
flutter run --dart-define=ALFAWZ_API_BASE=https://api.example.com --dart-define=ALFAWZ_API_KEY=secret
```

---

## 8. État « où on en est » (synthèse)

- Lecture sourate avec **swipe horizontal** entre versets (PageView dédié, hors scroll parent problématique).
- **Lecteur audio** en bas, boucles off / un verset / plage ; sync page ↔ piste audio.
- **Signets** simples + **plages** ; **progression** ; **favoris** sourates ; **cache offline** par sourate ; **paramètres** (dont taille police arabe).
- **Tests** : au minimum `test/reader_features_test.dart` — lancer `flutter test`.
- **Git** : historique initial sur `main` ; évolutions futures : commits atomiques + messages clairs.

---

## 9. Faire évoluer ce fichier

Quand une fonctionnalité majeure change (nouvelle API, refonte navigation, règles audio), **mettre à jour ce `.md`** dans le même commit ou juste après — ça aide toutes les sessions IA et humaines sur d’autres machines.
