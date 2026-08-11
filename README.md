# Bandana HAR

Bandana is an AI-powered IoT wearable Flutter application for Human Activity Recognition (HAR). It connects to an ESP32-C3 microcontroller via Bluetooth Low Energy (BLE) to receive real-time IMU data (Accelerometer and Gyroscope) and uses on-device machine learning to classify user activities.

## Features

- **BLE Connectivity**: Seamlessly connects to the Bandana ESP32-C3 wearable device and subscribes to IMU sensor data characteristics.
- **Record Mode**: Log user activity streams and tag them with user-defined labels (e.g., "Walking", "Running", "Sitting"). Ground-truth data is securely saved to a local SQLite database.
- **On-Device Machine Learning**: Train a lightweight K-Nearest Neighbors (KNN) classification model entirely on the mobile device using the recorded data.
- **Live Classification**: Feed real-time BLE streams into the trained ML model for instant activity classification with a confidence gauge.
- **Data Visualization**: Real-time interactive charts for visualizing the incoming IMU sensor data.

## Architecture

The application is built using a modern Flutter architecture:

- **State Management**: `flutter_riverpod` for reactive, predictable state management.
- **Local Storage**: `drift` for type-safe SQLite database operations and data persistence.
- **Machine Learning**: `ml_algo` and `ml_dataframe` for feature extraction (Mean, Std Dev, Variance, Min, Max over time windows) and K-Nearest Neighbors classification.
- **Dependency Injection**: `get_it` service locator for decoupled business logic and services (`BleService`, `DatabaseService`, `MlService`).
- **Bluetooth**: `flutter_blue_plus` for reliable BLE scanning and high-throughput connections (Android MTU 512).

## Getting Started

### Prerequisites

- Flutter SDK (>=3.44.0 recommended, or Dart SDK >=3.11.1)
- An Android or iOS physical device for BLE functionality (BLE does not work on emulators natively)
- The Bandana ESP32-C3 hardware flashed with the corresponding IMU BLE firmware.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/bandana.git
   cd bandana
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate Drift database files and Riverpod code (if applicable):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Hardware Configuration (ESP32-C3)

Ensure your ESP32-C3 device advertises the following UUIDs, which the app is configured to scan for:

- **Service UUID**: `550e8400-e29b-41d4-a716-446655440000`
- **Characteristic UUID**: `550e8401-e29b-41d4-a716-446655440000`

The IMU data stream over BLE should be formatted as a CSV string per line:
`ax,ay,az,gx,gy,gz`

## License

This project is licensed under the MIT License - see the LICENSE file for details.

*Note: This project relies on `flutter_blue_plus` which uses a dual-license model. The app connects using `License.nonprofit`.*
