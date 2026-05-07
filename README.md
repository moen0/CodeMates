# CodeMates

En Flutter-app som hjelper studenter å finne medstudenter til prosjekter. Brukere kan opprette og oppdage prosjekter, søke om å bli med, og bygge en profil med ferdigheter og lenker.

Utviklet som prosjekt i faget Systemutvikling ved Universitetet i Sørøst-Norge (USN), vårsemesteret 2026.

---

## Teknologi

| Lag | Teknologi |
|-----|-----------|
| Frontend | Flutter (Dart) |
| Backend | Supabase (PostgreSQL, Auth, Storage, Realtime) |
| Font | Google Fonts, Space Mono |
| State management | StatefulWidget |

---

## Kom i gang

### Krav

Flutter SDK 3.x eller nyere, Dart SDK 3.x eller nyere, og en Supabase-instans (se konfigurasjon nedenfor).

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

## Arkitektur

Appen er bygget med en lagdelt arkitektur som skiller presentasjon, forretningslogikk og data. Hvert lag har ett ansvar, og avhengigheter går alltid nedover.

```
Presentasjon (screens, widgets)
        |
Service Layer (services)
        |
Domenemodeller (models)
        |
Datakilde (Supabase)
```

**Presentasjonslaget** inneholder skjermer og UI-komponenter. Skjermene kaller services for å hente og endre data, men kjenner ikke til Supabase eller databasestrukturen.

**Service-laget** inneholder all forretningslogikk og datatilgang. Hver service eier ett ansvarsområde (auth, profiler, prosjekter, søknader, meldinger, matching).

**Modell-laget** definerer typede dataklasser med immutable felter, factory-metoder for serialisering, og `copyWith` for endringer. Modellene speiler databasen, men bruker camelCase i Dart og snake_case mot databasen.

**Datakilde** er Supabase, som gir PostgreSQL, autentisering, fillagring og Realtime-abonnement.

---

## Autentisering

`AuthGate` i `main.dart` lytter på Supabase sin auth-stream ved oppstart. Hvis brukeren har en aktiv sesjon (lagret lokalt på enheten av Supabase), sendes de direkte til `HomeScreen`. Ellers vises `Welcome`. Dette gjør at innloggede brukere slipper å logge inn på nytt hver gang appen åpnes.

---

## Databaseskjema

| Tabell | Innhold |
|--------|---------|
| `profiles` | Brukerprofil med navn, bio, universitet, studieprogram, årstrinn, lenker (GitHub, LinkedIn, nettside) og tilgjengelighetsstatus |
| `skills` | Alle tilgjengelige ferdigheter med kategori (language, frontend, backend, data_ai, devops, database, design, mobile) |
| `user_skills` | Kobling mellom bruker og ferdighet med ferdighetsnivå (beginner, intermediate, advanced) |
| `projects` | Prosjekter med tittel, beskrivelse, status (recruiting, active, completed), maks antall medlemmer, type, mål, erfaringsnivå, tidsramme og møtelenke |
| `project_skills` | Ferdigheter et prosjekt ser etter |
| `project_members` | Godkjente medlemmer i et prosjekt med rolle og tidspunkt for innmelding |
| `applications` | Søknader med status (pending, accepted, rejected) |
| `messages` | Chat-meldinger knyttet til prosjekter, brukt av Realtime-abonnement |

---

## Skjermer

### Autentisering
`Welcome` er landingssiden med innlogging og registrering. `Login` håndterer e-post og passord-innlogging. `Register` håndterer kontoopprettelse med validering.

### Profil
`EditProfileScreen` er en to-stegs onboarding (grunninfo, deretter ferdigheter og lenker). `ProfileScreen` viser og lar bruker redigere egen profil, laste opp avatar og se ferdigheter med aktivitetsstatistikk. `EditSkillsScreen` håndterer ferdigheter med ferdighetsnivå og kategorifilter.

### Prosjekter
`FeedScreen` viser prosjekter som rekrutterer, med match-score basert på brukerens ferdigheter. `MyProjectsScreen` viser egne og deltatte prosjekter i to faner. `CreateProjectScreen` og `CreateProjectStep2Screen` er en to-stegs prosjektoppretting (info, deretter ferdigheter og teamstørrelse). `ProjectDetailScreen` viser prosjektdetaljer med søknadsmulighet. `EditProjectScreen` lar eieren redigere prosjektet. `ProjectsChatScreen` er prosjektchat med sanntidsoppdatering via Supabase Realtime.

### Søknader
`ApplicationsScreen` viser innkommende og utgående søknader i to faner. Eier kan godkjenne eller avslå søknader, som automatisk oppdaterer prosjektets medlemsliste og status.

---

## Matching-algoritme

Match-scoren (0 til 100 prosent) beregnes basert på brukerens ferdigheter mot prosjektets krav:

| Ferdighetsnivå | Vekt |
|----------------|------|
| Advanced | 1.0 |
| Intermediate | 0.6 |
| Beginner | 0.3 |

```
score = (sum av vekter for matchende ferdigheter) / (antall påkrevde ferdigheter) x 100
```

Prosjekter uten ferdighetskrav gir automatisk 100 prosent match.

---

## UI-system

Appen bruker et egenutviklet brutalist-designsystem i `lib/widgets/brutalist_ui.dart`.

### Fargepalett

| Token | Hex | Bruk |
|-------|-----|------|
| `bg` | `#000000` | Bakgrunn |
| `panel` | `#111111` | Kort og paneler |
| `border` | `#333333` | Kanter |
| `muted` | `#888888` | Sekundaertekst |
| `accent` | `#6366F1` | Interaktive elementer |

Bakgrunnen har et rutenettmønster og en scanline-effekt for et minimalistisk, teknisk utseende.

### Komponenter

`BrutalistScaffold`, `BrutalistHeader`, `BrutalistPanel`, `brutalistInputDecoration`, `brutalistPrimaryButtonStyle`, `brutalistOutlineButtonStyle`.

---

## Prosjektstruktur

```
lib/
  main.dart
  models/
    application.dart
    message.dart
    profile.dart
    project.dart
    project_member.dart
    project_skill.dart
    skill.dart
    user_skill.dart
  services/
    application_service.dart
    auth_service.dart
    matching_service.dart
    message_service.dart
    profile_service.dart
    project_service.dart
  screens/
    welcome.dart
    login.dart
    register.dart
    home_screen.dart
    feed_screen.dart
    profile_screen.dart
    public_profile_screen.dart
    edit_profile_screen.dart
    edit_skills_screen.dart
    my_projects.dart
    create_project_screen.dart
    create_project_step2_screen.dart
    project_detail_screen.dart
    edit_project_screen.dart
    projects_chat_screen.dart
    application_screen.dart
  widgets/
    brutalist_ui.dart
```
