use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct User {
    pub id: Uuid,
    pub email: String,
    #[serde(skip_serializing)]  // Never send password hash to client
    pub password_hash: String,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub role: String,
    pub avatar_url: Option<String>,
    pub is_active: bool,
    pub last_login: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum UserRole {
    Admin,
    Manager,
    User,
}

impl std::fmt::Display for UserRole {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            UserRole::Admin => write!(f, "admin"),
            UserRole::Manager => write!(f, "manager"),
            UserRole::User => write!(f, "user"),
        }
    }
}

impl std::str::FromStr for UserRole {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "admin" => Ok(UserRole::Admin),
            "manager" => Ok(UserRole::Manager),
            "user" => Ok(UserRole::User),
            _ => Err(format!("Invalid role: {}", s)),
        }
    }
}

// Request DTOs
#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub email: String,
    pub password: String,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

// Response DTOs
#[derive(Debug, Serialize)]
pub struct UserResponse {
    pub id: Uuid,
    pub email: String,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub role: String,
    pub avatar_url: Option<String>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
}

impl From<User> for UserResponse {
    fn from(user: User) -> Self {
        Self {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            role: user.role,
            avatar_url: user.avatar_url,
            is_active: user.is_active,
            created_at: user.created_at,
        }
    }
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub token_type: String,
    pub expires_in: usize,
    pub user: UserResponse,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_user_role_to_string() {
        assert_eq!(UserRole::Admin.to_string(), "admin");
        assert_eq!(UserRole::Manager.to_string(), "manager");
        assert_eq!(UserRole::User.to_string(), "user");
    }

    #[test]
    fn test_user_role_from_str() {
        assert!(matches!("admin".parse::<UserRole>(), Ok(UserRole::Admin)));
        assert!(matches!("manager".parse::<UserRole>(), Ok(UserRole::Manager)));
        assert!(matches!("user".parse::<UserRole>(), Ok(UserRole::User)));
        assert!(matches!("ADMIN".parse::<UserRole>(), Ok(UserRole::Admin)));
    }

    #[test]
    fn test_user_role_from_str_invalid() {
        assert!("invalid".parse::<UserRole>().is_err());
    }

    #[test]
    fn test_user_response_from_user() {
        let user = User {
            id: Uuid::new_v4(),
            email: "test@example.com".to_string(),
            password_hash: "hash".to_string(),
            first_name: Some("Test".to_string()),
            last_name: Some("User".to_string()),
            role: "user".to_string(),
            avatar_url: None,
            is_active: true,
            last_login: None,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        let response = UserResponse::from(user.clone());

        assert_eq!(response.id, user.id);
        assert_eq!(response.email, user.email);
        assert_eq!(response.first_name, user.first_name);
    }

    #[test]
    fn test_user_serialization_excludes_password() {
        let user = User {
            id: Uuid::new_v4(),
            email: "test@example.com".to_string(),
            password_hash: "secret_hash".to_string(),
            first_name: None,
            last_name: None,
            role: "user".to_string(),
            avatar_url: None,
            is_active: true,
            last_login: None,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };

        let json = serde_json::to_string(&user).unwrap();
        assert!(!json.contains("password_hash"));
        assert!(!json.contains("secret_hash"));
    }
}
