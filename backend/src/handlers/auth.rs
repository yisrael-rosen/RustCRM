use axum::{extract::State, http::HeaderMap, Json};
use std::sync::Arc;
use uuid::Uuid;

use crate::models::{AuthResponse, LoginRequest, RegisterRequest, UserResponse};
use crate::services::AuthService;
use crate::utils::{extract_token_from_header, validate_token, ApiError, TokenType};

/// Application state containing services
#[derive(Clone)]
pub struct AppState {
    pub auth_service: AuthService,
    pub jwt_secret: String,
}

/// Register a new user
/// POST /api/v1/auth/register
pub async fn register_handler(
    State(state): State<Arc<AppState>>,
    Json(request): Json<RegisterRequest>,
) -> Result<Json<UserResponse>, ApiError> {
    let user = state.auth_service.register(request).await?;
    Ok(Json(UserResponse::from(user)))
}

/// Login user and return JWT tokens
/// POST /api/v1/auth/login
pub async fn login_handler(
    State(state): State<Arc<AppState>>,
    Json(request): Json<LoginRequest>,
) -> Result<Json<AuthResponse>, ApiError> {
    let auth_response = state.auth_service.login(request).await?;
    Ok(Json(auth_response))
}

/// Get current user information (protected endpoint)
/// GET /api/v1/auth/me
/// Requires: Authorization: Bearer <token>
pub async fn get_current_user_handler(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
) -> Result<Json<UserResponse>, ApiError> {
    // Extract Authorization header
    let auth_header = headers
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .ok_or_else(|| ApiError::Unauthorized("Missing authorization header".to_string()))?;

    // Extract token from Authorization header
    let token = extract_token_from_header(auth_header)?;

    // Validate token and extract claims
    let claims = validate_token(&token, &state.jwt_secret)?;

    // Parse user ID from claims
    let user_id = Uuid::parse_str(&claims.sub)
        .map_err(|_| ApiError::Unauthorized("Invalid token".to_string()))?;

    // Get user from database
    let user = state.auth_service.get_user(user_id).await?;

    Ok(Json(UserResponse::from(user)))
}

/// Refresh access token using refresh token
/// POST /api/v1/auth/refresh
/// Body: { "refresh_token": "..." }
pub async fn refresh_token_handler(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<serde_json::Value>,
) -> Result<Json<AuthResponse>, ApiError> {
    // Extract refresh token from request body
    let refresh_token = payload
        .get("refresh_token")
        .and_then(|v| v.as_str())
        .ok_or_else(|| ApiError::BadRequest("Missing refresh_token".to_string()))?;

    // Validate refresh token
    let claims = validate_token(refresh_token, &state.jwt_secret)?;

    // Verify it's a refresh token
    if claims.token_type != TokenType::Refresh {
        return Err(ApiError::Unauthorized(
            "Invalid token type".to_string(),
        ));
    }

    // Parse user ID from claims
    let user_id = Uuid::parse_str(&claims.sub)
        .map_err(|_| ApiError::Unauthorized("Invalid token".to_string()))?;

    // Get user from database
    let user = state.auth_service.get_user(user_id).await?;

    // Check if user is still active
    if !user.is_active {
        return Err(ApiError::Unauthorized("Account is disabled".to_string()));
    }

    // Generate new tokens
    let access_token = crate::utils::create_access_token(
        user.id,
        &user.email,
        &user.role,
        &state.jwt_secret,
    )?;

    let new_refresh_token = crate::utils::create_refresh_token(
        user.id,
        &user.email,
        &user.role,
        &state.jwt_secret,
    )?;

    Ok(Json(AuthResponse {
        access_token,
        refresh_token: new_refresh_token,
        token_type: "Bearer".to_string(),
        expires_in: 3600, // 1 hour
        user: UserResponse::from(user),
    }))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::repositories::UserRepository;
    use sqlx::PgPool;

    // Helper function to create test app state
    #[allow(dead_code)]
    async fn create_test_state(pool: PgPool) -> Arc<AppState> {
        let user_repository = UserRepository::new(pool);
        let jwt_secret = "test-secret-key-for-testing-12345".to_string();
        let auth_service = AuthService::new(user_repository, jwt_secret.clone());

        Arc::new(AppState {
            auth_service,
            jwt_secret,
        })
    }

    // Note: Integration tests for handlers will be in tests/integration_tests.rs
    // These will test the full request/response cycle with a test database
}
