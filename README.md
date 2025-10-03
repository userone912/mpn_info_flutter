# MPN-Info Flutter

A modern, cross-platform tax revenue processing application for Indonesian tax offices (KPP/Kanwil), migrated from Qt to Flutter.

## Overview

MPN-Info Flutter is a comprehensive application designed to process Indonesian tax data including:
- **MPN** (Modul Penerimaan Negara) - State Revenue Module
- **SPM** (Surat Perintah Membayar) - Payment Order Letters  
- **SPT** (Surat Pemberitahuan Tahunan) - Annual Tax Returns
- **SPMKP/SPMPP** - Various tax payment types

## Features

### Core Features
- ✅ Multi-platform support (Windows, Android, Web)
- ✅ Tax revenue data import/export
- ✅ Advanced search and filtering
- ✅ Interactive charts and analytics
- ✅ Report generation (Excel, PDF)
- ✅ User management and authentication
- ✅ Database management (SQLite, PostgreSQL)
- ✅ Online data download from tax portals

### Platform-Specific Features
- **Desktop**: Native file system integration, window management
- **Android**: Mobile-optimized UI, offline capabilities
- **Web**: Responsive design, PWA support

## Technology Stack

- **Framework**: Flutter 3.35.5
- **Language**: Dart 3.9.2
- **State Management**: Riverpod
- **Database**: SQLite (local), PostgreSQL (server)
- **Charts**: FL Chart, Syncfusion Charts
- **Navigation**: GoRouter
- **UI**: Material Design 3

## Project Structure

```
lib/
├── core/
│   ├── constants/      # App constants and configurations
│   ├── services/       # Core services (database, network, etc.)
│   └── utils/          # Utility functions and helpers
├── data/
│   ├── datasources/    # Data sources (local, remote)
│   ├── models/         # Data models
│   └── repositories/   # Repository implementations
├── features/
│   ├── auth/           # Authentication feature
│   ├── dashboard/      # Main dashboard
│   ├── data_import/    # Data import functionality
│   └── reports/        # Report generation
├── presentation/       # UI layer
└── shared/
    ├── themes/         # App themes and styling
    └── widgets/        # Reusable widgets
```

## Getting Started

### Prerequisites

- Flutter SDK 3.35.5 or later
- Dart SDK 3.9.2 or later
- Android Studio (for Android development)
- Visual Studio (for Windows development)
- Git

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd mpn_info_flutter
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
# For Windows desktop
flutter run -d windows

# For Android
flutter run -d android

# For Web
flutter run -d chrome
```

### Building for Production

```bash
# Windows
flutter build windows

# Android
flutter build apk

# Web
flutter build web
```

## Development

### Code Generation

This project uses code generation for various purposes. Run the following command after making changes to annotated classes:

```bash
dart run build_runner build
```

For development with automatic rebuilding:

```bash
dart run build_runner watch
```

### Testing

Run all tests:
```bash
flutter test
```

### Linting

This project follows strict linting rules. Check code quality:
```bash
flutter analyze
```

## Migration Progress

This is a migration from the original Qt-based MPN-Info application. 

### Completed
- [x] Project setup and dependencies
- [x] Basic project structure
- [ ] Authentication system
- [ ] Database layer
- [ ] Core models
- [ ] Main dashboard
- [ ] Data import functionality
- [ ] Charts and analytics
- [ ] Report generation
- [ ] Multi-platform optimizations

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the GPL v3 License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Original Qt-based MPN-Info application by Ichdyan Thalasa
- Indonesian Ministry of Finance (Kemenkeu) for domain expertise
- Flutter team for the excellent framework

## Contact

For questions or support, please open an issue in the GitHub repository.
