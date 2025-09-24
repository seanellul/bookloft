# Book Loft - Cayman Humane Society

A Flutter-based inventory management system for Cayman Humane's Book Loft, designed to help volunteers manage book donations and sales efficiently.

## Overview

Book Loft is a volunteer-run book loft that accepts donated books and resells them for $2-5 each. This app digitizes their operations while maintaining their volunteer-driven approach, providing:

- **Barcode/ISBN Scanning**: Quick book identification using mobile camera
- **Inventory Management**: Track book quantities, donations, and sales
- **Search Functionality**: Find books by title, author, or ISBN
- **Offline Support**: Works even in areas with poor connectivity
- **Transaction Tracking**: Record donations and sales with dates and volunteer information

## Features

### 📱 Core Functionality
- **Barcode Scanner**: Scan ISBN barcodes to quickly identify books
- **Book Lookup**: Automatic book information retrieval from Open Library API
- **Inventory Tracking**: Real-time quantity management
- **Search & Filter**: Find books by various criteria
- **Transaction History**: Track all donations and sales

### 🔄 Transaction Management
- **Donation Tracking**: Add books to inventory with date and volunteer info
- **Sale Processing**: Remove books from inventory when sold
- **Multiple Copies**: Special handling for books with 2+ copies
- **Volunteer Attribution**: Track which volunteer processed each transaction

### 📊 Analytics & Reporting
- **Inventory Summary**: Total books, available stock, sales rate
- **Multiple Copies Alert**: Identify books with special offers
- **Sales Analytics**: Track donation vs. sale ratios

### 🌐 Offline Support
- **Local Database**: SQLite storage for offline operation
- **Sync Capability**: Upload changes when connection is restored
- **Fallback Mode**: Graceful degradation when API is unavailable

## Technical Architecture

### Frontend (Flutter)
- **State Management**: Provider pattern for reactive UI
- **Local Storage**: SQLite database for offline data
- **Barcode Scanning**: Mobile Scanner plugin for camera integration
- **HTTP Client**: API communication with backend services

### Backend (Planned)
- **REST API**: Node.js/Express or Python/FastAPI
- **Database**: PostgreSQL for production data
- **Authentication**: JWT-based volunteer authentication
- **Sync Service**: Handle offline data synchronization

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Physical device or emulator for testing

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd bookloft
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Configuration

1. **Update API Endpoint**
   - Edit `lib/services/api_service.dart`
   - Replace `baseUrl` with your backend API URL

2. **Configure Permissions**
   - **Android**: Camera permission in `android/app/src/main/AndroidManifest.xml`
   - **iOS**: Camera usage description in `ios/Runner/Info.plist`

## Usage Guide

### For Volunteers

#### Adding a New Book (Donation)
1. Open the app and tap "Scan Book"
2. Point camera at the book's barcode
3. Review auto-populated book information
4. Enter quantity and volunteer name
5. Tap "Add Book" to save

#### Processing a Sale
1. Search for the book or scan its barcode
2. Select "Process Sale" from book details
3. Enter quantity sold and volunteer name
4. Confirm the transaction

#### Searching Inventory
1. Tap "Search Books" from home screen
2. Enter title, author, or ISBN
3. View results with availability status
4. Tap any book for detailed information

### For Administrators

#### Viewing Inventory Summary
- Home screen displays key metrics
- Total books, available stock, sales rate
- Books with multiple copies highlighted

#### Managing Transactions
- All donations and sales are logged
- Volunteer attribution for accountability
- Date tracking for reporting

## Data Models

### Book
```dart
{
  "id": "unique_id",
  "isbn": "9781234567890",
  "title": "Book Title",
  "author": "Author Name",
  "publisher": "Publisher Name",
  "quantity": 3,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

### Transaction
```dart
{
  "id": "unique_id",
  "book_id": "book_id",
  "type": "donation|sale",
  "quantity": 1,
  "date": "2024-01-01T00:00:00Z",
  "volunteer_name": "Volunteer Name",
  "notes": "Optional notes"
}
```

## API Integration

### Open Library API
- Automatic book information lookup by ISBN
- Fallback to manual entry if lookup fails
- No API key required for basic usage

### Backend API (Planned)
- RESTful endpoints for CRUD operations
- Authentication and authorization
- Data synchronization for offline support

## Development

### Project Structure
```
lib/
├── models/           # Data models and serialization
├── services/         # API and database services
├── providers/        # State management
├── screens/          # UI screens
├── widgets/          # Reusable UI components
└── main.dart         # App entry point
```

### Key Dependencies
- `mobile_scanner`: Barcode scanning functionality
- `provider`: State management
- `sqflite`: Local database storage
- `http`: API communication
- `json_annotation`: JSON serialization

### Adding New Features
1. Create data models in `lib/models/`
2. Add API endpoints in `lib/services/api_service.dart`
3. Update state management in `lib/providers/`
4. Create UI screens in `lib/screens/`
5. Add reusable widgets in `lib/widgets/`

## Contributing

This is an open-source project for Cayman Humane Society. Contributions are welcome!

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Code Style
- Follow Flutter/Dart conventions
- Use meaningful variable names
- Add comments for complex logic
- Maintain consistent formatting

## Deployment

### Android
1. Generate signed APK
2. Distribute to volunteers via Google Play or direct install
3. Configure app permissions

### iOS
1. Build for iOS devices
2. Distribute via TestFlight or App Store
3. Configure camera permissions

## Support

For technical support or feature requests:
- Create an issue in the repository
- Contact the development team
- Check the documentation wiki

## License

This project is open-source and available under the MIT License. See LICENSE file for details.

## Acknowledgments

- Cayman Humane Society for the opportunity to help
- Flutter community for excellent documentation
- Open Library for free book data API
- All volunteers who will use this system

---

**Built with ❤️ for Cayman Humane Society**