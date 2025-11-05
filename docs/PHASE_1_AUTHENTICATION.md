# 🔐 Phase 1: Authentication & Authorization

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Day-by-Day Plan](#day-by-day-plan)
4. [Implementation Guide](#implementation-guide)
5. [Testing Strategy](#testing-strategy)
6. [Security Considerations](#security-considerations)
7. [API Documentation](#api-documentation)

---

## 🎯 Overview

### Goals

Build a complete, secure authentication system with:

- ✅ User registration with email validation
- ✅ Password hashing with Argon2
- ✅ JWT-based authentication
- ✅ Token refresh mechanism
- ✅ Role-based access control (RBAC)
- ✅ Protected endpoints
- ✅ Comprehensive testing (90%+ coverage)

### Success Criteria

- [ ] All auth endpoints functional
- [ ] Passwords securely hashed (never stored in plain text)
- [ ] JWT tokens properly signed and validated
- [ ] Middleware protects routes correctly
- [ ] 90%+ test coverage
- [ ] API documentation complete
- [ ] No security vulnerabilities

---

## 🏗️ Architecture

### Authentication Flow

```
┌──────────┐
│  Client  │
└────┬─────┘
     │ POST /api/v1/auth/register
     │ {email, password}
     ▼
┌────────────────┐
│   Handler      │ ─── Validates input
└────┬───────────┘
     │
     ▼
┌────────────────┐
│   Service      │ ─── Hashes password
│                │ ─── Creates user
└────┬───────────┘
     │
     ▼
┌────────────────┐
│  Repository    │ ─── Saves to DB
└────┬───────────┘
     │
     ▼
┌────────────────┐
│   Response     │ ─── Returns user (no password)
└────────────────┘
```

### Login Flow

```
┌──────────┐
│  Client  │
└────┬─────┘
     │ POST /api/v1/auth/login
     │ {email, password}
     ▼
┌────────────────┐
│   Handler      │ ─── Validates input
└────┬───────────┘
     │
     ▼
┌────────────────┐
│   Service      │ ─── Finds user by email
│                │ ─── Verifies password
│                │ ─── Generates JWT tokens
└────┬───────────┘
     │
     ▼
┌────────────────┐
│   Response     │ ─── Returns tokens
│                │     {access_token, refresh_token}
└────────────────┘
```

### Protected Request Flow

```
┌──────────┐
│  Client  │
└────┬─────┘
     │ GET /api/v1/auth/me
     │ Authorization: Bearer <token>
     ▼
┌────────────────┐
│  Middleware    │ ─── Extracts token
│                │ ─── Validates token
│                │ ─── Decodes claims
└────┬───────────┘
     │ (adds user to request context)
     ▼
┌────────────────┐
│   Handler      │ ─── Gets user from context
│                │ ─── Returns user data
└────────────────┘
```

---

## 📅 Day-by-Day Plan

### Day 2: Core Authentication (6-8 hours)

**Morning (3-4 hours)**:
1. Create User model
2. Create password hashing utilities
3. Create JWT utilities
4. Write unit tests for utilities

**Afternoon (3-4 hours)**:
5. Implement user repository
6. Implement auth service
7. Create registration endpoint
8. Write integration tests

**Deliverables**:
- User model with tests
- Password hashing with tests
- JWT generation with tests
- Registration endpoint with tests

### Day 3: Authentication Middleware (4-6 hours)

**Morning (2-3 hours)**:
1. Create JWT validation middleware
2. Create role-based authorization middleware
3. Write middleware tests

**Afternoon (2-3 hours)**:
4. Implement login endpoint
5. Implement token refresh endpoint
6. Write integration tests
7. Update documentation

**Deliverables**:
- Auth middleware with tests
- Login endpoint with tests
- Token refresh with tests

### Day 4: User Management & Polish (4-6 hours)

**Morning (2-3 hours)**:
1. Implement "Get Current User" endpoint
2. Implement logout endpoint
3. Add password strength validation
4. Write comprehensive tests

**Afternoon (2-3 hours)**:
5. Performance testing
6. Security review
7. API documentation
8. Code review and refactoring

**Deliverables**:
- Complete auth system
- 90%+ test coverage
- API documentation
- Security review complete

---

## 💻 Implementation Guide

### Step 1: User Model

**File**: `backend/src/models/user.rs`

```rust
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct User {
    pub id: Uuid,
    pub email: String,
    #[serde(skip_serializing)]  // Never send password hash to client
    pub password_hash: String,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub role: UserRole,
    pub avatar_url: Option<String>,
    pub is_active: bool,
    pub last_login: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "text")]
pub enum UserRole {
    Admin,
    Manager,
    User,
}

impl std::fmt::Display for UserRole {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            UserRole::Admin => write!(f, "admin"),
            UserRole::Manager => write!(f, "manager"),
            UserRole::User => write!(f, "user"),
        }
    }
}

impl std::str::FromStr for UserRole {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "admin" => Ok(UserRole::Admin),
            "manager" => Ok(UserRole::Manager),
            "user" => Ok(UserRole::User),
            _ => Err(format!("Invalid role: {}", s)),
        }
    }
}

// Request DTOs
#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub email: String,
    pub password: String,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

// Response DTOs
#[derive(Debug, Serialize)]
pub struct UserResponse {
    pub id: Uuid,
    pub email: String,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub role: UserRole,
    pub avatar_url: Option<String>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
}

impl From<User> for UserResponse {
    fn from(user: User) -> Self {
        Self {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            role: user.role,
            avatar_url: user.avatar_url,
            is_active: user.is_active,
            created_at: user.created_at,
        }
    }
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub token_type: String,
    pub expires_in: usize,
    pub user: UserResponse,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_user_role_to_string() {
        assert_eq!(UserRole::Admin.to_string(), "admin");
        assert_eq!(UserRole::Manager.to_string(), "manager");
        assert_eq!(UserRole::User.to_string(), "user");
    }

    #[test]
    fn test_user_role_from_str() {
        assert!(matches!("admin".parse::<UserRole>(), Ok(UserRole::Admin)));
        assert!(matches!("manager".parse::<UserRole>(), Ok(UserRole::Manager)));
        assert!(matches!("user".parse::<UserRole>(), Ok(UserRole::User)));
        assert!(matches!("ADMIN".parse::<UserRole>(), Ok(UserRole::Admin)));
    }

    #[test]
    fn test_user_role_from_str_invalid() {
        assert!("invalid".parse::<UserRole>().is_err());
    }

    #[test]
    fn test_user_response_from_user() {
        let user = User {
            id: Uuid::new_v4(),
            email: "test@example.com".to_string(),
            password_hash: "hash".to_string(),
            first_name: Some("Test".to_string()),
            last_name: Some("User".to_string()),
            role: UserRole::User,
            avatar_url: None,
            is_active: true,
            last_login: None,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        let response = UserResponse::from(user.clone());

        assert_eq!(response.id, user.id);
        assert_eq!(response.email, user.email);
        assert_eq!(response.first_name, user.first_name);
    }

    #[test]
    fn test_user_serialization_excludes_password() {
        let user = User {
            id: Uuid::new_v4(),
            email: "test@example.com".to_string(),
            password_hash: "secret_hash".to_string(),
            first_name: None,
            last_name: None,
            role: UserRole::User,
            avatar_url: None,
            is_active: true,
            last_login: None,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        let json = serde_json::to_string(&user).unwrap();
        assert!(!json.contains("password_hash"));
        assert!(!json.contains("secret_hash"));
    }
}
```

**Update**: `backend/src/models/mod.rs`

```rust
pub mod user;

pub use user::{
    User, UserRole, UserResponse,
    RegisterRequest, LoginRequest, AuthResponse,
};
```

---

### Step 2: Password Hashing Utilities

**File**: `backend/src/utils/password.rs`

```rust
use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};

use crate::utils::ApiError;

/// Hash a password using Argon2
pub fn hash_password(password: &str) -> Result<String, ApiError> {
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();

    argon2
        .hash_password(password.as_bytes(), &salt)
        .map(|hash| hash.to_string())
        .map_err(|e| {
            tracing::error!("Failed to hash password: {:?}", e);
            ApiError::InternalServerError("Failed to hash password".to_string())
        })
}

/// Verify a password against a hash
pub fn verify_password(password: &str, hash: &str) -> Result<bool, ApiError> {
    let parsed_hash = PasswordHash::new(hash).map_err(|e| {
        tracing::error!("Failed to parse password hash: {:?}", e);
        ApiError::InternalServerError("Invalid password hash".to_string())
    })?;

    let argon2 = Argon2::default();

    Ok(argon2
        .verify_password(password.as_bytes(), &parsed_hash)
        .is_ok())
}

/// Validate password strength
pub fn validate_password_strength(password: &str) -> Result<(), ApiError> {
    if password.len() < 8 {
        return Err(ApiError::BadRequest(
            "Password must be at least 8 characters long".to_string(),
        ));
    }

    if password.len() > 128 {
        return Err(ApiError::BadRequest(
            "Password must be less than 128 characters".to_string(),
        ));
    }

    let has_uppercase = password.chars().any(|c| c.is_uppercase());
    let has_lowercase = password.chars().any(|c| c.is_lowercase());
    let has_digit = password.chars().any(|c| c.is_numeric());

    if !has_uppercase || !has_lowercase || !has_digit {
        return Err(ApiError::BadRequest(
            "Password must contain uppercase, lowercase, and numeric characters".to_string(),
        ));
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hash_password_success() {
        let password = "TestPassword123";
        let hash = hash_password(password).unwrap();

        assert!(!hash.is_empty());
        assert!(hash.starts_with("$argon2"));
    }

    #[test]
    fn test_hash_password_different_salts() {
        let password = "TestPassword123";
        let hash1 = hash_password(password).unwrap();
        let hash2 = hash_password(password).unwrap();

        // Same password should produce different hashes (different salts)
        assert_ne!(hash1, hash2);
    }

    #[test]
    fn test_verify_password_correct() {
        let password = "TestPassword123";
        let hash = hash_password(password).unwrap();

        let result = verify_password(password, &hash).unwrap();
        assert!(result);
    }

    #[test]
    fn test_verify_password_incorrect() {
        let password = "TestPassword123";
        let hash = hash_password(password).unwrap();

        let result = verify_password("WrongPassword123", &hash).unwrap();
        assert!(!result);
    }

    #[test]
    fn test_verify_password_invalid_hash() {
        let result = verify_password("password", "invalid_hash");
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_password_strength_valid() {
        assert!(validate_password_strength("ValidPass123").is_ok());
        assert!(validate_password_strength("AnotherGood1").is_ok());
    }

    #[test]
    fn test_validate_password_strength_too_short() {
        let result = validate_password_strength("Short1");
        assert!(result.is_err());
        assert!(result
            .unwrap_err()
            .to_string()
            .contains("at least 8 characters"));
    }

    #[test]
    fn test_validate_password_strength_too_long() {
        let password = "a".repeat(129) + "A1";
        let result = validate_password_strength(&password);
        assert!(result.is_err());
        assert!(result
            .unwrap_err()
            .to_string()
            .contains("less than 128 characters"));
    }

    #[test]
    fn test_validate_password_strength_no_uppercase() {
        let result = validate_password_strength("lowercase123");
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("uppercase"));
    }

    #[test]
    fn test_validate_password_strength_no_lowercase() {
        let result = validate_password_strength("UPPERCASE123");
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("lowercase"));
    }

    #[test]
    fn test_validate_password_strength_no_digit() {
        let result = validate_password_strength("NoDigitsHere");
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("numeric"));
    }
}
```

**Update**: `backend/src/utils/mod.rs`

```rust
pub mod errors;
pub mod password;

pub use errors::{ApiError, ApiResult};
pub use password::{hash_password, verify_password, validate_password_strength};
```

---

### Step 3: JWT Utilities

**File**: `backend/src/utils/jwt.rs`

```rust
use chrono::Utc;
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::models::UserRole;
use crate::utils::ApiError;

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,      // Subject (user ID)
    pub email: String,    // User email
    pub role: String,     // User role
    pub exp: usize,       // Expiration time
    pub iat: usize,       // Issued at
    pub token_type: TokenType,
}

#[derive(Debug, Serialize, Deserialize, PartialEq)]
pub enum TokenType {
    Access,
    Refresh,
}

const ACCESS_TOKEN_EXPIRATION: i64 = 60 * 60;        // 1 hour
const REFRESH_TOKEN_EXPIRATION: i64 = 60 * 60 * 24 * 7;  // 7 days

/// Create an access token
pub fn create_access_token(user_id: Uuid, email: &str, role: &UserRole, secret: &str) -> Result<String, ApiError> {
    create_token(user_id, email, role, secret, TokenType::Access, ACCESS_TOKEN_EXPIRATION)
}

/// Create a refresh token
pub fn create_refresh_token(user_id: Uuid, email: &str, role: &UserRole, secret: &str) -> Result<String, ApiError> {
    create_token(user_id, email, role, secret, TokenType::Refresh, REFRESH_TOKEN_EXPIRATION)
}

/// Create a JWT token
fn create_token(
    user_id: Uuid,
    email: &str,
    role: &UserRole,
    secret: &str,
    token_type: TokenType,
    expiration_seconds: i64,
) -> Result<String, ApiError> {
    let now = Utc::now();
    let iat = now.timestamp() as usize;
    let exp = (now.timestamp() + expiration_seconds) as usize;

    let claims = Claims {
        sub: user_id.to_string(),
        email: email.to_string(),
        role: role.to_string(),
        exp,
        iat,
        token_type,
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_ref()),
    )
    .map_err(|e| {
        tracing::error!("Failed to create token: {:?}", e);
        ApiError::InternalServerError("Failed to create token".to_string())
    })
}

/// Validate and decode a token
pub fn validate_token(token: &str, secret: &str) -> Result<Claims, ApiError> {
    decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_ref()),
        &Validation::default(),
    )
    .map(|data| data.claims)
    .map_err(|e| {
        tracing::debug!("Token validation failed: {:?}", e);
        ApiError::Unauthorized("Invalid or expired token".to_string())
    })
}

/// Extract token from Authorization header
pub fn extract_token_from_header(header: &str) -> Result<String, ApiError> {
    if !header.starts_with("Bearer ") {
        return Err(ApiError::Unauthorized(
            "Invalid authorization header format".to_string(),
        ));
    }

    Ok(header[7..].to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    const TEST_SECRET: &str = "test_secret_key_for_jwt_testing_12345";

    #[test]
    fn test_create_access_token() {
        let user_id = Uuid::new_v4();
        let email = "test@example.com";
        let role = UserRole::User;

        let token = create_access_token(user_id, email, &role, TEST_SECRET).unwrap();

        assert!(!token.is_empty());
        assert_eq!(token.matches('.').count(), 2); // JWT has 3 parts
    }

    #[test]
    fn test_create_refresh_token() {
        let user_id = Uuid::new_v4();
        let email = "test@example.com";
        let role = UserRole::User;

        let token = create_refresh_token(user_id, email, &role, TEST_SECRET).unwrap();

        assert!(!token.is_empty());
    }

    #[test]
    fn test_validate_token_success() {
        let user_id = Uuid::new_v4();
        let email = "test@example.com";
        let role = UserRole::Admin;

        let token = create_access_token(user_id, email, &role, TEST_SECRET).unwrap();
        let claims = validate_token(&token, TEST_SECRET).unwrap();

        assert_eq!(claims.sub, user_id.to_string());
        assert_eq!(claims.email, email);
        assert_eq!(claims.role, "admin");
        assert_eq!(claims.token_type, TokenType::Access);
    }

    #[test]
    fn test_validate_token_wrong_secret() {
        let user_id = Uuid::new_v4();
        let token = create_access_token(user_id, "test@example.com", &UserRole::User, TEST_SECRET).unwrap();

        let result = validate_token(&token, "wrong_secret");
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_token_invalid_format() {
        let result = validate_token("invalid.token.format", TEST_SECRET);
        assert!(result.is_err());
    }

    #[test]
    fn test_validate_token_empty() {
        let result = validate_token("", TEST_SECRET);
        assert!(result.is_err());
    }

    #[test]
    fn test_token_types_different() {
        let user_id = Uuid::new_v4();
        let access_token = create_access_token(user_id, "test@example.com", &UserRole::User, TEST_SECRET).unwrap();
        let refresh_token = create_refresh_token(user_id, "test@example.com", &UserRole::User, TEST_SECRET).unwrap();

        let access_claims = validate_token(&access_token, TEST_SECRET).unwrap();
        let refresh_claims = validate_token(&refresh_token, TEST_SECRET).unwrap();

        assert_eq!(access_claims.token_type, TokenType::Access);
        assert_eq!(refresh_claims.token_type, TokenType::Refresh);

        // Refresh token should have longer expiration
        assert!(refresh_claims.exp > access_claims.exp);
    }

    #[test]
    fn test_extract_token_from_header_success() {
        let header = "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.token";
        let token = extract_token_from_header(header).unwrap();

        assert_eq!(token, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.token");
    }

    #[test]
    fn test_extract_token_from_header_invalid_format() {
        let result = extract_token_from_header("InvalidHeader token");
        assert!(result.is_err());
    }

    #[test]
    fn test_extract_token_from_header_empty() {
        let result = extract_token_from_header("");
        assert!(result.is_err());
    }
}
```

**Update**: `backend/src/utils/mod.rs`

```rust
pub mod errors;
pub mod jwt;
pub mod password;

pub use errors::{ApiError, ApiResult};
pub use jwt::{create_access_token, create_refresh_token, validate_token, extract_token_from_header, Claims, TokenType};
pub use password::{hash_password, verify_password, validate_password_strength};
```

---

### Step 4: User Repository

**File**: `backend/src/repositories/user_repository.rs`

```rust
use sqlx::PgPool;
use uuid::Uuid;

use crate::models::{User, UserRole};
use crate::utils::ApiError;

pub struct UserRepository {
    pool: PgPool,
}

impl UserRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Create a new user
    pub async fn create(
        &self,
        email: &str,
        password_hash: &str,
        first_name: Option<&str>,
        last_name: Option<&str>,
    ) -> Result<User, ApiError> {
        let user = sqlx::query_as::<_, User>(
            r#"
            INSERT INTO users (email, password_hash, first_name, last_name, role)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING *
            "#,
        )
        .bind(email)
        .bind(password_hash)
        .bind(first_name)
        .bind(last_name)
        .bind(UserRole::User.to_string())
        .fetch_one(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Failed to create user: {:?}", e);
            if let sqlx::Error::Database(db_err) = &e {
                if db_err.is_unique_violation() {
                    return ApiError::BadRequest("Email already exists".to_string());
                }
            }
            ApiError::DatabaseError(e)
        })?;

        Ok(user)
    }

    /// Find user by email
    pub async fn find_by_email(&self, email: &str) -> Result<Option<User>, ApiError> {
        let user = sqlx::query_as::<_, User>(
            r#"
            SELECT * FROM users
            WHERE email = $1
            "#,
        )
        .bind(email)
        .fetch_optional(&self.pool)
        .await?;

        Ok(user)
    }

    /// Find user by ID
    pub async fn find_by_id(&self, id: Uuid) -> Result<Option<User>, ApiError> {
        let user = sqlx::query_as::<_, User>(
            r#"
            SELECT * FROM users
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(user)
    }

    /// Update last login time
    pub async fn update_last_login(&self, id: Uuid) -> Result<(), ApiError> {
        sqlx::query(
            r#"
            UPDATE users
            SET last_login = NOW()
            WHERE id = $1
            "#,
        )
        .bind(id)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// Check if email exists
    pub async fn email_exists(&self, email: &str) -> Result<bool, ApiError> {
        let exists = sqlx::query_scalar::<_, bool>(
            r#"
            SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)
            "#,
        )
        .bind(email)
        .fetch_one(&self.pool)
        .await?;

        Ok(exists)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::utils::hash_password;

    // Note: These tests require a test database
    // Run with: cargo test --features test-db

    async fn setup_test_db() -> PgPool {
        let database_url = std::env::var("TEST_DATABASE_URL")
            .unwrap_or_else(|_| "postgresql://postgres:password@localhost:5432/rustcrm_test".to_string());

        let pool = PgPool::connect(&database_url).await.unwrap();

        // Clean users table
        sqlx::query("TRUNCATE TABLE users CASCADE")
            .execute(&pool)
            .await
            .unwrap();

        pool
    }

    #[sqlx::test]
    async fn test_create_user() {
        let pool = setup_test_db().await;
        let repo = UserRepository::new(pool);

        let password_hash = hash_password("TestPassword123").unwrap();
        let user = repo
            .create("test@example.com", &password_hash, Some("Test"), Some("User"))
            .await
            .unwrap();

        assert_eq!(user.email, "test@example.com");
        assert_eq!(user.first_name, Some("Test".to_string()));
        assert_eq!(user.last_name, Some("User".to_string()));
        assert!(user.is_active);
    }

    #[sqlx::test]
    async fn test_create_user_duplicate_email() {
        let pool = setup_test_db().await;
        let repo = UserRepository::new(pool);

        let password_hash = hash_password("TestPassword123").unwrap();

        // Create first user
        repo.create("duplicate@example.com", &password_hash, None, None)
            .await
            .unwrap();

        // Try to create second user with same email
        let result = repo
            .create("duplicate@example.com", &password_hash, None, None)
            .await;

        assert!(result.is_err());
    }

    #[sqlx::test]
    async fn test_find_by_email() {
        let pool = setup_test_db().await;
        let repo = UserRepository::new(pool);

        let password_hash = hash_password("TestPassword123").unwrap();
        let created_user = repo
            .create("find@example.com", &password_hash, None, None)
            .await
            .unwrap();

        let found_user = repo
            .find_by_email("find@example.com")
            .await
            .unwrap()
            .unwrap();

        assert_eq!(found_user.id, created_user.id);
        assert_eq!(found_user.email, created_user.email);
    }

    #[sqlx::test]
    async fn test_find_by_email_not_found() {
        let pool = setup_test_db().await;
        let repo = UserRepository::new(pool);

        let result = repo.find_by_email("nonexistent@example.com").await.unwrap();

        assert!(result.is_none());
    }

    #[sqlx::test]
    async fn test_find_by_id() {
        let pool = setup_test_db().await;
        let repo = UserRepository::new(pool);

        let password_hash = hash_password("TestPassword123").unwrap();
        let created_user = repo
            .create("findbyid@example.com", &password_hash, None, None)
            .await
            .unwrap();

        let found_user = repo.find_by_id(created_user.id).await.unwrap().unwrap();

        assert_eq!(found_user.id, created_user.id);
        assert_eq!(found_user.email, created_user.email);
    }

    #[sqlx::test]
    async fn test_email_exists() {
        let pool = setup_test_db().await;
        let repo = UserRepository::new(pool);

        let password_hash = hash_password("TestPassword123").unwrap();
        repo.create("exists@example.com", &password_hash, None, None)
            .await
            .unwrap();

        assert!(repo.email_exists("exists@example.com").await.unwrap());
        assert!(!repo.email_exists("notexists@example.com").await.unwrap());
    }

    #[sqlx::test]
    async fn test_update_last_login() {
        let pool = setup_test_db().await;
        let repo = UserRepository::new(pool);

        let password_hash = hash_password("TestPassword123").unwrap();
        let user = repo
            .create("login@example.com", &password_hash, None, None)
            .await
            .unwrap();

        assert!(user.last_login.is_none());

        repo.update_last_login(user.id).await.unwrap();

        let updated_user = repo.find_by_id(user.id).await.unwrap().unwrap();
        assert!(updated_user.last_login.is_some());
    }
}
```

**Update**: `backend/src/repositories/mod.rs`

```rust
pub mod user_repository;

pub use user_repository::UserRepository;
```

---

## 🧪 Testing Strategy

### Unit Tests

1. **Password Utilities** (✅ Already in utils/password.rs)
   - Hash generation
   - Hash verification
   - Password strength validation

2. **JWT Utilities** (✅ Already in utils/jwt.rs)
   - Token creation
   - Token validation
   - Token expiration
   - Header extraction

3. **User Model** (✅ Already in models/user.rs)
   - Serialization
   - Role conversion
   - DTO conversion

### Integration Tests

Create `tests/integration/auth_test.rs`:

```rust
mod common;

use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use serde_json::json;
use tower::ServiceExt;

#[tokio::test]
async fn test_register_user_success() {
    let pool = common::setup_test_db().await;
    let app = backend::routes::create_router(pool.clone());

    let request_body = json!({
        "email": "newuser@example.com",
        "password": "SecurePass123!",
        "first_name": "John",
        "last_name": "Doe"
    });

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/register")
        .header("content-type", "application/json")
        .body(Body::from(serde_json::to_string(&request_body).unwrap()))
        .unwrap();

    let response = app.oneshot(request).await.unwrap();

    assert_eq!(response.status(), StatusCode::CREATED);

    common::cleanup_test_db(&pool).await;
}

#[tokio::test]
async fn test_login_flow() {
    let pool = common::setup_test_db().await;
    let app = backend::routes::create_router(pool.clone());

    // Register
    let register_body = json!({
        "email": "login@example.com",
        "password": "SecurePass123!",
    });

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/register")
        .header("content-type", "application/json")
        .body(Body::from(serde_json::to_string(&register_body).unwrap()))
        .unwrap();

    app.clone().oneshot(request).await.unwrap();

    // Login
    let login_body = json!({
        "email": "login@example.com",
        "password": "SecurePass123!",
    });

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/login")
        .header("content-type", "application/json")
        .body(Body::from(serde_json::to_string(&login_body).unwrap()))
        .unwrap();

    let response = app.oneshot(request).await.unwrap();

    assert_eq!(response.status(), StatusCode::OK);

    let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let body: serde_json::Value = serde_json::from_slice(&body).unwrap();

    assert!(body["access_token"].is_string());
    assert!(body["refresh_token"].is_string());

    common::cleanup_test_db(&pool).await;
}
```

### Coverage Target

- Password utilities: 95%+
- JWT utilities: 95%+
- User repository: 90%+
- Auth service: 90%+
- Auth handlers: 85%+
- **Overall auth module: 90%+**

---

## 🔒 Security Considerations

### 1. Password Security

✅ **DO**:
- Use Argon2 for hashing (memory-hard, GPU-resistant)
- Use random salts (automatic with Argon2)
- Enforce minimum password strength
- Never log passwords

❌ **DON'T**:
- Store passwords in plain text
- Use MD5 or SHA1
- Use weak hashing algorithms
- Echo passwords in logs or errors

### 2. JWT Security

✅ **DO**:
- Use strong secret keys (256+ bits)
- Set appropriate expiration times
- Validate tokens on every request
- Use HTTPS in production
- Include user context in claims

❌ **DON'T**:
- Store secrets in code
- Use weak secrets
- Set very long expiration times
- Trust token claims without validation

### 3. Rate Limiting

Implement rate limiting on auth endpoints:

```rust
// Future implementation
- /auth/register: 5 requests per hour per IP
- /auth/login: 10 requests per 15 minutes per IP
- /auth/refresh: 20 requests per hour per user
```

### 4. HTTPS Only

In production:
- Always use HTTPS
- Set secure cookie flags
- Implement HSTS headers

---

## 📝 API Documentation

### POST /api/v1/auth/register

**Description**: Register a new user

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "first_name": "John",  // optional
  "last_name": "Doe"      // optional
}
```

**Responses**:
```
201 Created
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "role": "user",
  "is_active": true,
  "created_at": "2024-01-01T00:00:00Z"
}

400 Bad Request
{
  "error": "Email already exists"
}

400 Bad Request
{
  "error": "Password must be at least 8 characters long"
}
```

### POST /api/v1/auth/login

**Description**: Login and receive JWT tokens

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Responses**:
```
200 OK
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "user"
  }
}

401 Unauthorized
{
  "error": "Invalid credentials"
}
```

### GET /api/v1/auth/me

**Description**: Get current user information

**Headers**:
```
Authorization: Bearer <access_token>
```

**Responses**:
```
200 OK
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "role": "user",
  "is_active": true
}

401 Unauthorized
{
  "error": "Invalid or expired token"
}
```

---

## ✅ Checklist

Before marking Phase 1 as complete:

- [ ] User model implemented and tested
- [ ] Password hashing with Argon2
- [ ] Password strength validation
- [ ] JWT token generation
- [ ] JWT token validation
- [ ] User repository with database operations
- [ ] Auth service with business logic
- [ ] Registration endpoint
- [ ] Login endpoint
- [ ] Get current user endpoint
- [ ] Token refresh endpoint
- [ ] Logout endpoint (optional)
- [ ] Authentication middleware
- [ ] Authorization middleware (role-based)
- [ ] 90%+ test coverage
- [ ] All integration tests passing
- [ ] API documentation complete
- [ ] Security review complete
- [ ] No hardcoded secrets

---

**Next**: Proceed to `PHASE_2_CONTACTS_COMPANIES.md` for implementing the core CRM features!
