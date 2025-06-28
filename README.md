# JobFind - Flutter Job Finding Application

A modern Flutter application for job seekers and employers to connect through a comprehensive job marketplace. Built with Flutter and Supabase backend with advanced features like real-time status tracking, image uploads, and soft delete functionality.

## 📱 Features

### For Job Seekers
- **Browse Jobs**: View and search through available job listings with company images
- **Job Details**: Detailed information about each job position with rich media
- **Apply for Jobs**: Submit applications directly through the app
- **Profile Management**: Update personal information and upload profile photos
- **Application Tracking**: Comprehensive application status tracking with real-time updates
- **My Applications**: View all submitted applications with status badges and management tools
- **Soft Delete**: Remove applications from your view while maintaining data integrity

### For Employers/Admins
- **Post Jobs**: Create and publish new job listings with company images
- **Manage Applications**: Review and manage incoming applications with accept/reject functionality
- **Job Management**: Edit or delete existing job postings
- **Admin Dashboard**: Access to administrative functions
- **Application Status Management**: Update application statuses with soft delete support

### General Features
- **Supabase Auth Integration**: Secure authentication using Supabase Auth
- **UUID-based System**: Modern UUID-based user and data management
- **Real-time Search**: Search jobs by title or company name
- **Responsive Design**: Optimized for various screen sizes
- **Modern UI**: Clean and intuitive user interface with Material Design 3
- **Image Upload**: Profile photo and job image management with Supabase Storage
- **Status Notifications**: Real-time status updates with visual indicators
- **Pull-to-Refresh**: Refresh data with intuitive gestures
- **Error Handling**: Comprehensive error handling with user-friendly messages

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.7.0+
- **Backend**: Supabase (PostgreSQL + Real-time API)
- **Authentication**: Supabase Auth with JWT tokens
- **Storage**: Supabase Storage for image management
- **State Management**: Flutter StatefulWidget
- **UI Components**: Material Design 3
- **Image Handling**: image_picker package with Supabase Storage
- **Loading Effects**: Shimmer loading animations
- **Database**: PostgreSQL with UUID primary keys

## 📋 Prerequisites

Before running this application, make sure you have:

- **Flutter SDK** (3.7.0 or higher)
- **Dart SDK** (3.0.0 or higher)
- **Android Studio** or **VS Code** with Flutter extensions
- **Android Emulator** or **Physical Device** for testing
- **Supabase Account** and project setup
- **Supabase Storage** buckets configured

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/JJThomson12/jobfind.git
cd jobfind
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Supabase
1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Set up the following database tables using the SQL commands below
3. Configure Supabase Storage buckets for profile photos and job images
4. Set up Row Level Security (RLS) policies

### 4. Update Configuration
Update the Supabase configuration in `lib/main.dart`:
```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### 5. Configure Storage Buckets
Create the following storage buckets in Supabase:
- `profiles` - for user profile photos
- `company` - for job/company images

### 6. Run the Application
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── main.dart                           # Application entry point
├── pages/                              # Screen components
│   ├── splash_screen.dart              # Loading screen
│   ├── login_screen.dart               # User authentication
│   ├── register_screen.dart            # User registration
│   ├── home_screen.dart                # Main job listing screen
│   ├── job_detail.dart                 # Job details view
│   ├── input_job.dart                  # Job posting form
│   ├── profile_screen.dart             # User profile management
│   ├── application_list_page.dart      # Admin application management
│   └── user_application_list_page.dart # User application tracking
├── services/
│   ├── auth_service.dart               # Authentication service
│   └── storage_service.dart            # Storage service for images
└── assets/
    └── images/                         # Static images
```

## 🔧 Database Schema

### Users Table (UUID-based)
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('job_seeker', 'admin')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Job Seekers Table
```sql
CREATE TABLE job_seekers (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  experience TEXT,
  education TEXT,
  skills TEXT,
  photo_url TEXT
);
```

### Jobs Table
```sql
CREATE TABLE jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  company TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Applications Table (with Soft Delete)
```sql
CREATE TABLE applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID REFERENCES jobs(id),
  job_seeker_id UUID REFERENCES auth.users(id),
  status TEXT NOT NULL CHECK (status IN ('submitted', 'accepted', 'rejected')),
  applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_by_admin BOOLEAN DEFAULT FALSE,
  deleted_by_user BOOLEAN DEFAULT FALSE
);
```

## 🎯 Usage Guide

### For Job Seekers
1. **Register/Login**: Create an account using Supabase Auth
2. **Complete Profile**: Add experience, education, skills, and profile photo
3. **Browse Jobs**: View available job listings with company images
4. **Search Jobs**: Use the search bar to find specific positions
5. **View Details**: Tap on a job to see full details and company image
6. **Apply**: Submit your application with one tap
7. **Track Applications**: Monitor your application status in "Lamaran Saya"
8. **Manage Applications**: Delete applications from your view when needed

### For Employers/Admins
1. **Admin Login**: Sign in with admin credentials
2. **Post Jobs**: Use the "Input Job" feature to create new listings with images
3. **Manage Applications**: Review incoming applications and update statuses
4. **Edit/Delete Jobs**: Modify or remove existing job postings
5. **Application Management**: Accept/reject applications with soft delete support

## 🔐 Security Features

- **Supabase Row Level Security (RLS)** for data protection
- **JWT Authentication** for secure user sessions
- **UUID-based Security** for enhanced data protection
- **Input Validation** to prevent malicious data
- **Secure API Keys** management
- **Role-based Access Control** with user roles
- **Storage Security** with bucket policies

## 🆕 Recent Updates

### v2.0.0 - Enhanced Features
- **UUID Migration**: Upgraded to UUID-based system for better security
- **Supabase Auth Integration**: Modern authentication system
- **Profile Photo Upload**: User profile photo management with Supabase Storage
- **Job Image Upload**: Company/job image support
- **Soft Delete System**: Intelligent application deletion for both users and admins
- **Enhanced Application Tracking**: Comprehensive status tracking with visual indicators
- **Real-time Notifications**: Status update notifications with "BARU" badges
- **Improved UI/UX**: Modern Material Design 3 interface with better user experience

### v1.0.0 - Initial Release
- Basic authentication system
- Job listing and application features
- Admin panel for job management

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

1. Check the [Issues](https://github.com/JJThomson12/jobfind/issues) page
2. Create a new issue with detailed description
3. Contact the development team

## 🔄 Version History

- **v2.0.0** - Enhanced features with UUID migration, Supabase Auth, image uploads, and soft delete
- **v1.0.0** - Initial release with basic job finding functionality

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure and authentication
- Material Design for UI components
- All contributors and testers

---

**Made with ❤️ using Flutter & Supabase**
