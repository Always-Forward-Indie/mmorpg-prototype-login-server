# Login Server — Client API Reference

**Transport:** TCP / JSON, delimiter `\n`  
**Max message size:** 8 KB  
**Host/Port:** configured in `config.json` (default `27014`)

---

## Common Packet Structure

### Request (Client → Server)
```json
{
  "header": {
    "eventType": "<eventType>",
    "clientId": 0,
    "hash": ""
  },
  "body": {}
}
```

### Response (Server → Client)
```json
{
  "header": {
    "eventType": "<eventType>",
    "status": "success | error",
    "message": "Human-readable message or error code",
    "clientId": 0,
    "hash": ""
  },
  "body": {}
}
```

`clientId` and `hash` are **0 / empty** on the very first request. After successful login or registration the client must store and send them with every subsequent request.

---

## 1. Register Account

**Request eventType:** `registerAccount`  
**Auth required:** No

### Request
```json
{
  "header": { "eventType": "registerAccount" },
  "body": {
    "login":    "MyLogin",
    "password": "MyPassword123",
    "email":    "optional@example.com"
  }
}
```

| Field      | Type   | Required | Constraints                              |
|------------|--------|----------|------------------------------------------|
| `login`    | string | Yes      | 3–20 chars, `[A-Za-z0-9_]` only         |
| `password` | string | Yes      | 8–100 chars                              |
| `email`    | string | No       | Must contain `@` if provided            |

### Success Response
```json
{
  "header": {
    "eventType": "registerAccount",
    "status":    "success",
    "message":   "Registration successful",
    "clientId":  42,
    "hash":      "550e8400-e29b-41d4-a716-446655440000",
    "login":     "MyLogin"
  },
  "body": {}
}
```

### Error Codes

| `message`               | Meaning                                    |
|-------------------------|--------------------------------------------|
| `ERR_LOGIN_INVALID`     | Login format check failed                  |
| `ERR_LOGIN_TAKEN`       | Login already registered (case-insensitive)|
| `ERR_PASSWORD_TOO_SHORT`| Password shorter than 8 characters        |
| `ERR_PASSWORD_TOO_LONG` | Password longer than 100 characters       |
| `ERR_EMAIL_INVALID`     | Email provided but has no `@`             |
| `ERR_REGISTER_FAILED`   | Internal/DB error                          |

---

## 2. Authenticate (Login)

**Request eventType:** `authentificationClient`  
**Auth required:** No

### Request
```json
{
  "header": { "eventType": "authentificationClient" },
  "body": {
    "login":    "MyLogin",
    "password": "MyPassword123"
  }
}
```

### Success Response
```json
{
  "header": {
    "eventType": "authentificationClient",
    "status":    "success",
    "message":   "Authentication success for user!",
    "clientId":  42,
    "hash":      "550e8400-e29b-41d4-a716-446655440000",
    "login":     "MyLogin"
  },
  "body": {}
}
```

### Error Response
```json
{
  "header": {
    "eventType": "authentificationClient",
    "status":    "error",
    "message":   "Authentication failed for user!",
    "clientId":  0,
    "hash":      ""
  },
  "body": {}
}
```

---

## 3. Get Character Creation Options

**Request eventType:** `getCharacterCreationOptions`  
**Auth required:** Yes (`clientId` + `hash`)

Returns available classes, races and genders for the character creation screen. Call this **once** after login/registration, before showing the creation UI.

### Request
```json
{
  "header": {
    "eventType": "getCharacterCreationOptions",
    "clientId":  42,
    "hash":      "550e8400-..."
  },
  "body": {}
}
```

### Success Response
```json
{
  "header": {
    "eventType": "getCharacterCreationOptions",
    "status":    "success",
    "message":   "Options retrieved successfully",
    "clientId":  42,
    "hash":      "550e8400-..."
  },
  "body": {
    "classes": [
      { "id": 1, "name": "Mage",    "slug": "mage",    "description": "..." },
      { "id": 2, "name": "Warrior", "slug": "warrior", "description": "..." }
    ],
    "races": [
      { "id": 1, "name": "Human", "slug": "human" }
    ],
    "genders": [
      { "id": 0, "name": "male",   "label": "Male"   },
      { "id": 1, "name": "female", "label": "Female" }
    ]
  }
}
```

Use `name` field values directly in the `createCharacter` request.

---

## 4. Get Characters List

**Request eventType:** `getCharactersList`  
**Auth required:** Yes

### Request
```json
{
  "header": {
    "eventType": "getCharactersList",
    "clientId":  42,
    "hash":      "550e8400-..."
  },
  "body": {}
}
```

### Success Response
```json
{
  "header": {
    "eventType": "getCharactersList",
    "status":    "success",
    "message":   "Characters list retrieved successfully!",
    "clientId":  42,
    "hash":      "550e8400-..."
  },
  "body": {
    "charactersList": [
      {
        "characterId":    7,
        "characterName":  "Gandalf",
        "characterClass": "Mage",
        "characterLevel": 5
      }
    ]
  }
}
```

Empty `charactersList` array `[]` means the account has no characters yet.

---

## 5. Create Character

**Request eventType:** `createCharacter`  
**Auth required:** Yes  
**Limit:** Max 4 characters per account

### Request
```json
{
  "header": {
    "eventType": "createCharacter",
    "clientId":  42,
    "hash":      "550e8400-..."
  },
  "body": {
    "characterName":   "Gandalf",
    "characterClass":  "Mage",
    "characterRace":   "Human",
    "characterGender": "male"
  }
}
```

| Field             | Type   | Required | Source                          |
|-------------------|--------|----------|---------------------------------|
| `characterName`   | string | Yes      | 2–20 chars, letters and spaces  |
| `characterClass`  | string | Yes      | `name` from `getCharacterCreationOptions` → `classes` |
| `characterRace`   | string | Yes      | `name` from `getCharacterCreationOptions` → `races`   |
| `characterGender` | string | Yes      | `name` from `getCharacterCreationOptions` → `genders` |

The server automatically:
- Grants default skills for the chosen class
- Adds starter items (weapon + 50 gold) to the inventory
- Sets starting position (zone 1 — village)
- Initialises HP/MP

### Success Response
```json
{
  "header": {
    "eventType": "createCharacter",
    "status":    "success",
    "message":   "Character created successfully",
    "clientId":  42,
    "hash":      "550e8400-..."
  },
  "body": {
    "characterId": 7
  }
}
```

### Error Codes

| `message`                 | Meaning                                     |
|---------------------------|---------------------------------------------|
| `ERR_CHAR_NAME_TAKEN`     | Name already used (case-insensitive)        |
| `ERR_CHAR_NAME_INVALID`   | Name format check failed                   |
| `ERR_CHAR_SLOT_FULL`      | Account has reached the 4-character limit  |
| `ERR_CHAR_MISSING_FIELD`  | One or more required fields are empty      |
| `ERR_CHAR_CREATE_FAILED`  | Internal/DB error                           |
| `Unauthorized`            | Invalid or missing `clientId` / `hash`     |

---

## 6. Delete Character

**Request eventType:** `deleteCharacter`  
**Auth required:** Yes  
**Note:** Soft-delete — character data is retained in the DB with `deleted_at` timestamp. The operation is **irreversible** from the client's perspective.

### Request
```json
{
  "header": {
    "eventType": "deleteCharacter",
    "clientId":  42,
    "hash":      "550e8400-..."
  },
  "body": {
    "characterId": 7
  }
}
```

### Success Response
```json
{
  "header": {
    "eventType": "deleteCharacter",
    "status":    "success",
    "message":   "Character deleted successfully",
    "clientId":  42,
    "hash":      "550e8400-..."
  },
  "body": {
    "characterId": 7
  }
}
```

### Error Codes

| `message`                    | Meaning                                           |
|------------------------------|---------------------------------------------------|
| `ERR_CHARACTER_NOT_FOUND`    | Character doesn't exist or belongs to another account |
| `ERR_INVALID_CHARACTER_ID`   | `characterId` is missing or zero                |
| `Unauthorized`               | Invalid or missing `clientId` / `hash`           |

---

## 7. Ping

**Request eventType:** `pingClient`  
**Auth required:** No

### Request
```json
{
  "header": { "eventType": "pingClient" }
}
```

### Response
```json
{
  "header": {
    "eventType":        "pingClient",
    "status":           "success",
    "message":          "Pong!",
    "serverRecvMs":     1713567890123,
    "serverSendMs":     1713567890125,
    "clientSendMsEcho": 1713567890100
  },
  "body": {}
}
```

---

## Typical Client Flow

```
1. [Optional] registerAccount  →  receive clientId + hash
            OR
   authentificationClient      →  receive clientId + hash

2. getCharacterCreationOptions  →  populate class/race/gender dropdowns

3a. [New account] createCharacter  →  receive characterId
3b. [Existing]   getCharactersList →  show character list
                 createCharacter   →  (if creating new)

4. deleteCharacter  →  (optional, on character deletion screen)

5. Connect to Game Server with clientId + hash + characterId
   (see Game Server / Chunk Server protocol documentation)
```

---

## Error Handling Guidelines

- All error responses have `"status": "error"` in the header.
- The `message` field contains a machine-readable error code (`ERR_*`) or a human-readable string.
- Map `ERR_*` codes to localized UI strings on the client side; never display raw codes to the player.
- On `Unauthorized` response: clear stored `clientId`/`hash` and redirect to the login screen.
