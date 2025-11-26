# DevOps Monorepo - Cursor Rules

## Project Structure
- This is a monorepo containing multiple applications under `apps/` directory
- Each application should be organized in domain-specific subdirectories (e.g., `apps/slack-app/`, `apps/data-app/`)
- Follow conventional project structure for each technology stack

## Go Development Guidelines

### Code Style
- Follow standard Go conventions and formatting
- Use `gofmt` and `goimports` for formatting
- Use `golangci-lint` for linting
- Prefer composition over inheritance
- Keep functions small and focused (max 50 lines)
- Use meaningful variable and function names
- Add comments for exported functions and types

### Error Handling
- Always handle errors explicitly
- Use wrapped errors with context: `fmt.Errorf("operation failed: %w", err)`
- Prefer returning errors over panics
- Log errors at the point where they are handled
- Use custom error types for domain-specific errors

### Testing
- Write unit tests for all public functions
- Use table-driven tests for multiple test cases
- Aim for 80%+ test coverage
- Use dependency injection for testability
- Mock external dependencies
- Test error cases and edge conditions

### Project Structure for Go Apps
```
app-name/
├── main.go              # Application entry point
├── handlers/            # HTTP handlers (if web app)
├── services/            # Business logic
├── models/             # Data models
├── config/             # Configuration handling
├── internal/           # Private application code
├── pkg/               # Shared packages
├── go.mod             # Module definition
├── go.sum             # Dependency checksums
├── Dockerfile         # Container configuration
├── Makefile          # Build automation
└── README.md         # Documentation
```

## TypeScript/Node.js Guidelines

### Code Style
- Use TypeScript for all new code
- Follow ESLint and Prettier configurations
- Use meaningful interfaces and types
- Prefer `const` over `let`, avoid `var`
- Use async/await over Promise chains
- Use barrel exports for clean imports

### Error Handling
- Use proper error types
- Handle promises with proper error catching
- Use Result types for operations that can fail
- Log errors with appropriate context

### Testing
- Use Jest for unit testing
- Write tests for all business logic
- Use supertest for API endpoint testing
- Mock external dependencies properly

## Docker Guidelines

### Dockerfile Best Practices
- Use multi-stage builds for optimization
- Use specific base image versions, not `latest`
- Minimize layer count and image size
- Use `.dockerignore` to exclude unnecessary files
- Run as non-root user when possible
- Use HEALTHCHECK for container monitoring
- Set proper labels for metadata

### Example Multi-stage Dockerfile Structure
```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Production stage
FROM node:18-alpine AS production
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
USER node
CMD ["npm", "start"]
```

## Documentation Standards

### README Files
- Include project description and purpose
- Document installation and setup steps
- Provide usage examples
- Include API documentation for services
- Document environment variables
- Include troubleshooting section
- Use emojis and clear structure for readability

### Code Comments
- Comment the "why" not the "what"
- Use JSDoc/GoDoc style comments
- Document complex algorithms
- Include examples in function comments

## Git Workflow

### Branch Naming
- `feature/INFRA-123-description` for new features
- `bugfix/INFRA-123-description` for bug fixes
- `hotfix/INFRA-123-description` for urgent fixes
- `chore/description` for maintenance tasks

### Commit Messages
- Use conventional commits format
- Start with type: `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `test:`, `chore:`
- Include JIRA ticket number: `feat(slack-bot): add deployment command [INFRA-123]`
- Keep first line under 50 characters
- Add detailed description if needed

### Pull Request Guidelines
- Use the provided PR template
- Include JIRA ticket link: `@https://demo.atlassian.net/browse/INFRA-{JIRA_NUMBER}`
- Ensure all tests pass
- Get at least one approval before merging
- Squash commits when merging

## Security Guidelines

### Secrets Management
- Never commit secrets to the repository
- Use environment variables for configuration
- Use `.env.example` files for documenting required variables
- Use proper secret management services in production

### Dependencies
- Keep dependencies up to date
- Use dependency scanning tools
- Review security advisories regularly
- Use lock files (`package-lock.json`, `go.sum`)

## CI/CD Guidelines

### GitHub Actions
- Use matrix builds for multiple environments
- Include linting, testing, and security scans
- Use proper caching for dependencies
- Deploy only from main branch
- Use environment-specific secrets

### Deployment
- Use infrastructure as code
- Document deployment procedures
- Use blue-green or rolling deployments
- Include health checks and rollback procedures

## Performance Guidelines

### General
- Profile before optimizing
- Use appropriate data structures
- Implement proper caching strategies
- Monitor memory usage
- Use connection pooling for databases

### Go Specific
- Use goroutines for concurrent operations
- Implement proper context cancellation
- Use buffered channels appropriately
- Profile with `go tool pprof`

### Node.js Specific
- Use streaming for large data processing
- Implement proper connection pooling
- Use clustering for CPU-intensive tasks
- Monitor event loop lag

## Monitoring and Logging

### Logging
- Use structured logging (JSON format)
- Include correlation IDs for request tracing
- Log at appropriate levels (DEBUG, INFO, WARN, ERROR)
- Don't log sensitive information
- Use consistent log formats across services

### Metrics
- Implement health check endpoints
- Monitor key performance indicators
- Use proper alerting thresholds
- Include business metrics, not just technical ones

## File Organization

### Naming Conventions
- Use kebab-case for file and directory names
- Use PascalCase for Go types and interfaces
- Use camelCase for Go functions and variables
- Use UPPER_SNAKE_CASE for constants and environment variables

### Directory Structure
- Keep related files together
- Use `internal/` for private packages in Go
- Separate configuration files into `config/` directory
- Keep documentation in `docs/` directory
- Store scripts in `scripts/` directory

## Development Environment

### Required Tools
- Go 1.21+ for Go applications
- Node.js 18+ for JavaScript/TypeScript applications
- Docker and Docker Compose
- Git
- Make (for build automation)
- Your preferred IDE with appropriate extensions

### IDE Configuration
- Install language-specific extensions
- Configure auto-formatting on save
- Set up linting integration
- Use debugging tools appropriately

## Code Review Guidelines

### Reviewers Should Check
- Code follows established patterns
- Tests are comprehensive and meaningful
- Security considerations are addressed
- Performance implications are considered
- Documentation is updated
- Breaking changes are documented

### Authors Should
- Keep PRs small and focused
- Write descriptive commit messages
- Add appropriate tests
- Update documentation
- Respond to feedback promptly

## Deployment Guidelines

### Environment Management
- Use separate environments for dev, staging, and production
- Environment-specific configuration through environment variables
- Automate deployments through CI/CD pipelines
- Implement proper health checks and monitoring

### Database Changes
- Use migrations for schema changes
- Test migrations in staging first
- Plan for rollback procedures
- Document breaking changes

This document should be followed by all team members and updated as the project evolves. 