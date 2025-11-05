use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use backend::{create_pool, run_migrations, Settings};
use serde_json::{json, Value};
use sqlx::PgPool;
use tower::util::ServiceExt;

/// Helper function to create test database pool
async fn setup_test_db() -> PgPool {
    dotenvy::dotenv().ok();

    let settings = Settings::new().expect("Failed to load settings");
    let pool = create_pool(&settings.database_url)
        .await
        .expect("Failed to create pool");

    run_migrations(&pool)
        .await
        .expect("Failed to run migrations");

    pool
}

/// Helper function to clean up test data
async fn cleanup_test_user(pool: &PgPool, email: &str) {
    sqlx::query("DELETE FROM users WHERE email = $1")
        .bind(email)
        .execute(pool)
        .await
        .ok();
}

/// Helper function to create router
fn create_test_router(pool: PgPool) -> axum::Router {
    let settings = Settings::new().expect("Failed to load settings");
    backend::routes::create_router(pool, settings.jwt_secret)
}

/// Helper to parse JSON response
async fn response_json(response: axum::response::Response) -> Value {
    let body = axum::body::to_bytes(response.into_body(), usize::MAX)
        .await
        .expect("Failed to read response body");
    serde_json::from_slice(&body).expect("Failed to parse JSON")
}

#[tokio::test]
async fn test_register_success() {
    let pool = setup_test_db().await;
    let test_email = "test_register@example.com";

    // Cleanup any existing test data
    cleanup_test_user(&pool, test_email).await;

    let app = create_test_router(pool.clone());

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/register")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "email": test_email,
                "password": "SecurePass123!",
                "first_name": "Test",
                "last_name": "User"
            })
            .to_string(),
        ))
        .unwrap();

    let response = app.oneshot(request).await.unwrap();

    assert_eq!(response.status(), StatusCode::OK);

    let body = response_json(response).await;
    assert_eq!(body["email"], test_email);
    assert_eq!(body["first_name"], "Test");
    assert_eq!(body["last_name"], "User");
    assert_eq!(body["role"], "user");
    assert_eq!(body["is_active"], true);
    assert!(body.get("password_hash").is_none()); // Should not return password hash

    // Cleanup
    cleanup_test_user(&pool, test_email).await;
}

#[tokio::test]
async fn test_register_duplicate_email() {
    let pool = setup_test_db().await;
    let test_email = "test_duplicate@example.com";

    cleanup_test_user(&pool, test_email).await;

    let app = create_test_router(pool.clone());

    // First registration
    let request1 = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/register")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "email": test_email,
                "password": "SecurePass123!"
            })
            .to_string(),
        ))
        .unwrap();

    let response1 = app.clone().oneshot(request1).await.unwrap();
    assert_eq!(response1.status(), StatusCode::OK);

    // Second registration with same email
    let request2 = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/register")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "email": test_email,
                "password": "AnotherPass123!"
            })
            .to_string(),
        ))
        .unwrap();

    let response2 = app.oneshot(request2).await.unwrap();
    assert_eq!(response2.status(), StatusCode::BAD_REQUEST);

    let body = response_json(response2).await;
    assert_eq!(body["error"], "Email already exists");

    cleanup_test_user(&pool, test_email).await;
}

#[tokio::test]
async fn test_register_weak_password() {
    let pool = setup_test_db().await;
    let app = create_test_router(pool.clone());

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/register")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "email": "weak@example.com",
                "password": "weak"
            })
            .to_string(),
        ))
        .unwrap();

    let response = app.oneshot(request).await.unwrap();
    assert_eq!(response.status(), StatusCode::BAD_REQUEST);

    let body = response_json(response).await;
    assert!(body["error"].as_str().unwrap().contains("Password"));
}

#[tokio::test]
async fn test_register_invalid_email() {
    let pool = setup_test_db().await;
    let app = create_test_router(pool.clone());

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/register")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "email": "invalid-email",
                "password": "SecurePass123!"
            })
            .to_string(),
        ))
        .unwrap();

    let response = app.oneshot(request).await.unwrap();
    assert_eq!(response.status(), StatusCode::BAD_REQUEST);

    let body = response_json(response).await;
    assert_eq!(body["error"], "Invalid email format");
}

#[tokio::test]
async fn test_login_success() {
    let pool = setup_test_db().await;
    let test_email = "test_login@example.com";
    let test_password = "SecurePass123!";

    cleanup_test_user(&pool, test_email).await;

    let app = create_test_router(pool.clone());

    // Register user first
    let register_request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/register")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "email": test_email,
                "password": test_password
            })
            .to_string(),
        ))
        .unwrap();

    app.clone().oneshot(register_request).await.unwrap();

    // Login
    let login_request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/login")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "email": test_email,
                "password": test_password
            })
            .to_string(),
        ))
        .unwrap();

    let response = app.oneshot(login_request).await.unwrap();
    assert_eq!(response.status(), StatusCode::OK);

    let body = response_json(response).await;
    assert!(body["access_token"].is_string());
    assert!(body["refresh_token"].is_string());
    assert_eq!(body["token_type"], "Bearer");
    assert_eq!(body["expires_in"], 3600);
    assert_eq!(body["user"]["email"], test_email);

    cleanup_test_user(&pool, test_email).await;
}

#[tokio::test]
async fn test_login_invalid_credentials() {
    let pool = setup_test_db().await;
    let test_email = "test_invalid_login@example.com";

    cleanup_test_user(&pool, test_email).await;

    let app = create_test_router(pool.clone());

    // Register user
    let register_request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/register")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "email": test_email,
                "password": "CorrectPass123!"
            })
            .to_string(),
        ))
        .unwrap();

    app.clone().oneshot(register_request).await.unwrap();

    // Login with wrong password
    let login_request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/login")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "email": test_email,
                "password": "WrongPass123!"
            })
            .to_string(),
        ))
        .unwrap();

    let response = app.oneshot(login_request).await.unwrap();
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);

    let body = response_json(response).await;
    assert_eq!(body["error"], "Invalid credentials");

    cleanup_test_user(&pool, test_email).await;
}

#[tokio::test]
async fn test_login_nonexistent_user() {
    let pool = setup_test_db().await;
    let app = create_test_router(pool.clone());

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/login")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "email": "nonexistent@example.com",
                "password": "AnyPass123!"
            })
            .to_string(),
        ))
        .unwrap();

    let response = app.oneshot(request).await.unwrap();
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);

    let body = response_json(response).await;
    assert_eq!(body["error"], "Invalid credentials");
}

#[tokio::test]
async fn test_get_current_user_success() {
    let pool = setup_test_db().await;
    let test_email = "test_me@example.com";
    let test_password = "SecurePass123!";

    cleanup_test_user(&pool, test_email).await;

    let app = create_test_router(pool.clone());

    // Register and login
    let register_request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/register")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "email": test_email,
                "password": test_password,
                "first_name": "Current",
                "last_name": "User"
            })
            .to_string(),
        ))
        .unwrap();

    app.clone().oneshot(register_request).await.unwrap();

    let login_request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/login")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "email": test_email,
                "password": test_password
            })
            .to_string(),
        ))
        .unwrap();

    let login_response = app.clone().oneshot(login_request).await.unwrap();
    let login_body = response_json(login_response).await;
    let access_token = login_body["access_token"].as_str().unwrap();

    // Get current user
    let me_request = Request::builder()
        .method("GET")
        .uri("/api/v1/auth/me")
        .header("authorization", format!("Bearer {}", access_token))
        .body(Body::empty())
        .unwrap();

    let response = app.oneshot(me_request).await.unwrap();
    assert_eq!(response.status(), StatusCode::OK);

    let body = response_json(response).await;
    assert_eq!(body["email"], test_email);
    assert_eq!(body["first_name"], "Current");
    assert_eq!(body["last_name"], "User");

    cleanup_test_user(&pool, test_email).await;
}

#[tokio::test]
async fn test_get_current_user_missing_token() {
    let pool = setup_test_db().await;
    let app = create_test_router(pool.clone());

    let request = Request::builder()
        .method("GET")
        .uri("/api/v1/auth/me")
        .body(Body::empty())
        .unwrap();

    let response = app.oneshot(request).await.unwrap();
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn test_get_current_user_invalid_token() {
    let pool = setup_test_db().await;
    let app = create_test_router(pool.clone());

    let request = Request::builder()
        .method("GET")
        .uri("/api/v1/auth/me")
        .header("authorization", "Bearer invalid_token_here")
        .body(Body::empty())
        .unwrap();

    let response = app.oneshot(request).await.unwrap();
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn test_refresh_token_success() {
    let pool = setup_test_db().await;
    let test_email = "test_refresh@example.com";
    let test_password = "SecurePass123!";

    cleanup_test_user(&pool, test_email).await;

    let app = create_test_router(pool.clone());

    // Register and login
    let register_request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/register")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "email": test_email,
                "password": test_password
            })
            .to_string(),
        ))
        .unwrap();

    app.clone().oneshot(register_request).await.unwrap();

    let login_request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/login")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "email": test_email,
                "password": test_password
            })
            .to_string(),
        ))
        .unwrap();

    let login_response = app.clone().oneshot(login_request).await.unwrap();
    let login_body = response_json(login_response).await;
    let refresh_token = login_body["refresh_token"].as_str().unwrap();

    // Refresh token
    let refresh_request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/refresh")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "refresh_token": refresh_token
            })
            .to_string(),
        ))
        .unwrap();

    let response = app.oneshot(refresh_request).await.unwrap();
    assert_eq!(response.status(), StatusCode::OK);

    let body = response_json(response).await;
    assert!(body["access_token"].is_string());
    assert!(body["refresh_token"].is_string());
    // New tokens should be different from original
    assert_ne!(body["access_token"].as_str().unwrap(), login_body["access_token"].as_str().unwrap());

    cleanup_test_user(&pool, test_email).await;
}

#[tokio::test]
async fn test_refresh_token_invalid() {
    let pool = setup_test_db().await;
    let app = create_test_router(pool.clone());

    let request = Request::builder()
        .method("POST")
        .uri("/api/v1/auth/refresh")
        .header("content-type", "application/json")
        .body(Body::from(
            json!({
                "refresh_token": "invalid_refresh_token"
            })
            .to_string(),
        ))
        .unwrap();

    let response = app.oneshot(request).await.unwrap();
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}
