use axum::{
    extract::Request,
    http::StatusCode,
    middleware::Next,
    response::{IntoResponse, Response},
};
use uuid::Uuid;

use crate::utils::{extract_token_from_header, validate_token, Claims};

/// Extension type to store authenticated user information
#[derive(Clone, Debug)]
pub struct AuthUser {
    pub user_id: Uuid,
    pub email: String,
    pub role: String,
}

impl From<Claims> for AuthUser {
    fn from(claims: Claims) -> Self {
        Self {
            user_id: Uuid::parse_str(&claims.sub).unwrap_or_default(),
            email: claims.email,
            role: claims.role,
        }
    }
}

/// JWT authentication middleware
///
/// This middleware:
/// 1. Extracts the JWT token from the Authorization header
/// 2. Validates the token
/// 3. Adds user information to request extensions
///
/// Usage:
/// ```rust
/// use axum::Router;
/// use axum::middleware;
///
/// let protected_routes = Router::new()
///     .route("/protected", get(protected_handler))
///     .layer(middleware::from_fn_with_state(app_state, auth_middleware));
/// ```
pub async fn auth_middleware(
    mut req: Request,
    next: Next,
    jwt_secret: String,
) -> Result<Response, StatusCode> {
    // Extract Authorization header
    let auth_header = req
        .headers()
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    // Extract token from header
    let token = extract_token_from_header(auth_header)
        .map_err(|_| StatusCode::UNAUTHORIZED)?;

    // Validate token and get claims
    let claims = validate_token(&token, &jwt_secret)
        .map_err(|_| StatusCode::UNAUTHORIZED)?;

    // Convert claims to AuthUser and add to request extensions
    let auth_user = AuthUser::from(claims);
    req.extensions_mut().insert(auth_user);

    // Continue to the next handler
    Ok(next.run(req).await)
}

/// Alternative auth middleware that works with Axum's middleware layer
/// This version accepts the JWT secret from application state
pub async fn auth_middleware_with_secret(
    jwt_secret: String,
) -> impl Fn(Request, Next) -> std::pin::Pin<Box<dyn std::future::Future<Output = Result<Response, StatusCode>> + Send>> {
    move |req: Request, next: Next| {
        let secret = jwt_secret.clone();
        Box::pin(async move {
            auth_middleware(req, next, secret).await
        })
    }
}

/// Role-based authorization middleware
///
/// Checks if the authenticated user has one of the required roles
///
/// Note: This middleware requires auth_middleware to run first
pub fn require_role(allowed_roles: Vec<String>) -> impl Fn(Request, Next) -> std::pin::Pin<Box<dyn std::future::Future<Output = Response> + Send>> {
    move |req: Request, next: Next| {
        let roles = allowed_roles.clone();
        Box::pin(async move {
            // Get AuthUser from request extensions
            let auth_user = req.extensions().get::<AuthUser>().cloned();

            match auth_user {
                Some(user) => {
                    // Check if user has required role
                    if roles.contains(&user.role) {
                        next.run(req).await
                    } else {
                        (StatusCode::FORBIDDEN, "Insufficient permissions").into_response()
                    }
                }
                None => {
                    (StatusCode::UNAUTHORIZED, "Authentication required").into_response()
                }
            }
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::utils::create_access_token;
    use axum::{
        body::Body,
        http::{Request, StatusCode},
        middleware,
        routing::get,
        Extension, Router,
    };
    use tower::ServiceExt;
    use uuid::Uuid;

    // Helper handler that uses AuthUser extension
    async fn protected_handler(Extension(user): Extension<AuthUser>) -> String {
        format!("Hello, {}!", user.email)
    }

    const TEST_SECRET: &str = "test-secret-key-for-middleware-testing-12345";

    #[tokio::test]
    async fn test_auth_middleware_success() {
        let user_id = Uuid::new_v4();
        let email = "test@example.com";
        let role = "user";

        // Create a valid token
        let token = create_access_token(user_id, email, role, TEST_SECRET).unwrap();

        // Create router with auth middleware
        let app = Router::new()
            .route("/protected", get(protected_handler))
            .layer(middleware::from_fn(move |req, next| {
                auth_middleware(req, next, TEST_SECRET.to_string())
            }));

        // Create request with Authorization header
        let request = Request::builder()
            .uri("/protected")
            .header("authorization", format!("Bearer {}", token))
            .body(Body::empty())
            .unwrap();

        // Send request
        let response = app.oneshot(request).await.unwrap();

        // Should succeed
        assert_eq!(response.status(), StatusCode::OK);
    }

    #[tokio::test]
    async fn test_auth_middleware_missing_header() {
        let app = Router::new()
            .route("/protected", get(protected_handler))
            .layer(middleware::from_fn(move |req, next| {
                auth_middleware(req, next, TEST_SECRET.to_string())
            }));

        // Create request without Authorization header
        let request = Request::builder()
            .uri("/protected")
            .body(Body::empty())
            .unwrap();

        // Send request
        let response = app.oneshot(request).await.unwrap();

        // Should fail with Unauthorized
        assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    }

    #[tokio::test]
    async fn test_auth_middleware_invalid_token() {
        let app = Router::new()
            .route("/protected", get(protected_handler))
            .layer(middleware::from_fn(move |req, next| {
                auth_middleware(req, next, TEST_SECRET.to_string())
            }));

        // Create request with invalid token
        let request = Request::builder()
            .uri("/protected")
            .header("authorization", "Bearer invalid-token")
            .body(Body::empty())
            .unwrap();

        // Send request
        let response = app.oneshot(request).await.unwrap();

        // Should fail with Unauthorized
        assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    }

    #[test]
    fn test_auth_user_from_claims() {
        let user_id = Uuid::new_v4();
        let claims = Claims {
            sub: user_id.to_string(),
            email: "test@example.com".to_string(),
            role: "user".to_string(),
            exp: 0,
            iat: 0,
            token_type: crate::utils::TokenType::Access,
        };

        let auth_user = AuthUser::from(claims);
        assert_eq!(auth_user.user_id, user_id);
        assert_eq!(auth_user.email, "test@example.com");
        assert_eq!(auth_user.role, "user");
    }
}
