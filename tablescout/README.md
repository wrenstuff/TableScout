# Installation and Setup

## Prerequisites

Before running TableScout, ensure you have installed:

Flutter SDK

Dart SDK

Python 3

Git

Visual Studio with the desktop development with c++ Extension / Workload

A suitable IDE (Visual Studio Code or Android Studio recommended)


---

### 1. Clone the Repository

git clone https://github.com/wrenstuff/TableScout.git

Navigate into the project directory:

cd TableScout

---

### 2. Set Up the Backend

Navigate to the backend directory:

cd backend

Create a Python virtual environment:

python -m venv .venv

Activate the environment on Windows PowerShell:

.\.venv\Scripts\Activate.ps1

Install the required Python dependencies:

pip install -r requirements.txt

---

### 3. Build and Run the Application

Navigate to the Flutter project directory:

cd ..\tablescout

Install the required Flutter dependencies:

flutter pub get

Build the Windows application:

flutter build windows

Once the build has completed, navigate back to the Root directory:

cd..

Ensure all required dependencies and environment variables are configured, then launch the application using:

.\Launcher.bat

Alternatively, double-click Launcher.bat in Windows File Explorer.
The launcher is used to start the backend services without manually entering the individual startup commands.

If you run unto any issues delete the "build" folder TableScout\tablescout\build then run the following commands.

flutter clean
flutter pub get
flutter build windows

The bat from there should work. Any issues please contact us.

### User roles and test accounts
Admin
Username - admin@admin.com
password 12345678!
External administrator responsible for creating and overseeing store accounts.

Store
Username - store@store.com
password 12345678!
Store-level account responsible for managing associated users and operations.

Manager
Username - manager@manager.com
password 12345678!
Responsible for managing store operations and staff.

Supervisor
Username - supervisor@supervisor.com
password 12345678!
Supports store management and operational activities.

Staff
Username - staff@staff.com
password 12345678!
Accesses permitted staff functions.