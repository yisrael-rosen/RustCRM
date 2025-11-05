use axum::{routing::{get, post}, Router};
use sqlx::PgPool;
use std::sync::Arc;

use crate::handlers::{self, AppState};
use crate::repositories::UserRepository;
use crate::services::AuthService;

pub fn create_router(pool: PgPool, jwt_secret: String) -> Router {
    // Create repositories
    let user_repository = UserRepository::new(pool.clone());

    // Create services
    let auth_service = AuthService::new(user_repository, jwt_secret.clone());

    // Create application state
    let app_state = Arc::new(AppState {
        auth_service,
        jwt_secret,
    });

    // Health check routes (no auth required)
    let health_routes = Router::new()
        .route("/health", get(handlers::health_check))
        .route("/health/db", get(handlers::health_check_db))
        .with_state(pool);

    // Auth routes (public endpoints)
    let auth_routes = Router::new()
        .route("/api/v1/auth/register", post(handlers::register_handler))
        .route("/api/v1/auth/login", post(handlers::login_handler))
        .route("/api/v1/auth/refresh", post(handlers::refresh_token_handler))
        .route("/api/v1/auth/me", get(handlers::get_current_user_handler))
        .with_state(app_state);

    // Combine all routes
    Router::new()
        .merge(health_routes)
        .merge(auth_routes)
}
