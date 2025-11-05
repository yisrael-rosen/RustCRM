use sqlx::PgPool;
use uuid::Uuid;

use crate::models::User;
use crate::utils::ApiError;

#[derive(Clone)]
pub struct UserRepository {
    pool: PgPool,
}

impl UserRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Create a new user
    pub async fn create(
        &self,
        email: &str,
        password_hash: &str,
        first_name: Option<&str>,
        last_name: Option<&str>,
    ) -> Result<User, ApiError> {
        let user = sqlx::query_as::<_, User>(
            r#"
            INSERT INTO users (email, password_hash, first_name, last_name, role)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING *
            "#,
        )
        .bind(email)
        .bind(password_hash)
        .bind(first_name)
        .bind(last_name)
        .bind("user") // Default role
        .fetch_one(&self.pool)
        .await
        .map_err(|e| {
            tracing::error!("Failed to create user: {:?}", e);
            if let sqlx::Error::Database(db_err) = &e {
                if db_err.is_unique_violation() {
                    return ApiError::BadRequest("Email already exists".to_string());
                }
            }
            ApiError::DatabaseError(e)
        })?;

        Ok(user)
    }

    /// Find user by email
    pub async fn find_by_email(&self, email: &str) -> Result<Option<User>, ApiError> {
        let user = sqlx::query_as::<_, User>(
            r#"
            SELECT * FROM users
            WHERE email = $1
            "#,
        )
        .bind(email)
        .fetch_optional(&self.pool)
        .await?;

        Ok(user)
    }

    /// Find user by ID
    pub async fn find_by_id(&self, id: Uuid) -> Result<Option<User>, ApiError> {
        let user = sqlx::query_as::<_, User>(
            r#"
            SELECT * FROM users
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(user)
    }

    /// Update last login time
    pub async fn update_last_login(&self, id: Uuid) -> Result<(), ApiError> {
        sqlx::query(
            r#"
            UPDATE users
            SET last_login = NOW()
            WHERE id = $1
            "#,
        )
        .bind(id)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// Check if email exists
    pub async fn email_exists(&self, email: &str) -> Result<bool, ApiError> {
        let exists = sqlx::query_scalar::<_, bool>(
            r#"
            SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)
            "#,
        )
        .bind(email)
        .fetch_one(&self.pool)
        .await?;

        Ok(exists)
    }
}
