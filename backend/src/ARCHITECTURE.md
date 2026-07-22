# Clean Architecture Refactoring Guide

## Overview

This document describes the Clean Architecture refactoring applied to the Diocese Booking System backend.

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    Frameworks & Drivers                      │
│  (Express, Sequelize, Multer, Nodemailer, Passport)         │
├─────────────────────────────────────────────────────────────┤
│                   Interface Adapters                         │
│  (Controllers, DTOs, Request/Response Validators)           │
├─────────────────────────────────────────────────────────────┤
│                Application Business Rules                    │
│  (Use Cases - Single Responsibility Operations)             │
├─────────────────────────────────────────────────────────────┤
│                 Enterprise Business Rules                    │
│  (Domain Entities, Business Objects)                        │
└─────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
src/
├── config/              # Configuration files (database, etc.)
├── container/           # Dependency Injection Container
│   └── index.js
├── controllers/         # Interface Adapters - HTTP layer
│   ├── massIntentionController.js
│   └── ...
├── dto/                 # Data Transfer Objects
│   ├── MassIntentionDTO.js
│   └── ...
├── middleware/          # Express middleware
├── models/              # Domain Models (Sequelize)
├── repositories/        # Data Access Layer
│   ├── interfaces/      # Repository contracts
│   │   ├── IMassIntentionRepository.js
│   │   └── IParishRepository.js
│   ├── implementations/ # Repository implementations
│   │   ├── MassIntentionRepository.js
│   │   └── ParishRepository.js
│   └── index.js
├── routes/              # API route definitions
├── services/            # External services (email, file, etc.)
├── useCases/            # Application Business Logic
│   ├── massIntention/
│   │   ├── CreateMassIntentionUseCase.js
│   │   ├── GetAllMassIntentionsUseCase.js
│   │   └── ...
│   └── index.js
├── utils/               # Utility functions
└── app.js
```

## Key Concepts

### 1. **Repository Pattern**

Repositories abstract database operations behind interfaces:

```javascript
// Interface (contract)
class IMassIntentionRepository {
  async create(dto) { throw new Error('Not implemented'); }
  async findById(id) { throw new Error('Not implemented'); }
  async findAll(options) { throw new Error('Not implemented'); }
  async update(id, data) { throw new Error('Not implemented'); }
  async delete(id) { throw new Error('Not implemented'); }
}

// Implementation
class MassIntentionRepository {
  async create(dto) {
    const entity = await MassIntention.create(dto);
    return MassIntentionDTO.fromEntity(entity);
  }
  // ... other methods
}
```

**Benefits:**
- Easy to swap database implementations
- Simplifies testing (mock repositories)
- Centralizes data access logic

### 2. **Data Transfer Objects (DTOs)**

DTOs encapsulate data transfer between layers:

```javascript
class MassIntentionDTO {
  constructor({ id, type, intentionDetails, donorName, ... }) {
    this.id = id;
    this.type = type;
    // ...
  }

  static fromRequest(body) {
    return new this({
      type: body.type,
      intentionDetails: body.intentionDetails,
      // ...
    });
  }

  static fromEntity(entity) {
    return new this({
      id: entity.id,
      type: entity.type,
      // ...
    });
  }

  validate() {
    const errors = [];
    if (!this.type) errors.push('Type required');
    return { isValid: errors.length === 0, errors };
  }

  getAllowedUpdates(allowedFields) {
    // Returns only fields user is allowed to update
  }
}
```

**Benefits:**
- Consistent data format across layers
- Built-in validation
- Prevents over-posting attacks

### 3. **Use Cases**

Use cases contain application business logic with single responsibility:

```javascript
class CreateMassIntentionUseCase {
  constructor(massIntentionRepository, parishRepository, emailService) {
    this.massIntentionRepository = massIntentionRepository;
    this.parishRepository = parishRepository;
    this.emailService = emailService;
  }

  async execute(dto, user) {
    // 1. Validate input
    const validation = dto.validate();
    if (!validation.isValid) throw new Error(validation.errors);

    // 2. Verify parish exists
    const parish = await this.parishRepository.findById(dto.parishId);
    if (!parish) throw new Error('Parish not found');

    // 3. Set additional fields
    dto.userId = user.userId;
    dto.status = 'pending';

    // 4. Create intention
    const result = await this.massIntentionRepository.create(dto);

    // 5. Send notification (non-blocking)
    this._sendConfirmationEmail(user, result);

    return result;
  }
}
```

**Benefits:**
- Single responsibility (easy to test)
- Clear business logic location
- Reusable across different interfaces (web, mobile, CLI)

### 4. **Dependency Injection Container**

The container wires dependencies together:

```javascript
class Container {
  initialize() {
    // Repositories
    this.massIntentionRepository = new MassIntentionRepository();
    this.parishRepository = new ParishRepository();

    // Use Cases
    this.createMassIntentionUseCase = new CreateMassIntentionUseCase(
      this.massIntentionRepository,
      this.parishRepository,
      emailService
    );
  }

  get(name) {
    if (!this._initialized) this.initialize();
    return this._instances[name];
  }
}
```

**Benefits:**
- Centralized dependency management
- Easy testing (swap with mocks)
- Lazy initialization

### 5. **Refactored Controller**

Controllers become thin adapters:

```javascript
// BEFORE (150+ lines of mixed logic)
exports.createMassIntention = async (req, res, next) => {
  // Validation, business logic, DB calls, email sending - all mixed!
};

// AFTER (20 lines - clean!)
exports.createMassIntention = async (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ error: 'Validation failed', details: errors.array() });
  }

  const dto = MassIntentionDTO.fromRequest(req.body);
  const useCase = container.get('createMassIntentionUseCase');
  const result = await useCase.execute(dto, req.user);

  res.status(201).json({ message: 'Success', massIntention: result.toObject() });
};
```

## Migration Status

| Module | Repository | DTO | Use Cases | Controller | Status |
|--------|------------|-----|-----------|------------|--------|
| Mass Intention | ✅ | ✅ | ✅ | ✅ | Complete |
| Auth | ⏳ | ⏳ | ⏳ | ⏳ | Pending |
| Parish | ⏳ | ⏳ | ⏳ | ⏳ | Partial |
| Booking | ⏳ | ⏳ | ⏳ | ⏳ | Pending |
| User | ⏳ | ⏳ | ⏳ | ⏳ | Pending |

## Adding New Modules

Follow this pattern for new features:

### Step 1: Create Repository Interface

```javascript
// repositories/interfaces/IDocumentRequestRepository.js
class IDocumentRequestRepository {
  async create(dto) { throw new Error('Not implemented'); }
  async findById(id) { throw new Error('Not implemented'); }
  async findAll(options) { throw new Error('Not implemented'); }
}
```

### Step 2: Create Repository Implementation

```javascript
// repositories/implementations/DocumentRequestRepository.js
class DocumentRequestRepository {
  async create(dto) {
    // Database logic here
  }
}
```

### Step 3: Create DTO

```javascript
// dto/DocumentRequestDTO.js
class DocumentRequestDTO {
  static fromRequest(body) {
    return new this({
      documentType: body.document_type,
      purpose: body.purpose,
      // ...
    });
  }
}
```

### Step 4: Create Use Cases

```javascript
// useCases/documentRequest/CreateDocumentRequestUseCase.js
class CreateDocumentRequestUseCase {
  constructor(documentRequestRepository, emailService) {
    this.documentRequestRepository = documentRequestRepository;
    this.emailService = emailService;
  }

  async execute(dto, user) {
    // Business logic here
  }
}
```

### Step 5: Register in Container

```javascript
// container/index.js
this.documentRequestRepository = new DocumentRequestRepository();
this.createDocumentRequestUseCase = new CreateDocumentRequestUseCase(
  this.documentRequestRepository,
  emailService
);
```

### Step 6: Update Controller

```javascript
// controllers/documentRequestController.js
exports.createDocumentRequest = async (req, res, next) => {
  const dto = DocumentRequestDTO.fromRequest(req.body);
  const useCase = container.get('createDocumentRequestUseCase');
  const result = await useCase.execute(dto, req.user);
  res.status(201).json(result.toObject());
};
```

## Testing

### Unit Test Example

```javascript
const CreateMassIntentionUseCase = require('../useCases/massIntention/CreateMassIntentionUseCase');
const MassIntentionDTO = require('../dto/MassIntentionDTO');

describe('CreateMassIntentionUseCase', () => {
  let useCase;
  let mockRepository;
  let mockParishRepository;
  let mockEmailService;

  beforeEach(() => {
    mockRepository = { create: jest.fn() };
    mockParishRepository = { findById: jest.fn() };
    mockEmailService = { sendNotification: jest.fn() };
    
    useCase = new CreateMassIntentionUseCase(
      mockRepository,
      mockParishRepository,
      mockEmailService
    );
  });

  it('should create mass intention successfully', async () => {
    const dto = new MassIntentionDTO({ type: 'Thanksgiving', ... });
    mockParishRepository.findById.mockResolvedValue({ id: 1 });
    mockRepository.create.mockResolvedValue(dto);

    const result = await useCase.execute(dto, { userId: 1 });

    expect(result).toEqual(dto);
    expect(mockRepository.create).toHaveBeenCalledWith(dto);
  });

  it('should throw error if parish not found', async () => {
    mockParishRepository.findById.mockResolvedValue(null);

    await expect(useCase.execute(dto, { userId: 1 })).rejects.toThrow('Parish not found');
  });
});
```

## Benefits of This Architecture

| Benefit | Description |
|---------|-------------|
| **Testability** | Each layer can be tested independently with mocks |
| **Maintainability** | Clear separation of concerns |
| **Flexibility** | Easy to swap implementations (database, external services) |
| **Scalability** | Use cases can be extracted to microservices if needed |
| **Readability** | Business logic is in one place (use cases) |

## Next Steps

1. **Complete migration** for remaining modules (Auth, Parish, Booking)
2. **Add comprehensive tests** for all use cases
3. **Add more DTOs** for request/response validation
4. **Consider adding** a service layer abstraction for external services
