use axum::{extract::State, Json};
use serde_json::{json, Value};
use sqlx::PgPool;

pub async fn health_check() -> Json<Value> {
    Json(json!({
        "status": "ok",
        "service": "RustCRM API",
        "version": "0.1.0"
    }))
}

pub async fn health_check_db(State(pool): State<PgPool>) -> Json<Value> {
    match sqlx::query("SELECT 1").fetch_one(&pool).await {
        Ok(_) => Json(json!({
            "status": "ok",
            "database": "connected",
            "service": "RustCRM API",
            "version": "0.1.0"
        })),
        Err(e) => {
            tracing::error!("Database health check failed: {:?}", e);
            Json(json!({
                "status": "error",
                "database": "disconnected",
                "error": e.to_string()
            }))
        }
    }
}
