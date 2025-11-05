# 🚀 API Development Guide

## 📋 Best Practices for Building RustCRM APIs

This guide covers best practices, patterns, and standards for building REST APIs in RustCRM.

---

## 🎯 API Design Principles

### 1. RESTful Design

Follow REST principles:

✅ **DO**:
- Use nouns for resource names (`/contacts`, not `/getContacts`)
- Use HTTP methods correctly (GET, POST, PUT, DELETE)
- Use proper status codes
- Keep URLs hierarchical and logical
- Version your API (`/api/v1/...`)

❌ **DON'T**:
- Use verbs in URLs
- Return 200 for errors
- Mix singular/plural inconsistently
- Create deeply nested resources (max 2-3 levels)

### 2. HTTP Methods

| Method | Purpose | Idempotent | Safe |
|--------|---------|------------|------|
| GET | Retrieve resources | ✅ | ✅ |
| POST | Create new resource | ❌ | ❌ |
| PUT | Update entire resource | ✅ | ❌ |
| PATCH | Update partial resource | ❌ | ❌ |
| DELETE | Delete resource | ✅ | ❌ |

### 3. Status Codes

Use appropriate HTTP status codes:

**Success (2xx)**:
- `200 OK` - Successful GET, PUT, PATCH
- `201 Created` - Successful POST
- `204 No Content` - Successful DELETE

**Client Errors (4xx)**:
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Missing/invalid authentication
- `403 Forbidden` - Valid auth but insufficient permissions
- `404 Not Found` - Resource doesn't exist
- `409 Conflict` - Duplicate resource
- `422 Unprocessable Entity` - Validation errors

**Server Errors (5xx)**:
- `500 Internal Server Error` - Unexpected server error
- `503 Service Unavailable` - Temporary unavailability

---

## 📐 URL Structure

### Resource Naming

```
Good:
GET    /api/v1/contacts
POST   /api/v1/contacts
GET    /api/v1/contacts/{id}
PUT    /api/v1/contacts/{id}
DELETE /api/v1/contacts/{id}

Bad:
GET    /api/v1/getAllContacts
POST   /api/v1/createContact
GET    /api/v1/contact/{id}  (inconsistent singular/plural)
```

### Nested Resources

```rust
// One level is good
GET /api/v1/companies/{id}/contacts

// Two levels is acceptable
GET /api/v1/companies/{id}/contacts/{contactId}/activities

// Three+ levels is bad (use query params instead)
❌ GET /api/v1/companies/{id}/contacts/{contactId}/deals/{dealId}/notes
✅ GET /api/v1/notes?deal_id={dealId}
```

### Query Parameters

Use query parameters for:
- Filtering: `?status=active&role=admin`
- Sorting: `?sort=created_at&order=desc`
- Pagination: `?page=0&per_page=20`
- Search: `?search=john`
- Fields selection: `?fields=id,name,email`

```rust
// Example implementation
#[derive(Debug, Deserialize)]
pub struct ContactQuery {
    pub search: Option<String>,
    pub company_id: Option<Uuid>,
    pub tags: Option<Vec<String>>,
    pub sort: Option<String>,
    pub order: Option<String>,
    pub page: Option<i64>,
    pub per_page: Option<i64>,
}

pub async fn list_contacts(
    Query(params): Query<ContactQuery>,
) -> Result<Json<PaginatedResponse>> {
    // Use params to build query
}
```

---

## 📝 Request/Response Patterns

### Request DTOs

Always create separate DTOs for requests:

```rust
// ❌ BAD: Using domain model directly
pub async fn create_contact(Json(contact): Json<Contact>) { }

// ✅ GOOD: Using dedicated DTO
#[derive(Debug, Deserialize, Validate)]
pub struct CreateContactRequest {
    #[validate(length(min = 1, max = 100))]
    pub first_name: String,

    #[validate(length(min = 1, max = 100))]
    pub last_name: String,

    #[validate(email)]
    pub email: Option<String>,

    pub company_id: Option<Uuid>,
}

pub async fn create_contact(
    Json(request): Json<CreateContactRequest>
) -> Result<Json<ContactResponse>> {
    // Validate and convert to domain model
}
```

### Response DTOs

Never expose internal models directly:

```rust
// ❌ BAD: Exposing database model with password
#[derive(Serialize)]
pub struct User {
    pub id: Uuid,
    pub email: String,
    pub password_hash: String,  // Security risk!
}

// ✅ GOOD: Dedicated response DTO
#[derive(Serialize)]
pub struct UserResponse {
    pub id: Uuid,
    pub email: String,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub role: UserRole,
    pub created_at: DateTime<Utc>,
    // No password_hash!
}

impl From<User> for UserResponse {
    fn from(user: User) -> Self {
        Self {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            role: user.role,
            created_at: user.created_at,
        }
    }
}
```

### Pagination Response

Standardized pagination response:

```rust
#[derive(Debug, Serialize)]
pub struct PaginatedResponse<T> {
    pub data: Vec<T>,
    pub pagination: PaginationMeta,
}

#[derive(Debug, Serialize)]
pub struct PaginationMeta {
    pub total: i64,
    pub page: i64,
    pub per_page: i64,
    pub total_pages: i64,
    pub has_next: bool,
    pub has_prev: bool,
}

// Usage
pub async fn list_contacts() -> Result<Json<PaginatedResponse<ContactResponse>>> {
    let total_pages = (total as f64 / per_page as f64).ceil() as i64;

    Ok(Json(PaginatedResponse {
        data: contacts,
        pagination: PaginationMeta {
            total,
            page,
            per_page,
            total_pages,
            has_next: page < total_pages - 1,
            has_prev: page > 0,
        },
    }))
}
```

---

## 🔍 Input Validation

### Using Validator Crate

```rust
use validator::{Validate, ValidationError};

#[derive(Debug, Deserialize, Validate)]
pub struct CreateContactRequest {
    #[validate(length(min = 1, max = 100, message = "First name must be 1-100 characters"))]
    pub first_name: String,

    #[validate(email(message = "Invalid email format"))]
    pub email: Option<String>,

    #[validate(custom = "validate_phone")]
    pub phone: Option<String>,

    #[validate(range(min = 0, max = 5, message = "Invalid priority"))]
    pub priority: Option<i32>,
}

fn validate_phone(phone: &str) -> Result<(), ValidationError> {
    if phone.len() < 10 {
        return Err(ValidationError::new("phone_too_short"));
    }
    Ok(())
}

// In handler
pub async fn create_contact(
    Json(request): Json<CreateContactRequest>,
) -> Result<Json<ContactResponse>> {
    // Validate
    request.validate()
        .map_err(|e| ApiError::BadRequest(format!("Validation error: {}", e)))?;

    // Process...
}
```

### Custom Validation in Service Layer

```rust
impl ContactService {
    pub async fn create(&self, request: CreateContactRequest) -> Result<Contact> {
        // Business logic validation
        if let Some(ref email) = request.email {
            if self.repository.email_exists(email).await? {
                return Err(ApiError::Conflict("Email already exists".into()));
            }
        }

        // Additional validation
        self.validate_company_exists(request.company_id).await?;

        // Create contact
        self.repository.create(request).await
    }

    async fn validate_company_exists(&self, company_id: Option<Uuid>) -> Result<()> {
        if let Some(id) = company_id {
            self.company_repo.find_by_id(id).await?
                .ok_or(ApiError::BadRequest("Company not found".into()))?;
        }
        Ok(())
    }
}
```

---

## 🛡️ Error Handling

### Consistent Error Responses

```rust
#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub error: String,
    pub details: Option<serde_json::Value>,
    pub timestamp: DateTime<Utc>,
    pub path: Option<String>,
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, message, details) = match self {
            ApiError::BadRequest(msg) => (
                StatusCode::BAD_REQUEST,
                msg,
                None
            ),
            ApiError::NotFound(msg) => (
                StatusCode::NOT_FOUND,
                msg,
                None
            ),
            ApiError::ValidationError(errors) => (
                StatusCode::UNPROCESSABLE_ENTITY,
                "Validation failed".to_string(),
                Some(json!(errors))
            ),
            ApiError::DatabaseError(e) => {
                tracing::error!("Database error: {:?}", e);
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "Internal server error".to_string(),
                    None
                )
            },
        };

        let body = Json(ErrorResponse {
            error: message,
            details,
            timestamp: Utc::now(),
            path: None, // Can be added via middleware
        });

        (status, body).into_response()
    }
}
```

### Error Examples

```json
{
  "error": "Validation failed",
  "details": {
    "first_name": ["First name is required"],
    "email": ["Invalid email format"]
  },
  "timestamp": "2024-01-01T12:00:00Z",
  "path": "/api/v1/contacts"
}
```

---

## 🔐 Authentication & Authorization

### JWT Middleware

```rust
use axum::{
    extract::{Request, State},
    middleware::Next,
    response::Response,
};

pub async fn auth_middleware(
    State(config): State<AppConfig>,
    mut request: Request,
    next: Next,
) -> Result<Response, ApiError> {
    // Extract token from header
    let auth_header = request
        .headers()
        .get("authorization")
        .and_then(|h| h.to_str().ok())
        .ok_or(ApiError::Unauthorized("Missing authorization header".into()))?;

    let token = extract_token_from_header(auth_header)?;

    // Validate token
    let claims = validate_token(&token, &config.jwt_secret)?;

    // Add user info to request extensions
    request.extensions_mut().insert(AuthUser {
        id: Uuid::parse_str(&claims.sub)?,
        email: claims.email,
        role: claims.role.parse()?,
    });

    Ok(next.run(request).await)
}

// Usage in routes
async fn create_contact(
    AuthUser(user): AuthUser,  // Automatically extracted from middleware
    Json(request): Json<CreateContactRequest>,
) -> Result<Json<ContactResponse>> {
    // user.id is available here
}
```

### Role-Based Access Control

```rust
pub struct RequireRole(pub Vec<UserRole>);

impl<S> FromRequestParts<S> for RequireRole
where
    S: Send + Sync,
{
    type Rejection = ApiError;

    async fn from_request_parts(
        parts: &mut Parts,
        _state: &S,
    ) -> Result<Self, Self::Rejection> {
        let user = parts
            .extensions
            .get::<AuthUser>()
            .ok_or(ApiError::Unauthorized("Not authenticated".into()))?;

        Ok(Self(vec![user.role.clone()]))
    }
}

// Usage
async fn admin_only_endpoint(
    RequireRole(roles): RequireRole,
) -> Result<Json<SomeData>> {
    if !roles.contains(&UserRole::Admin) {
        return Err(ApiError::Forbidden("Admin access required".into()));
    }
    // Process...
}
```

---

## 📊 Performance Best Practices

### 1. Database Query Optimization

```rust
// ❌ BAD: N+1 query problem
pub async fn list_contacts() -> Vec<ContactWithCompany> {
    let contacts = sqlx::query_as::<_, Contact>("SELECT * FROM contacts")
        .fetch_all(&pool).await?;

    let mut result = Vec::new();
    for contact in contacts {
        // This executes N queries!
        let company = sqlx::query_as::<_, Company>(
            "SELECT * FROM companies WHERE id = $1"
        )
        .bind(contact.company_id)
        .fetch_one(&pool).await?;

        result.push(ContactWithCompany { contact, company });
    }
    result
}

// ✅ GOOD: Single JOIN query
pub async fn list_contacts() -> Vec<ContactWithCompany> {
    sqlx::query_as::<_, ContactWithCompany>(
        r#"
        SELECT
            c.*,
            co.name as company_name,
            co.domain as company_domain
        FROM contacts c
        LEFT JOIN companies co ON c.company_id = co.id
        "#
    )
    .fetch_all(&pool).await
}
```

### 2. Pagination Limits

```rust
#[derive(Debug, Deserialize)]
pub struct PaginationParams {
    pub page: Option<i64>,
    pub per_page: Option<i64>,
}

impl PaginationParams {
    pub fn normalize(&self) -> (i64, i64) {
        let page = self.page.unwrap_or(0).max(0);
        let per_page = self.per_page
            .unwrap_or(20)
            .clamp(1, 100);  // Limit max to 100

        (page, per_page)
    }
}
```

### 3. Caching

```rust
use redis::AsyncCommands;

pub async fn get_contact_cached(
    id: Uuid,
    pool: &PgPool,
    redis: &mut redis::aio::Connection,
) -> Result<Contact> {
    let cache_key = format!("contact:{}", id);

    // Try cache first
    if let Ok(Some(cached)) = redis.get::<_, Option<String>>(&cache_key).await {
        if let Ok(contact) = serde_json::from_str::<Contact>(&cached) {
            return Ok(contact);
        }
    }

    // Cache miss - fetch from database
    let contact = sqlx::query_as::<_, Contact>(
        "SELECT * FROM contacts WHERE id = $1"
    )
    .bind(id)
    .fetch_one(pool)
    .await?;

    // Update cache
    let _: () = redis.set_ex(
        &cache_key,
        serde_json::to_string(&contact)?,
        300  // 5 minutes TTL
    ).await?;

    Ok(contact)
}
```

---

## 📖 API Documentation

### Using OpenAPI/Swagger

Install dependencies:
```toml
[dependencies]
utoipa = "4"
utoipa-swagger-ui = { version = "6", features = ["axum"] }
```

Document your APIs:

```rust
use utoipa::{OpenApi, ToSchema};

#[derive(OpenApi)]
#[openapi(
    paths(
        list_contacts,
        create_contact,
        get_contact,
        update_contact,
        delete_contact,
    ),
    components(
        schemas(
            Contact,
            CreateContactRequest,
            UpdateContactRequest,
            PaginatedResponse,
        )
    ),
    tags(
        (name = "contacts", description = "Contact management endpoints")
    )
)]
struct ApiDoc;

#[utoipa::path(
    get,
    path = "/api/v1/contacts",
    tag = "contacts",
    params(
        ("page" = Option<i64>, Query, description = "Page number"),
        ("per_page" = Option<i64>, Query, description = "Items per page"),
    ),
    responses(
        (status = 200, description = "List of contacts", body = PaginatedResponse<Contact>),
        (status = 401, description = "Unauthorized"),
    ),
    security(
        ("bearer_token" = [])
    )
)]
pub async fn list_contacts() -> Result<Json<PaginatedResponse<Contact>>> {
    // Implementation
}

// Add Swagger UI to your app
use utoipa_swagger_ui::SwaggerUi;

let app = Router::new()
    .merge(SwaggerUi::new("/swagger-ui")
        .url("/api-docs/openapi.json", ApiDoc::openapi()));
```

Access docs at: `http://localhost:8000/swagger-ui`

---

## ✅ API Development Checklist

Before shipping an API endpoint:

- [ ] Follows REST naming conventions
- [ ] Uses appropriate HTTP methods and status codes
- [ ] Has input validation
- [ ] Has proper error handling
- [ ] Returns consistent response format
- [ ] Has authentication/authorization
- [ ] Is properly tested (unit + integration)
- [ ] Is documented (OpenAPI/Swagger)
- [ ] Has proper logging
- [ ] Handles edge cases
- [ ] Is performant (no N+1 queries)
- [ ] Has rate limiting (if public)
- [ ] Validates permissions correctly

---

**Next Steps**: Apply these patterns when implementing endpoints in Phase 2 and beyond!
