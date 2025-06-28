# JobFind - Flutter Job Finding Application

A modern Flutter application for job seekers and employers to connect through a comprehensive job marketplace. Built with Flutter and Supabase backend.

## 📱 Features

### For Job Seekers
- **Browse Jobs**: View and search through available job listings
- **Job Details**: Detailed information about each job position
- **Apply for Jobs**: Submit applications directly through the app
- **Profile Management**: Update personal information and profile photo
- **Application Tracking**: View status of submitted applications

### For Employers/Admins
- **Post Jobs**: Create and publish new job listings
- **Manage Applications**: Review and manage incoming applications
- **Job Management**: Edit or delete existing job postings
- **Admin Dashboard**: Access to administrative functions

### General Features
- **User Authentication**: Secure login and registration system
- **Real-time Search**: Search jobs by title or company name
- **Responsive Design**: Optimized for various screen sizes
- **Modern UI**: Clean and intuitive user interface with Material Design
- **Image Upload**: Profile photo management with image picker

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.7.0+
- **Backend**: Supabase (PostgreSQL + Real-time API)
- **Authentication**: Supabase Auth
- **State Management**: Flutter StatefulWidget
- **UI Components**: Material Design 3
- **Image Handling**: image_picker package
- **Loading Effects**: Shimmer loading animations

## 📋 Prerequisites

Before running this application, make sure you have:

- **Flutter SDK** (3.7.0 or higher)
- **Dart SDK** (3.0.0 or higher)
- **Android Studio** or **VS Code** with Flutter extensions
- **Android Emulator** or **Physical Device** for testing
- **Supabase Account** and project setup

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd jobfind
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Supabase
1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Set up the following database tables using the SQL commands below

### 4. Update Configuration
Update the Supabase configuration in `lib/main.dart`:
```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### 5. Run the Application
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── main.dart                 # Application entry point
├── pages/                    # Screen components
│   ├── splash_screen.dart    # Loading screen
│   ├── login_screen.dart     # User authentication
│   ├── register_screen.dart  # User registration
│   ├── home_screen.dart      # Main job listing screen
│   ├── job_detail.dart       # Job details view
│   ├── input_job.dart        # Job posting form
│   ├── profile_screen.dart   # User profile management
│   ├── application_list_page.dart # Application management
│   └── application_color.dart # Color utilities
└── services/
    └── auth_service.dart     # Authentication service
```

## 🔧 Database Schema

### Users Table
```sql
CREATE TABLE users (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('job_seeker', 'admin')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Job Seekers Table
```sql
CREATE TABLE job_seekers (
  id BIGINT PRIMARY KEY REFERENCES users (id),
  experience TEXT,
  education TEXT,
  skills TEXT
);
```

### Jobs Table
```sql
CREATE TABLE jobs (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id BIGINT REFERENCES users (id),
  company TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Applications Table
```sql
CREATE TABLE applications (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  job_id BIGINT REFERENCES jobs (id),
  job_seeker_id BIGINT REFERENCES job_seekers (id),
  status TEXT NOT NULL CHECK (status IN ('submitted', 'accepted', 'rejected')),
  applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Admin Actions Table
```sql
CREATE TABLE admin_actions (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  admin_id BIGINT REFERENCES users (id),
  action_type TEXT NOT NULL,
  action_details TEXT,
  action_time TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 🎯 Usage Guide

### For Job Seekers
1. **Register/Login**: Create an account or sign in
2. **Browse Jobs**: View available job listings on the home screen
3. **Search Jobs**: Use the search bar to find specific positions
4. **View Details**: Tap on a job to see full details
5. **Apply**: Submit your application with one tap
6. **Track Applications**: Monitor your application status

### For Employers/Admins
1. **Admin Login**: Sign in with admin credentials
2. **Post Jobs**: Use the "Input Job" feature to create new listings
3. **Manage Applications**: Review incoming applications
4. **Edit/Delete Jobs**: Modify or remove existing job postings

## 🔐 Security Features

- **Supabase Row Level Security (RLS)** for data protection
- **JWT Authentication** for secure user sessions
- **Input Validation** to prevent malicious data
- **Secure API Keys** management
- **Role-based Access Control** with user roles

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/yourusername/jobfind/issues) page
2. Create a new issue with detailed description
3. Contact the development team

## 🔄 Version History

- **v1.0.0** - Initial release with basic job finding functionality
- Basic authentication system
- Job listing and application features
- Admin panel for job management

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure
- Material Design for UI components
- All contributors and testers

---

**Made with ❤️ using Flutter & Supabase**
