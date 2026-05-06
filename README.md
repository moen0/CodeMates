# CodeMates

En Flutter-app som hjelper studenter å finne medstudenter til prosjekter. Brukere kan opprette og oppdage prosjekter, søke om å bli med, og bygge en profil med ferdigheter og lenker.

Utviklet som prosjekt i faget Systemutvikling ved Universitetet i Sørøst-Norge (USN), vårsemesteret 2026.

---

## Teknologi

| Lag | Teknologi |
|-----|-----------|
| Frontend | Flutter (Dart) |
| Backend | Supabase (PostgreSQL, Auth, Storage) |
| Font | Google Fonts – Space Mono |
| State management | StatefulWidget (ingen ekstern pakke) |
| Overvåkning | Datadog Flutter Plugin |

---

## Kom i gang

### Krav

- Flutter SDK ≥ 3.x
- Dart SDK ≥ 3.x
- En Supabase-instans (se konfigurasjon nedenfor)

### Installasjon

```bash
git clone https://github.com/moen0/CodeMates.git
cd CodeMates
flutter pub get
flutter run
```

### Supabase-konfigurasjon

Sett Supabase URL og anon-nøkkel i `lib/main.dart`:

```dart
supabaseUrl: 'DIN_SUPABASE_URL',
supabaseAnonKey: 'DIN_SUPABASE_ANON_KEY',
```

---

## Databaseskjema

| Tabell | Innhold |
|--------|---------|
| `profiles` | Brukerprofil – navn, bio, universitet, studieprogram, lenker, tilgjengelighet |
| `skills` | Alle tilgjengelige ferdigheter med kategori |
| `user_skills` | Kobling mellom bruker og ferdighet med ferdighetsnivå |
| `projects` | Prosjekter med type, mål, maks medlemmer og status |
| `project_skills` | Ferdigheter et prosjekt ser etter |
| `project_members` | Godkjente medlemmer i et prosjekt |
| `applications` | Søknader med status (pending / accepted / rejected) |

---

## Skjermer

### Autentisering
- **Welcome** – Landingsside med innlogging og registrering
- **Login** – E-post/passord-innlogging
- **Register** – Opprettelse av konto med validering

### Profil
- **EditProfileScreen** – 2-stegs onboarding (grunninfo → ferdigheter og lenker)
- **ProfileScreen** – Vis og rediger egen profil, last opp avatar, se ferdigheter og aktivitetsstatistikk
- **EditSkillsScreen** – Administrer ferdigheter med ferdighetsnivå og kategorifiltere

### Prosjekter
- **FeedScreen** – Bla gjennom prosjekter som rekrutterer, med match-score basert på egne ferdigheter
- **MyProjectsScreen** – Egne og deltatte prosjekter i to faner
- **CreateProjectScreen** – 2-stegs prosjektoppretting (info → ferdigheter og teamstørrelse)
- **ProjectDetailScreen** – Prosjektdetaljer med søknadsmulighet
- **EditProjectScreen** – Rediger prosjekt (kun eier)
- **ProjectsChatScreen** – Prosjektchat (under utvikling)

### Søknader
- **ApplicationsScreen** – Innkommende og utgående søknader i to faner

---

## Matching-algoritme

Match-scoren (0–100 %) beregnes basert på brukerens ferdigheter mot prosjektets krav:

| Ferdighetsnivå | Vekt |
|----------------|------|
| Advanced | 1.0 |
| Intermediate | 0.6 |
| Beginner | 0.3 |

```
score = (sum av vekter for matchende ferdigheter) / (antall påkrevde ferdigheter) × 100
```

Prosjekter uten ferdighetskrav gir automatisk 100 % match.

---

## UI-system

Appen bruker et egenutviklet brutalist-designsystem i `lib/widgets/brutalist_ui.dart`.

**Fargepalett:**

| Token | Hex | Bruk |
|-------|-----|------|
| `bg` | `#000000` | Bakgrunn |
| `panel` | `#111111` | Kort og paneler |
| `border` | `#333333` | Kanter |
| `muted` | `#888888` | Sekundærtekst |
| `accent` | `#6366F1` | Interaktive elementer |

Bakgrunnen har et rutenettmønster og en scanline-effekt for et minimalistisk, teknisk utseende.

**Komponenter:** `BrutalistScaffold`, `BrutalistHeader`, `BrutalistPanel`, `brutalistInputDecoration`, `brutalistPrimaryButtonStyle`, `brutalistOutlineButtonStyle`

---

## Prosjektstruktur

```
lib/
├── main.dart
├── screens/
│   ├── welcome.dart
│   ├── login.dart
│   ├── register.dart
│   ├── home_screen.dart
│   ├── feed_screen.dart
│   ├── profile_screen.dart
│   ├── edit_profile_screen.dart
│   ├── edit_skills_screen.dart
│   ├── my_projects.dart
│   ├── create_project_screen.dart
│   ├── create_project_step2_screen.dart
│   ├── project_detail_screen.dart
│   ├── edit_project_screen.dart
│   ├── projects_chat_screen.dart
│   └── application_screen.dart
├── services/
│   ├── matching_service.dart      # Match-score-beregning
│   ├── project_service.dart       # Prosjekt-CRUD og ferdighetskobling
│   └── application_service.dart   # Søknadsflyt og medlemshåndtering
└── widgets/
    └── brutalist_ui.dart          # Designsystem
```

---

## Kjente mangler / TODO

- URL-åpning for GitHub-, LinkedIn- og nettsidelenker
- Reelle aktivitetstall på profilskjermen
- Fullstendig prosjektchat

---

## Bidragsytere

- [@moen0](https://github.com/moen0)
- [@sinsan](https://github.com/sinsan)
