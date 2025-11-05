# 🦀 RustCRM - Modern CRM Built with Rust

A modern, scalable Customer Relationship Management (CRM) system built with Rust, featuring advanced AI capabilities powered by Claude.

## 🚀 Features

- **Contact Management** - Organize and track all your customer interactions
- **Company Management** - Manage company information and relationships
- **Deal Pipeline** - Visual sales pipeline with drag-and-drop
- **Task Management** - Never miss a follow-up with integrated task tracking
- **Email Integration** - Send and track emails directly from the CRM
- **AI-Powered Insights** - Leverage Claude AI for sentiment analysis, deal predictions, and smart suggestions
- **Real-time Updates** - WebSocket-based live notifications
- **Analytics Dashboard** - Comprehensive sales and performance metrics

## 🛠️ Tech Stack

### Backend
- **Rust** - Fast, reliable, and memory-safe
- **Axum** - Modern web framework
- **SQLx** - Async SQL toolkit
- **PostgreSQL** - Robust relational database
- **Redis** - High-performance caching
- **JWT** - Secure authentication

### Frontend (Coming Soon)
- **React** + **TypeScript**
- **Vite** - Lightning-fast build tool
- **Tailwind CSS** + **shadcn/ui**
- **TanStack Query** - Powerful data synchronization

## 📦 Prerequisites

- Rust 1.75 or higher
- Docker and Docker Compose
- PostgreSQL 15+ (or use Docker)
- Redis 7+ (or use Docker)

## 🚀 Quick Start

### 1. Clone the repository

```bash
git clone <repository-url>
cd RustCRM
```

### 2. Start the database services

```bash
docker-compose up -d
```

This will start:
- PostgreSQL on port 5432
- Redis on port 6379

### 3. Setup environment variables

```bash
cd backend
cp .env.example .env
```

Edit `.env` with your configuration (default values should work with Docker Compose).

### 4. Run database migrations

```bash
# Install sqlx-cli if you haven't already
cargo install sqlx-cli --no-default-features --features postgres

# Run migrations
sqlx migrate run
```

### 5. Start the backend server

```bash
cargo run
```

The server will start on `http://localhost:8000`

### 6. Test the API

```bash
# Health check
curl http://localhost:8000/health

# Database health check
curl http://localhost:8000/health/db
```

## 📚 API Documentation

### Health Endpoints

- `GET /health` - Basic health check
- `GET /health/db` - Database connectivity check

### Authentication (Coming Soon)

- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/refresh` - Refresh token
- `GET /api/v1/auth/me` - Get current user

### Contacts (Coming Soon)

- `GET /api/v1/contacts` - List contacts
- `POST /api/v1/contacts` - Create contact
- `GET /api/v1/contacts/:id` - Get contact
- `PUT /api/v1/contacts/:id` - Update contact
- `DELETE /api/v1/contacts/:id` - Delete contact

## 🗄️ Database Schema

The database includes the following core tables:

- **users** - System users and authentication
- **companies** - Company/organization records
- **contacts** - Individual contact records
- **deals** - Sales opportunities
- **tasks** - Task management
- **activities** - Activity logging
- **emails** - Email tracking

## 🧪 Testing

```bash
# Run all tests
cargo test

# Run tests with output
cargo test -- --nocapture

# Run specific test
cargo test test_name
```

## 📝 Development Roadmap

### Phase 1: Foundation ✅
- [x] Project setup
- [x] Database configuration
- [x] Error handling
- [x] Health check endpoints
- [x] Logging setup

### Phase 2: Authentication (In Progress)
- [ ] User registration
- [ ] Login/logout
- [ ] JWT middleware
- [ ] Password hashing

### Phase 3: Core CRM Features
- [ ] Contact management
- [ ] Company management
- [ ] Deal pipeline
- [ ] Task management

### Phase 4: Advanced Features
- [ ] Email integration
- [ ] AI-powered features
- [ ] Real-time notifications
- [ ] Analytics dashboard

### Phase 5: Frontend
- [ ] React application
- [ ] Component library
- [ ] State management
- [ ] API integration

## 🔧 Useful Commands

```bash
# Format code
cargo fmt

# Lint code
cargo clippy

# Check for errors without building
cargo check

# Build for production
cargo build --release

# Watch for changes and rebuild
cargo watch -x run

# Stop Docker services
docker-compose down

# View Docker logs
docker-compose logs -f postgres
```

## 📖 Project Structure

```
RustCRM/
├── backend/
│   ├── src/
│   │   ├── config/         # Configuration and settings
│   │   ├── handlers/       # Request handlers
│   │   ├── models/         # Data models
│   │   ├── routes/         # Route definitions
│   │   ├── services/       # Business logic
│   │   ├── repositories/   # Database layer
│   │   ├── middleware/     # Custom middleware
│   │   └── utils/          # Utilities and helpers
│   ├── migrations/         # Database migrations
│   └── tests/              # Test files
├── docker-compose.yml      # Docker services
└── README.md
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Built with [Rust](https://www.rust-lang.org/)
- Web framework: [Axum](https://github.com/tokio-rs/axum)
- Database: [PostgreSQL](https://www.postgresql.org/)
- AI powered by [Anthropic Claude](https://www.anthropic.com/)

---

**Status:** 🚧 In Active Development

Current Phase: Day 1 - Backend Foundation ✅
