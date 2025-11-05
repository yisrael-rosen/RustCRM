use uuid::Uuid;

use crate::models::{AuthResponse, LoginRequest, RegisterRequest, User, UserResponse, UserRole};
use crate::repositories::UserRepository;
use crate::utils::{
    create_access_token, create_refresh_token, hash_password, validate_password_strength,
    verify_password, ApiError,
};

#[derive(Clone)]
pub struct AuthService {
    user_repository: UserRepository,
    jwt_secret: String,
}

impl AuthService {
    pub fn new(user_repository: UserRepository, jwt_secret: String) -> Self {
        Self {
            user_repository,
            jwt_secret,
        }
    }

    /// Register a new user
    pub async fn register(&self, request: RegisterRequest) -> Result<User, ApiError> {
        // Validate email format
        if !Self::is_valid_email(&request.email) {
            return Err(ApiError::BadRequest("Invalid email format".to_string()));
        }

        // Validate password strength
        validate_password_strength(&request.password)?;

        // Check if email already exists
        if self.user_repository.email_exists(&request.email).await? {
            return Err(ApiError::BadRequest("Email already exists".to_string()));
        }

        // Hash password
        let password_hash = hash_password(&request.password)?;

        // Create user
        let user = self
            .user_repository
            .create(
                &request.email,
                &password_hash,
                request.first_name.as_deref(),
                request.last_name.as_deref(),
            )
            .await?;

        tracing::info!("User registered successfully: {}", user.email);

        Ok(user)
    }

    /// Login user and return tokens
    pub async fn login(&self, request: LoginRequest) -> Result<AuthResponse, ApiError> {
        // Find user by email
        let user = self
            .user_repository
            .find_by_email(&request.email)
            .await?
            .ok_or_else(|| ApiError::Unauthorized("Invalid credentials".to_string()))?;

        // Check if user is active
        if !user.is_active {
            return Err(ApiError::Unauthorized("Account is disabled".to_string()));
        }

        // Verify password
        let is_valid = verify_password(&request.password, &user.password_hash)?;
        if !is_valid {
            return Err(ApiError::Unauthorized("Invalid credentials".to_string()));
        }

        // Update last login
        self.user_repository.update_last_login(user.id).await?;

        // Generate tokens (use role as string)
        let access_token = create_access_token(user.id, &user.email, &user.role, &self.jwt_secret)?;
        let refresh_token = create_refresh_token(user.id, &user.email, &user.role, &self.jwt_secret)?;

        tracing::info!("User logged in successfully: {}", user.email);

        Ok(AuthResponse {
            access_token,
            refresh_token,
            token_type: "Bearer".to_string(),
            expires_in: 3600, // 1 hour
            user: UserResponse::from(user),
        })
    }

    /// Get user by ID
    pub async fn get_user(&self, user_id: Uuid) -> Result<User, ApiError> {
        self.user_repository
            .find_by_id(user_id)
            .await?
            .ok_or_else(|| ApiError::NotFound("User not found".to_string()))
    }

    /// Helper: Validate email format
    fn is_valid_email(email: &str) -> bool {
        // Basic email validation
        if email.len() < 5 {
            return false;
        }

        let parts: Vec<&str> = email.split('@').collect();
        if parts.len() != 2 {
            return false;
        }

        let (local, domain) = (parts[0], parts[1]);

        // Local part (before @) must not be empty
        if local.is_empty() {
            return false;
        }

        // Domain must contain a dot and not be empty
        domain.contains('.') && !domain.is_empty() && domain.len() > 2
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_valid_email() {
        assert!(AuthService::is_valid_email("user@example.com"));
        assert!(AuthService::is_valid_email("user.name@example.co.uk"));
        assert!(!AuthService::is_valid_email("invalid"));
        assert!(!AuthService::is_valid_email("@example.com"));
        assert!(!AuthService::is_valid_email("user@"));
        assert!(!AuthService::is_valid_email("a@b"));
    }
}
