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
