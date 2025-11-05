use axum::{routing::get, Router};
use sqlx::PgPool;

use crate::handlers;

pub fn create_router(pool: PgPool) -> Router {
    Router::new()
        .route("/health", get(handlers::health_check))
        .route("/health/db", get(handlers::health_check_db))
        .with_state(pool)
}
