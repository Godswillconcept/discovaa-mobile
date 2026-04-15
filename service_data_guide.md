# Service Data Guide

This guide contains all the data specifications for creating and managing services in the Discovaa app, based on the Discovaa API specification.

---

## Table of Contents

1. [Data Models](#data-models)
   - [Service](#service)
   - [ServiceCategory](#servicecategory)
2. [API Endpoints](#api-endpoints)
3. [Field Descriptions & Validation](#field-descriptions--validation)
4. [Enum Values](#enum-values)
5. [Implementation Examples](#implementation-examples)

---

## Data Models

### Service

Represents a service offered by a provider.

#### Read Model (API Response)

```json
{
  "id": "uuid",
  "provider": "uuid",
  "category": "uuid | null",
  "title": "string (max 255 chars)",
  "description": "string",
  "pricing_model": "FIXED | HOURLY | PACKAGE",
  "price_type": "FIXED | VARIABLE",
  "price_amount": "decimal | null",
  "price_min_amount": "decimal | null",
  "price_max_amount": "decimal | null",
  "currency": "string (3 chars)",
  "duration_minutes": "integer | null",
  "is_active": "boolean",
  "media": ["uuid array"],
  "created_at": "datetime (ISO 8601)",
  "updated_at": "datetime (ISO 8601)"
}
```

#### Write Model (Create/Update)

```json
{
  "category": "uuid | null",
  "title": "string (required, max 255 chars)",
  "description": "string",
  "pricing_model": "FIXED | HOURLY | PACKAGE",
  "price_type": "FIXED | VARIABLE",
  "price_amount": "decimal | null",
  "price_min_amount": "decimal | null",
  "price_max_amount": "decimal | null",
  "currency": "string (3 chars)",
  "duration_minutes": "integer | null",
  "is_active": "boolean"
}
```

### ServiceCategory

Represents a category for organizing services (hierarchical).

```json
{
  "id": "uuid",
  "name": "string (max 255 chars)",
  "slug": "string (max 255, pattern: [-a-zA-Z0-9_]+)",
  "picture": "url | null",
  "parent": "uuid | null",
  "children": ["uuid array"],
  "is_active": "boolean",
  "created_at": "datetime (ISO 8601)",
  "updated_at": "datetime (ISO 8601)"
}
```

---

## API Endpoints

### Services

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/services/` | List all services | Optional |
| POST | `/api/services/` | Create new service | Yes |
| GET | `/api/services/{id}/` | Get service details | Optional |
| PUT | `/api/services/{id}/` | Update service | Yes |
| PATCH | `/api/services/{id}/` | Partial update | Yes |
| DELETE | `/api/services/{id}/` | Delete service | Yes |
| GET | `/api/services/featured/` | Get featured service | Optional |

#### Query Parameters for List Endpoint

| Parameter | Type | Description |
|-----------|------|-------------|
| `category` | uuid | Filter by category |
| `currency` | string | Filter by currency |
| `is_active` | boolean | Filter by active status |
| `pricing_model` | enum | Filter by pricing model (FIXED, HOURLY, PACKAGE) |
| `provider` | uuid | Filter by provider |
| `search` | string | Search term |
| `ordering` | string | Field to order by |
| `page` | integer | Page number |
| `page_size` | integer | Items per page |

### Service Categories

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/service-categories/` | List all categories | Optional |
| POST | `/api/service-categories/` | Create category | Yes |
| GET | `/api/service-categories/{id}/` | Get category details | Optional |
| PUT | `/api/service-categories/{id}/` | Update category | Yes |
| PATCH | `/api/service-categories/{id}/` | Partial update | Yes |
| DELETE | `/api/service-categories/{id}/` | Delete category | Yes |

#### Query Parameters for Categories

| Parameter | Type | Description |
|-----------|------|-------------|
| `search` | string | Search term |
| `ordering` | string | Field to order by |
| `page` | integer | Page number |
| `page_size` | integer | Items per page |

---

## Field Descriptions & Validation

### Service Fields

| Field | Type | Required | Validation Rules | Description |
|-------|------|----------|------------------|-------------|
| `id` | UUID | Auto | Read-only | Unique identifier |
| `provider` | UUID | Yes | - | Provider offering this service |
| `category` | UUID | No | Nullable | Service category |
| `title` | String | Yes | Max 255 chars | Service name |
| `description` | String | No | - | Detailed description |
| `pricing_model` | Enum | No | FIXED, HOURLY, PACKAGE | How pricing is calculated |
| `price_type` | Enum | No | FIXED, VARIABLE | Whether price is fixed or variable |
| `price_amount` | Decimal | No | Max 10 digits, 2 decimals, nullable | Fixed price amount |
| `price_min_amount` | Decimal | No | Max 10 digits, 2 decimals, nullable | Minimum price (for VARIABLE) |
| `price_max_amount` | Decimal | No | Max 10 digits, 2 decimals, nullable | Maximum price (for VARIABLE) |
| `currency` | String | No | Max 3 chars (e.g., USD, EUR, NGN) | Currency code |
| `duration_minutes` | Integer | No | Min 0, nullable | Estimated duration |
| `is_active` | Boolean | No | Default: true | Whether service is active |
| `media` | UUID[] | Yes | Array of media IDs | Associated media files |
| `created_at` | DateTime | Auto | ISO 8601, read-only | Creation timestamp |
| `updated_at` | DateTime | Auto | ISO 8601, read-only | Last update timestamp |

### ServiceCategory Fields

| Field | Type | Required | Validation Rules | Description |
|-------|------|----------|------------------|-------------|
| `id` | UUID | Auto | Read-only | Unique identifier |
| `name` | String | Yes | Max 255 chars | Category name |
| `slug` | String | Yes | Max 255, pattern: `[-a-zA-Z0-9_]+` | URL-friendly identifier |
| `picture` | URL | No | Nullable | Category image URL |
| `parent` | UUID | No | Nullable | Parent category (for hierarchy) |
| `children` | UUID[] | Auto | Array of child category IDs | Sub-categories |
| `is_active` | Boolean | No | Default: true | Whether category is active |
| `created_at` | DateTime | Auto | ISO 8601, read-only | Creation timestamp |
| `updated_at` | DateTime | Auto | ISO 8601, read-only | Last update timestamp |

---

## Enum Values

### PricingModel

| Value | Description | Use Case |
|-------|-------------|----------|
| `FIXED` | Fixed price | One-time flat fee |
| `HOURLY` | Hourly rate | Time-based billing |
| `PACKAGE` | Package deal | Bundled services |

### PriceType

| Value | Description | Use Case |
|-------|-------------|----------|
| `FIXED` | Fixed price | Exact price known upfront |
| `VARIABLE` | Variable price | Price range (use min/max) |

---

## Implementation Examples

### Example Service Data (Create)

```json
{
  "title": "House Cleaning Service",
  "description": "Professional house cleaning including dusting, vacuuming, and sanitizing.",
  "category": "550e8400-e29b-41d4-a716-446655440000",
  "pricing_model": "HOURLY",
  "price_type": "FIXED",
  "price_amount": "25.00",
  "currency": "USD",
  "duration_minutes": 120,
  "is_active": true
}
```

### Example Service Data (Variable Price)

```json
{
  "title": "Interior Design Consultation",
  "description": "Personalized interior design consultation for your home or office.",
  "category": "550e8400-e29b-41d4-a716-446655440001",
  "pricing_model": "FIXED",
  "price_type": "VARIABLE",
  "price_min_amount": "150.00",
  "price_max_amount": "500.00",
  "currency": "USD",
  "duration_minutes": 60,
  "is_active": true
}
```

### Example ServiceCategory Data

```json
{
  "name": "Home Services",
  "slug": "home-services",
  "picture": "https://example.com/images/home-services.jpg",
  "parent": null,
  "is_active": true
}
```

### Example ServiceCategory with Parent

```json
{
  "name": "Cleaning",
  "slug": "cleaning",
  "picture": "https://example.com/images/cleaning.jpg",
  "parent": "550e8400-e29b-41d4-a716-446655440000",
  "is_active": true
}
```

---

## Flutter/Dart Implementation Notes

### Data Classes Structure

```dart
// Service Entity
class Service {
  final String id;
  final String provider;
  final String? category;
  final String title;
  final String? description;
  final PricingModel pricingModel;
  final PriceType priceType;
  final Decimal? priceAmount;
  final Decimal? priceMinAmount;
  final Decimal? priceMaxAmount;
  final String? currency;
  final int? durationMinutes;
  final bool isActive;
  final List<String> media;
  final DateTime createdAt;
  final DateTime updatedAt;
}

// Service Category Entity
class ServiceCategory {
  final String id;
  final String name;
  final String slug;
  final String? picture;
  final String? parent;
  final List<String> children;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}

// Enums
enum PricingModel { fixed, hourly, package }
enum PriceType { fixed, variable }
```

### API Response Wrapper

All API responses follow this structure:

```dart
class ApiResponse<T> {
  final bool success;
  final T data;
  final Meta? meta;
  final Error? error;
}

class Meta {
  final Pagination? pagination;
}

class Pagination {
  final int count;
  final String? next;
  final String? previous;
}
```

---

## Validation Rules Summary

### Before Submitting Service Data:

1. **Title**: Required, max 255 characters
2. **Price Amount**: Must match pattern `^-?\d{0,10}(?:\.\d{0,2})?$`
3. **Currency**: Max 3 characters (standard ISO codes)
4. **Duration**: Must be >= 0 if provided
5. **Category**: Must be valid UUID if provided
6. **Pricing Logic**:
   - If `price_type` = FIXED → use `price_amount`
   - If `price_type` = VARIABLE → use `price_min_amount` and `price_max_amount`

### Before Submitting Category Data:

1. **Name**: Required, max 255 characters
2. **Slug**: Required, must match pattern `[-a-zA-Z0-9_]+` (URL-safe)
3. **Parent**: Must be valid UUID if provided (self-reference for hierarchy)
4. **Picture**: Must be valid URL if provided

---

## Error Handling

Common HTTP Status Codes:

| Code | Meaning | Action |
|------|---------|--------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Validation error - check field values |
| 401 | Unauthorized | Authentication required |
| 403 | Forbidden | Not authorized for this action |
| 404 | Not Found | Resource doesn't exist |
| 500 | Server Error | Retry or contact support |

---

*Generated from Discovaa API Specification*
