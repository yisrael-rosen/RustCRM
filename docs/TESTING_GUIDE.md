# 🧪 RustCRM - Complete Testing Guide

## 📋 Table of Contents

1. [Testing Philosophy](#testing-philosophy)
2. [Test Types](#test-types)
3. [Unit Testing](#unit-testing)
4. [Integration Testing](#integration-testing)
5. [E2E Testing](#e2e-testing)
6. [Load Testing](#load-testing)
7. [Test Organization](#test-organization)
8. [Testing Tools](#testing-tools)
9. [Coverage Requirements](#coverage-requirements)
10. [Best Practices](#best-practices)
11. [Example Test Suite](#example-test-suite)

---

## 🎯 Testing Philosophy

### Why We Test

1. **Confidence**: Tests give us confidence that our code works
2. **Documentation**: Tests document how the code should behave
3. **Refactoring**: Tests enable safe refactoring
4. **Bug Prevention**: Catch bugs before production
5. **Regression**: Prevent old bugs from returning

### Test-Driven Development (TDD)

We follow TDD where practical:

```
1. Write a failing test (RED)
2. Write minimal code to pass (GREEN)
3. Refactor while keeping tests green (REFACTOR)
```

### Test Pyramid

```
           ┌─────────────┐
           │  E2E Tests  │  10% - Full user workflows
           │  (Slow)     │
           └─────────────┘
          ┌───────────────┐
          │ Integration   │  30% - API & Database
          │  Tests        │
          └───────────────┘
        ┌─────────────────┐
        │   Unit Tests    │  60% - Business logic
        │   (Fast)        │
        └─────────────────┘
```

---

## 📝 Test Types

### 1. Unit Tests

**Purpose**: Test individual functions and methods in isolation

**Characteristics**:
- Fast execution (< 1ms each)
- No external dependencies
- Mock all I/O
- Test one thing at a time

**Location**: `src/` (same file as code or separate `tests` module)

**Example**:
```rust
// src/utils/validators.rs
pub fn validate_email(email: &str) -> bool {
    email.contains('@') && email.contains('.')
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_email_valid() {
        assert!(validate_email("user@example.com"));
    }

    #[test]
    fn test_validate_email_invalid_no_at() {
        assert!(!validate_email("userexample.com"));
    }

    #[test]
    fn test_validate_email_invalid_no_dot() {
        assert!(!validate_email("user@examplecom"));
    }

    #[test]
    fn test_validate_email_empty() {
        assert!(!validate_email(""));
    }
}
```

### 2. Integration Tests

**Purpose**: Test how components work together

**Characteristics**:
- Slower execution (10-100ms each)
- Use real database (test DB)
- Test complete request/response cycle
- Test error scenarios

**Location**: `tests/integration/`

**Example**:
```rust
// tests/integration/auth_test.rs
use backend::*;
use sqlx::PgPool;

#[sqlx::test]
async fn test_user_registration(pool: PgPool) -> sqlx::Result<()> {
    // Setup
    let app = create_test_app(pool).await;

    // Execute
    let response = app
        .post("/api/v1/auth/register")
        .json(&serde_json::json!({
            "email": "test@example.com",
            "password": "SecurePass123!",
            "first_name": "Test",
            "last_name": "User"
        }))
        .await;

    // Assert
    assert_eq!(response.status(), 201);

    let body: serde_json::Value = response.json().await;
    assert!(body["id"].is_string());
    assert_eq!(body["email"], "test@example.com");
    assert_eq!(body["first_name"], "Test");

    Ok(())
}
```

### 3. End-to-End (E2E) Tests

**Purpose**: Test complete user workflows

**Characteristics**:
- Slowest execution (1-10s each)
- Full system integration
- Browser automation (frontend)
- Test critical paths only

**Location**: `tests/e2e/`

### 4. Load Tests

**Purpose**: Test system performance under load

**Characteristics**:
- Test with realistic traffic
- Measure response times
- Find bottlenecks
- Ensure scalability

**Tools**: Apache Bench, k6, Gatling

---

## 🔬 Unit Testing

### What to Unit Test

✅ **DO Test**:
- Business logic
- Calculations
- Validators
- Formatters
- Parsers
- Utilities
- Pure functions

❌ **DON'T Test**:
- Framework code
- External libraries
- Simple getters/setters
- Trivial code

### Unit Test Structure

```rust
#[cfg(test)]
mod tests {
    use super::*;

    // Test naming: test_<function>_<scenario>_<expected_result>
    #[test]
    fn test_calculate_discount_valid_percentage_returns_correct_amount() {
        // Arrange
        let price = 100.0;
        let discount_percent = 20.0;

        // Act
        let result = calculate_discount(price, discount_percent);

        // Assert
        assert_eq!(result, 20.0);
    }
}
```

### Testing Error Cases

```rust
#[test]
#[should_panic(expected = "Invalid percentage")]
fn test_calculate_discount_invalid_percentage_panics() {
    calculate_discount(100.0, 150.0);
}

#[test]
fn test_parse_date_invalid_format_returns_error() {
    let result = parse_date("invalid");
    assert!(result.is_err());
    assert_eq!(
        result.unwrap_err().to_string(),
        "Invalid date format"
    );
}
```

### Testing with Mock Data

```rust
// src/services/email_service.rs

#[cfg(test)]
pub mod mock {
    pub struct MockEmailService {
        pub sent_emails: Vec<Email>,
    }

    impl MockEmailService {
        pub fn new() -> Self {
            Self {
                sent_emails: Vec::new(),
            }
        }
    }

    impl EmailService for MockEmailService {
        async fn send_email(&mut self, email: Email) -> Result<()> {
            self.sent_emails.push(email);
            Ok(())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use super::mock::MockEmailService;

    #[tokio::test]
    async fn test_send_welcome_email() {
        let mut email_service = MockEmailService::new();
        let user = User::new("test@example.com");

        send_welcome_email(&mut email_service, &user).await.unwrap();

        assert_eq!(email_service.sent_emails.len(), 1);
        assert_eq!(email_service.sent_emails[0].to, "test@example.com");
        assert!(email_service.sent_emails[0].subject.contains("Welcome"));
    }
}
```

### Example: Testing Password Hashing

```rust
// src/utils/password.rs

use argon2::{
    password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use rand_core::OsRng;

pub fn hash_password(password: &str) -> Result<String, argon2::password_hash::Error> {
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    let password_hash = argon2.hash_password(password.as_bytes(), &salt)?;
    Ok(password_hash.to_string())
}

pub fn verify_password(password: &str, hash: &str) -> Result<bool, argon2::password_hash::Error> {
    let parsed_hash = PasswordHash::new(hash)?;
    let argon2 = Argon2::default();
    Ok(argon2.verify_password(password.as_bytes(), &parsed_hash).is_ok())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hash_password_creates_valid_hash() {
        let password = "SecurePassword123!";
        let hash = hash_password(password).unwrap();

        // Hash should not be empty
        assert!(!hash.is_empty());

        // Hash should start with $argon2
        assert!(hash.starts_with("$argon2"));
    }

    #[test]
    fn test_hash_password_creates_different_hashes() {
        let password = "SecurePassword123!";
        let hash1 = hash_password(password).unwrap();
        let hash2 = hash_password(password).unwrap();

        // Same password should create different hashes (different salts)
        assert_ne!(hash1, hash2);
    }

    #[test]
    fn test_verify_password_correct_password() {
        let password = "SecurePassword123!";
        let hash = hash_password(password).unwrap();

        let result = verify_password(password, &hash).unwrap();
        assert!(result);
    }

    #[test]
    fn test_verify_password_incorrect_password() {
        let password = "SecurePassword123!";
        let hash = hash_password(password).unwrap();

        let result = verify_password("WrongPassword", &hash).unwrap();
        assert!(!result);
    }

    #[test]
    fn test_verify_password_empty_password() {
        let hash = hash_password("password").unwrap();
        let result = verify_password("", &hash).unwrap();
        assert!(!result);
    }

    #[test]
    fn test_verify_password_invalid_hash() {
        let result = verify_password("password", "invalid_hash");
        assert!(result.is_err());
    }
}
```

### Example: Testing JWT

```rust
// src/utils/jwt.rs

use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,  // User ID
    pub email: String,
    pub role: String,
    pub exp: usize,   // Expiration time
}

pub fn create_token(user_id: Uuid, email: &str, role: &str, secret: &str) -> Result<String, jsonwebtoken::errors::Error> {
    let expiration = chrono::Utc::now()
        .checked_add_signed(chrono::Duration::hours(24))
        .expect("valid timestamp")
        .timestamp() as usize;

    let claims = Claims {
        sub: user_id.to_string(),
        email: email.to_string(),
        role: role.to_string(),
        exp: expiration,
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_ref()),
    )
}

pub fn validate_token(token: &str, secret: &str) -> Result<Claims, jsonwebtoken::errors::Error> {
    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_ref()),
        &Validation::default(),
    )?;
    Ok(token_data.claims)
}

#[cfg(test)]
mod tests {
    use super::*;

    const TEST_SECRET: &str = "test_secret_key_12345";

    #[test]
    fn test_create_token_success() {
        let user_id = Uuid::new_v4();
        let email = "test@example.com";
        let role = "user";

        let token = create_token(user_id, email, role, TEST_SECRET).unwrap();

        assert!(!token.is_empty());
        assert!(token.contains('.'));  // JWT has 3 parts separated by dots
    }

    #[test]
    fn test_validate_token_success() {
        let user_id = Uuid::new_v4();
        let email = "test@example.com";
        let role = "admin";

        let token = create_token(user_id, email, role, TEST_SECRET).unwrap();
        let claims = validate_token(&token, TEST_SECRET).unwrap();

        assert_eq!(claims.sub, user_id.to_string());
        assert_eq!(claims.email, email);
        assert_eq!(claims.role, role);
    }

    #[test]
    fn test_validate_token_wrong_secret() {
        let user_id = Uuid::new_v4();
        let token = create_token(user_id, "test@example.com", "user", TEST_SECRET).unwrap();

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
}
```

---

## 🔗 Integration Testing

### Setup Test Database

```rust
// tests/common/mod.rs

use sqlx::{postgres::PgPoolOptions, PgPool};
use std::sync::Once;

static INIT: Once = Once::new();

pub async fn setup_test_db() -> PgPool {
    INIT.call_once(|| {
        dotenv::dotenv().ok();
    });

    let database_url = std::env::var("TEST_DATABASE_URL")
        .unwrap_or_else(|_| "postgresql://postgres:password@localhost:5432/rustcrm_test".to_string());

    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .expect("Failed to connect to test database");

    // Run migrations
    sqlx::migrate!("./migrations")
        .run(&pool)
        .await
        .expect("Failed to run migrations");

    pool
}

pub async fn cleanup_test_db(pool: &PgPool) {
    // Clean all tables
    sqlx::query("TRUNCATE TABLE users, companies, contacts, deals, tasks, activities, emails CASCADE")
        .execute(pool)
        .await
        .expect("Failed to cleanup database");
}
```

### Integration Test Example: User Registration

```rust
// tests/integration/auth_test.rs

mod common;

use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use serde_json::json;
use tower::ServiceExt;

#[tokio::test]
async fn test_register_user_success() {
    // Setup
    let pool = common::setup_test_db().await;
    let app = backend::routes::create_router(pool.clone());

    // Prepare request
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

    // Execute
    let response = app.oneshot(request).await.unwrap();

    // Assert
    assert_eq!(response.status(), StatusCode::CREATED);

    let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let body: serde_json::Value = serde_json::from_slice(&body).unwrap();

    assert!(body["id"].is_string());
    assert_eq!(body["email"], "newuser@example.com");
    assert_eq!(body["first_name"], "John");
    assert_eq!(body["last_name"], "Doe");
    assert!(body["password_hash"].is_null() || !body.as_object().unwrap().contains_key("password_hash"));

    // Cleanup
    common::cleanup_test_db(&pool).await;
}

#[tokio::test]
async fn test_register_user_duplicate_email() {
    let pool = common::setup_test_db().await;
    let app = backend::routes::create_router(pool.clone());

    // First registration
    let request_body = json!({
        "email": "duplicate@example.com",
        "password": "SecurePass123!",
    });

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/register")
        .header("content-type", "application/json")
        .body(Body::from(serde_json::to_string(&request_body).unwrap()))
        .unwrap();

    app.clone().oneshot(request).await.unwrap();

    // Second registration with same email
    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/register")
        .header("content-type", "application/json")
        .body(Body::from(serde_json::to_string(&request_body).unwrap()))
        .unwrap();

    let response = app.oneshot(request).await.unwrap();

    assert_eq!(response.status(), StatusCode::CONFLICT);

    let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let body: serde_json::Value = serde_json::from_slice(&body).unwrap();

    assert!(body["error"].as_str().unwrap().contains("already exists"));

    common::cleanup_test_db(&pool).await;
}

#[tokio::test]
async fn test_register_user_invalid_email() {
    let pool = common::setup_test_db().await;
    let app = backend::routes::create_router(pool.clone());

    let test_cases = vec![
        ("", "Email cannot be empty"),
        ("invalid", "Invalid email format"),
        ("@example.com", "Invalid email format"),
        ("user@", "Invalid email format"),
    ];

    for (email, expected_error) in test_cases {
        let request_body = json!({
            "email": email,
            "password": "SecurePass123!",
        });

        let request = Request::builder()
            .method("POST")
            .uri("/api/v1/auth/register")
            .header("content-type", "application/json")
            .body(Body::from(serde_json::to_string(&request_body).unwrap()))
            .unwrap();

        let response = app.clone().oneshot(request).await.unwrap();

        assert_eq!(response.status(), StatusCode::BAD_REQUEST);

        let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
        let body: serde_json::Value = serde_json::from_slice(&body).unwrap();

        assert!(
            body["error"].as_str().unwrap().contains(expected_error),
            "Expected error to contain '{}' for email '{}'",
            expected_error,
            email
        );
    }

    common::cleanup_test_db(&pool).await;
}

#[tokio::test]
async fn test_register_user_weak_password() {
    let pool = common::setup_test_db().await;
    let app = backend::routes::create_router(pool.clone());

    let weak_passwords = vec![
        ("123", "Password too short"),
        ("password", "Password too weak"),
        ("12345678", "Password must contain letters"),
    ];

    for (password, expected_error) in weak_passwords {
        let request_body = json!({
            "email": "test@example.com",
            "password": password,
        });

        let request = Request::builder()
            .method("POST")
            .uri("/api/v1/auth/register")
            .header("content-type", "application/json")
            .body(Body::from(serde_json::to_string(&request_body).unwrap()))
            .unwrap();

        let response = app.clone().oneshot(request).await.unwrap();

        assert_eq!(response.status(), StatusCode::BAD_REQUEST);
    }

    common::cleanup_test_db(&pool).await;
}
```

### Integration Test Example: Login Flow

```rust
#[tokio::test]
async fn test_login_success() {
    let pool = common::setup_test_db().await;
    let app = backend::routes::create_router(pool.clone());

    // First, register a user
    let register_body = json!({
        "email": "logintest@example.com",
        "password": "SecurePass123!",
    });

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/register")
        .header("content-type", "application/json")
        .body(Body::from(serde_json::to_string(&register_body).unwrap()))
        .unwrap();

    app.clone().oneshot(request).await.unwrap();

    // Now login
    let login_body = json!({
        "email": "logintest@example.com",
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
    assert_eq!(body["token_type"], "Bearer");

    common::cleanup_test_db(&pool).await;
}

#[tokio::test]
async fn test_login_wrong_password() {
    let pool = common::setup_test_db().await;
    let app = backend::routes::create_router(pool.clone());

    // Register user
    let register_body = json!({
        "email": "user@example.com",
        "password": "CorrectPass123!",
    });

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/register")
        .header("content-type", "application/json")
        .body(Body::from(serde_json::to_string(&register_body).unwrap()))
        .unwrap();

    app.clone().oneshot(request).await.unwrap();

    // Try to login with wrong password
    let login_body = json!({
        "email": "user@example.com",
        "password": "WrongPass123!",
    });

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/login")
        .header("content-type", "application/json")
        .body(Body::from(serde_json::to_string(&login_body).unwrap()))
        .unwrap();

    let response = app.oneshot(request).await.unwrap();

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);

    common::cleanup_test_db(&pool).await;
}

#[tokio::test]
async fn test_protected_endpoint_without_token() {
    let pool = common::setup_test_db().await;
    let app = backend::routes::create_router(pool.clone());

    let request = Request::builder()
        .method("GET")
        .uri("/api/v1/auth/me")
        .body(Body::empty())
        .unwrap();

    let response = app.oneshot(request).await.unwrap();

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);

    common::cleanup_test_db(&pool).await;
}

#[tokio::test]
async fn test_protected_endpoint_with_token() {
    let pool = common::setup_test_db().await;
    let app = backend::routes::create_router(pool.clone());

    // Register and login
    let register_body = json!({
        "email": "protected@example.com",
        "password": "SecurePass123!",
        "first_name": "Protected",
        "last_name": "User"
    });

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/register")
        .header("content-type", "application/json")
        .body(Body::from(serde_json::to_string(&register_body).unwrap()))
        .unwrap();

    app.clone().oneshot(request).await.unwrap();

    let login_body = json!({
        "email": "protected@example.com",
        "password": "SecurePass123!",
    });

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/login")
        .header("content-type", "application/json")
        .body(Body::from(serde_json::to_string(&login_body).unwrap()))
        .unwrap();

    let login_response = app.clone().oneshot(request).await.unwrap();
    let login_body = hyper::body::to_bytes(login_response.into_body()).await.unwrap();
    let login_body: serde_json::Value = serde_json::from_slice(&login_body).unwrap();
    let token = login_body["access_token"].as_str().unwrap();

    // Access protected endpoint
    let request = Request::builder()
        .method("GET")
        .uri("/api/v1/auth/me")
        .header("authorization", format!("Bearer {}", token))
        .body(Body::empty())
        .unwrap();

    let response = app.oneshot(request).await.unwrap();

    assert_eq!(response.status(), StatusCode::OK);

    let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let body: serde_json::Value = serde_json::from_slice(&body).unwrap();

    assert_eq!(body["email"], "protected@example.com");
    assert_eq!(body["first_name"], "Protected");

    common::cleanup_test_db(&pool).await;
}
```

### Testing CRUD Operations

```rust
// tests/integration/contacts_test.rs

#[tokio::test]
async fn test_create_contact() {
    let pool = common::setup_test_db().await;
    let (app, token) = common::setup_authenticated_app(pool.clone()).await;

    let contact_body = json!({
        "first_name": "John",
        "last_name": "Doe",
        "email": "john.doe@example.com",
        "phone": "+1234567890",
        "position": "CEO"
    });

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/contacts")
        .header("authorization", format!("Bearer {}", token))
        .header("content-type", "application/json")
        .body(Body::from(serde_json::to_string(&contact_body).unwrap()))
        .unwrap();

    let response = app.oneshot(request).await.unwrap();

    assert_eq!(response.status(), StatusCode::CREATED);

    let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let body: serde_json::Value = serde_json::from_slice(&body).unwrap();

    assert!(body["id"].is_string());
    assert_eq!(body["first_name"], "John");
    assert_eq!(body["last_name"], "Doe");
    assert_eq!(body["email"], "john.doe@example.com");

    common::cleanup_test_db(&pool).await;
}

#[tokio::test]
async fn test_list_contacts_with_pagination() {
    let pool = common::setup_test_db().await;
    let (app, token) = common::setup_authenticated_app(pool.clone()).await;

    // Create 25 contacts
    for i in 0..25 {
        let contact_body = json!({
            "first_name": format!("User{}", i),
            "last_name": "Test",
            "email": format!("user{}@example.com", i)
        });

        let request = Request::builder()
            .method("POST")
            .uri("/api/v1/contacts")
            .header("authorization", format!("Bearer {}", token))
            .header("content-type", "application/json")
            .body(Body::from(serde_json::to_string(&contact_body).unwrap()))
            .unwrap();

        app.clone().oneshot(request).await.unwrap();
    }

    // Test first page
    let request = Request::builder()
        .method("GET")
        .uri("/api/v1/contacts?page=0&per_page=10")
        .header("authorization", format!("Bearer {}", token))
        .body(Body::empty())
        .unwrap();

    let response = app.clone().oneshot(request).await.unwrap();
    assert_eq!(response.status(), StatusCode::OK);

    let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let body: serde_json::Value = serde_json::from_slice(&body).unwrap();

    assert_eq!(body["data"].as_array().unwrap().len(), 10);
    assert_eq!(body["total"], 25);
    assert_eq!(body["page"], 0);
    assert_eq!(body["per_page"], 10);

    // Test second page
    let request = Request::builder()
        .method("GET")
        .uri("/api/v1/contacts?page=1&per_page=10")
        .header("authorization", format!("Bearer {}", token))
        .body(Body::empty())
        .unwrap();

    let response = app.oneshot(request).await.unwrap();
    let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let body: serde_json::Value = serde_json::from_slice(&body).unwrap();

    assert_eq!(body["data"].as_array().unwrap().len(), 10);

    common::cleanup_test_db(&pool).await;
}

#[tokio::test]
async fn test_update_contact() {
    let pool = common::setup_test_db().await;
    let (app, token) = common::setup_authenticated_app(pool.clone()).await;

    // Create contact
    let contact_body = json!({
        "first_name": "John",
        "last_name": "Doe",
        "email": "john@example.com"
    });

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/contacts")
        .header("authorization", format!("Bearer {}", token))
        .header("content-type", "application/json")
        .body(Body::from(serde_json::to_string(&contact_body).unwrap()))
        .unwrap();

    let create_response = app.clone().oneshot(request).await.unwrap();
    let create_body = hyper::body::to_bytes(create_response.into_body()).await.unwrap();
    let create_body: serde_json::Value = serde_json::from_slice(&create_body).unwrap();
    let contact_id = create_body["id"].as_str().unwrap();

    // Update contact
    let update_body = json!({
        "first_name": "Jane",
        "phone": "+1234567890"
    });

    let request = Request::builder()
        .method("PUT")
        .uri(format!("/api/v1/contacts/{}", contact_id))
        .header("authorization", format!("Bearer {}", token))
        .header("content-type", "application/json")
        .body(Body::from(serde_json::to_string(&update_body).unwrap()))
        .unwrap();

    let response = app.oneshot(request).await.unwrap();

    assert_eq!(response.status(), StatusCode::OK);

    let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let body: serde_json::Value = serde_json::from_slice(&body).unwrap();

    assert_eq!(body["first_name"], "Jane");
    assert_eq!(body["last_name"], "Doe");  // Unchanged
    assert_eq!(body["phone"], "+1234567890");

    common::cleanup_test_db(&pool).await;
}

#[tokio::test]
async fn test_delete_contact() {
    let pool = common::setup_test_db().await;
    let (app, token) = common::setup_authenticated_app(pool.clone()).await;

    // Create contact
    let contact_body = json!({
        "first_name": "Delete",
        "last_name": "Me",
        "email": "delete@example.com"
    });

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/contacts")
        .header("authorization", format!("Bearer {}", token))
        .header("content-type", "application/json")
        .body(Body::from(serde_json::to_string(&contact_body).unwrap()))
        .unwrap();

    let create_response = app.clone().oneshot(request).await.unwrap();
    let create_body = hyper::body::to_bytes(create_response.into_body()).await.unwrap();
    let create_body: serde_json::Value = serde_json::from_slice(&create_body).unwrap();
    let contact_id = create_body["id"].as_str().unwrap();

    // Delete contact
    let request = Request::builder()
        .method("DELETE")
        .uri(format!("/api/v1/contacts/{}", contact_id))
        .header("authorization", format!("Bearer {}", token))
        .body(Body::empty())
        .unwrap();

    let response = app.clone().oneshot(request).await.unwrap();

    assert_eq!(response.status(), StatusCode::NO_CONTENT);

    // Verify deletion
    let request = Request::builder()
        .method("GET")
        .uri(format!("/api/v1/contacts/{}", contact_id))
        .header("authorization", format!("Bearer {}", token))
        .body(Body::empty())
        .unwrap();

    let response = app.oneshot(request).await.unwrap();

    assert_eq!(response.status(), StatusCode::NOT_FOUND);

    common::cleanup_test_db(&pool).await;
}
```

---

## 🎭 Load Testing

### Using k6

Create `load_tests/script.js`:

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '30s', target: 20 },  // Ramp up to 20 users
    { duration: '1m', target: 20 },   // Stay at 20 users
    { duration: '30s', target: 50 },  // Ramp up to 50 users
    { duration: '1m', target: 50 },   // Stay at 50 users
    { duration: '30s', target: 0 },   // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
    http_req_failed: ['rate<0.01'],   // Error rate should be less than 1%
  },
};

const BASE_URL = 'http://localhost:8000';

export function setup() {
  // Register and login to get token
  const registerRes = http.post(`${BASE_URL}/api/v1/auth/register`, JSON.stringify({
    email: `loadtest${Date.now()}@example.com`,
    password: 'LoadTest123!',
  }), {
    headers: { 'Content-Type': 'application/json' },
  });

  const loginRes = http.post(`${BASE_URL}/api/v1/auth/login`, JSON.stringify({
    email: registerRes.json().email,
    password: 'LoadTest123!',
  }), {
    headers: { 'Content-Type': 'application/json' },
  });

  return { token: loginRes.json().access_token };
}

export default function (data) {
  const params = {
    headers: {
      'Authorization': `Bearer ${data.token}`,
      'Content-Type': 'application/json',
    },
  };

  // Test 1: List contacts
  let res = http.get(`${BASE_URL}/api/v1/contacts`, params);
  check(res, {
    'list contacts status is 200': (r) => r.status === 200,
    'list contacts response time < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(1);

  // Test 2: Create contact
  res = http.post(`${BASE_URL}/api/v1/contacts`, JSON.stringify({
    first_name: 'Load',
    last_name: 'Test',
    email: `loadtest${__VU}@example.com`,
  }), params);

  check(res, {
    'create contact status is 201': (r) => r.status === 201,
    'create contact response time < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(1);
}

export function teardown(data) {
  // Cleanup if needed
}
```

Run with:
```bash
k6 run load_tests/script.js
```

---

## 📊 Coverage Requirements

### Target Coverage by Module

| Module | Target Coverage | Priority |
|--------|----------------|----------|
| Business Logic (Services) | 90%+ | 🔴 Critical |
| API Handlers | 85%+ | 🔴 Critical |
| Repositories | 75%+ | 🟡 Important |
| Utilities | 90%+ | 🟡 Important |
| Middleware | 80%+ | 🟡 Important |
| Models | 70%+ | 🟢 Nice to have |

### Measuring Coverage

```bash
# Install tarpaulin
cargo install cargo-tarpaulin

# Run with coverage
cargo tarpaulin --out Html --output-dir coverage

# View report
open coverage/index.html
```

---

## ✅ Best Practices

### 1. Test Naming

**Pattern**: `test_<function>_<scenario>_<expected_result>`

```rust
✅ GOOD:
test_create_user_valid_data_returns_created_user()
test_create_user_duplicate_email_returns_error()
test_create_user_invalid_email_returns_validation_error()

❌ BAD:
test_user()
test_create()
test_error()
```

### 2. AAA Pattern

Always structure tests as:
- **Arrange**: Set up test data
- **Act**: Execute the code being tested
- **Assert**: Verify the results

```rust
#[test]
fn test_example() {
    // Arrange
    let input = "test data";
    let expected = "expected result";

    // Act
    let result = function_under_test(input);

    // Assert
    assert_eq!(result, expected);
}
```

### 3. One Assertion Per Test

Each test should verify one thing:

```rust
❌ BAD:
#[test]
fn test_user_creation() {
    let user = create_user("test@example.com", "password");
    assert!(user.id.is_some());
    assert_eq!(user.email, "test@example.com");
    assert!(user.is_active);
    assert!(user.created_at.is_some());
}

✅ GOOD:
#[test]
fn test_user_creation_assigns_id() {
    let user = create_user("test@example.com", "password");
    assert!(user.id.is_some());
}

#[test]
fn test_user_creation_sets_email() {
    let user = create_user("test@example.com", "password");
    assert_eq!(user.email, "test@example.com");
}

#[test]
fn test_user_creation_sets_active_flag() {
    let user = create_user("test@example.com", "password");
    assert!(user.is_active);
}
```

### 4. Test Independence

Tests should not depend on each other:

```rust
❌ BAD:
static mut COUNTER: i32 = 0;

#[test]
fn test_1() {
    unsafe { COUNTER += 1; }
}

#[test]
fn test_2() {
    unsafe { assert_eq!(COUNTER, 1); }  // Depends on test_1!
}

✅ GOOD:
#[test]
fn test_1() {
    let mut counter = 0;
    counter += 1;
    assert_eq!(counter, 1);
}

#[test]
fn test_2() {
    let counter = 1;
    assert_eq!(counter, 1);
}
```

### 5. Use Test Fixtures

```rust
// Test helper functions
fn create_test_user() -> User {
    User {
        id: Uuid::new_v4(),
        email: "test@example.com".to_string(),
        first_name: Some("Test".to_string()),
        last_name: Some("User".to_string()),
        role: UserRole::User,
        is_active: true,
        created_at: Utc::now(),
    }
}

#[test]
fn test_with_fixture() {
    let user = create_test_user();
    // Test with user
}
```

---

## 🔧 Test Organization

### Directory Structure

```
backend/
├── src/
│   ├── handlers/
│   │   └── auth.rs         # Unit tests at bottom
│   └── services/
│       └── user_service.rs # Unit tests at bottom
└── tests/
    ├── common/
    │   └── mod.rs          # Shared test utilities
    ├── integration/
    │   ├── auth_test.rs
    │   ├── contacts_test.rs
    │   └── deals_test.rs
    └── e2e/
        └── user_flow_test.rs
```

### Running Tests

```bash
# Run all tests
cargo test

# Run only unit tests
cargo test --lib

# Run only integration tests
cargo test --test '*'

# Run specific test
cargo test test_login_success

# Run tests with output
cargo test -- --nocapture

# Run tests in parallel (default)
cargo test

# Run tests serially
cargo test -- --test-threads=1
```

---

## 📝 Checklist: Testing New Feature

Before marking a feature as complete:

- [ ] Write unit tests for all business logic
- [ ] Write integration tests for all API endpoints
- [ ] Test happy path
- [ ] Test error cases
- [ ] Test edge cases (empty, null, max values)
- [ ] Test authentication/authorization
- [ ] Test validation rules
- [ ] Test database constraints
- [ ] Achieve target coverage (80%+)
- [ ] All tests pass
- [ ] No flaky tests
- [ ] Performance acceptable

---

**Remember**: Good tests are an investment. They give you confidence, enable refactoring, and serve as documentation. Write tests for the code you want to maintain!
