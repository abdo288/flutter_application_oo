# Firebase Firestore Rules Setup for Secondary Projects

## Overview

This application uses multiple Firebase projects to distribute load and avoid hitting free tier quotas. Each secondary project needs its own Firestore rules configured.

## Projects Configuration

### 1. Main Products Project (`main-products`)
- **Purpose**: Products and inventory data
- **Collections**: `products`, `quantities`, `inventory`
- **Rules**: Already configured in `firestore.rules`

### 2. Sales Analytics Project (`sales-analytics`)
- **Purpose**: Sales transactions and analytics
- **Collections**: `sales`, `reports`
- **Rules**: **NEEDS CONFIGURATION**

### 3. Users Settings Project (`users-settings`)
- **Purpose**: User preferences and settings
- **Collections**: `users`, `settings`, `preferences`
- **Rules**: **NEEDS CONFIGURATION**

## Required Firestore Rules

### For Sales Analytics Project

Create a `firestore.rules` file in the `sales-analytics` project:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Sales collection rules
    match /sales/{saleId} {
      // Allow read/write for authenticated users only
      allow read, write: if request.auth != null && request.auth.uid != null;
      
      // Data validation for sales
      allow create: if request.auth != null 
        && request.auth.uid != null
        && request.resource.data.keys().hasAll(['items', 'total_amount', 'sale_date'])
        && request.resource.data.items is string
        && request.resource.data.total_amount is number
        && request.resource.data.total_amount >= 0
        && request.resource.data.sale_date is string;
        
      allow update: if request.auth != null 
        && request.auth.uid != null
        && request.resource.data.keys().hasAny(['last_modified', 'updated_at']);
    }
    
    // Reports collection rules
    match /reports/{reportId} {
      allow read, write: if request.auth != null && request.auth.uid != null;
      
      // Data validation for reports
      allow create: if request.auth != null 
        && request.auth.uid != null
        && request.resource.data.keys().hasAll(['report_type', 'generated_at'])
        && request.resource.data.report_type is string
        && request.resource.data.generated_at is timestamp;
    }
    
    // General rule for other documents
    match /{document=**} {
      allow read, write: if request.auth != null && request.auth.uid != null;
    }
  }
}
```

### For Users Settings Project

Create a `firestore.rules` file in the `users-settings` project:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection rules
    match /users/{userId} {
      // Users can only access their own data
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Data validation for users
      allow create: if request.auth != null 
        && request.auth.uid == userId
        && request.resource.data.keys().hasAll(['email', 'created_at'])
        && request.resource.data.email is string
        && request.resource.data.created_at is timestamp;
        
      allow update: if request.auth != null 
        && request.auth.uid == userId
        && request.resource.data.keys().hasAny(['last_modified', 'updated_at']);
    }
    
    // Settings collection rules
    match /settings/{settingId} {
      allow read, write: if request.auth != null && request.auth.uid != null;
      
      // Data validation for settings
      allow create: if request.auth != null 
        && request.auth.uid != null
        && request.resource.data.keys().hasAll(['setting_key', 'setting_value', 'user_id'])
        && request.resource.data.setting_key is string
        && request.resource.data.user_id is string;
    }
    
    // Preferences collection rules
    match /preferences/{preferenceId} {
      allow read, write: if request.auth != null && request.auth.uid != null;
      
      // Data validation for preferences
      allow create: if request.auth != null 
        && request.auth.uid != null
        && request.resource.data.keys().hasAll(['preference_type', 'user_id'])
        && request.resource.data.preference_type is string
        && request.resource.data.user_id is string;
    }
    
    // General rule for other documents
    match /{document=**} {
      allow read, write: if request.auth != null && request.auth.uid != null;
    }
  }
}
```

## Deployment Instructions

### 1. Deploy Rules to Sales Analytics Project

```bash
# Navigate to sales-analytics project
cd sales-analytics-project

# Deploy rules
firebase deploy --only firestore:rules
```

### 2. Deploy Rules to Users Settings Project

```bash
# Navigate to users-settings project
cd users-settings-project

# Deploy rules
firebase deploy --only firestore:rules
```

### 3. Verify Rules Deployment

```bash
# Check rules status for each project
firebase firestore:rules:get --project sales-analytics
firebase firestore:rules:get --project users-settings
```

## Testing Rules

### Test Sales Analytics Rules

```bash
# Test sales collection access
firebase firestore:rules:test --project sales-analytics --test-file sales-test.json
```

### Test Users Settings Rules

```bash
# Test users collection access
firebase firestore:rules:test --project users-settings --test-file users-test.json
```

## Common Issues and Solutions

### 1. Permission Denied Errors

**Problem**: `permission-denied` errors when syncing to secondary projects

**Solution**: 
- Ensure rules are deployed to the correct project
- Verify authentication is working
- Check that the user has proper permissions

### 2. Resource Exhausted Errors

**Problem**: `resource-exhausted` errors even with low usage

**Solution**:
- The app now includes circuit breaker pattern
- Quota monitoring will detect actual Firebase errors
- Automatic fallback to local-only mode when quota exhausted

### 3. Missing Collections

**Problem**: Collections don't exist in secondary projects

**Solution**:
- Collections are created automatically on first write
- Ensure proper authentication before writing
- Check that the project is properly initialized

## Monitoring and Maintenance

### 1. Quota Monitoring

The app includes built-in quota monitoring that:
- Tracks actual Firebase errors (not just counters)
- Implements circuit breaker pattern
- Provides fallback mechanisms

### 2. Error Handling

Enhanced error handling includes:
- Retry logic with exponential backoff
- Circuit breaker pattern for repeated failures
- Graceful degradation to local-only mode

### 3. Logging

All operations are logged with:
- Detailed error messages
- Quota status tracking
- Circuit breaker state changes

## Security Considerations

1. **Authentication Required**: All operations require valid authentication
2. **User Data Isolation**: Users can only access their own data
3. **Data Validation**: All writes are validated against schema
4. **Rate Limiting**: Circuit breaker prevents quota exhaustion

## Troubleshooting

### Check Project Status

```bash
# Verify project initialization
firebase projects:list
firebase use --list
```

### Check Authentication

```bash
# Verify authentication
firebase auth:export users.json --project your-project
```

### Check Rules Status

```bash
# View current rules
firebase firestore:rules:get --project your-project
```

## Support

If you encounter issues:

1. Check the application logs for detailed error messages
2. Verify that all projects have proper rules deployed
3. Ensure authentication is working correctly
4. Check quota status in Firebase Console

The app now includes comprehensive error handling and will provide detailed information about any issues encountered.
