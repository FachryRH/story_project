# Story App

A Flutter application that allows users to share stories with images.

## Features

- **Authentication**: Login and register with secure password handling.
- **Story List**: View a list of stories from other users.
- **Story Detail**: See detailed information about a specific story.
- **Create Story**: Add your own stories with images from camera or gallery.
- **Multilingual Support**: Switch between English and Bahasa Indonesia.

## Requirements

- Flutter SDK: 3.x or higher
- Dart SDK: 3.x or higher

## Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the application

## API Documentation

This app uses the Dicoding Story API which is available at:
https://story-api.dicoding.dev/v1

The API provides endpoints for:
- User registration and login
- Story listing and details
- Adding new stories with images

## Architecture

The app follows a clean architecture approach with:

- **Data Layer**: API services, local storage, and repositories
- **Domain Layer**: Models and business logic
- **Presentation Layer**: UI screens, widgets, and state management

## Libraries Used

- **State Management**: Provider
- **Navigation**: Go Router (declarative navigation)
- **Networking**: HTTP
- **Storage**: Shared Preferences
- **Images**: Image Picker, Cached Network Image
- **Internationalization**: Flutter Localizations

## License

This project is licensed under the MIT License.
