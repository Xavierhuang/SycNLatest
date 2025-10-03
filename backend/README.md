# SyncN Backend Authentication API

A secure Node.js backend API for the SyncN women's health and fitness app, providing authentication, user management, and cycle prediction services.

## 🚀 Features

- **Secure Authentication**: JWT-based authentication with refresh tokens
- **User Management**: Registration, login, profile management
- **Password Reset**: Email-based password reset functionality
- **Data Sync**: User data synchronization across devices
- **Cycle Predictions**: Menstrual cycle phase calculations
- **Rate Limiting**: Protection against brute force attacks
- **Email Integration**: Automated emails for verification and password reset

## 📋 Prerequisites

- Node.js 16+ 
- npm or yarn
- SQLite3
- Email service (Gmail, SendGrid, etc.)

## 🛠 Installation

1. **Clone and navigate to backend directory**
```bash
cd backend
```

2. **Install dependencies**
```bash
npm install
```

3. **Set up environment variables**
```bash
cp config.env.example .env
```

4. **Configure your .env file**
```env
# Server Configuration
PORT=8000
NODE_ENV=development

# Database Configuration
DATABASE_PATH=./data/syncn.db

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=30d
JWT_REFRESH_EXPIRES_IN=90d

# Email Configuration
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM=SyncN App <noreply@syncnapp.com>

# Security
BCRYPT_ROUNDS=12
SESSION_SECRET=your-session-secret-key

# CORS Configuration
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:8081
```

5. **Start the server**
```bash
# Development mode with auto-restart
npm run dev

# Production mode
npm start
```

## 📚 API Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | User login |
| POST | `/api/auth/logout` | User logout |
| POST | `/api/auth/refresh` | Refresh access token |
| POST | `/api/auth/forgot-password` | Request password reset |
| POST | `/api/auth/reset-password` | Reset password with token |

### User Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/user/profile` | Get user profile |
| PUT | `/api/user/profile` | Update user profile |
| POST | `/api/user/sync-data` | Sync user data |
| GET | `/api/user/sync-data` | Get synced data |

### Cycle Predictions

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/cycle/predictions` | Generate cycle predictions |
| GET | `/api/cycle/phases` | Get cycle phase for date |

## 🔐 Security Features

- **Password Hashing**: bcrypt with configurable rounds
- **JWT Tokens**: Secure access and refresh tokens
- **Rate Limiting**: Prevents brute force attacks
- **CORS Protection**: Configurable allowed origins
- **Helmet**: Security headers
- **Input Validation**: Joi schema validation
- **SQL Injection Protection**: Parameterized queries

## 📧 Email Setup

### Gmail Setup
1. Enable 2-factor authentication on your Gmail account
2. Generate an App Password: Google Account → Security → App passwords
3. Use the app password in `EMAIL_PASS`

### Other Providers
Update the SMTP configuration in your `.env` file:
```env
EMAIL_HOST=your-smtp-host
EMAIL_PORT=587
EMAIL_USER=your-email
EMAIL_PASS=your-password
```

## 🗄️ Database Schema

The API automatically creates the following tables:

- **users**: User accounts and authentication
- **user_profiles**: Extended user profile data
- **user_sessions**: Active login sessions
- **password_reset_tokens**: Password reset tokens
- **email_verification_tokens**: Email verification tokens
- **user_data_sync**: User data synchronization

## 🧪 Testing

```bash
# Run tests
npm test

# Health check
curl http://localhost:8000/health
```

## 🚀 Deployment

### Production Setup

1. **Update environment variables**
```env
NODE_ENV=production
JWT_SECRET=your-super-secure-production-secret
DATABASE_PATH=/var/lib/syncn/syncn.db
```

2. **Use PM2 for process management**
```bash
npm install -g pm2
pm2 start server.js --name "syncn-backend"
pm2 startup
pm2 save
```

3. **Set up reverse proxy (Nginx)**
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | 8000 |
| `NODE_ENV` | Environment | development |
| `DATABASE_PATH` | SQLite database path | ./data/syncn.db |
| `JWT_SECRET` | JWT signing secret | Required |
| `JWT_EXPIRES_IN` | Access token expiry | 30d |
| `JWT_REFRESH_EXPIRES_IN` | Refresh token expiry | 90d |
| `BCRYPT_ROUNDS` | Password hashing rounds | 12 |
| `EMAIL_HOST` | SMTP host | smtp.gmail.com |
| `EMAIL_PORT` | SMTP port | 587 |
| `EMAIL_USER` | SMTP username | Required |
| `EMAIL_PASS` | SMTP password | Required |

## 📱 iOS Integration

The iOS app is configured to use this backend by default. Update the backend URL in `AuthenticationManager.swift`:

```swift
private let baseURL = "https://your-backend-domain.com"
```

## 🆘 Troubleshooting

### Common Issues

1. **Database locked**: Ensure only one instance is running
2. **Email not sending**: Check SMTP credentials and firewall
3. **CORS errors**: Verify `ALLOWED_ORIGINS` configuration
4. **Token expiry**: Check JWT secret and expiry settings

### Logs

```bash
# View logs in development
npm run dev

# View PM2 logs in production
pm2 logs syncn-backend
```

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📞 Support

For support, email support@syncnapp.com or create an issue on GitHub.
