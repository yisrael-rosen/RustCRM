# 📇 Phase 2: Contacts & Companies Management

## 📋 Table of Contents

1. [Overview](#overview)
2. [Data Models](#data-models)
3. [Day-by-Day Implementation](#day-by-day-implementation)
4. [Contacts Module](#contacts-module)
5. [Companies Module](#companies-module)
6. [Advanced Features](#advanced-features)
7. [Testing](#testing)
8. [API Documentation](#api-documentation)

---

## 🎯 Overview

### Goals

Build comprehensive contact and company management with:

- ✅ CRUD operations for contacts
- ✅ CRUD operations for companies
- ✅ Search and filtering
- ✅ Pagination
- ✅ CSV import/export
- ✅ Contact-Company relationships
- ✅ Full-text search
- ✅ Data deduplication
- ✅ 85%+ test coverage

### Success Criteria

- [ ] All CRUD endpoints functional
- [ ] Search works across multiple fields
- [ ] Pagination handles large datasets
- [ ] CSV import handles 10,000+ records
- [ ] Full-text search is performant (<100ms)
- [ ] 85%+ test coverage
- [ ] API documentation complete

---

## 📦 Data Models

### Contact Model

**File**: `backend/src/models/contact.rs`

```rust
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Contact {
    pub id: Uuid,
    pub first_name: String,
    pub last_name: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub position: Option<String>,
    pub company_id: Option<Uuid>,
    pub owner_id: Option<Uuid>,
    pub linkedin_url: Option<String>,
    pub notes: Option<String>,
    pub tags: Option<Vec<String>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct CreateContactRequest {
    pub first_name: String,
    pub last_name: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub position: Option<String>,
    pub company_id: Option<Uuid>,
    pub linkedin_url: Option<String>,
    pub notes: Option<String>,
    pub tags: Option<Vec<String>>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateContactRequest {
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub position: Option<String>,
    pub company_id: Option<Uuid>,
    pub linkedin_url: Option<String>,
    pub notes: Option<String>,
    pub tags: Option<Vec<String>>,
}

#[derive(Debug, Deserialize)]
pub struct ContactFilter {
    pub search: Option<String>,
    pub company_id: Option<Uuid>,
    pub owner_id: Option<Uuid>,
    pub tags: Option<Vec<String>>,
    pub page: Option<i64>,
    pub per_page: Option<i64>,
}

#[derive(Debug, Serialize)]
pub struct ContactResponse {
    pub id: Uuid,
    pub first_name: String,
    pub last_name: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub position: Option<String>,
    pub company_id: Option<Uuid>,
    pub company_name: Option<String>,  // Joined from company
    pub owner_id: Option<Uuid>,
    pub owner_name: Option<String>,     // Joined from user
    pub linkedin_url: Option<String>,
    pub notes: Option<String>,
    pub tags: Option<Vec<String>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct PaginatedContacts {
    pub data: Vec<ContactResponse>,
    pub total: i64,
    pub page: i64,
    pub per_page: i64,
    pub total_pages: i64,
}
```

### Company Model

**File**: `backend/src/models/company.rs`

```rust
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Company {
    pub id: Uuid,
    pub name: String,
    pub domain: Option<String>,
    pub industry: Option<String>,
    pub size: Option<String>,
    pub website: Option<String>,
    pub phone: Option<String>,
    pub address: Option<String>,
    pub city: Option<String>,
    pub country: Option<String>,
    pub owner_id: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct CreateCompanyRequest {
    pub name: String,
    pub domain: Option<String>,
    pub industry: Option<String>,
    pub size: Option<String>,
    pub website: Option<String>,
    pub phone: Option<String>,
    pub address: Option<String>,
    pub city: Option<String>,
    pub country: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateCompanyRequest {
    pub name: Option<String>,
    pub domain: Option<String>,
    pub industry: Option<String>,
    pub size: Option<String>,
    pub website: Option<String>,
    pub phone: Option<String>,
    pub address: Option<String>,
    pub city: Option<String>,
    pub country: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct CompanyFilter {
    pub search: Option<String>,
    pub industry: Option<String>,
    pub size: Option<String>,
    pub country: Option<String>,
    pub page: Option<i64>,
    pub per_page: Option<i64>,
}

#[derive(Debug, Serialize)]
pub struct CompanyResponse {
    pub id: Uuid,
    pub name: String,
    pub domain: Option<String>,
    pub industry: Option<String>,
    pub size: Option<String>,
    pub website: Option<String>,
    pub phone: Option<String>,
    pub address: Option<String>,
    pub city: Option<String>,
    pub country: Option<String>,
    pub owner_id: Option<Uuid>,
    pub owner_name: Option<String>,
    pub contact_count: i64,  // Aggregated count
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize)]
pub struct PaginatedCompanies {
    pub data: Vec<CompanyResponse>,
    pub total: i64,
    pub page: i64,
    pub per_page: i64,
    pub total_pages: i64,
}
```

---

## 📅 Day-by-Day Implementation

### Day 5: Contacts CRUD (6-8 hours)

**Morning (3-4 hours)**:
1. Create contact model and DTOs
2. Implement contact repository
3. Write repository unit tests
4. Create contact service with validation

**Afternoon (3-4 hours)**:
5. Implement CRUD handlers
6. Add authentication middleware to routes
7. Write integration tests
8. Test with Postman/Insomnia

**Deliverables**:
- Contact CRUD endpoints
- Unit tests for repository
- Integration tests for all endpoints
- 85%+ coverage

### Day 6: Contact Search & Features (4-6 hours)

**Morning (2-3 hours)**:
1. Implement search functionality
2. Add pagination
3. Implement filtering by company/owner
4. Write search tests

**Afternoon (2-3 hours)**:
5. CSV import functionality
6. CSV export functionality
7. Data validation for imports
8. Test with large datasets

**Deliverables**:
- Search working across fields
- Pagination handling 10,000+ records
- CSV import/export
- Performance benchmarks

### Day 7: Companies CRUD (6-8 hours)

**Morning (3-4 hours)**:
1. Create company model and DTOs
2. Implement company repository
3. Write repository unit tests
4. Create company service

**Afternoon (3-4 hours)**:
5. Implement CRUD handlers
6. Link companies to contacts
7. Write integration tests
8. Test company-contact relationships

**Deliverables**:
- Company CRUD endpoints
- Contact-company linking
- Integration tests
- 85%+ coverage

### Day 8: Advanced Company Features (4-6 hours)

**Morning (2-3 hours)**:
1. Implement full-text search
2. Add company aggregations (contact count)
3. Implement company enrichment
4. Write search tests

**Afternoon (2-3 hours)**:
5. Performance optimization
6. Add database indexes
7. Load testing
8. Documentation

**Deliverables**:
- Full-text search
- Optimized queries
- Complete API documentation
- Performance benchmarks

---

## 📇 Contacts Module

### Contact Repository

**File**: `backend/src/repositories/contact_repository.rs`

```rust
use sqlx::PgPool;
use uuid::Uuid;

use crate::models::contact::{Contact, ContactFilter, ContactResponse, PaginatedContacts};
use crate::utils::ApiError;

pub struct ContactRepository {
    pool: PgPool,
}

impl ContactRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// Create a new contact
    pub async fn create(
        &self,
        first_name: &str,
        last_name: &str,
        email: Option<&str>,
        phone: Option<&str>,
        position: Option<&str>,
        company_id: Option<Uuid>,
        owner_id: Uuid,
        linkedin_url: Option<&str>,
        notes: Option<&str>,
        tags: Option<&[String]>,
    ) -> Result<Contact, ApiError> {
        let contact = sqlx::query_as::<_, Contact>(
            r#"
            INSERT INTO contacts (
                first_name, last_name, email, phone, position,
                company_id, owner_id, linkedin_url, notes, tags
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            RETURNING *
            "#,
        )
        .bind(first_name)
        .bind(last_name)
        .bind(email)
        .bind(phone)
        .bind(position)
        .bind(company_id)
        .bind(owner_id)
        .bind(linkedin_url)
        .bind(notes)
        .bind(tags)
        .fetch_one(&self.pool)
        .await?;

        Ok(contact)
    }

    /// Find contact by ID
    pub async fn find_by_id(&self, id: Uuid) -> Result<Option<Contact>, ApiError> {
        let contact = sqlx::query_as::<_, Contact>(
            r#"
            SELECT * FROM contacts
            WHERE id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(contact)
    }

    /// Find contact by ID with relations
    pub async fn find_by_id_with_relations(
        &self,
        id: Uuid,
    ) -> Result<Option<ContactResponse>, ApiError> {
        let contact = sqlx::query_as::<_, ContactResponse>(
            r#"
            SELECT
                c.*,
                co.name as company_name,
                u.first_name || ' ' || u.last_name as owner_name
            FROM contacts c
            LEFT JOIN companies co ON c.company_id = co.id
            LEFT JOIN users u ON c.owner_id = u.id
            WHERE c.id = $1
            "#,
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await?;

        Ok(contact)
    }

    /// List contacts with pagination and filtering
    pub async fn list(
        &self,
        filter: ContactFilter,
        owner_id: Uuid,
    ) -> Result<PaginatedContacts, ApiError> {
        let page = filter.page.unwrap_or(0).max(0);
        let per_page = filter.per_page.unwrap_or(20).clamp(1, 100);
        let offset = page * per_page;

        // Build dynamic query
        let mut query = String::from(
            r#"
            SELECT
                c.*,
                co.name as company_name,
                u.first_name || ' ' || u.last_name as owner_name
            FROM contacts c
            LEFT JOIN companies co ON c.company_id = co.id
            LEFT JOIN users u ON c.owner_id = u.id
            WHERE c.owner_id = $1
            "#,
        );

        let mut bindings = vec![owner_id.to_string()];
        let mut param_count = 1;

        // Add search filter
        if let Some(search) = &filter.search {
            param_count += 1;
            query.push_str(&format!(
                " AND (c.first_name ILIKE ${} OR c.last_name ILIKE ${} OR c.email ILIKE ${})",
                param_count, param_count, param_count
            ));
            bindings.push(format!("%{}%", search));
        }

        // Add company filter
        if let Some(company_id) = filter.company_id {
            param_count += 1;
            query.push_str(&format!(" AND c.company_id = ${}", param_count));
            bindings.push(company_id.to_string());
        }

        // Add tags filter
        if let Some(tags) = &filter.tags {
            if !tags.is_empty() {
                param_count += 1;
                query.push_str(&format!(" AND c.tags && ${}", param_count));
                // Handle tags array binding
            }
        }

        query.push_str(" ORDER BY c.created_at DESC");
        query.push_str(&format!(" LIMIT {} OFFSET {}", per_page, offset));

        // Execute query (simplified - use sqlx query builder for complex queries)
        let contacts = sqlx::query_as::<_, ContactResponse>(&query)
            .bind(owner_id)
            .fetch_all(&self.pool)
            .await?;

        // Get total count
        let total: i64 = sqlx::query_scalar(
            r#"
            SELECT COUNT(*)
            FROM contacts
            WHERE owner_id = $1
            "#,
        )
        .bind(owner_id)
        .fetch_one(&self.pool)
        .await?;

        let total_pages = (total as f64 / per_page as f64).ceil() as i64;

        Ok(PaginatedContacts {
            data: contacts,
            total,
            page,
            per_page,
            total_pages,
        })
    }

    /// Update contact
    pub async fn update(
        &self,
        id: Uuid,
        first_name: Option<&str>,
        last_name: Option<&str>,
        email: Option<&str>,
        phone: Option<&str>,
        position: Option<&str>,
        company_id: Option<Uuid>,
        linkedin_url: Option<&str>,
        notes: Option<&str>,
        tags: Option<&[String]>,
    ) -> Result<Contact, ApiError> {
        // Build dynamic UPDATE query based on provided fields
        // This is simplified - in production, use a query builder

        let contact = sqlx::query_as::<_, Contact>(
            r#"
            UPDATE contacts
            SET
                first_name = COALESCE($2, first_name),
                last_name = COALESCE($3, last_name),
                email = COALESCE($4, email),
                phone = COALESCE($5, phone),
                position = COALESCE($6, position),
                company_id = COALESCE($7, company_id),
                linkedin_url = COALESCE($8, linkedin_url),
                notes = COALESCE($9, notes),
                tags = COALESCE($10, tags),
                updated_at = NOW()
            WHERE id = $1
            RETURNING *
            "#,
        )
        .bind(id)
        .bind(first_name)
        .bind(last_name)
        .bind(email)
        .bind(phone)
        .bind(position)
        .bind(company_id)
        .bind(linkedin_url)
        .bind(notes)
        .bind(tags)
        .fetch_one(&self.pool)
        .await?;

        Ok(contact)
    }

    /// Delete contact
    pub async fn delete(&self, id: Uuid) -> Result<(), ApiError> {
        let result = sqlx::query("DELETE FROM contacts WHERE id = $1")
            .bind(id)
            .execute(&self.pool)
            .await?;

        if result.rows_affected() == 0 {
            return Err(ApiError::NotFound("Contact not found".to_string()));
        }

        Ok(())
    }

    /// Search contacts
    pub async fn search(
        &self,
        query: &str,
        owner_id: Uuid,
        limit: i64,
    ) -> Result<Vec<ContactResponse>, ApiError> {
        let contacts = sqlx::query_as::<_, ContactResponse>(
            r#"
            SELECT
                c.*,
                co.name as company_name,
                u.first_name || ' ' || u.last_name as owner_name
            FROM contacts c
            LEFT JOIN companies co ON c.company_id = co.id
            LEFT JOIN users u ON c.owner_id = u.id
            WHERE c.owner_id = $1
              AND (
                c.first_name ILIKE $2 OR
                c.last_name ILIKE $2 OR
                c.email ILIKE $2 OR
                c.phone ILIKE $2 OR
                c.position ILIKE $2
              )
            ORDER BY c.created_at DESC
            LIMIT $3
            "#,
        )
        .bind(owner_id)
        .bind(format!("%{}%", query))
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(contacts)
    }

    /// Find duplicates by email
    pub async fn find_duplicates_by_email(
        &self,
        email: &str,
    ) -> Result<Vec<Contact>, ApiError> {
        let contacts = sqlx::query_as::<_, Contact>(
            r#"
            SELECT * FROM contacts
            WHERE email = $1
            "#,
        )
        .bind(email)
        .fetch_all(&self.pool)
        .await?;

        Ok(contacts)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // Add comprehensive tests similar to user_repository tests
    // Test create, read, update, delete, search, pagination, etc.
}
```

### Contact Service

**File**: `backend/src/services/contact_service.rs`

```rust
use uuid::Uuid;

use crate::models::contact::{
    Contact, ContactFilter, CreateContactRequest, PaginatedContacts,
    UpdateContactRequest,
};
use crate::repositories::ContactRepository;
use crate::utils::ApiError;

pub struct ContactService {
    repository: ContactRepository,
}

impl ContactService {
    pub fn new(repository: ContactRepository) -> Self {
        Self { repository }
    }

    /// Create a new contact
    pub async fn create(
        &self,
        request: CreateContactRequest,
        owner_id: Uuid,
    ) -> Result<Contact, ApiError> {
        // Validate email format if provided
        if let Some(ref email) = request.email {
            if !Self::is_valid_email(email) {
                return Err(ApiError::BadRequest("Invalid email format".to_string()));
            }

            // Check for duplicates
            let duplicates = self.repository.find_duplicates_by_email(email).await?;
            if !duplicates.is_empty() {
                tracing::warn!("Duplicate email found: {}", email);
                // Could return error or warning depending on requirements
            }
        }

        // Validate phone format if provided
        if let Some(ref phone) = request.phone {
            if !Self::is_valid_phone(phone) {
                return Err(ApiError::BadRequest("Invalid phone format".to_string()));
            }
        }

        self.repository
            .create(
                &request.first_name,
                &request.last_name,
                request.email.as_deref(),
                request.phone.as_deref(),
                request.position.as_deref(),
                request.company_id,
                owner_id,
                request.linkedin_url.as_deref(),
                request.notes.as_deref(),
                request.tags.as_deref(),
            )
            .await
    }

    /// Get contact by ID
    pub async fn get_by_id(&self, id: Uuid) -> Result<Contact, ApiError> {
        self.repository
            .find_by_id(id)
            .await?
            .ok_or_else(|| ApiError::NotFound("Contact not found".to_string()))
    }

    /// List contacts with pagination
    pub async fn list(
        &self,
        filter: ContactFilter,
        owner_id: Uuid,
    ) -> Result<PaginatedContacts, ApiError> {
        self.repository.list(filter, owner_id).await
    }

    /// Update contact
    pub async fn update(
        &self,
        id: Uuid,
        request: UpdateContactRequest,
        owner_id: Uuid,
    ) -> Result<Contact, ApiError> {
        // Verify contact exists and belongs to user
        let existing = self.get_by_id(id).await?;
        if existing.owner_id != Some(owner_id) {
            return Err(ApiError::Forbidden("Access denied".to_string()));
        }

        // Validate email if being updated
        if let Some(ref email) = request.email {
            if !Self::is_valid_email(email) {
                return Err(ApiError::BadRequest("Invalid email format".to_string()));
            }
        }

        // Validate phone if being updated
        if let Some(ref phone) = request.phone {
            if !Self::is_valid_phone(phone) {
                return Err(ApiError::BadRequest("Invalid phone format".to_string()));
            }
        }

        self.repository
            .update(
                id,
                request.first_name.as_deref(),
                request.last_name.as_deref(),
                request.email.as_deref(),
                request.phone.as_deref(),
                request.position.as_deref(),
                request.company_id,
                request.linkedin_url.as_deref(),
                request.notes.as_deref(),
                request.tags.as_deref(),
            )
            .await
    }

    /// Delete contact
    pub async fn delete(&self, id: Uuid, owner_id: Uuid) -> Result<(), ApiError> {
        // Verify contact exists and belongs to user
        let existing = self.get_by_id(id).await?;
        if existing.owner_id != Some(owner_id) {
            return Err(ApiError::Forbidden("Access denied".to_string()));
        }

        self.repository.delete(id).await
    }

    /// Search contacts
    pub async fn search(
        &self,
        query: &str,
        owner_id: Uuid,
    ) -> Result<Vec<ContactResponse>, ApiError> {
        if query.len() < 2 {
            return Err(ApiError::BadRequest(
                "Search query must be at least 2 characters".to_string(),
            ));
        }

        self.repository.search(query, owner_id, 50).await
    }

    // Helper methods
    fn is_valid_email(email: &str) -> bool {
        // Basic email validation
        email.contains('@') && email.contains('.')
    }

    fn is_valid_phone(phone: &str) -> bool {
        // Basic phone validation
        phone.len() >= 10 && phone.chars().filter(|c| c.is_numeric()).count() >= 10
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_valid_email() {
        assert!(ContactService::is_valid_email("user@example.com"));
        assert!(ContactService::is_valid_email("user.name@example.co.uk"));
        assert!(!ContactService::is_valid_email("invalid"));
        assert!(!ContactService::is_valid_email("@example.com"));
        assert!(!ContactService::is_valid_email("user@"));
    }

    #[test]
    fn test_is_valid_phone() {
        assert!(ContactService::is_valid_phone("+1234567890"));
        assert!(ContactService::is_valid_phone("(123) 456-7890"));
        assert!(ContactService::is_valid_phone("1234567890"));
        assert!(!ContactService::is_valid_phone("123"));
        assert!(!ContactService::is_valid_phone("abc"));
    }
}
```

### Contact Handlers

**File**: `backend/src/handlers/contacts.rs`

```rust
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use uuid::Uuid;

use crate::middleware::AuthUser;
use crate::models::contact::{
    ContactFilter, CreateContactRequest, UpdateContactRequest,
};
use crate::services::ContactService;
use crate::utils::{ApiError, ApiResult};

/// Create contact
pub async fn create_contact(
    State(service): State<ContactService>,
    AuthUser(user): AuthUser,
    Json(request): Json<CreateContactRequest>,
) -> ApiResult<(StatusCode, Json<Contact>)> {
    let contact = service.create(request, user.id).await?;
    Ok((StatusCode::CREATED, Json(contact)))
}

/// Get contact by ID
pub async fn get_contact(
    State(service): State<ContactService>,
    AuthUser(user): AuthUser,
    Path(id): Path<Uuid>,
) -> ApiResult<Json<Contact>> {
    let contact = service.get_by_id(id).await?;

    // Verify ownership
    if contact.owner_id != Some(user.id) {
        return Err(ApiError::Forbidden("Access denied".to_string()));
    }

    Ok(Json(contact))
}

/// List contacts
pub async fn list_contacts(
    State(service): State<ContactService>,
    AuthUser(user): AuthUser,
    Query(filter): Query<ContactFilter>,
) -> ApiResult<Json<PaginatedContacts>> {
    let contacts = service.list(filter, user.id).await?;
    Ok(Json(contacts))
}

/// Update contact
pub async fn update_contact(
    State(service): State<ContactService>,
    AuthUser(user): AuthUser,
    Path(id): Path<Uuid>,
    Json(request): Json<UpdateContactRequest>,
) -> ApiResult<Json<Contact>> {
    let contact = service.update(id, request, user.id).await?;
    Ok(Json(contact))
}

/// Delete contact
pub async fn delete_contact(
    State(service): State<ContactService>,
    AuthUser(user): AuthUser,
    Path(id): Path<Uuid>,
) -> ApiResult<StatusCode> {
    service.delete(id, user.id).await?;
    Ok(StatusCode::NO_CONTENT)
}

/// Search contacts
pub async fn search_contacts(
    State(service): State<ContactService>,
    AuthUser(user): AuthUser,
    Query(params): Query<HashMap<String, String>>,
) -> ApiResult<Json<Vec<ContactResponse>>> {
    let query = params
        .get("q")
        .ok_or_else(|| ApiError::BadRequest("Missing search query".to_string()))?;

    let contacts = service.search(query, user.id).await?;
    Ok(Json(contacts))
}
```

---

## 🧪 Testing

### Integration Tests

**File**: `tests/integration/contacts_test.rs`

```rust
mod common;

use serde_json::json;

#[tokio::test]
async fn test_create_contact() {
    let pool = common::setup_test_db().await;
    let (app, token) = common::setup_authenticated_app(pool.clone()).await;

    let contact_body = json!({
        "first_name": "John",
        "last_name": "Doe",
        "email": "john.doe@example.com",
        "phone": "+1234567890",
        "position": "CEO"
    });

    let response = common::post_json(&app, "/api/v1/contacts", &contact_body, &token).await;

    assert_eq!(response.status(), 201);
    assert!(response.body["id"].is_string());
    assert_eq!(response.body["first_name"], "John");

    common::cleanup_test_db(&pool).await;
}

#[tokio::test]
async fn test_list_contacts_pagination() {
    // Create 25 contacts and test pagination
    // Verify page 0 has 10 items
    // Verify page 1 has 10 items
    // Verify page 2 has 5 items
}

#[tokio::test]
async fn test_update_contact() {
    // Create contact
    // Update some fields
    // Verify changes
    // Verify unchanged fields remain the same
}

#[tokio::test]
async fn test_delete_contact() {
    // Create contact
    // Delete contact
    // Verify 404 on subsequent GET
}

#[tokio::test]
async fn test_search_contacts() {
    // Create multiple contacts
    // Search by first name
    // Search by email
    // Verify results
}
```

---

## 📝 API Documentation

### POST /api/v1/contacts

**Description**: Create a new contact

**Authentication**: Required (Bearer token)

**Request Body**:
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "phone": "+1234567890",
  "position": "CEO",
  "company_id": "550e8400-e29b-41d4-a716-446655440000",
  "linkedin_url": "https://linkedin.com/in/johndoe",
  "notes": "Met at conference",
  "tags": ["vip", "enterprise"]
}
```

**Responses**:
```
201 Created
400 Bad Request - Invalid email format
401 Unauthorized - Missing/invalid token
```

### GET /api/v1/contacts

**Description**: List contacts with pagination

**Query Parameters**:
- `page` (optional): Page number (default: 0)
- `per_page` (optional): Items per page (default: 20, max: 100)
- `search` (optional): Search query
- `company_id` (optional): Filter by company
- `tags` (optional): Filter by tags

**Example**: `/api/v1/contacts?page=0&per_page=20&search=john`

**Response**:
```json
{
  "data": [...],
  "total": 150,
  "page": 0,
  "per_page": 20,
  "total_pages": 8
}
```

---

**Continue to**: `PHASE_3_DEALS_TASKS.md` for implementing deals and task management!
