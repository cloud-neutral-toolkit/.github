# Security Best Practices Guide

**Version**: 1.0.0  
**Last Updated**: 2026-01-30  
**Audience**: All Developers

## Table of Contents

1. [Secrets Management](#secrets-management)
2. [Token Transmission](#token-transmission)
3. [Logging Security](#logging-security)
4. [Error Handling](#error-handling)
5. [Environment Variables](#environment-variables)
6. [API Security](#api-security)
7. [Database Security](#database-security)
8. [CI/CD Security](#cicd-security)

---

## Secrets Management

### ✅ Best Practices

#### 1. Never Hardcode Secrets

```typescript
// ❌ BAD - Hardcoded secret
const apiKey = "sk_live_abc123def456..."

// ✅ GOOD - Environment variable
const apiKey = process.env.API_KEY
if (!apiKey) {
  throw new Error('API_KEY environment variable is required')
}
```

#### 2. Use Secrets Management Services

**Cloud Run / Google Cloud**:
```bash
# Store secret
gcloud secrets create api-key --data-file=-

# Grant access
gcloud secrets add-iam-policy-binding api-key \
  --member="serviceAccount:SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor"

# Use in Cloud Run
gcloud run deploy SERVICE \
  --update-secrets=API_KEY=api-key:latest
```

**AWS Secrets Manager**:
```typescript
import { SecretsManager } from '@aws-sdk/client-secrets-manager'

const client = new SecretsManager({ region: 'us-east-1' })
const secret = await client.getSecretValue({ SecretId: 'api-key' })
const apiKey = secret.SecretString
```

#### 3. Rotate Secrets Regularly

- **Production**: Every 90 days
- **Staging**: Every 180 days
- **Development**: Annually or when team members leave

### ❌ Common Mistakes

```typescript
// ❌ Committing .env files
git add .env  // NEVER DO THIS

// ❌ Logging secrets
console.log('API Key:', apiKey)  // NEVER DO THIS

// ❌ Secrets in URLs
fetch(`/api?key=${apiKey}`)  // NEVER DO THIS

// ❌ Secrets in error messages
throw new Error(`Invalid API key: ${apiKey}`)  // NEVER DO THIS
```

---

## Token Transmission

### ✅ Best Practices

#### 1. Always Use HTTP Headers

```typescript
// ✅ GOOD - Token in header
const response = await fetch('/api/data', {
  headers: {
    'Authorization': `Bearer ${accessToken}`,
    'X-Service-Token': serviceToken,
  }
})
```

#### 2. Never Use URL Parameters

```typescript
// ❌ BAD - Token in URL
fetch(`/api/data?token=${token}`)

// ❌ BAD - Token in query string
const url = new URL('/api/data', base)
url.searchParams.set('token', token)  // NEVER DO THIS
```

#### 3. Use HTTPS Only

```typescript
// ✅ GOOD - Enforce HTTPS
if (url.protocol !== 'https:' && process.env.NODE_ENV === 'production') {
  throw new Error('HTTPS required in production')
}
```

#### 4. Implement Token Validation

**Backend (Go)**:
```go
func InternalAuthMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        serviceToken := c.GetHeader("X-Service-Token")
        if serviceToken == "" {
            c.JSON(401, gin.H{"error": "missing service token"})
            c.Abort()
            return
        }

        expectedToken := os.Getenv("INTERNAL_SERVICE_TOKEN")
        if serviceToken != expectedToken {
            c.JSON(401, gin.H{"error": "invalid service token"})
            c.Abort()
            return
        }

        c.Next()
    }
}
```

---

## Logging Security

### ✅ Best Practices

#### 1. Sanitize Logs

```typescript
// ❌ BAD - Logging sensitive data
console.log('User:', user)  // May contain tokens

// ✅ GOOD - Sanitized logging
console.log('User:', { id: user.id, email: user.email })
```

#### 2. Redact Sensitive Fields

```typescript
// ✅ GOOD - Redaction utility
function sanitizeForLog(obj: any): any {
  const sensitive = ['password', 'token', 'apiKey', 'secret', 'authorization']
  const sanitized = { ...obj }
  
  for (const key of Object.keys(sanitized)) {
    if (sensitive.some(s => key.toLowerCase().includes(s))) {
      sanitized[key] = '***REDACTED***'
    }
  }
  
  return sanitized
}

console.log('Request:', sanitizeForLog(request))
```

#### 3. Use Log Levels Appropriately

```typescript
// ✅ GOOD - Appropriate log levels
logger.debug('Request headers:', sanitizeForLog(headers))  // Debug only
logger.info('User authenticated', { userId: user.id })     // Info
logger.error('Authentication failed', { reason: 'invalid_token' })  // Error
```

#### 4. Production Logging

```typescript
// ✅ GOOD - Environment-aware logging
if (process.env.NODE_ENV === 'development') {
  console.log('Full request:', request)
} else {
  logger.info('Request received', { path: request.path, method: request.method })
}
```

---

## Error Handling

### ✅ Best Practices

#### 1. Generic Error Messages

```typescript
// ❌ BAD - Exposing details
throw new Error(`Invalid token: ${token}`)

// ✅ GOOD - Generic message
throw new Error('Authentication failed')
```

#### 2. Separate Internal and External Errors

```typescript
// ✅ GOOD - Error handling
class AppError extends Error {
  constructor(
    public message: string,
    public statusCode: number,
    public internalMessage?: string
  ) {
    super(message)
  }
}

// Usage
try {
  validateToken(token)
} catch (error) {
  // Log internal details
  logger.error('Token validation failed', { 
    error: error.message,
    tokenPrefix: token.substring(0, 8) 
  })
  
  // Return generic message to client
  return res.status(401).json({ 
    error: 'Authentication failed' 
  })
}
```

#### 3. Avoid Stack Traces in Production

```typescript
// ✅ GOOD - Environment-aware error responses
app.use((err, req, res, next) => {
  logger.error('Unhandled error', { error: err })
  
  res.status(err.statusCode || 500).json({
    error: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  })
})
```

---

## Environment Variables

### ✅ Best Practices

#### 1. Use .env Files Locally

```bash
# .env (NEVER commit this file)
DATABASE_URL=postgresql://localhost:5432/mydb
API_KEY=your_api_key_here
INTERNAL_SERVICE_TOKEN=your_token_here
```

#### 2. Always Add .env to .gitignore

```bash
# .gitignore
.env
.env.local
.env.*.local
.env.production
*.env
```

#### 3. Provide .env.example

```bash
# .env.example (safe to commit)
DATABASE_URL=postgresql://localhost:5432/dbname
API_KEY=your_api_key_here
INTERNAL_SERVICE_TOKEN=generate_with_openssl_rand
```

#### 4. Validate Environment Variables

```typescript
// ✅ GOOD - Validation on startup
const requiredEnvVars = [
  'DATABASE_URL',
  'API_KEY',
  'INTERNAL_SERVICE_TOKEN'
]

for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    throw new Error(`Missing required environment variable: ${envVar}`)
  }
}
```

---

## API Security

### ✅ Best Practices

#### 1. Rate Limiting

```typescript
import rateLimit from 'express-rate-limit'

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP'
})

app.use('/api/', limiter)
```

#### 2. Input Validation

```typescript
import { z } from 'zod'

const userSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8)
})

app.post('/api/register', async (req, res) => {
  try {
    const data = userSchema.parse(req.body)
    // Process validated data
  } catch (error) {
    return res.status(400).json({ error: 'Invalid input' })
  }
})
```

#### 3. CORS Configuration

```typescript
import cors from 'cors'

app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || 'http://localhost:3000',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Service-Token']
}))
```

---

## Database Security

### ✅ Best Practices

#### 1. Use Parameterized Queries

```typescript
// ❌ BAD - SQL Injection vulnerability
const query = `SELECT * FROM users WHERE email = '${email}'`

// ✅ GOOD - Parameterized query
const query = 'SELECT * FROM users WHERE email = $1'
const result = await db.query(query, [email])
```

#### 2. Encrypt Sensitive Data

```typescript
import bcrypt from 'bcrypt'

// ✅ GOOD - Hash passwords
const hashedPassword = await bcrypt.hash(password, 10)

// ✅ GOOD - Verify passwords
const isValid = await bcrypt.compare(password, hashedPassword)
```

#### 3. Use TLS for Database Connections

```typescript
// ✅ GOOD - TLS connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: true,
    ca: fs.readFileSync('/path/to/ca-cert.pem')
  }
})
```

---

## CI/CD Security

### ✅ Best Practices

#### 1. Use Secrets in CI/CD

**GitHub Actions**:
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy
        env:
          API_KEY: ${{ secrets.API_KEY }}
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
        run: |
          npm run deploy
```

#### 2. Scan for Secrets

```yaml
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Security Audit
        run: |
          chmod +x ./skills/security-audit/scripts/quick-audit.sh
          ./skills/security-audit/scripts/quick-audit.sh
```

#### 3. Dependency Scanning

```yaml
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run npm audit
        run: npm audit --audit-level=high
```

---

## Quick Reference Checklist

### Before Every Commit

- [ ] No hardcoded secrets
- [ ] .env files not committed
- [ ] Tokens only in HTTP headers
- [ ] No sensitive data in logs
- [ ] Generic error messages
- [ ] Run security audit: `./skills/security-audit/scripts/quick-audit.sh`

### Before Deployment

- [ ] Environment variables configured
- [ ] Secrets in secrets manager
- [ ] HTTPS enabled
- [ ] Rate limiting configured
- [ ] Input validation implemented
- [ ] Security headers configured

### Regular Maintenance

- [ ] Rotate secrets quarterly
- [ ] Update dependencies monthly
- [ ] Review access logs weekly
- [ ] Audit permissions quarterly
- [ ] Security training annually

---

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [Google Cloud Security Best Practices](https://cloud.google.com/security/best-practices)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)

## Support

For security concerns or questions:
- Email: security@svc.plus
- GitHub: https://github.com/cloud-neutral-toolkit/.github/issues
- Emergency: Contact security team immediately
