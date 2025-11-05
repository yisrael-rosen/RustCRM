use std::env;

#[derive(Debug, Clone)]
pub struct Settings {
    pub database_url: String,
    pub redis_url: String,
    pub jwt_secret: String,
    pub port: u16,
    pub host: String,
    pub anthropic_api_key: Option<String>,
}

impl Settings {
    pub fn new() -> Result<Self, env::VarError> {
        Ok(Self {
            database_url: env::var("DATABASE_URL")?,
            redis_url: env::var("REDIS_URL").unwrap_or_else(|_| "redis://localhost:6379".to_string()),
            jwt_secret: env::var("JWT_SECRET")?,
            port: env::var("PORT")
                .unwrap_or_else(|_| "8000".to_string())
                .parse()
                .expect("PORT must be a valid number"),
            host: env::var("HOST").unwrap_or_else(|_| "0.0.0.0".to_string()),
            anthropic_api_key: env::var("ANTHROPIC_API_KEY").ok(),
        })
    }

    pub fn server_address(&self) -> String {
        format!("{}:{}", self.host, self.port)
    }
}

impl Default for Settings {
    fn default() -> Self {
        Self::new().expect("Failed to load settings from environment")
    }
}
