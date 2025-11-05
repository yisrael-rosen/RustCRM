# ⚡ RustCRM - Quick Start Guide

Get RustCRM up and running in 10 minutes!

---

## 🚀 Prerequisites

Make sure you have:
- **Rust** 1.75+ (`rustup` recommended)
- **Docker** & **Docker Compose**
- **Git**

Check versions:
```bash
rust --version  # Should be 1.75+
docker --version
docker-compose --version
```

---

## 📦 Quick Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourorg/RustCRM.git
cd RustCRM
```

### 2. Start Database Services

```bash
# Start PostgreSQL and Redis
docker-compose up -d

# Verify they're running
docker-compose ps
```

You should see:
```
NAME                  STATUS
rustcrm_postgres      Up
rustcrm_redis         Up
```

### 3. Configure Backend

```bash
cd backend

# Copy environment file
cp .env.example .env

# The default values work with Docker Compose!
# DATABASE_URL=postgresql://postgres:password@localhost:5432/rustcrm
# REDIS_URL=redis://localhost:6379
# JWT_SECRET=dev-secret-key-please-change-in-production-12345
# PORT=8000
```

### 4. Run Database Migrations

```bash
# Install sqlx-cli (first time only)
cargo install sqlx-cli --no-default-features --features postgres

# Run migrations
sqlx migrate run
```

You should see:
```
Applied migration: 20240101000001_create_users_table.sql
Applied migration: 20240101000002_create_companies_table.sql
Applied migration: 20240101000003_create_contacts_table.sql
...
```

### 5. Start the Backend

```bash
# Development mode (with auto-reload)
cargo watch -x run

# Or standard run
cargo run
```

Backend is now running at: `http://localhost:8000`

### 6. Test the API

Open a new terminal and test the health endpoint:

```bash
# Health check
curl http://localhost:8000/health

# Should return:
{
  "status": "ok",
  "service": "RustCRM API",
  "version": "0.1.0"
}

# Database health check
curl http://localhost:8000/health/db

# Should return:
{
  "status": "ok",
  "database": "connected",
  "service": "RustCRM API"
}
```

---

## 🎯 Your First API Calls

### Register a User

```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "SecurePass123!",
    "first_name": "Admin",
    "last_name": "User"
  }'
```

Response:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "admin@example.com",
  "first_name": "Admin",
  "last_name": "User",
  "role": "user",
  "is_active": true,
  "created_at": "2024-01-01T00:00:00Z"
}
```

### Login

```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "SecurePass123!"
  }'
```

Response:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "user": { ... }
}
```

Save the `access_token` for the next step!

### Get Current User

```bash
# Replace YOUR_TOKEN with the access_token from login
curl http://localhost:8000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 🧪 Running Tests

```bash
cd backend

# Run all tests
cargo test

# Run tests with output
cargo test -- --nocapture

# Run specific test
cargo test test_health_check

# Run tests with coverage
cargo tarpaulin --out Html
```

---

## 🛠️ Development Tools

### Useful Commands

```bash
# Check code without building
cargo check

# Format code
cargo fmt

# Lint code
cargo clippy

# Watch for changes and rebuild
cargo watch -x run

# Build for release
cargo build --release
```

### Database Tools

```bash
# Create a new migration
sqlx migrate add migration_name

# Revert last migration
sqlx migrate revert

# Check migration status
sqlx migrate info

# Access PostgreSQL directly
docker-compose exec postgres psql -U postgres -d rustcrm
```

### View Logs

```bash
# Backend logs (if running with cargo run)
# They'll appear in your terminal

# Database logs
docker-compose logs -f postgres

# Redis logs
docker-compose logs -f redis

# All logs
docker-compose logs -f
```

---

## 📚 Next Steps

Now that you're set up, explore:

1. **📖 Read the Documentation**
   - `docs/MASTER_PLAN.md` - Complete roadmap
   - `docs/PHASE_1_AUTHENTICATION.md` - Implement auth (Day 2)
   - `docs/TESTING_GUIDE.md` - Learn testing patterns
   - `docs/API_DEVELOPMENT_GUIDE.md` - API best practices

2. **🔨 Start Building**
   - Follow Phase 1: Authentication (Days 2-4)
   - Implement user registration and login
   - Add JWT middleware
   - Write comprehensive tests

3. **🧪 Explore Testing**
   - Run existing tests
   - Write your first test
   - Achieve 80%+ coverage

4. **🚀 Deploy**
   - See `docs/DEPLOYMENT_GUIDE.md`
   - Deploy to your own server
   - Configure SSL and monitoring

---

## 🆘 Troubleshooting

### Database Connection Errors

If you see `connection refused`:

```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# If not running, start it
docker-compose up -d postgres

# Check logs
docker-compose logs postgres
```

### Port Already in Use

If port 8000 is taken:

```bash
# Change port in backend/.env
PORT=8080

# Or kill the process using port 8000
lsof -ti:8000 | xargs kill
```

### Migration Errors

If migrations fail:

```bash
# Check migration status
sqlx migrate info

# Reset database (⚠️ DELETES ALL DATA)
docker-compose down -v
docker-compose up -d
sqlx migrate run
```

### Cargo Build Errors

If you see compilation errors:

```bash
# Update Rust
rustup update

# Clean and rebuild
cargo clean
cargo build
```

---

## 📝 Useful Resources

- **Documentation**: `/docs` folder
- **API Endpoints**: See `PHASE_1_AUTHENTICATION.md`
- **Database Schema**: See migrations in `backend/migrations/`
- **Tests**: See `backend/tests/`

---

## 🎓 Learning Path

**Week 1** - Backend Foundation
- ✅ Day 1: Setup (you just did this!)
- Day 2: Authentication system
- Day 3: Auth middleware & testing
- Day 4: User management

**Week 2** - Core Features
- Days 5-6: Contacts management
- Days 7-8: Companies management
- Days 9-10: Deals pipeline
- Days 11-12: Tasks & activities

**Week 3** - Advanced Features
- Days 13-14: Email integration
- Days 15-16: AI features (Claude)
- Day 17: Real-time (WebSocket)
- Days 18-20: Analytics & reporting

**Week 4** - Frontend & Polish
- Days 21-28: React frontend
- Day 29: Testing & optimization
- Day 30: Deployment & documentation

---

## 💡 Quick Tips

1. **Use `cargo watch`** for auto-reload during development
2. **Check logs** when things don't work as expected
3. **Write tests** as you build features
4. **Read error messages** carefully - Rust errors are helpful!
5. **Use the docs** - everything is documented in `/docs`

---

## ✅ Quick Check

You're ready if you can:
- ✅ Start the backend server
- ✅ Access health endpoints
- ✅ Register a user
- ✅ Login and get a token
- ✅ Access protected endpoints with token
- ✅ Run tests successfully

---

**🎉 Congratulations! You're all set to build RustCRM!**

**Next**: Read `docs/PHASE_1_AUTHENTICATION.md` to start implementing the authentication system.

**Questions?** Check the main `README.md` or specific documentation in `/docs`.

Happy coding! 🦀
