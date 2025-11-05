use chrono::Utc;
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use super::ApiError;

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
pub fn create_access_token(user_id: Uuid, email: &str, role: &str, secret: &str) -> Result<String, ApiError> {
    create_token(user_id, email, role, secret, TokenType::Access, ACCESS_TOKEN_EXPIRATION)
}

/// Create a refresh token
pub fn create_refresh_token(user_id: Uuid, email: &str, role: &str, secret: &str) -> Result<String, ApiError> {
    create_token(user_id, email, role, secret, TokenType::Refresh, REFRESH_TOKEN_EXPIRATION)
}

/// Create a JWT token
fn create_token(
    user_id: Uuid,
    email: &str,
    role: &str,
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
        let role = "user";

        let token = create_access_token(user_id, email, role, TEST_SECRET).unwrap();

        assert!(!token.is_empty());
        assert_eq!(token.matches('.').count(), 2); // JWT has 3 parts
    }

    #[test]
    fn test_create_refresh_token() {
        let user_id = Uuid::new_v4();
        let email = "test@example.com";
        let role = "user";

        let token = create_refresh_token(user_id, email, role, TEST_SECRET).unwrap();

        assert!(!token.is_empty());
    }

    #[test]
    fn test_validate_token_success() {
        let user_id = Uuid::new_v4();
        let email = "test@example.com";
        let role = "admin";

        let token = create_access_token(user_id, email, role, TEST_SECRET).unwrap();
        let claims = validate_token(&token, TEST_SECRET).unwrap();

        assert_eq!(claims.sub, user_id.to_string());
        assert_eq!(claims.email, email);
        assert_eq!(claims.role, "admin");
        assert_eq!(claims.token_type, TokenType::Access);
    }

    #[test]
    fn test_validate_token_wrong_secret() {
        let user_id = Uuid::new_v4();
        let token = create_access_token(user_id, "test@example.com", "user", TEST_SECRET).unwrap();

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
        let access_token = create_access_token(user_id, "test@example.com", "user", TEST_SECRET).unwrap();
        let refresh_token = create_refresh_token(user_id, "test@example.com", "user", TEST_SECRET).unwrap();

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
